#!/usr/bin/env bash
set -u

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT" || exit 1

status=0

required=(
    README.md
    app/app.sh
    scripts/lint.sh
    scripts/build.sh
    tests/test.sh
    Dockerfile
    compose.yaml
    .dockerignore
    .github/workflows/ci.yml
)

echo "Checking required files..."
for f in "${required[@]}"; do
    if [[ -f "$f" ]]; then
        echo "OK:   $f exists"
    else
        echo "FAIL: missing required file: $f" >&2
        status=1
    fi
done

echo "Checking Bash syntax..."
for f in app/*.sh scripts/*.sh tests/*.sh; do
    [[ -f "$f" ]] || continue
    if bash -n "$f"; then
        echo "OK:   syntax $f"
    else
        echo "FAIL: syntax error in $f" >&2
        status=1
    fi
done

if (( status == 0 )); then
    echo "Lint passed"
else
    echo "Lint failed" >&2
fi
exit "$status"
