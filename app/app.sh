#!/usr/bin/env bash
set -u

usage() {
    cat << 'EOF'
Usage: app.sh <command> [arguments]

Commands:
  system-info                 Show system information
  check-host <host>           Resolve and ping a host
  check-port <host> <port>    Check TCP connectivity to a port
  help                        Show this help message

Exit codes: 0 success, 1 check failed, 2 invalid command or input
EOF
}

row() {
    printf '%-18s: %s\n' "$1" "$2"
}

get_uptime() {
    awk '{
        s = int($1)
        printf "%d days, %d hours, %d minutes", int(s / 86400), int((s % 86400) / 3600), int((s % 3600) / 60)
    }' /proc/uptime
}

get_memory() {
    awk '
        /^MemTotal:/     {t = $2}
        /^MemAvailable:/ {a = $2}
        END {printf "Total: %d MiB | Available: %d MiB", t / 1024, a / 1024}
    ' /proc/meminfo
}

get_cpu_model() {
    local model
    model="$(awk -F': *' '/^model name/ {print $2; exit}' /proc/cpuinfo)"
    echo "${model:-$(uname -m)}"
}

cmd_system_info() {
    row "Hostname" "$(hostname)"
    row "Current User" "$(id -un)"
    row "Date/Time" "$(date '+%Y-%m-%d %H:%M:%S %Z')"
    row "Operating System" "$(grep '^PRETTY_NAME' /etc/os-release | cut -d= -f2 | tr -d '"')"
    row "Kernel Version" "$(uname -r)"
    row "Uptime" "$(get_uptime)"
    row "CPU Model" "$(get_cpu_model)"
    row "CPU Cores" "$(nproc)"
    row "Memory" "$(get_memory)"
    row "Working Directory" "$(pwd)"
}

is_valid_host() {
    local h="$1"
    [[ -n "$h" && ${#h} -le 253 ]] || return 1
    [[ "$h" != *..* ]] || return 1
    [[ "$h" =~ ^[A-Za-z0-9]([A-Za-z0-9.-]*[A-Za-z0-9])?$ ]]
}

is_valid_port() {
    local p="$1"
    [[ "$p" =~ ^[0-9]{1,5}$ ]] || return 1
    (( 10#$p >= 1 && 10#$p <= 65535 ))
}

cmd_check_host() {
    local host="$1"

    if ! is_valid_host "$host"; then
        echo "Error: invalid hostname or IP address: $host" >&2
        exit 2
    fi

    echo "Checking host: $host"

    local resolved=""
    if command -v getent >/dev/null 2>&1; then
        resolved="$(getent ahosts "$host" | awk 'NR==1 {print $1}')"
    fi
    if [[ -z "$resolved" ]]; then
        echo "Resolution: FAILED - could not resolve $host" >&2
        exit 1
    fi
    echo "Resolved address: $resolved"

    if ! command -v ping >/dev/null 2>&1; then
        echo "Ping: skipped (ping is not installed)"
    elif ping -c 2 -W 2 -- "$host" >/dev/null 2>&1; then
        echo "Ping: host is reachable"
    else
        echo "Ping: no reply from $host" >&2
        exit 1
    fi

    echo "Result: host check passed"
}

cmd_check_port() {
    local host="$1" port="$2"

    if ! is_valid_host "$host"; then
        echo "Error: invalid hostname or IP address: $host" >&2
        exit 2
    fi
    if ! is_valid_port "$port"; then
        echo "Error: port must be a whole number from 1 to 65535 (got '$port')" >&2
        exit 2
    fi
    port=$((10#$port))

    if timeout 5 bash -c 'exec 3<>"/dev/tcp/$1/$2"' _ "$host" "$port" 2>/dev/null; then
        echo "Port $port on $host: OPEN"
    else
        echo "Port $port on $host: CLOSED or unreachable" >&2
        exit 1
    fi
}

main() {
    if [[ $# -lt 1 ]]; then
        echo "Error: no command given" >&2
        usage >&2
        exit 2
    fi

    local cmd="$1"
    shift

    case "$cmd" in
        system-info)
            cmd_system_info
            ;;
        check-host)
            if [[ $# -lt 1 ]]; then
                echo "Error: 'check-host' requires a host" >&2
                usage >&2
                exit 2
            fi
            cmd_check_host "$1"
            ;;
        check-port)
            if [[ $# -lt 2 ]]; then
                echo "Error: 'check-port' requires a host and a port" >&2
                usage >&2
                exit 2
            fi
            cmd_check_port "$1" "$2"
            ;;
        help|-h|--help)
            usage
            ;;
        *)
            echo "Error: unknown command '$cmd'" >&2
            usage >&2
            exit 2
            ;;
    esac
}

main "$@"
