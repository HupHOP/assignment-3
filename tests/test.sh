#!/usr/bin/env bash
set -u

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
APP="$ROOT/app/app.sh"
PASS=0
FAIL=0

# run_test NAME EXPECTED_EXIT_CODE EXPECTED_TEXT ARGS...
run_test() {
    local name="$1" want_rc="$2" want_text="$3"
    shift 3
    local output rc
    output="$("$APP" "$@" 2>&1)"
    rc=$?
    if [[ $rc -eq $want_rc ]] && grep -q -- "$want_text" <<< "$output"; then
        echo "PASS: $name"
        PASS=$((PASS + 1))
    else
        echo "FAIL: $name (exit $rc, expected $want_rc; looking for '$want_text')"
        sed 's/^/    /' <<< "$output"
        FAIL=$((FAIL + 1))
    fi
}

run_test "help exits 0 and shows usage" 0 "Usage: app.sh" help
run_test "system-info exits 0 and shows hostname" 0 "Hostname" system-info
run_test "no command is rejected" 2 "no command given" 
run_test "unknown command is rejected" 2 "unknown command" nonsense
run_test "check-host without a host is rejected" 2 "requires a host" check-host
run_test "check-host rejects a bad hostname" 2 "invalid hostname" check-host 'a;b'
run_test "check-host passes for localhost" 0 "host check passed" check-host localhost
run_test "check-host falls for an unresolvable host" 1 "FAILED" check-host no-such-host.invalid
run_test "check-port without a port is rejected" 2 "requires a host and a port" check-port localhost 
run_test "check-port rejects a non-numeric port" 2 "whole number" check-port localhost abc
run_test "check-port rejects port 0" 2 "whole number" check-port localhost 0
run_test "check-port rejects port 65536" 2 "whole number" check-port localhost 65536

echo
echo "Passed: $PASS  Failed: $FAIL"
[[ $FAIL -eq 0 ]]
