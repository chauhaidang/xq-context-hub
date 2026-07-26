#!/usr/bin/env bash
# Report which linked repos expose CONSUMER_CONTEXT.md / AGENTS.md / AGENT.md.
set -eu

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
LINKS="${ROOT}/org/links.yaml"
ORG="$(yq -r '.org // "chauhaidang"' "${LINKS}")"

http_code() {
  local path="$1"
  local code
  code="$(gh api --silent --include "${path}" 2>/dev/null | awk 'BEGIN{c="000"} /^HTTP/{c=$2} END{print c}')" || true
  if [[ -z "${code}" ]]; then
    code="000"
  fi
  printf '%s' "${code}"
}

ok_n=0
miss_n=0

printf '%-28s %-8s %-8s %-10s %s\n' REPO AGENTS.md AGENT.md CONSUMER ok
printf '%s\n' "--------------------------------------------------------------------------------"

names="$(yq -r '.repos | keys | .[]' "${LINKS}")"
for name in ${names}; do
  a="$(http_code "repos/${ORG}/${name}/contents/AGENTS.md")"
  b="$(http_code "repos/${ORG}/${name}/contents/AGENT.md")"
  c="$(http_code "repos/${ORG}/${name}/contents/CONSUMER_CONTEXT.md")"
  ctx_ok="no"
  if [[ "${a}" == "200" || "${b}" == "200" || "${c}" == "200" ]]; then
    ctx_ok="yes"
    ok_n=$((ok_n + 1))
  else
    miss_n=$((miss_n + 1))
  fi
  printf '%-28s %-8s %-8s %-10s %s\n' "${name}" "${a}" "${b}" "${c}" "${ctx_ok}"
done

echo
echo "ok=${ok_n} missing=${miss_n}"
if [[ "${miss_n}" -ne 0 ]]; then
  exit 1
fi
