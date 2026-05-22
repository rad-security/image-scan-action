#!/bin/sh
set -eu

# --- Translate inputs to CLI args ------------------------------------------

ARGS=""

# Output format (table | json | sarif | cyclonedx).
SARIF_FILE=""
case "${FORMAT:-table}" in
  sarif)
    SARIF_FILE="./sarif_output.json"
    ARGS="$ARGS -o sarif --file $SARIF_FILE"
    echo "sarif=$SARIF_FILE" >> "$GITHUB_OUTPUT"
    ;;
  json|cyclonedx|table)
    ARGS="$ARGS -o ${FORMAT}"
    ;;
  *)
    echo "unknown format: $FORMAT" >&2
    exit 2
    ;;
esac

# Grype fail-on severity (independent of RAD regression gate).
if [ -n "${FAIL_ON_SEVERITY:-}" ]; then
  ARGS="$ARGS --fail-on ${FAIL_ON_SEVERITY}"
fi

# Ignore-CVE list: grype takes this via a config file.
if [ -n "${IGNORE_CVES:-}" ]; then
  CONFIG=/tmp/grype-config.yaml
  echo "ignore:" > "$CONFIG"
  echo "$IGNORE_CVES" | while IFS= read -r cve; do
    [ -z "$cve" ] && continue
    echo "  - vulnerability: $cve" >> "$CONFIG"
  done
  ARGS="$ARGS -c $CONFIG"
fi

# RAD enrichment flags. RAD_ACCESS_KEY_ID and RAD_SECRET_KEY are passed via
# the workflow's `env:` block — we don't accept them as `inputs:` because
# Actions inputs are visible in workflow logs.
if [ -n "${RAD_ACCOUNT_IDS:-}" ]; then
  if [ -n "${RAD_FAIL_ON_REGRESSION:-}" ]; then
    ARGS="$ARGS --rad-fail-on-regression ${RAD_FAIL_ON_REGRESSION}"
  fi
  if [ "${RAD_FAIL_ON_EOL:-}" = "true" ]; then
    ARGS="$ARGS --rad-fail-on-eol"
  fi
  if [ -n "${RAD_REPORT:-}" ]; then
    ARGS="$ARGS --rad-report ${RAD_REPORT}"
    echo "rad_report=${RAD_REPORT}" >> "$GITHUB_OUTPUT"
  fi
  if [ "${FORMAT}" = "sarif" ] && [ "${RAD_ANNOTATE_SARIF:-true}" = "true" ]; then
    ARGS="$ARGS --rad-annotate-sarif"
  fi
fi

# Target: image ref or sbom:path. Image takes precedence.
if [ -n "${IMAGE:-}" ]; then
  TARGET="${IMAGE}"
elif [ -n "${SBOM:-}" ]; then
  TARGET="sbom:${SBOM}"
else
  echo "either 'image' or 'sbom' input is required" >&2
  exit 2
fi

# shellcheck disable=SC2086
exec /usr/local/bin/rad-image-scanner ${ARGS} "${TARGET}"
