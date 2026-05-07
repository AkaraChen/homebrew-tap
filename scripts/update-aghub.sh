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
  if command -v sha256sum >/dev/null 2>&1; then
    sha256sum "$1" | awk '{print $1}'
  else
    shasum -a 256 "$1" | awk '{print $1}'
  fi
}

if [[ "${requested_version}" == "-h" || "${requested_version}" == "--help" ]]; then
  usage
  exit 0
fi

need gh
need awk
need grep
need mktemp

[[ -f "${cask_file}" ]] || die "cask file not found: ${cask_file}"

if [[ -z "${requested_version}" || "${requested_version}" == "latest" ]]; then
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

tmp_cask="$(mktemp)"
awk \
  -v version="${version}" \
  -v arm_sha="${arm_sha}" \
  -v intel_sha="${intel_sha}" \
  '
  BEGIN {
    version_count = 0
    sha_count = 0
  }

  /^  version "/ {
    print "  version \"" version "\""
    version_count++
    next
  }

  /^  sha256 arm:/ {
    print "  sha256 arm:   \"" arm_sha "\","
    if (getline <= 0) {
      exit 41
    }
    print "         intel: \"" intel_sha "\""
    sha_count++
    next
  }

  {
    print
  }

  END {
    if (version_count != 1 || sha_count != 1) {
      exit 42
    }
  }
  ' "${cask_file}" >"${tmp_cask}" || {
    rm -f "${tmp_cask}"
    die "failed to update ${cask_file}; cask format may have changed"
  }

mv "${tmp_cask}" "${cask_file}"

echo "Updated ${cask_file}"
echo "  version: ${version}"
echo "  arm64:   ${arm_sha}"
echo "  intel:   ${intel_sha}"
