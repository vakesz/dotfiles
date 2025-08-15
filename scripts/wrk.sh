# shellcheck shell=bash
install_wrk() {
  if need_cmd wrk; then return; fi
  if apt-cache show wrk >/dev/null 2>&1; then
    apt_install wrk
  else
    local tmp_dir; tmp_dir="$(mktemp -d)"
    git clone --depth 1 https://github.com/wg/wrk.git "$tmp_dir/wrk"
    (cd "$tmp_dir/wrk" && make -j"$(nproc)")
    sudo cp "$tmp_dir/wrk/wrk" /usr/local/bin/
    rm -rf "$tmp_dir"
  fi
}

register_installer install_wrk 130