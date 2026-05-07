#!/usr/bin/env bash
set -euo pipefail

repo="${AGHUB_REPO:-AkaraChen/aghub}"
cask_file="${CASK_FILE:-Casks/aghub.rb}"
requested_version="${1:-${AGHUB_VERSION:-latest}}"

arm_asset="aghub_aarch64.app.tar.gz"
intel_asset="aghub_x64.app.tar.gz"

usage() {
  cat <<EOF
Usage: scripts/update-aghub.sh [version]

Updates ${cask_file} from ${repo}.

Arguments:
  version   Optional. Use "latest", "1.2.3", or "v1.2.3".
            Defaults to latest.
EOF
}

die() {
  echo "error: $*" >&2
  exit 1
}

need() {
  command -v "$1" >/dev/null 2>&1 || die "missing required command: $1"
}

sha256_file() {
  if command -v sha256sum >/dev/null 2>&1
  then
    sha256sum "$1" | awk '{print $1}'
  else
    shasum -a 256 "$1" | awk '{print $1}'
  fi
}

if [[ "${requested_version}" == "-h" || "${requested_version}" == "--help" ]]
then
  usage
  exit 0
fi

need gh
need awk
need grep
need mktemp
need ruby

[[ -f "${cask_file}" ]] || die "cask file not found: ${cask_file}"

if [[ -z "${requested_version}" || "${requested_version}" == "latest" ]]
then
  endpoint="repos/${repo}/releases/latest"
else
  tag="${requested_version}"
  [[ "${tag}" == v* ]] || tag="v${tag}"
  endpoint="repos/${repo}/releases/tags/${tag}"
fi

tag="$(gh api "${endpoint}" --jq '.tag_name')"
[[ -n "${tag}" && "${tag}" != "null" ]] || die "could not determine release tag"

version="${tag#v}"
[[ "${tag}" == "v${version}" ]] || die "expected a v-prefixed release tag, got: ${tag}"

assets="$(gh api "${endpoint}" --jq '.assets[].name')"
grep -Fxq "${arm_asset}" <<<"${assets}" || die "release ${tag} is missing ${arm_asset}"
grep -Fxq "${intel_asset}" <<<"${assets}" || die "release ${tag} is missing ${intel_asset}"

tmpdir="$(mktemp -d)"
trap 'rm -rf "${tmpdir}"' EXIT

echo "Downloading ${repo} ${tag} assets..."
gh release download "${tag}" \
  --repo "${repo}" \
  --pattern "${arm_asset}" \
  --pattern "${intel_asset}" \
  --dir "${tmpdir}" \
  --clobber

arm_file="${tmpdir}/${arm_asset}"
intel_file="${tmpdir}/${intel_asset}"
[[ -f "${arm_file}" ]] || die "download failed: ${arm_asset}"
[[ -f "${intel_file}" ]] || die "download failed: ${intel_asset}"

arm_sha="$(sha256_file "${arm_file}")"
intel_sha="$(sha256_file "${intel_file}")"

ruby - "${cask_file}" "${version}" "${arm_sha}" "${intel_sha}" <<'RUBY'
path, version, arm_sha, intel_sha = ARGV
content = File.read(path)

unless content.scan(/^  version "/).length == 1
  abort "expected exactly one version stanza in #{path}"
end

unless content.scan(/^  sha256 arm:/).length == 1
  abort "expected exactly one dual-arch sha256 stanza in #{path}"
end

content = content.sub(/^  version ".*"$/, %(  version "#{version}"))
content = content.sub(
  /^  sha256 arm:\s+"[0-9a-f]{64}",\n\s+intel:\s+"[0-9a-f]{64}"$/,
  %(  sha256 arm:   "#{arm_sha}",\n         intel: "#{intel_sha}"),
)

File.write(path, content)
RUBY

echo "Updated ${cask_file}"
echo "  version: ${version}"
echo "  arm64:   ${arm_sha}"
echo "  intel:   ${intel_sha}"
