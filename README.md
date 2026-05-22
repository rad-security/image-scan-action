# RAD Image Scan Action

![GitHub release (latest by date)](https://img.shields.io/github/v/release/rad-security/image-scan-action)

Scans container images for vulnerabilities using [Grype](https://github.com/anchore/grype). When configured with [RAD Security](https://rad.security) credentials, the report is enriched with data about the same image as it is *currently deployed* in your fleet — vulnerability count deltas vs deployed instances, regression detection, and distro EOL warnings.

This action wraps [`rad-image-scanner`](https://github.com/rad-security/image-scanner).

## Plain (Grype-only) usage

```yaml
- name: Build local image
  uses: docker/build-push-action@v6
  with:
    tags: localbuild/testimage:latest
    push: false
    load: true

- name: Scan image
  uses: rad-security/image-scan-action@v1
  with:
    image: localbuild/testimage:latest
    fail_on_severity: medium
    ignore_cves: |
      CVE-2021-1234
      CVE-2021-5678
```

## RAD-enriched usage

Add your RAD access key and account IDs. Credentials must be passed via `env:` (not `with:`) so they are not echoed to workflow logs.

```yaml
- name: Scan image with RAD enrichment
  uses: rad-security/image-scan-action@v1
  env:
    RAD_ACCESS_KEY_ID: ${{ secrets.RAD_ACCESS_KEY_ID }}
    RAD_SECRET_KEY:    ${{ secrets.RAD_SECRET_KEY }}
  with:
    image: ghcr.io/example/svc:v1.2.3
    format: sarif
    rad_account_ids: acct_1,acct_2
    rad_fail_on_regression: critical
    rad_fail_on_eol: "true"

- name: Upload SARIF
  if: success() || failure()
  uses: github/codeql-action/upload-sarif@v3
  with:
    sarif_file: ${{ steps.scan.outputs.sarif }}

- name: Upload RAD report
  if: success() || failure()
  uses: actions/upload-artifact@v4
  with:
    name: rad-report
    path: ${{ steps.scan.outputs.rad_report }}
```

When `format: sarif`, the RAD enrichment is injected into the SARIF document under `runs[].properties.rad` (toggle with `rad_annotate_sarif: false`).

## Inputs

| Input | Description |
|---|---|
| `image` | Image to scan. Required unless `sbom` is set. |
| `sbom` | Path to a Syft JSON SBOM. Used instead of `image`. |
| `format` | `table` (default) \| `json` \| `sarif` \| `cyclonedx`. |
| `fail_on_severity` | Grype gate: `negligible` \| `low` \| `medium` \| `high` \| `critical`. |
| `ignore_cves` | Multiline list of CVE IDs to ignore. |
| `rad_account_ids` | Comma-separated account IDs. Triggers RAD enrichment when set. |
| `rad_fail_on_regression` | `critical` \| `high` \| `medium` \| `low` \| `any`. Fails the workflow if the new scan adds vulnerabilities at this severity or higher vs any deployed instance. |
| `rad_fail_on_eol` | Set to `true` to fail the workflow if the scanned image is built on an end-of-life distro. |
| `rad_api_url` | Override the RAD API base URL (default `https://api.rad.security`). |
| `rad_report` | Path for the RAD enrichment JSON (default `rad-report.json`). |
| `rad_annotate_sarif` | When `format: sarif`, inject the RAD report into the SARIF document. Default `true`. |

## Outputs

| Output | When set | Description |
|---|---|---|
| `sarif` | `format: sarif` | Path to the SARIF report. |
| `rad_report` | `rad_account_ids` set | Path to the RAD enrichment JSON. |

## Credentials

`RAD_ACCESS_KEY_ID` and `RAD_SECRET_KEY` must be supplied via the workflow's `env:` block (typically from `secrets`). They are intentionally not exposed as Action inputs.

## Breaking changes from v0.x

- New action major version. v0.x flags `fail_on_severity`, `ignore_cves`, `image`, `format` are preserved; everything else is new.
- Output format `table` now uses grype's native table format, not the legacy template.

## License

Apache-2.0. Grype is © Anchore, Inc., distributed under Apache-2.0.
