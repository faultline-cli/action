# Faultline Action

[![faultline-cli/faultline](https://img.shields.io/badge/faultline-cli%2Ffaultline-blue)](https://github.com/faultline-cli/faultline)

Stop spelunking CI logs. Add one step to your failure path and get a deterministic, evidence-backed diagnosis from [faultline](https://github.com/faultline-cli/faultline).

```yaml
- name: Diagnose failure
  if: failure()
  uses: faultline-cli/faultline-action@0.1.0
  with:
    log: build.log
```

That's it. Faultline installs itself, analyzes the log, writes a diagnosis to the job summary, and uploads the JSON artifacts.

## Inputs

| Input | Required | Default | Description |
|-------|----------|---------|-------------|
| `log` | **yes** | — | Path to the failing build log file |
| `version` | no | latest | Faultline version to install (e.g. `v0.4.3`) |
| `format` | no | `markdown` | Output format for the human-readable summary: `text` or `markdown` |
| `annotations` | no | `false` | Emit GitHub-native CI annotations alongside the summary |
| `json` | no | `true` | Produce a machine-readable JSON analysis artifact |
| `bayes` | no | `false` | Add Bayesian ranking hints to the JSON analysis output |
| `workflow` | no | `true` | Produce a deterministic `workflow.v1` handoff artifact |
| `workflow-mode` | no | `agent` | Mode passed to `faultline workflow`: `agent` or `human` |
| `fail-on-silent` | no | `false` | Exit non-zero if silent failure detectors fire |
| `delta` | no | `false` | Enable experimental delta analysis against the last successful run on the same branch |
| `github-token` | no | `''` | GitHub token for the delta provider (required when `delta` is `true`) |
| `upload-artifacts` | no | `true` | Upload JSON and markdown outputs as workflow artifacts |
| `artifact-retention-days` | no | `30` | Number of days to retain uploaded artifacts |
| `job-summary` | no | `true` | Append the markdown analysis to the GitHub Actions job summary |

## Outputs

| Output | Description |
|--------|-------------|
| `summary-markdown` | Path to the markdown analysis summary file |
| `analysis-json` | Path to the JSON analysis artifact (when `json` is `true`) |
| `workflow-json` | Path to the `workflow.v1` JSON artifact (when `workflow` is `true`) |
| `failure-id` | The matched failure ID from the top diagnosis (empty when no match) |

## Usage

### Basic — diagnose on failure

```yaml
jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - name: Build
        run: make build 2>&1 | tee build.log

      - name: Diagnose failure
        if: failure()
        uses: faultline-cli/faultline-action@0.1.0
        with:
          log: build.log
```

### Pin to a specific faultline version

```yaml
- name: Diagnose failure
  if: failure()
  uses: faultline-cli/faultline-action@0.1.0
  with:
    log: build.log
    version: v0.4.3
```

### Add GitHub CI annotations

```yaml
- name: Diagnose failure
  if: failure()
  uses: faultline-cli/faultline-action@0.1.0
  with:
    log: build.log
    annotations: 'true'
```

### Use the `failure-id` output to gate follow-up steps

```yaml
- name: Diagnose failure
  if: failure()
  id: diagnosis
  uses: faultline-cli/faultline-action@0.1.0
  with:
    log: build.log

- name: Open remediation issue
  if: failure() && steps.diagnosis.outputs.failure-id != ''
  run: |
    echo "Failure: ${{ steps.diagnosis.outputs.failure-id }}"
    # hand off to your automation here
```

### Enable Bayesian ranking and experimental delta analysis

```yaml
- name: Diagnose failure
  if: failure()
  uses: faultline-cli/faultline-action@0.1.0
  with:
    log: build.log
    json: 'true'
    bayes: 'true'
    delta: 'true'
    github-token: ${{ secrets.GITHUB_TOKEN }}
```

### Silent failure detection

```yaml
- name: Check for silent failures
  uses: faultline-cli/faultline-action@0.1.0
  with:
    log: build.log
    fail-on-silent: 'true'
```

### Minimal — summary and JSON only, no artifact upload

```yaml
- name: Diagnose failure
  if: failure()
  uses: faultline-cli/faultline-action@0.1.0
  with:
    log: build.log
    workflow: 'false'
    upload-artifacts: 'false'
```

## Artifacts

When `upload-artifacts` is `true` (the default), the action uploads a `faultline-analysis` artifact containing:

- `faultline-summary.md` — the human-readable markdown diagnosis
- `faultline-analysis.json` — the structured analysis (when `json` is `true`)
- `faultline-workflow.json` — the `workflow.v1` remediation handoff (when `workflow` is `true`)

The JSON schemas are stable. See [workflow.v1 contract](https://github.com/faultline-cli/faultline/blob/main/docs/github-action-contract.md) for details.

## How it works

1. **Install** — downloads the faultline binary from the [faultline releases](https://github.com/faultline-cli/faultline/releases) using the official install script
2. **Analyze** — runs `faultline analyze` to match the log against 187 bundled playbooks and produce evidence-backed diagnosis
3. **Workflow** — optionally runs `faultline workflow` to produce a typed `workflow.v1` handoff artifact for downstream automation
4. **Summary** — writes the markdown diagnosis to the GitHub Actions job summary
5. **Upload** — optionally uploads the JSON and markdown outputs as workflow artifacts

No AI, no guesswork. The same log in always produces the same diagnosis out.

## License

MIT
