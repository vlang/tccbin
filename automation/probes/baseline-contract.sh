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

temp_parent_input=${RUNNER_TEMP:-${TMPDIR:-/tmp}}
case "$target_id" in
	windows-amd64)
		[[ "$(type -t -- cygpath || true)" == file ]] || {
			printf '%s\n' 'Windows baseline probe requires external cygpath' >&2
			exit 1
		}
		cygpath_path=$(command -v -- cygpath)
		[[ "$cygpath_path" == /* && -x "$cygpath_path" && ! -d "$cygpath_path" ]] || exit 1
		staging_parent=$("$cygpath_path" -u "$temp_parent_input")
		;;
	*)
		staging_parent=$temp_parent_input
		;;
esac
[[ "$staging_parent" == /* && "$staging_parent" != *$'\n'* \
	&& "$staging_parent" != *$'\r'* && "$staging_parent" != *$'\t'* \
	&& -d "$staging_parent" && ! -L "$staging_parent" ]] || exit 1
staging_parent=$(cd -P -- "$staging_parent" && pwd -P)
staging_root=$(mktemp -d "$staging_parent/tccbin-payload.XXXXXX")
cleanup_paths=("$staging_root")
linked_bundle=false
for generated_v in v1 v2 v v1.exe v2.exe v.exe v2.exe.c v.exe.c; do
	[[ ! -e "$contract_root/$generated_v" && ! -L "$contract_root/$generated_v" ]]
done
cleanup() {
	status=$?
	trap - EXIT HUP INT TERM
	if [[ "$linked_bundle" == true ]]; then
		rm -rf -- "$contract_root/thirdparty/tcc"
	fi
	rm -f -- "$contract_root/v1" "$contract_root/v2" "$contract_root/v" \
		"$contract_root/v1.exe" "$contract_root/v2.exe" "$contract_root/v.exe" \
		"$contract_root/v2.exe.c" "$contract_root/v.exe.c"
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
			"$staging_root/0010-win32-export-batched-iocp.patch" \
			"$staging_root/0011-win32-include-synchapi-from-windows-h.patch" \
			"$staging_root/0012-win32-declare-and-export-GetTickCount64.patch" \
			"$staging_root/0013-win32-export-GetFileSizeEx-and-TryAcquireSRWLockExclusive.patch" \
			"$staging_root/0014-win32-declare-and-export-GetFileInformationByHandleEx.patch" \
			"$staging_root/0015-win32-export-SRW-lock-functions.patch" \
			"$staging_root/0016-win32-export-bundled-kernel32-functions.patch" \
			"$staging_root/0017-win32-ignore-remaining-benign-debug-exceptions.patch" \
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

# Keep the probe's compiler bootstrap aligned with the pinned contract helper.
export V_MACOS_V3_NO_FALLBACK=1
v_link_flags=()
case "$target_id" in
	freebsd-amd64 | openbsd-amd64)
		v_link_flags=(-ldflags -lexecinfo)
		;;
esac

build_v_compiler() {
	local compiler=$1 output=$2
	if [[ "$target_id" == windows-amd64 ]]; then
		"$compiler" -new-compiler -no-parallel -nocache -cc "$cc_path" \
			-gc none -o "$output.c" cmd/v
		"$cc_path" -std=gnu11 -municode -w -fwrapv -o "$output" "$output.c" \
			vlib/builtin/core_windows.c vlib/v/modulecache/file_metadata.c \
			vlib/time/ticks_windows.c vlib/v/winthread_helper_windows.c \
			cmd/v/toolcache_windows_helpers.c vlib/sync/thread_helper.c \
			-I thirdparty/stdatomic/win -ldbghelp -lws2_32 -lbcrypt -ladvapi32 \
			-Wl,-stack=33554432
		rm -f -- "$output.c"
	else
		"$compiler" -new-compiler -no-parallel -nocache -cc "$cc_path" \
			-gc none ${v_link_flags[@]+"${v_link_flags[@]}"} -o "$output" cmd/v
	fi
}

if [[ "$target_id" == windows-amd64 ]]; then
	# Native MinGW gcc cannot reliably read the MSYS FIFO used on Unix.
	compat_root=$(mktemp -d "$staging_parent/tccbin-vc-compat.XXXXXX")
	cleanup_paths+=("$compat_root")
	compat_source="$compat_root/v_win_compat.c"
	powershell -NoProfile -ExecutionPolicy Bypass \
		-File "$contract_root/cmd/tools/vc_compat_uint.ps1" \
		-Source "$vc_root/v_win.c" -Destination "$compat_source"
	"$cc_path" -std=c99 -DCUSTOM_DEFINE_v1_fallback -municode -w \
		-o "$contract_root/v1.exe" "$compat_source" \
		-ladvapi32 -lws2_32 -lbcrypt -Wl,-stack=33554432
	rm -f -- "$compat_source"
else
	seed_flags=(-DCUSTOM_DEFINE_v1_fallback)
	seed_sources=()
	link_flags=(-lm -lpthread)
	case "$target_id" in
		freebsd-amd64 | openbsd-amd64)
			link_flags+=(-lexecinfo)
			;;
	esac
	if [[ "$target_id" == openbsd-amd64 ]]; then
		seed_flags+=(-DSYS_getrandom=0)
		seed_sources=("$contract_root/cmd/tools/openbsd_vc_compat.c")
	fi
	sh "$contract_root/cmd/tools/vc_compat.sh" "$vc_root/v.c" "$cc_path" \
		-std=c99 "${seed_flags[@]}" -w -o "$contract_root/v1" -- \
		${seed_sources[@]+"${seed_sources[@]}"} "${link_flags[@]}"
fi
(
	cd -P -- "$contract_root"
	build_v_compiler "./v1${exe_suffix}" "./v2${exe_suffix}"
	build_v_compiler "./v2${exe_suffix}" "./v${exe_suffix}"
)

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
	"./v${exe_suffix}" -new-compiler -cc tcc -gc none -showcc -no-retry-compilation \
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
