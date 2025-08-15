# shellcheck shell=bash
install_docker() {
  if need_cmd docker; then return; fi
  local docker_key="/etc/apt/keyrings/docker.gpg"
  local arch codename
  arch="$(dpkg --print-architecture)"
  # shellcheck disable=SC1091
  codename="$(. /etc/os-release; echo "$VERSION_CODENAME")"
  local docker_list
  docker_list="deb [arch=${arch} signed-by=${docker_key}] https://download.docker.com/linux/${DISTRO} ${codename} stable"
  add_apt_source "docker" "$docker_list" "$docker_key" "https://download.docker.com/linux/${DISTRO}/gpg"
  apt_update_if_needed
  apt_install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
  sudo usermod -aG docker "${USER}"
}

register_installer install_docker 110