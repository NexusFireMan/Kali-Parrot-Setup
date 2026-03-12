#!/usr/bin/env bash

detect_desktop_env() {
  local raw="${XDG_CURRENT_DESKTOP:-${DESKTOP_SESSION:-}}"
  local upper="${raw^^}"

  if [[ "${upper}" == *"PLASMA"* || "${upper}" == *"KDE"* ]]; then
    printf 'plasma\n'
  elif [[ "${upper}" == *"XFCE"* ]]; then
    printf 'xfce\n'
  elif [[ "${upper}" == *"MATE"* ]]; then
    printf 'mate\n'
  elif [[ "${upper}" == *"GNOME"* ]]; then
    printf 'gnome\n'
  else
    printf 'unknown\n'
  fi
}

configure_plasma_prtsc() {
  local kglobal_file="${HOME}/.config/kglobalshortcutsrc"
  local kwrite=""

  if command -v kwriteconfig6 >/dev/null 2>&1; then
    kwrite="kwriteconfig6"
  elif command -v kwriteconfig5 >/dev/null 2>&1; then
    kwrite="kwriteconfig5"
  else
    return 1
  fi

  backup_file "${kglobal_file}"

  # Disable Spectacle defaults.
  "${kwrite}" --file kglobalshortcutsrc --group org.kde.spectacle.desktop --key RectangularRegionScreenShot "none,none,none" >/dev/null 2>&1 || true
  "${kwrite}" --file kglobalshortcutsrc --group org.kde.spectacle.desktop --key FullScreenScreenShot "none,none,none" >/dev/null 2>&1 || true
  "${kwrite}" --file kglobalshortcutsrc --group org.kde.spectacle.desktop --key CurrentMonitorScreenShot "none,none,none" >/dev/null 2>&1 || true
  "${kwrite}" --file kglobalshortcutsrc --group org.kde.spectacle.desktop --key ActiveWindowScreenShot "none,none,none" >/dev/null 2>&1 || true

  # Set Flameshot on Print (different builds expose different actions).
  "${kwrite}" --file kglobalshortcutsrc --group org.flameshot.Flameshot.desktop --key gui "Print,Print,flameshot gui" >/dev/null 2>&1 || true
  "${kwrite}" --file kglobalshortcutsrc --group org.flameshot.Flameshot.desktop --key launcher "Print,Print,flameshot gui" >/dev/null 2>&1 || true
  "${kwrite}" --file kglobalshortcutsrc --group org.flameshot.Flameshot.desktop --key Flameshot "Print,Print,flameshot gui" >/dev/null 2>&1 || true

  # Ask KDE services to reload shortcuts when possible.
  if command -v qdbus >/dev/null 2>&1; then
    qdbus org.kde.KWin /KWin reconfigure >/dev/null 2>&1 || true
    qdbus org.kde.kglobalaccel /kglobalaccel org.kde.KGlobalAccel.reloadConfig >/dev/null 2>&1 || true
  fi

  return 0
}

set_flameshot_prtsc() {
  local applied=0
  local desktop_env
  local xfce_kb_xml="${HOME}/.config/xfce4/xfconf/xfce-perchannel-xml/xfce4-keyboard-shortcuts.xml"
  local mate_applied=0
  local i cmd_key bind_key current_cmd

  desktop_env="$(detect_desktop_env)"

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

    # MATE/Parrot route.
    gsettings set org.mate.SettingsDaemon.plugins.media-keys screenshot "disabled" >/dev/null 2>&1 || \
      gsettings set org.mate.SettingsDaemon.plugins.media-keys screenshot "['disabled']" >/dev/null 2>&1 || true
    gsettings set org.mate.SettingsDaemon.plugins.media-keys window-screenshot "disabled" >/dev/null 2>&1 || \
      gsettings set org.mate.SettingsDaemon.plugins.media-keys window-screenshot "['disabled']" >/dev/null 2>&1 || true
    gsettings set org.mate.SettingsDaemon.plugins.media-keys area-screenshot "disabled" >/dev/null 2>&1 || \
      gsettings set org.mate.SettingsDaemon.plugins.media-keys area-screenshot "['disabled']" >/dev/null 2>&1 || true

    gsettings set org.mate.Marco.global-keybindings run-command-screenshot "disabled" >/dev/null 2>&1 || true
    gsettings set org.mate.Marco.keybinding-commands command-screenshot "flameshot gui" >/dev/null 2>&1 || true
    gsettings set org.mate.Marco.global-keybindings run-command-screenshot "Print" >/dev/null 2>&1 || true
    gsettings set org.mate.Marco.global-keybindings run-command-window-screenshot "disabled" >/dev/null 2>&1 || true
    gsettings set org.mate.Marco.global-keybindings run-command-terminal "disabled" >/dev/null 2>&1 || true

    for i in $(seq 1 12); do
      cmd_key="command-${i}"
      bind_key="run-command-${i}"
      current_cmd="$(gsettings get org.mate.Marco.keybinding-commands "${cmd_key}" 2>/dev/null || true)"
      if [[ "${current_cmd}" == "''" || "${current_cmd}" == "'flameshot gui'" ]]; then
        gsettings set org.mate.Marco.keybinding-commands "${cmd_key}" "flameshot gui" >/dev/null 2>&1 || true
        gsettings set org.mate.Marco.global-keybindings "${bind_key}" "Print" >/dev/null 2>&1 || true
        mate_applied=1
        break
      fi
    done

    if [[ "$(gsettings get org.mate.Marco.global-keybindings run-command-screenshot 2>/dev/null || true)" == "'Print'" ]]; then
      mate_applied=1
    elif command -v dconf >/dev/null 2>&1; then
      dconf write /org/mate/marco/keybinding-commands/command-screenshot "'flameshot gui'" >/dev/null 2>&1 || true
      dconf write /org/mate/marco/global-keybindings/run-command-screenshot "'Print'" >/dev/null 2>&1 || true
      [[ "$(dconf read /org/mate/marco/global-keybindings/run-command-screenshot 2>/dev/null || true)" == "'Print'" ]] && mate_applied=1 || true
    fi

    [[ "${mate_applied}" -eq 1 ]] && applied=1
  fi

  if [[ "${desktop_env}" == "plasma" ]]; then
    if configure_plasma_prtsc; then
      applied=1
      log "Plasma detectado: atajo Print configurado para Flameshot (puede requerir reiniciar sesión)."
    fi
  fi

  if [[ "${applied}" -eq 1 ]]; then
    log "Atajo configurado: PrtSc -> flameshot gui"
  else
    log "No se detectó método compatible para configurar el atajo de PrtSc."
  fi
}

install_optional_xfce_panel_plugin() {
  if [[ "$(detect_desktop_env)" != "xfce" ]]; then
    return 0
  fi
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

setup_plasma_top_panel_netinfo() {
  local script_path="${HOME}/.local/bin/plasma-panel-netinfo.sh"
  local panel_template="${TEMPLATE_DIR}/plasma-panel-netinfo.sh.tmpl"
  local plasmoid_id="pentest.dashboard"
  local plasmoid_root="${HOME}/.local/share/plasma/plasmoids/${plasmoid_id}"
  local build_root="${HOME}/.local/share/kali-parrot-setup/plasmoid-build"
  local package_dir="${build_root}/pentest-dashboard"
  local package_file="${build_root}/pentest-dashboard.plasmoid"
  local metadata_template="${TEMPLATE_DIR}/plasma-pentest-metadata.json.tmpl"
  local qml_template_plasma6="${TEMPLATE_DIR}/plasma-pentest-main.qml.tmpl"
  local qml_template_plasma5="${TEMPLATE_DIR}/plasma-pentest-main5.qml.tmpl"
  local qml_template=""
  local ipinfo_template="${TEMPLATE_DIR}/plasma-pentest-ipinfo.sh.tmpl"
  local kpackagetool=""

  mkdir -p "${HOME}/.local/bin"
  require_file "${panel_template}"
  cp -f "${panel_template}" "${script_path}"
  chmod +x "${script_path}"

  require_file "${metadata_template}"
  require_file "${qml_template_plasma6}"
  require_file "${qml_template_plasma5}"
  require_file "${ipinfo_template}"

  if command -v kpackagetool6 >/dev/null 2>&1; then
    kpackagetool="kpackagetool6"
    qml_template="${qml_template_plasma6}"
  elif command -v kpackagetool5 >/dev/null 2>&1; then
    kpackagetool="kpackagetool5"
    qml_template="${qml_template_plasma5}"
  else
    qml_template="${qml_template_plasma6}"
  fi

  rm -rf "${package_dir}"
  mkdir -p "${package_dir}/contents/ui" "${package_dir}/contents/scripts" "${plasmoid_root}/contents/ui" "${plasmoid_root}/contents/scripts"
  cp -f "${metadata_template}" "${package_dir}/metadata.json"
  cp -f "${qml_template}" "${package_dir}/contents/ui/main.qml"
  cp -f "${ipinfo_template}" "${package_dir}/contents/scripts/network.sh"
  chmod +x "${package_dir}/contents/scripts/network.sh"

  # Keep unpacked copy under ~/.local/share/plasma/plasmoids as fallback/manual install source.
  cp -f "${package_dir}/metadata.json" "${plasmoid_root}/metadata.json"
  cp -f "${package_dir}/contents/ui/main.qml" "${plasmoid_root}/contents/ui/main.qml"
  cp -f "${package_dir}/contents/scripts/network.sh" "${plasmoid_root}/contents/scripts/network.sh"

  if [[ -n "${kpackagetool}" ]]; then
    mkdir -p "${build_root}"
    if command -v zip >/dev/null 2>&1; then
      rm -f "${package_file}"
      (
        cd "${build_root}"
        zip -qr "$(basename "${package_file}")" pentest-dashboard
      )
      "${kpackagetool}" -t Plasma/Applet -r "${plasmoid_id}" >/dev/null 2>&1 || true
      "${kpackagetool}" -t Plasma/Applet -i "${package_file}" >/dev/null 2>&1 || true
      log "Plasmoid instalado desde paquete: ${package_file}"
    else
      "${kpackagetool}" -t Plasma/Applet -r "${plasmoid_id}" >/dev/null 2>&1 || true
      "${kpackagetool}" -t Plasma/Applet -i "${package_dir}" >/dev/null 2>&1 || true
      warn "No se encontró 'zip'; instalado desde directorio ${package_dir}."
    fi
    log "En Plasma: Editar panel -> Añadir widgets -> 'Pentest Dashboard Mini'"
  else
    warn "No se encontró kpackagetool5/6; se creó el plasmoid en ${plasmoid_root}."
  fi

  log "Plasma detectado: script de netinfo creado en ${script_path}."
  log "Añade manualmente el widget 'Command Output' al panel y usa comando: ${script_path}"
  log "Intervalo recomendado: 5 segundos"
}

setup_top_panel_netinfo() {
  case "$(detect_desktop_env)" in
    xfce)
      setup_xfce_top_panel_netinfo
      ;;
    plasma)
      setup_plasma_top_panel_netinfo
      ;;
    *)
      # Keep backward compatibility: generate XFCE script as generic fallback.
      setup_xfce_top_panel_netinfo
      ;;
  esac
}
