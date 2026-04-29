#!/bin/sh
set -eu

OUTDIR="${RUNNER_TEMP}/faultline"
mkdir -p "$OUTDIR"

SUMMARY_MD="$OUTDIR/faultline-summary.md"
ANALYSIS_JSON="$OUTDIR/faultline-analysis.json"
WORKFLOW_JSON="$OUTDIR/faultline-workflow.json"

# Use the provided github-token when set (needed for the delta provider)
if [ -n "${INPUT_GITHUB_TOKEN:-}" ]; then
  export GITHUB_TOKEN="$INPUT_GITHUB_TOKEN"
fi

# Build optional flags for faultline analyze
ANNOTATION_FLAG=""
if [ "${INPUT_ANNOTATIONS:-false}" = "true" ]; then
  ANNOTATION_FLAG="--ci-annotations"
fi

SILENT_FLAG=""
if [ "${INPUT_FAIL_ON_SILENT:-false}" = "true" ]; then
  SILENT_FLAG="--fail-on-silent"
fi

# Generate human-readable summary
# shellcheck disable=SC2086
faultline analyze "$INPUT_LOG" --format "$INPUT_FORMAT" $ANNOTATION_FLAG $SILENT_FLAG > "$SUMMARY_MD"
printf '%s\n' "summary-markdown=$SUMMARY_MD" >> "$GITHUB_OUTPUT"

# Generate JSON analysis when requested
if [ "${INPUT_JSON:-true}" = "true" ]; then
  BAYES_FLAG=""
  if [ "${INPUT_BAYES:-false}" = "true" ]; then
    BAYES_FLAG="--bayes"
  fi

  if [ "${INPUT_DELTA:-false}" = "true" ]; then
    # shellcheck disable=SC2086
    FAULTLINE_EXPERIMENTAL_PROVIDER_DELTA=1 \
      faultline analyze "$INPUT_LOG" --json $BAYES_FLAG --delta-provider github-actions > "$ANALYSIS_JSON"
  else
    # shellcheck disable=SC2086
    faultline analyze "$INPUT_LOG" --json $BAYES_FLAG > "$ANALYSIS_JSON"
  fi

  printf '%s\n' "analysis-json=$ANALYSIS_JSON" >> "$GITHUB_OUTPUT"

  # Extract failure_id from JSON (portable sed, no jq dependency)
  FAILURE_ID=$(sed -n 's/.*"failure_id"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' "$ANALYSIS_JSON" 2>/dev/null | head -1 || true)
  printf '%s\n' "failure-id=${FAILURE_ID:-}" >> "$GITHUB_OUTPUT"
else
  printf '%s\n' "failure-id=" >> "$GITHUB_OUTPUT"
fi

# Generate workflow.v1 artifact when requested
if [ "${INPUT_WORKFLOW:-true}" = "true" ]; then
  faultline workflow "$INPUT_LOG" --json --mode "$INPUT_WORKFLOW_MODE" > "$WORKFLOW_JSON"
  printf '%s\n' "workflow-json=$WORKFLOW_JSON" >> "$GITHUB_OUTPUT"
else
  printf '%s\n' "workflow-json=" >> "$GITHUB_OUTPUT"
fi
