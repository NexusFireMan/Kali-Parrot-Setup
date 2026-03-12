#!/usr/bin/env bash

configure_root_zsh() {
  local root_home="/root"
  local root_zsh_dir="${root_home}/.oh-my-zsh"
  local root_custom="${root_zsh_dir}/custom"
  local root_zshrc="${root_home}/.zshrc"
  local root_p10k="${root_home}/.p10k.zsh"
  local root_p10k_template="${TEMPLATE_DIR}/p10k-root.zsh"

  log "Configurando entorno zsh para root..."
  backup_root_file "${root_zshrc}" "root.zshrc.bak"
  backup_root_file "${root_p10k}" "root.p10k.zsh.bak"

  if ! ${SUDO} test -d "${root_zsh_dir}"; then
    log "Instalando Oh My Zsh para root..."
    ${SUDO} -H sh -c 'RUNZSH=no CHSH=no KEEP_ZSHRC=yes sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"'
  fi

  ${SUDO} mkdir -p "${root_custom}/themes" "${root_custom}/plugins"
  if ! ${SUDO} test -d "${root_custom}/themes/powerlevel10k"; then
    ${SUDO} git clone --depth=1 https://github.com/romkatv/powerlevel10k.git "${root_custom}/themes/powerlevel10k"
  fi
  if ! ${SUDO} test -d "${root_custom}/plugins/zsh-autosuggestions"; then
    ${SUDO} git clone --depth=1 https://github.com/zsh-users/zsh-autosuggestions "${root_custom}/plugins/zsh-autosuggestions"
  fi
  if ! ${SUDO} test -d "${root_custom}/plugins/zsh-syntax-highlighting"; then
    ${SUDO} git clone --depth=1 https://github.com/zsh-users/zsh-syntax-highlighting.git "${root_custom}/plugins/zsh-syntax-highlighting"
  fi

  ${SUDO} cp -f "${ZSHRC}" "${root_zshrc}"
  upsert_root_p10k_source_block "${root_zshrc}"
  ${SUDO} chown root:root "${root_zshrc}"
  ${SUDO} chmod 600 "${root_zshrc}"

  require_file "${root_p10k_template}"
  ${SUDO} cp -f "${root_p10k_template}" "${root_p10k}"
  ${SUDO} chown root:root "${root_p10k}"
  ${SUDO} chmod 600 "${root_p10k}"
}

configure_user_zsh() {
  local zsh_managed_start="# >>> kali-parrot-setup >>>"
  local zsh_managed_end="# <<< kali-parrot-setup <<<"
  local tmp_zshrc

  if [[ ! -f "${ZSHRC}" ]]; then
    log "Creando .zshrc base..."
    cp "${ZSH_DIR}/templates/zshrc.zsh-template" "${ZSHRC}"
  else
    backup_file "${ZSHRC}"
  fi

  log "Configurando tema y plugins en .zshrc..."
  if grep -q '^ZSH_THEME=' "${ZSHRC}"; then
    sed -i 's|^ZSH_THEME=.*|ZSH_THEME="powerlevel10k/powerlevel10k"|' "${ZSHRC}"
  else
    printf '\nZSH_THEME="powerlevel10k/powerlevel10k"\n' >> "${ZSHRC}"
  fi

  if grep -q '^plugins=' "${ZSHRC}"; then
    sed -i 's|^plugins=.*|plugins=(git sudo zsh-autosuggestions zsh-syntax-highlighting)|' "${ZSHRC}"
  else
    printf '\nplugins=(git sudo zsh-autosuggestions zsh-syntax-highlighting)\n' >> "${ZSHRC}"
  fi

  upsert_ohmyzsh_bootstrap_block "${ZSHRC}"

  log "Configurando Powerlevel10k..."
  if [[ ! -f "${P10K_FILE}" ]] || grep -q '# >>> kali-parrot-setup-p10k >>>' "${P10K_FILE}"; then
    backup_file "${P10K_FILE}"
    require_file "${P10K_USER_TEMPLATE}"
    cp -f "${P10K_USER_TEMPLATE}" "${P10K_FILE}"
  else
    log "Detectada config personalizada en ${P10K_FILE}; no se sobrescribe."
  fi

  upsert_user_p10k_source_block "${ZSHRC}"

  log "Aplicando aliases y mejoras de terminal en .zshrc..."
  tmp_zshrc="$(mktemp)"
  awk -v start="${zsh_managed_start}" -v end="${zsh_managed_end}" '
    $0 == start { in_block=1; next }
    $0 == end { in_block=0; next }
    !in_block { print }
  ' "${ZSHRC}" > "${tmp_zshrc}"
  mv "${tmp_zshrc}" "${ZSHRC}"
  require_file "${ZSH_MANAGED_TEMPLATE}"
  printf '\n' >> "${ZSHRC}"
  cat "${ZSH_MANAGED_TEMPLATE}" >> "${ZSHRC}"
}

install_ohmyzsh_and_plugins_user() {
  if [[ ! -d "${ZSH_DIR}" ]]; then
    log "Instalando Oh My Zsh..."
    RUNZSH=no CHSH=no KEEP_ZSHRC=yes sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
  else
    warn "Oh My Zsh ya está instalado, omitiendo."
  fi

  mkdir -p "${ZSH_CUSTOM}/themes" "${ZSH_CUSTOM}/plugins"

  if [[ ! -d "${ZSH_CUSTOM}/themes/powerlevel10k" ]]; then
    log "Instalando Powerlevel10k..."
    git clone --depth=1 https://github.com/romkatv/powerlevel10k.git "${ZSH_CUSTOM}/themes/powerlevel10k"
  else
    warn "Powerlevel10k ya está instalado, omitiendo."
  fi

  if [[ ! -d "${ZSH_CUSTOM}/plugins/zsh-autosuggestions" ]]; then
    log "Instalando zsh-autosuggestions..."
    git clone --depth=1 https://github.com/zsh-users/zsh-autosuggestions "${ZSH_CUSTOM}/plugins/zsh-autosuggestions"
  else
    warn "zsh-autosuggestions ya está instalado, omitiendo."
  fi

  if [[ ! -d "${ZSH_CUSTOM}/plugins/zsh-syntax-highlighting" ]]; then
    log "Instalando zsh-syntax-highlighting..."
    git clone --depth=1 https://github.com/zsh-users/zsh-syntax-highlighting.git "${ZSH_CUSTOM}/plugins/zsh-syntax-highlighting"
  else
    warn "zsh-syntax-highlighting ya está instalado, omitiendo."
  fi
}

install_gomap() {
  log "Instalando gomap..."
  mkdir -p "${HOME}/.local/bin"
  GOBIN="${HOME}/.local/bin" go install github.com/NexusFireMan/gomap/v2@latest
}

ensure_default_shell_zsh() {
  local current_shell zsh_bin

  current_shell="$(getent passwd "${USER}" | cut -d: -f7)"
  zsh_bin="$(command -v zsh || true)"

  if [[ -n "${zsh_bin}" && "${current_shell}" != "${zsh_bin}" ]]; then
    log "Cambiando shell por defecto a zsh..."
    if chsh -s "${zsh_bin}" "${USER}"; then
      ok "Shell por defecto actualizada a zsh."
    else
      err "No se pudo cambiar la shell automáticamente. Ejecuta: chsh -s ${zsh_bin}"
    fi
  fi
}
