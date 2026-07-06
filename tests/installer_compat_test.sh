#!/bin/sh
set -eu

REPO_DIR="$(CDPATH= cd -- "$(dirname "$0")/.." && pwd)"
TMP_ROOT="$(mktemp -d)"
trap 'rm -rf "$TMP_ROOT"' EXIT INT TERM

assert_contains() {
  haystack="$1"
  needle="$2"
  printf '%s' "$haystack" | grep -F "$needle" >/dev/null 2>&1 || {
    printf 'assert_contains failed: missing [%s]\n' "$needle" >&2
    exit 1
  }
}

make_fakebin() {
  fakebin="$1"
  mkdir -p "$fakebin"

  cat >"$fakebin/uname" <<'EOF'
#!/bin/sh
if [ "${1:-}" = "-s" ]; then
  printf 'Linux\n'
elif [ "${1:-}" = "-m" ]; then
  printf '%s\n' "${FAKE_UNAME_M:-x86_64}"
else
  printf 'Linux\n'
fi
EOF

  cat >"$fakebin/id" <<'EOF'
#!/bin/sh
if [ "${1:-}" = "-u" ]; then
  printf '0\n'
else
  /usr/bin/id "$@"
fi
EOF

  cat >"$fakebin/curl" <<'EOF'
#!/bin/sh
out=""
last=""
while [ "$#" -gt 0 ]; do
  case "$1" in
    -o)
      out="$2"
      shift 2
      ;;
    *)
      last="$1"
      shift
      ;;
  esac
done
case "$last" in
  *"/releases/latest")
    if [ -n "$out" ]; then
      printf '{"tag_name":"v9.9.9"}\n' >"$out"
    else
      printf '{"tag_name":"v9.9.9"}\n'
    fi
    ;;
  *"vohive_v9.9.9_linux_"*)
    printf '#!/bin/sh\nexit 0\n' >"$out"
    ;;
  *)
    printf 'unexpected curl url: %s\n' "$last" >&2
    exit 1
    ;;
esac
EOF

  cat >"$fakebin/wget" <<'EOF'
#!/bin/sh
out=""
url=""
while [ "$#" -gt 0 ]; do
  case "$1" in
    -O)
      out="$2"
      shift 2
      ;;
    *)
      url="$1"
      shift
      ;;
  esac
done
case "$url" in
  *"/releases/latest")
    printf '{"tag_name":"v9.9.9"}\n' >"$out"
    ;;
  *"vohive_v9.9.9_linux_"*)
    printf '#!/bin/sh\nexit 0\n' >"$out"
    ;;
  *)
    printf 'unexpected wget url: %s\n' "$url" >&2
    exit 1
    ;;
esac
EOF

  cat >"$fakebin/systemctl" <<'EOF'
#!/bin/sh
printf 'systemctl %s\n' "$*" >&2
exit 0
EOF

  chmod +x "$fakebin/uname" "$fakebin/id" "$fakebin/curl" "$fakebin/wget" "$fakebin/systemctl"
}

run_install_case() {
  shell_name="$1"
  platform="$2"
  shift 2
  case_dir="$TMP_ROOT/install-$shell_name-$platform"
  fakebin="$case_dir/fakebin"
  root_dir="$case_dir/root"
  mkdir -p "$root_dir"
  make_fakebin "$fakebin"

  openwrt_release="$case_dir/openwrt_release"
  procd_path="$case_dir/procd"
  systemd_dir="$case_dir/systemd"
  init_path="$case_dir/init.d/vohive"
  service_path="$case_dir/vohive.service"

  mkdir -p "$(dirname "$init_path")" "$systemd_dir"
  : >"$procd_path"

  if [ "$platform" = "openwrt" ]; then
    printf 'DISTRIB_ID=OpenWrt\n' >"$openwrt_release"
  else
    rm -f "$openwrt_release"
  fi

  if [ "$platform" = "systemd" ]; then
    : >"$systemd_dir/active"
  else
    rm -f "$systemd_dir/active"
  fi

  env \
    PATH="$fakebin:$PATH" \
    VOHIVE_INSTALL_ROOT="$root_dir/opt/vohive" \
    VOHIVE_OPENWRT_RELEASE_FILE="$openwrt_release" \
    VOHIVE_PROCD_PATH="$procd_path" \
    VOHIVE_SYSTEMD_RUN_DIR="$systemd_dir/active" \
    VOHIVE_OPENWRT_INIT_PATH="$init_path" \
    VOHIVE_SYSTEMD_SERVICE_PATH="$service_path" \
    "$shell_name" "$REPO_DIR/install.sh" --dry-run "$@" 2>&1
}

run_uninstall_case() {
  shell_name="$1"
  platform="$2"
  shift 2
  case_dir="$TMP_ROOT/uninstall-$shell_name-$platform"
  fakebin="$case_dir/fakebin"
  root_dir="$case_dir/root"
  mkdir -p "$root_dir"
  make_fakebin "$fakebin"

  openwrt_release="$case_dir/openwrt_release"
  procd_path="$case_dir/procd"
  systemd_dir="$case_dir/systemd"
  init_path="$case_dir/init.d/vohive"
  service_path="$case_dir/vohive.service"

  mkdir -p "$(dirname "$init_path")" "$systemd_dir"
  : >"$procd_path"
  : >"$init_path"
  : >"$service_path"

  if [ "$platform" = "openwrt" ]; then
    printf 'DISTRIB_ID=OpenWrt\n' >"$openwrt_release"
  else
    rm -f "$openwrt_release"
  fi

  if [ "$platform" = "systemd" ]; then
    : >"$systemd_dir/active"
  else
    rm -f "$systemd_dir/active"
  fi

  env \
    PATH="$fakebin:$PATH" \
    VOHIVE_INSTALL_ROOT="$root_dir/opt/vohive" \
    VOHIVE_OPENWRT_RELEASE_FILE="$openwrt_release" \
    VOHIVE_PROCD_PATH="$procd_path" \
    VOHIVE_SYSTEMD_RUN_DIR="$systemd_dir/active" \
    VOHIVE_OPENWRT_INIT_PATH="$init_path" \
    VOHIVE_SYSTEMD_SERVICE_PATH="$service_path" \
    "$shell_name" "$REPO_DIR/uninstall.sh" --dry-run "$@" 2>&1
}

install_sh_output="$(run_install_case sh none --no-systemd)"
assert_contains "$install_sh_output" "手动启动命令"

install_systemd_output="$(run_install_case sh systemd)"
assert_contains "$install_systemd_output" "systemctl enable vohive"

install_openwrt_output="$(run_install_case sh openwrt)"
assert_contains "$install_openwrt_output" "init.d/vohive"

install_bash_output="$(run_install_case bash none --no-systemd)"
assert_contains "$install_bash_output" "手动启动命令"

uninstall_systemd_output="$(run_uninstall_case sh systemd --purge)"
assert_contains "$uninstall_systemd_output" "systemctl disable vohive"

uninstall_openwrt_output="$(run_uninstall_case sh openwrt --purge)"
assert_contains "$uninstall_openwrt_output" "init.d/vohive disable"

printf 'ok - installer compatibility smoke tests passed\n'
