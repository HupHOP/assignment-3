#!/usr/bin/env bash
set -u

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
IMAGE="devops-tool"
status=0

echo "Building image $IMAGE..."
if ! docker build -t "$IMAGE" "$ROOT"; then
    echo "FAIL: docker build failed" >&2
    exit 1
fi

# smoke NAME EXPECTED_EXIT_CODE ARGS...
smoke() {
    local name="$1" want="$2"
    shift 2
    docker run --rm "$IMAGE" "$@" >/dev/null 2>&1
    local rc=$?
    if [[ $rc -eq $want ]]; then
        echo "PASS: $name"
    else
        echo "FAIL: $name (exit $rc, expected $want)" >&2
        status=1
    fi
}

smoke "help exits 0" 0 help
smoke "system-info exits 0" 0 system-info
smoke "invalid command exits 2" 2 invalid-command

if (( status == 0 )); then
    echo "Build and smoke tests passed"
else
    echo "Smoke tests failed" >&2
fi
exit "$status"
