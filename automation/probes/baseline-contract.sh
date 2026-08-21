#!/usr/bin/env bash

set -euo pipefail
IFS=$'\n\t'
export LC_ALL=C

readonly expected_contract_repository='vlang/v'

if [[ $# -ne 8 ]]; then
	printf '%s\n' 'usage: baseline-contract.sh <validator> <contract-root> <bundle-root> <target-id> <canonical-branch> <contract-sha> <bundle-sha> <vc-root>' >&2
	exit 2
fi

validator=$1
contract_root=$2
bundle_root=$3
target_id=$4
canonical_branch=$5
expected_contract_sha=$6
bundle_sha=$7
vc_root=$8
manifest="$bundle_root/automation/bundle-manifest.json"
schema="$contract_root/thirdparty/tccbin_automation/schemas/bundle-manifest.schema.json"

[[ -x "$validator" && -d "$contract_root" && -d "$bundle_root" && -d "$vc_root" ]] || exit 1
[[ -f "$manifest" && ! -L "$manifest" && -f "$schema" && ! -L "$schema" ]] || exit 1
[[ "$expected_contract_sha" =~ ^[0-9a-f]{40}$ && "$bundle_sha" =~ ^[0-9a-f]{40}$ ]] || exit 1

validator_command() {
	(cd -P -- "$contract_root" && "$validator" "$@")
}

case "${PUBLISH:-false}:${TCCBIN_PUBLISH:-false}" in
	false:false | 0:0 | false:0 | 0:false) ;;
	*) printf '%s\n' 'baseline contract probe refuses publication' >&2; exit 1 ;;
esac

binding=$(validator_command contract-binding)
[[ "$binding" == "repository=$expected_contract_repository sha=$expected_contract_sha" ]] || {
	printf '%s\n' 'validator contract binding mismatch' >&2
	exit 1
}

validator_command contract >/dev/null
[[ "$(validator_command validate "$schema" "$manifest")" == 'valid' ]]
canonical=$(validator_command canonicalize "$manifest")

for exact_member in \
	"\"contract_repository\":\"$expected_contract_repository\"" \
	"\"contract_sha\":\"$expected_contract_sha\"" \
	'"contract_mode":"production"' \
	"\"v_source_sha\":\"$expected_contract_sha\"" \
	"\"target_id\":\"$target_id\"" \
	"\"branch\":\"$canonical_branch\"" \
	'"provenance_status":"incomplete"'; do
	case "$canonical" in
		*"$exact_member"*) ;;
		*) printf '%s\n' 'manifest baseline binding mismatch' >&2; exit 1 ;;
	esac
done

fingerprints=$(validator_command fingerprint "$manifest")
[[ $(printf '%s\n' "$fingerprints" | wc -l | tr -d ' ') == 3 ]]
for key in manifest_hash input_fingerprint artifact_fingerprint; do
	value=$(printf '%s\n' "$fingerprints" | sed -n "s/^${key}=//p")
	[[ "$value" =~ ^[0-9a-f]{64}$ ]]
done

[[ "$(git -C "$bundle_root" config --get core.autocrlf)" == false ]]
[[ "$(git -C "$bundle_root" rev-parse HEAD)" == "$bundle_sha" ]]
[[ "$(git -C "$bundle_root" rev-parse --verify "${bundle_sha}^{commit}")" == "$bundle_sha" ]]
[[ "$(git -C "$bundle_root" symbolic-ref -q HEAD || true)" == '' ]]
[[ "$(git -C "$bundle_root" status --porcelain=v1 --untracked-files=all --ignored=matching)" == '' ]]

staging_parent=${RUNNER_TEMP:-${TMPDIR:-/tmp}}
staging_root=$(mktemp -d "$staging_parent/tccbin-payload.XXXXXX")
cleanup_paths=("$staging_root")
linked_bundle=false
for generated_v in v1 v2 v v1.exe v2.exe v.exe; do
	[[ ! -e "$contract_root/$generated_v" && ! -L "$contract_root/$generated_v" ]]
done
cleanup() {
	status=$?
	trap - EXIT HUP INT TERM
	if [[ "$linked_bundle" == true ]]; then
		rm -rf -- "$contract_root/thirdparty/tcc"
	fi
	rm -f -- "$contract_root/v1" "$contract_root/v2" "$contract_root/v" \
		"$contract_root/v1.exe" "$contract_root/v2.exe" "$contract_root/v.exe"
	for cleanup_path in "${cleanup_paths[@]}"; do
		[[ -n "$cleanup_path" && -d "$cleanup_path" ]] && rm -rf -- "$cleanup_path"
	done
	exit "$status"
}
trap cleanup EXIT HUP INT TERM

git -C "$bundle_root" archive --format=tar "$bundle_sha" | tar -xf - -C "$staging_root"
rm -rf -- "$staging_root/.github" "$staging_root/automation"
case "$target_id" in
	windows-amd64)
		rm -f -- \
			"$staging_root/build.ps1" \
			"$staging_root/0001-tccpe-strip-quotes-and-default-.dll-extension-in-DEF.patch" \
			"$staging_root/0002-win32-don-t-treat-DBG_PRINTEXCEPTION_C-as-a-fatal-cr.patch" \
			"$staging_root/0003-win32-declare-CreateSymbolicLink.patch" \
			"$staging_root/0004-win32-declare-WSAConnectBy-family.patch" \
			"$staging_root/0005-win32-declare-InetNtop-InetPton-family.patch" \
			"$staging_root/0006-win32-declare-shell-drag-drop-family.patch" \
			"$staging_root/0007-win32-declare-secure-narrow-stdio.patch" \
			"$staging_root/0008-win32-fix-exp2-range-reduction.patch" \
			"$staging_root/0009-win32-declare-CancelIoEx.patch" \
			"$staging_root/vlang-header-compat.patch" \
			"$staging_root/v-ae88ee5-tinycc-bdwgc.patch"
		;;
	linux-amd64 | macos-amd64 | macos-arm64 | freebsd-amd64 | openbsd-amd64)
		rm -f -- "$staging_root/build.sh"
		;;
	*) printf '%s\n' 'unknown target for payload staging' >&2; exit 1 ;;
esac

staged_result=$(validator_command staged-preflight \
	"$manifest" "$staging_root" "$bundle_root" "$bundle_sha" false)
readonly expected_staged_result='eligible=false reason=staged_provenance_incomplete publish_allowed=false manifest_hash= input_fingerprint= artifact_fingerprint='
[[ "$staged_result" == "$expected_staged_result" ]] || {
	printf 'unexpected staged preflight result: %s\n' "$staged_result" >&2
	exit 1
}

[[ "$(git -C "$contract_root" config --get core.autocrlf)" == false ]]
[[ "$(git -C "$vc_root" config --get core.autocrlf)" == false ]]
[[ "$(git -C "$contract_root" rev-parse HEAD)" == "$expected_contract_sha" ]]
vc_sha=$(sed -n 's/^commit=//p' "$contract_root/thirdparty/tccbin_automation/bootstrap/vc.lock")
[[ "$vc_sha" =~ ^[0-9a-f]{40}$ && "$(git -C "$vc_root" rev-parse HEAD)" == "$vc_sha" ]]

contract_tcc="$contract_root/thirdparty/tcc"
if [[ -e "$contract_tcc" || -L "$contract_tcc" ]]; then
	[[ "$(cd -P -- "$contract_tcc" && pwd)" == "$(cd -P -- "$bundle_root" && pwd)" ]]
else
	ln -s "$bundle_root" "$contract_tcc"
	linked_bundle=true
fi

case "$target_id" in
	windows-amd64)
		cc_name=${CC:-gcc}
		exe_suffix=.exe
		;;
	*)
		cc_name=${CC:-cc}
		exe_suffix=
		;;
esac
cc_path=$(command -v -- "$cc_name")
[[ "$cc_path" == /* && -x "$cc_path" ]]

if [[ "$target_id" == windows-amd64 ]]; then
	"$cc_path" -std=c99 -municode -w -o "$contract_root/v1.exe" "$vc_root/v_win.c" \
		-ladvapi32 -lws2_32 -Wl,-stack=33554432
	(
		cd -P -- "$contract_root"
		./v1.exe -no-parallel -nocache -cc "$cc_path" -o ./v2.exe -gc none cmd/v
		./v2.exe -no-parallel -nocache -cc "$cc_path" -o ./v.exe -gc none cmd/v
	)
else
	link_flags=(-lm -lpthread)
	case "$target_id" in
		freebsd-amd64 | openbsd-amd64)
			link_flags+=(-lexecinfo)
			;;
	esac
	"$cc_path" -std=c99 -w -o "$contract_root/v1" "$vc_root/v.c" "${link_flags[@]}"
	(
		cd -P -- "$contract_root"
		case "$target_id" in
		freebsd-amd64 | openbsd-amd64)
			./v1 -no-parallel -nocache -cc "$cc_path" -o ./v2 -gc none \
				-ldflags -lexecinfo cmd/v
			./v2 -no-parallel -nocache -cc "$cc_path" -o ./v -gc none \
				-ldflags -lexecinfo cmd/v
			;;
		*)
			./v1 -no-parallel -nocache -cc "$cc_path" -o ./v2 -gc none cmd/v
			./v2 -no-parallel -nocache -cc "$cc_path" -o ./v -gc none cmd/v
			;;
		esac
	)
fi

smoke_root=$(mktemp -d "$staging_parent/tccbin-v-smoke.XXXXXX")
cleanup_paths+=("$smoke_root")
cat > "$smoke_root/main.v" <<'VEOF'
module main

fn main() {
	println('tccbin-v-smoke')
}
VEOF
smoke_binary="$smoke_root/tccbin-v-smoke${exe_suffix}"
if ! showcc_output=$(
	cd -P -- "$contract_root"
	"./v${exe_suffix}" -cc tcc -gc none -showcc -no-retry-compilation -no-rsp \
		-o "$smoke_binary" "$smoke_root/main.v" 2>&1
); then
	printf '%s\n' "$showcc_output" >&2
	exit 1
fi
printf '%s\n' "$showcc_output"
if printf '%s\n' "$showcc_output" | grep -Eiq \
	'falling back to|retrying with|fallback compiler|backup compiler'; then
	printf '%s\n' 'V attempted a compiler fallback' >&2
	exit 1
fi
normalized_showcc=$(printf '%s\n' "$showcc_output" | tr '\\' '/')
case "$normalized_showcc" in
	*'/thirdparty/tcc/tcc.exe'*) ;;
	*) printf '%s\n' 'V did not report the bundled tcc.exe command' >&2; exit 1 ;;
esac
[[ -f "$smoke_binary" ]]
[[ "$($smoke_binary)" == 'tccbin-v-smoke' ]]

printf 'tccbin baseline contract target=%s staged=incomplete smoke=v-tcc publish=false: PASS\n' "$target_id"
