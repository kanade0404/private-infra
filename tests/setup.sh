#!/usr/bin/env bash
set -euo pipefail

repo="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
fixture="$(mktemp -d)"
trap 'rm -rf "$fixture"' EXIT
mkdir -p "$fixture/repo with spaces/scripts" "$fixture/bin"
cp "$repo/scripts/setup" "$fixture/repo with spaces/scripts/setup"
setup="$fixture/repo with spaces/scripts/setup"
export SETUP_TEST_LOG="$fixture/calls"
export PATH="$fixture/bin:$PATH"
unset PRIVATE_INFRA_SETUP_IN_NIX GOOGLE_APPLICATION_CREDENTIALS GOOGLE_CREDENTIALS GRAFANA_URL GRAFANA_AUTH

cat > "$fixture/bin/mock" <<'MOCK'
#!/usr/bin/env bash
set -euo pipefail
tool="${0##*/}"
if [[ "$tool" == nix ]]; then
  [[ "$1" == develop && "$3" == --command ]]
  shift 3
  exec "$@"
fi
printf '%s' "$tool" >> "$SETUP_TEST_LOG"
printf ' %s' "$@" >> "$SETUP_TEST_LOG"
printf '\n' >> "$SETUP_TEST_LOG"
if [[ "$tool" == aws && "$1 $2" == 'configure get' ]]; then
  if [[ "${SETUP_TEST_NEW_PROFILE:-0}" == 1 ]]; then
    exit 1
  fi
  if [[ "$3" == sso_session ]]; then
    if [[ "${SETUP_TEST_DISTINCT_SESSIONS:-0}" == 1 ]]; then
      printf '%s\n' "$5"
    else
      printf '%s\n' shared-session
    fi
  else
    exit 1
  fi
fi
MOCK
chmod +x "$fixture/bin/mock"
for tool in nix aws gcloud terraform tofu lefthook; do
  ln -s mock "$fixture/bin/$tool"
done

run_setup() {
  : > "$SETUP_TEST_LOG"
  bash "$setup" "$@" > "$fixture/output" 2>&1
}

expect_call() {
  grep -Fxq -- "$*" "$SETUP_TEST_LOG"
}

run_setup gcp
expect_call 'gcloud auth login'
expect_call 'gcloud auth application-default login'
expect_call 'gcloud auth application-default set-quota-project kanade0404'
expect_call 'terraform -chdir=gcp init'

run_setup aws personal-dev
[[ "$(grep -c '^aws sso login ' "$SETUP_TEST_LOG")" == 1 ]]
expect_call 'aws sts get-caller-identity --profile management-admin'
expect_call 'aws sts get-caller-identity --profile personal-dev-admin'
expect_call 'tofu -chdir=aws/environments/personal-dev init'

SETUP_TEST_DISTINCT_SESSIONS=1 run_setup aws business-dev
[[ "$(grep -c '^aws sso login ' "$SETUP_TEST_LOG")" == 2 ]]
expect_call 'aws sso login --profile management-admin'
expect_call 'aws sso login --profile business-dev-admin'

SETUP_TEST_NEW_PROFILE=1 run_setup aws management
expect_call 'aws configure sso --profile management-admin'
expect_call 'tofu -chdir=aws/environments/management init'

if GOOGLE_APPLICATION_CREDENTIALS=/old/container.json run_setup gcp; then
  printf '%s\n' 'Expected credential override to be rejected' >&2
  exit 1
fi
[[ ! -s "$SETUP_TEST_LOG" ]]

if run_setup grafana; then
  printf '%s\n' 'Expected missing Grafana credentials to be rejected' >&2
  exit 1
fi
[[ ! -s "$SETUP_TEST_LOG" ]]
GRAFANA_URL=https://example.grafana.net GRAFANA_AUTH=test-token run_setup grafana
expect_call 'gcloud auth application-default login'
expect_call 'tofu -chdir=grafana init'
if grep -q test-token "$fixture/output" "$SETUP_TEST_LOG"; then
  printf '%s\n' 'Grafana token leaked into output' >&2
  exit 1
fi

if run_setup aws ../management; then
  printf '%s\n' 'Expected invalid environment to be rejected' >&2
  exit 1
fi
[[ ! -s "$SETUP_TEST_LOG" ]]
printf '%s\n' 'Setup smoke tests passed'
