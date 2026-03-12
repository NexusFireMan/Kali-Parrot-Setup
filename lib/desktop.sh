#!/usr/bin/env bash

set_flameshot_prtsc() {
  local applied=0
  local xfce_kb_xml="${HOME}/.config/xfce4/xfconf/xfce-perchannel-xml/xfce4-keyboard-shortcuts.xml"
  local mate_applied=0

  if command -v xfconf-query >/dev/null 2>&1; then
    backup_file "${xfce_kb_xml}"
    xfconf-query -c xfce4-keyboard-shortcuts -p "/commands/custom/Print" -n -t string -s "flameshot gui" >/dev/null 2>&1 || \
      xfconf-query -c xfce4-keyboard-shortcuts -p "/commands/custom/Print" -s "flameshot gui" >/dev/null 2>&1 || true
    xfconf-query -c xfce4-keyboard-shortcuts -p "/commands/custom/<Print>" -n -t string -s "flameshot gui" >/dev/null 2>&1 || \
      xfconf-query -c xfce4-keyboard-shortcuts -p "/commands/custom/<Print>" -s "flameshot gui" >/dev/null 2>&1 || true
    xfconf-query -c xfce4-keyboard-shortcuts -p "/commands/custom/Print Screen" -n -t string -s "flameshot gui" >/dev/null 2>&1 || \
      xfconf-query -c xfce4-keyboard-shortcuts -p "/commands/custom/Print Screen" -s "flameshot gui" >/dev/null 2>&1 || true
    xfconf-query -c xfce4-keyboard-shortcuts -p "/commands/default/Print" -n -t string -s "" >/dev/null 2>&1 || \
      xfconf-query -c xfce4-keyboard-shortcuts -p "/commands/default/Print" -s "" >/dev/null 2>&1 || true
    xfconf-query -c xfce4-keyboard-shortcuts -p "/commands/default/<Print>" -n -t string -s "" >/dev/null 2>&1 || \
      xfconf-query -c xfce4-keyboard-shortcuts -p "/commands/default/<Print>" -s "" >/dev/null 2>&1 || true
    applied=1
  fi

  if command -v gsettings >/dev/null 2>&1; then
    gsettings set org.gnome.settings-daemon.plugins.media-keys screenshot "[]" >/dev/null 2>&1 || true
    gsettings set org.gnome.settings-daemon.plugins.media-keys window-screenshot "[]" >/dev/null 2>&1 || true
    gsettings set org.gnome.settings-daemon.plugins.media-keys area-screenshot "[]" >/dev/null 2>&1 || true

    local kb_base="/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings"
    local kb_path="${kb_base}/custom0/"
    gsettings set org.gnome.settings-daemon.plugins.media-keys custom-keybindings "['${kb_path}']" >/dev/null 2>&1 || true
    gsettings set org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:${kb_path} name "Flameshot" >/dev/null 2>&1 || true
    gsettings set org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:${kb_path} command "flameshot gui" >/dev/null 2>&1 || true
    gsettings set org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:${kb_path} binding "Print" >/dev/null 2>&1 || true
    applied=1

    # MATE/Parrot fallback paths.
    gsettings set org.mate.SettingsDaemon.plugins.media-keys screenshot "['disabled']" >/dev/null 2>&1 && mate_applied=1 || true
    gsettings set org.mate.SettingsDaemon.plugins.media-keys window-screenshot "['disabled']" >/dev/null 2>&1 || true
    gsettings set org.mate.SettingsDaemon.plugins.media-keys area-screenshot "['disabled']" >/dev/null 2>&1 || true

    gsettings set org.mate.Marco.global-keybindings run-command-screenshot "disabled" >/dev/null 2>&1 || true
    gsettings set org.mate.Marco.global-keybindings run-command-window-screenshot "disabled" >/dev/null 2>&1 || true
    gsettings set org.mate.Marco.global-keybindings run-command-terminal "disabled" >/dev/null 2>&1 || true

    gsettings set org.mate.Marco.keybinding-commands command-screenshot "flameshot gui" >/dev/null 2>&1 && mate_applied=1 || true
    gsettings set org.mate.Marco.global-keybindings run-command-screenshot "Print" >/dev/null 2>&1 && mate_applied=1 || true

    [[ "${mate_applied}" -eq 1 ]] && applied=1
  fi

  if [[ "${applied}" -eq 1 ]]; then
    log "Atajo configurado: PrtSc -> flameshot gui"
  else
    log "No se detectó método compatible para configurar el atajo de PrtSc."
  fi
}

install_optional_xfce_panel_plugin() {
  if apt-cache show xfce4-genmon-plugin >/dev/null 2>&1; then
    ${SUDO} apt install -y xfce4-genmon-plugin >/dev/null 2>&1 || true
  fi
}

fix_common_compfix_permissions() {
  local bspc_completion="/usr/local/share/zsh/site-functions/_bspc"
  if [[ -e "${bspc_completion}" ]]; then
    ${SUDO} chown root:root "${bspc_completion}" >/dev/null 2>&1 || true
    ${SUDO} chmod 644 "${bspc_completion}" >/dev/null 2>&1 || true
    log "Permisos compfix ajustados: ${bspc_completion}"
  fi
}

setup_xfce_top_panel_netinfo() {
  local script_path="${HOME}/.local/bin/xfce-panel-netinfo.sh"
  local xfce_panel_xml="${HOME}/.config/xfce4/xfconf/xfce-perchannel-xml/xfce4-panel.xml"
  local panel_template="${TEMPLATE_DIR}/xfce-panel-netinfo.sh.tmpl"
  local plugin_ids=()
  local id plugin_type plugin_cmd

  mkdir -p "${HOME}/.local/bin"
  require_file "${panel_template}"
  cp -f "${panel_template}" "${script_path}"
  chmod +x "${script_path}"

  if ! command -v xfconf-query >/dev/null 2>&1; then
    log "XFCE no detectado; script de netinfo creado en ${script_path}."
    return 0
  fi

  backup_file "${xfce_panel_xml}"

  mapfile -t plugin_ids < <(
    xfconf-query -c xfce4-panel -p /panels/panel-1/plugin-ids 2>/dev/null \
      | sed 's/^[[:space:]]*//;s/[[:space:]]*$//' \
      | awk '/^[0-9]+$/'
  )

  for id in "${plugin_ids[@]}"; do
    plugin_type="$(xfconf-query -c xfce4-panel -p "/plugins/plugin-${id}" 2>/dev/null || true)"
    plugin_cmd="$(xfconf-query -c xfce4-panel -p "/plugins/plugin-${id}/command" 2>/dev/null || true)"
    if [[ "${plugin_type}" == "genmon" && ( "${plugin_cmd}" == "${script_path}" || "${plugin_cmd}" == "xfce-panel-netinfo.sh" || "${plugin_cmd}" == "./xfce-panel-netinfo.sh" || "${plugin_cmd}" == *"/xfce-panel-netinfo.sh" ) ]]; then
      xfconf-query -c xfce4-panel -p "/plugins/plugin-${id}/command" -n -t string -s "${script_path}" >/dev/null 2>&1 || \
        xfconf-query -c xfce4-panel -p "/plugins/plugin-${id}/command" -t string -s "${script_path}" >/dev/null 2>&1 || true
      xfconf-query -c xfce4-panel -p "/plugins/plugin-${id}/cycle" -n -t int -s 5 >/dev/null 2>&1 || \
        xfconf-query -c xfce4-panel -p "/plugins/plugin-${id}/cycle" -t int -s 5 >/dev/null 2>&1 || true
      xfconf-query -c xfce4-panel -p "/plugins/plugin-${id}/label" -n -t string -s "" >/dev/null 2>&1 || \
        xfconf-query -c xfce4-panel -p "/plugins/plugin-${id}/label" -t string -s "" >/dev/null 2>&1 || true
      xfconf-query -c xfce4-panel -p "/plugins/plugin-${id}/use-label" -n -t bool -s false >/dev/null 2>&1 || \
        xfconf-query -c xfce4-panel -p "/plugins/plugin-${id}/use-label" -t bool -s false >/dev/null 2>&1 || true
      xfconf-query -c xfce4-panel -p "/plugins/plugin-${id}/use-markup" -n -t bool -s true >/dev/null 2>&1 || \
        xfconf-query -c xfce4-panel -p "/plugins/plugin-${id}/use-markup" -t bool -s true >/dev/null 2>&1 || true
      xfce4-panel -r >/dev/null 2>&1 || true
      log "Widget netinfo actualizado en plugin genmon existente (id ${id}, ruta absoluta)."
      return 0
    fi
  done

  log "No se modificó el panel automáticamente para evitar desorden."
  log "Añade manualmente un plugin 'Generic Monitor' y pon comando: ${script_path}"
}
