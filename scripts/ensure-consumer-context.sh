#!/usr/bin/env bash
# Ensure each linked repo has CONSUMER_CONTEXT.md, AGENTS.md, or AGENT.md.
# Missing repos get a PR that adds CONSUMER_CONTEXT.md (unless --apply is omitted).
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
LINKS="${ROOT}/org/links.yaml"
ORG="$(yq -r '.org // "chauhaidang"' "${LINKS}")"
CATALOGUE="${ROOT}/org/catalogue.md"
BRANCH="feat/add-consumer-context"
APPLY=0
ONLY_REPO=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --apply) APPLY=1; shift ;;
    --repo) ONLY_REPO="${2:-}"; shift 2 ;;
    -h|--help)
      cat <<'EOF'
Usage: ensure-consumer-context.sh [--apply] [--repo <name>]

Without --apply: print missing repos only.
With --apply: create branch + CONSUMER_CONTEXT.md + PR on each missing repo.
EOF
      exit 0
      ;;
    *) echo "unknown arg: $1" >&2; exit 1 ;;
  esac
done

role_for() {
  local name="$1"
  # one-line role from catalogue table rows: | `name` | role |
  local line
  line="$(rg -N "^\| \`${name}\` \|" "${CATALOGUE}" | head -1 || true)"
  if [[ -n "${line}" ]]; then
    echo "${line}" | awk -F'|' '{gsub(/^ +| +$/,"",$3); print $3}'
  else
    echo "XQ repository in org ${ORG}"
  fi
}

http_code() {
  local out
  out="$(gh api -i "$1" 2>&1 || true)"
  printf '%s\n' "${out}" | awk 'NR==1 {print $2; exit}'
}

has_context() {
  local name="$1" code
  for f in AGENTS.md AGENT.md CONSUMER_CONTEXT.md; do
    code="$(http_code "repos/${ORG}/${name}/contents/${f}")"
    if [[ "${code}" == "200" ]]; then
      return 0
    fi
  done
  return 1
}

render_consumer_context() {
  local name="$1" domain="$2" role purpose
  role="$(role_for "${name}")"
  purpose="${role}"
  cat <<EOF
# Consumer context — ${name}

Hub-facing context for agents working from
[\`xq-context-hub\`](https://github.com/chauhaidang/xq-context-hub).

## Identity

| Field | Value |
| --- | --- |
| Repo | \`${name}\` |
| Org | \`${ORG}\` |
| Domain | \`${domain}\` |
| Default branch | \`main\` |
| Hub catalogue | \`xq-context-hub\` \`org/catalogue.md\` |

## Purpose

${purpose}

## Boundary

**Owns:**

- Responsibilities described by the purpose above (see also hub domain
  \`domains/${domain}/CONTEXT.md\`)

**Does not own:**

- Org-wide conventions (see hub \`org/conventions.md\`)
- Other product repos’ implementation details

## Stack

- See this repository’s README and package manifests after checkout
- Published packages (if any) use the \`@chauhaidang\` GitHub Packages scope

## Agent entry

- Prefer this file for hub consumers
- Local agent instructions: \`AGENTS.md\` when present
- Domain glossary (hub): \`xq-context-hub/domains/${domain}/CONTEXT.md\`
- Org conventions (hub): \`xq-context-hub/org/conventions.md\`

## Verification

Run the verification commands documented in this repo’s README / \`AGENTS.md\`
before claiming done. If none exist yet, run the minimal smoke checks available
(\`npm test\`, \`make test\`, or language-equivalent) and report gaps.

## Hub pointer

Multi-repo plans and fan-out are orchestrated from
https://github.com/chauhaidang/xq-context-hub
(\`CONTEXT-MAP.md\` → \`domains/${domain}/CONTEXT.md\` → this checkout).
EOF
}

ensure_one() {
  local name="$1" domain url default_branch sha body tmp pr_url existing
  domain="$(yq -r ".repos.\"${name}\".domain" "${LINKS}")"
  url="$(yq -r ".repos.\"${name}\".url" "${LINKS}")"
  default_branch="$(yq -r ".repos.\"${name}\".default_branch // \"main\"" "${LINKS}")"

  if has_context "${name}"; then
    echo "ok   ${name} (already has context file)"
    return 0
  fi

  echo "need ${name} (domain=${domain})"
  if [[ "${APPLY}" -ne 1 ]]; then
    return 0
  fi

  if ! sha="$(gh api "repos/${ORG}/${name}/git/ref/heads/${default_branch}" --jq .object.sha 2>/dev/null)"; then
    echo "  FAIL ${name}: cannot read default branch (permissions?)" >&2
    return 1
  fi

  # recreate branch tip at default if it already exists from a prior run
  if gh api "repos/${ORG}/${name}/git/ref/heads/${BRANCH}" >/dev/null 2>&1; then
    if ! gh api --method PATCH "repos/${ORG}/${name}/git/refs/heads/${BRANCH}" \
      -f sha="${sha}" -F force=true >/dev/null 2>&1; then
      echo "  FAIL ${name}: cannot update branch ${BRANCH}" >&2
      return 1
    fi
  else
    if ! gh api --method POST "repos/${ORG}/${name}/git/refs" \
      -f ref="refs/heads/${BRANCH}" -f sha="${sha}" >/dev/null 2>&1; then
      echo "  FAIL ${name}: cannot create branch ${BRANCH}" >&2
      return 1
    fi
  fi

  tmp="$(mktemp)"
  render_consumer_context "${name}" "${domain}" >"${tmp}"
  body="$(base64 <"${tmp}" | tr -d '\n')"
  rm -f "${tmp}"

  if gh api "repos/${ORG}/${name}/contents/CONSUMER_CONTEXT.md?ref=${BRANCH}" >/dev/null 2>&1; then
    existing="$(gh api "repos/${ORG}/${name}/contents/CONSUMER_CONTEXT.md?ref=${BRANCH}" --jq .sha)"
    if ! gh api --method PUT "repos/${ORG}/${name}/contents/CONSUMER_CONTEXT.md" \
      -f message="docs: add CONSUMER_CONTEXT.md for xq-context-hub" \
      -f content="${body}" \
      -f branch="${BRANCH}" \
      -f sha="${existing}" >/dev/null 2>&1; then
      echo "  FAIL ${name}: cannot update CONSUMER_CONTEXT.md" >&2
      return 1
    fi
  else
    if ! gh api --method PUT "repos/${ORG}/${name}/contents/CONSUMER_CONTEXT.md" \
      -f message="docs: add CONSUMER_CONTEXT.md for xq-context-hub" \
      -f content="${body}" \
      -f branch="${BRANCH}" >/dev/null 2>&1; then
      echo "  FAIL ${name}: cannot create CONSUMER_CONTEXT.md" >&2
      return 1
    fi
  fi

  pr_url="$(gh pr list --repo "${ORG}/${name}" --head "${BRANCH}" --json url --jq '.[0].url // empty' 2>/dev/null || true)"
  if [[ -z "${pr_url}" ]]; then
    if ! pr_url="$(gh pr create --repo "${ORG}/${name}" --base "${default_branch}" --head "${BRANCH}" \
      --title "docs: add CONSUMER_CONTEXT.md for xq-context-hub" \
      --body "$(cat <<EOF
## Summary
- Add \`CONSUMER_CONTEXT.md\` so [\`xq-context-hub\`](https://github.com/chauhaidang/xq-context-hub) can load hub-facing context for this repo after checkout.

## Test plan
- [ ] File present at repo root on this branch
- [ ] Purpose / domain match this repository
EOF
)" 2>&1)"; then
      echo "  FAIL ${name}: cannot open PR — ${pr_url}" >&2
      return 1
    fi
  fi
  echo "  PR ${pr_url}"
  return 0
}
fail_n=0
while IFS= read -r name; do
  [[ -z "${name}" ]] && continue
  if [[ -n "${ONLY_REPO}" && "${name}" != "${ONLY_REPO}" ]]; then
    continue
  fi
  if ! ensure_one "${name}"; then
    fail_n=$((fail_n + 1))
  fi
done < <(yq -r '.repos | keys | .[]' "${LINKS}")

if [[ "${APPLY}" -ne 1 ]]; then
  echo
  echo "Dry-run only. Re-run with --apply to open PRs."
fi

if [[ "${fail_n}" -gt 0 ]]; then
  echo "failed=${fail_n}" >&2
  exit 1
fi
