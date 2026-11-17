# Assignment 3 - CI/CD with GitHub Actions

A small Bash application with automated linting, tests and a Docker build,
run on every push and pull request by a GitHub Actions pipeline. Nothing is
deployed; the pipeline only validates, tests and smoke-tests the build.

## Project structure

```
assignment-3/
├── README.md
├── Dockerfile
├── compose.yaml
├── .dockerignore
├── grade.sh                  # local grading script (supplied by instructor)
├── app/
│   └── app.sh                # the application
├── scripts/
│   ├── lint.sh               # file and syntax checks
│   └── build.sh              # docker build and smoke tests
├── tests/
│   └── test.sh               # application test suite
└── .github/
    └── workflows/
        └── ci.yml            # CI pipeline
```

## Requirements

- Bash, Docker and Docker Compose v2
- Linux (the app reads `/proc` and uses `getent`)

## Setup

```bash
git clone <your-repository-url>
cd assignment-3
chmod +x grade.sh app/*.sh scripts/*.sh tests/*.sh
```

## Usage

```bash
./app/app.sh help
./app/app.sh system-info
./app/app.sh check-host <host>
./app/app.sh check-port <host> <port>
```

| Command | Description |
|---------|-------------|
| `system-info` | Hostname, user, date, OS, kernel, uptime, CPU, memory, working directory |
| `check-host <host>` | Validates the host, resolves it and pings it |
| `check-port <host> <port>` | Validates the host and port (1-65535) and tests a TCP connection |
| `help` | Shows usage |

| Exit code | Meaning |
|-----------|---------|
| 0 | success |
| 1 | a check failed (host unresolvable or unreachable, port closed) |
| 2 | invalid command, missing argument or invalid input |

## Docker

```bash
docker build -t devops-tool .
docker run --rm devops-tool help
docker run --rm devops-tool system-info
docker compose run --rm app system-info
```

## Testing

```bash
./scripts/lint.sh     # required files exist and every script passes bash -n
./tests/test.sh       # 12 tests of the application
./scripts/build.sh    # builds the image and runs smoke tests
./grade.sh            # the instructor's grading script
```

## CI pipeline

`.github/workflows/ci.yml` runs on every `push` and `pull_request` with three
jobs that depend on each other:

```
validate  ->  test  ->  docker
```

| Job | Runs | Needs |
|-----|------|-------|
| `validate` | `scripts/lint.sh` | - |
| `test` | `tests/test.sh` | `validate` |
| `docker` | `scripts/build.sh` | `test` |

Each job uses `needs:` so a failure stops everything after it.

## CI failure demonstration

A deliberate syntax error was committed on the branch `demo/ci-failure`:

1. **Failing run:** [run 44043201066](https://github.com/HupHOP/assignment-3/actions/runs/44043201066).
   `validate` failed because `lint.sh` ran `bash -n` on `app/app.sh` and found
   `syntax error: unexpected end of file from
   `docker` were skipped because of `needs:`.
2. **Fix:** the bad commit was undone with `git revert`, and the push triggered
   [run 44044393266](https://github.com/HupHOP/assignment-3/actions/runs/44044393266),
   where all three jobs passed.
3. A pull request from the same branch triggered
   [run 44044769492](https://github.com/HupHOP/assignment-3/actions/runs/44044769492),
   which also passed, showing the `pull_request` trigger.

The final workflow on `main` passes.

## Git workflow

- `feature/ci-pipeline` holds the application, tests, Docker files and workflow,
  and was merged into `main` with a merge commit.
- `demo/ci-failure` holds the failing commit and its fix, and was merged
  through pull request #1.
- Both branches were kept for history.
