#!/usr/bin/env bash
set -euo pipefail

repo="${TWOCODE_REPO:-AkaraChen/2code}"
cask_file="${CASK_FILE:-Casks/2code.rb}"
requested_version="${1:-${TWOCODE_VERSION:-latest}}"

usage() {
  cat <<EOF
Usage: scripts/update-2code.sh [version]

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

asset_sha_from_digest() {
  local asset="$1"
  local digest

  digest="$(gh api "${endpoint}" --jq ".assets[] | select(.name == \"${asset}\") | .digest" 2>/dev/null || true)"
  digest="${digest#sha256:}"

  if [[ "${digest}" =~ ^[0-9a-f]{64}$ ]]
  then
    printf '%s\n' "${digest}"
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

arm_asset="2code_${version}_aarch64.dmg"
intel_asset="2code_${version}_x64.dmg"

assets="$(gh api "${endpoint}" --jq '.assets[].name')"
grep -Fxq "${arm_asset}" <<<"${assets}" || die "release ${tag} is missing ${arm_asset}"
grep -Fxq "${intel_asset}" <<<"${assets}" || die "release ${tag} is missing ${intel_asset}"

arm_sha="$(asset_sha_from_digest "${arm_asset}")"
intel_sha="$(asset_sha_from_digest "${intel_asset}")"

if [[ -n "${arm_sha}" && -n "${intel_sha}" ]]
then
  echo "Using ${repo} ${tag} asset digests..."
else
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
fi

ruby -e '
path, version, arm_sha, intel_sha = ARGV
content = File.read(path)

unless content.scan(/^  version "/).length == 1
  abort "expected exactly one version stanza in #{path}"
end

unless content.match?(/^  arch arm: "aarch64", intel: "x64"$/)
  content = content.sub(/\Acask "2code" do\n+/, %(cask "2code" do\n  arch arm: "aarch64", intel: "x64"\n\n))
end

content = content.sub(/^  version ".*"$/, %(  version "#{version}"))

dual_sha = %(  sha256 arm:   "#{arm_sha}",\n         intel: "#{intel_sha}")
dual_sha_regex = /^  sha256 arm:\s+"[0-9a-f]{64}",\n\s+intel:\s+"[0-9a-f]{64}"$/
single_sha_regex = /^  sha256 "[0-9a-f]{64}"$/
unless content.sub!(dual_sha_regex, dual_sha) || content.sub!(single_sha_regex, dual_sha)
  abort "expected a single or dual-arch sha256 stanza in #{path}"
end

url_regex = %r{^  url "https://github\.com/AkaraChen/2code/releases/download/v#\{version\}/[^"]+",(?:\\n|\n)      verified: "github\.com/AkaraChen/2code/"$}
url_stanza = %q(  url "https://github.com/AkaraChen/2code/releases/download/v#{version}/2code_#{version}_#{arch}.dmg",
      verified: "github.com/AkaraChen/2code/")
unless content.sub!(url_regex, url_stanza)
  abort "expected a 2code GitHub url stanza in #{path}"
end

content = content.sub(/^  depends_on arch: :arm64\n\n/, "")
content = content.sub(/^  app ".*"$/, %(  app "2code.app"))
content = content.sub(%r{\#\{appdir\}/[^"]+\.app}, %q(#{appdir}/2code.app))

File.write(path, content)
' "${cask_file}" "${version}" "${arm_sha}" "${intel_sha}"

echo "Updated ${cask_file}"
echo "  version: ${version}"
echo "  arm64:   ${arm_sha}"
echo "  intel:   ${intel_sha}"
