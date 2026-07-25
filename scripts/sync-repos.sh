#!/usr/bin/env bash
# Clone or update linked repos into the hub checkout root (see org/links.yaml).
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
LINKS="${ROOT}/org/links.yaml"

if [[ ! -f "${LINKS}" ]]; then
  echo "missing ${LINKS}" >&2
  exit 1
fi

if ! command -v yq >/dev/null 2>&1; then
  echo "yq is required (https://github.com/mikefarah/yq)" >&2
  exit 1
fi

CHECKOUT_ROOT="$(yq -r '.checkout_root // "checkouts"' "${LINKS}")"
DEST_ROOT="${ROOT}/${CHECKOUT_ROOT}"
mkdir -p "${DEST_ROOT}"

DOMAIN=""
REPO=""
while [[ $# -gt 0 ]]; do
  case "$1" in
    --domain)
      DOMAIN="${2:-}"
      shift 2
      ;;
    --repo)
      REPO="${2:-}"
      shift 2
      ;;
    -h|--help)
      cat <<'EOF'
Usage: sync-repos.sh [--domain <name>] [--repo <name>]

Clone or fast-forward repos listed in org/links.yaml into checkouts/<name>.
EOF
      exit 0
      ;;
    *)
      echo "unknown arg: $1" >&2
      exit 1
      ;;
  esac
done

names="$(yq -r '.repos | keys | .[]' "${LINKS}")"

sync_one() {
  local name="$1"
  local url domain branch path
  url="$(yq -r ".repos.\"${name}\".url" "${LINKS}")"
  domain="$(yq -r ".repos.\"${name}\".domain // \"\"" "${LINKS}")"
  branch="$(yq -r ".repos.\"${name}\".default_branch // \"main\"" "${LINKS}")"
  path="${DEST_ROOT}/${name}"

  if [[ -n "${DOMAIN}" && "${domain}" != "${DOMAIN}" ]]; then
    return 0
  fi
  if [[ -n "${REPO}" && "${name}" != "${REPO}" ]]; then
    return 0
  fi

  if [[ ! -d "${path}/.git" ]]; then
    echo "clone ${name} → ${path}"
    git clone --branch "${branch}" "${url}" "${path}"
    return 0
  fi

  echo "update ${name} → ${path}"
  git -C "${path}" fetch --prune origin
  # Fast-forward default branch only when clean and on that branch.
  local current
  current="$(git -C "${path}" rev-parse --abbrev-ref HEAD)"
  if [[ "${current}" == "${branch}" ]] && git -C "${path}" diff --quiet && git -C "${path}" diff --cached --quiet; then
    git -C "${path}" merge --ff-only "origin/${branch}" || true
  else
    echo "  skip ff (${current}; dirty or not on ${branch}) — fetch only"
  fi
}

matched=0
while IFS= read -r name; do
  [[ -z "${name}" ]] && continue
  if [[ -n "${REPO}" && "${name}" != "${REPO}" ]]; then
    continue
  fi
  if [[ -n "${DOMAIN}" ]]; then
    d="$(yq -r ".repos.\"${name}\".domain // \"\"" "${LINKS}")"
    [[ "${d}" == "${DOMAIN}" ]] || continue
  fi
  sync_one "${name}"
  matched=1
done <<< "${names}"

if [[ -n "${REPO}" && "${matched}" -eq 0 ]]; then
  echo "repo not in org/links.yaml: ${REPO}" >&2
  exit 1
fi

echo "checkout root: ${DEST_ROOT}"
