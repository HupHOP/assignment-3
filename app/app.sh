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
