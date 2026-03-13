#!/usr/bin/env bash

configure_kitty_theme() {
  local profile="$1"
  local kitty_dir="${HOME}/.config/kitty"
  local kitty_conf="${kitty_dir}/kitty.conf"
  local managed_template="${TEMPLATE_DIR}/kitty-managed.conf.tmpl"
  local start="# >>> kali-parrot-kitty >>>"
  local end="# <<< kali-parrot-kitty <<<"
  local tmp
  local zsh_bin
  local theme_template=""
  local theme_dest=""
  local include_file=""
  local url_color=""
  local inactive_tab_bg=""
  local active_tab_bg=""
  local inactive_tab_fg=""
  local tab_bar_margin=""
  local background_opacity=""

  zsh_bin="$(command -v zsh || true)"
  [[ -n "${zsh_bin}" ]] || zsh_bin="/bin/zsh"

  case "${profile}" in
    samurai)
      theme_template="${TEMPLATE_DIR}/kitty-samurai-dark.conf"
      theme_dest="${kitty_dir}/samurai-dark.conf"
      include_file="samurai-dark.conf"
      url_color="#9aa1a9"
      inactive_tab_bg="#474c52"
      active_tab_bg="#a7adb4"
      inactive_tab_fg="#111315"
      tab_bar_margin="#111315"
      background_opacity="0.92"
      ;;
    katana|*)
      theme_template="${TEMPLATE_DIR}/kitty-katana-dark.conf"
      theme_dest="${kitty_dir}/katana-dark.conf"
      include_file="katana-dark.conf"
      url_color="#61afef"
      inactive_tab_bg="#e06c75"
      active_tab_bg="#98c379"
      inactive_tab_fg="#000000"
      tab_bar_margin="black"
      background_opacity="0.95"
      ;;
  esac

  mkdir -p "${kitty_dir}"
  backup_file "${kitty_conf}"
  require_file "${theme_template}"
  require_file "${managed_template}"
  cp -f "${theme_template}" "${theme_dest}"

  if [[ ! -f "${kitty_conf}" ]]; then
    : > "${kitty_conf}"
  fi

  tmp="$(mktemp)"
  awk -v start="${start}" -v end="${end}" '
    $0 == start { in_block=1; next }
    $0 == end { in_block=0; next }
    !in_block { print }
  ' "${kitty_conf}" > "${tmp}"
  mv "${tmp}" "${kitty_conf}"

  render_template "${managed_template}" \
    "ZSH_BIN=${zsh_bin}" \
    "KITTY_THEME_FILE=${include_file}" \
    "URL_COLOR=${url_color}" \
    "INACTIVE_TAB_BG=${inactive_tab_bg}" \
    "ACTIVE_TAB_BG=${active_tab_bg}" \
    "INACTIVE_TAB_FG=${inactive_tab_fg}" \
    "TAB_BAR_MARGIN=${tab_bar_margin}" \
    "BACKGROUND_OPACITY=${background_opacity}" >> "${kitty_conf}"
}

configure_kitty_katana() {
  configure_kitty_theme "katana"
}

configure_kitty_samurai() {
  configure_kitty_theme "samurai"
}

apply_dark_katana_theme() {
  log "Aplicando estilo dark-katana..."

  if command -v xfconf-query >/dev/null 2>&1; then
    xfconf-query -c xsettings -p /Net/ThemeName -s "Kali-Dark" >/dev/null 2>&1 || true
    xfconf-query -c xsettings -p /Net/IconThemeName -s "Flat-Remix-Blue-Dark" >/dev/null 2>&1 || true
    xfconf-query -c xsettings -p /Gtk/CursorThemeName -s "Adwaita" >/dev/null 2>&1 || true
    xfconf-query -c xsettings -p /Gtk/FontName -s "Hack Nerd Font 11" >/dev/null 2>&1 || true
    xfconf-query -c xfwm4 -p /general/theme -s "Kali-Dark" >/dev/null 2>&1 || true
    xfconf-query -c xfwm4 -p /general/title_font -s "Hack Nerd Font Bold 10" >/dev/null 2>&1 || true
  fi

  if command -v gsettings >/dev/null 2>&1; then
    gsettings set org.gnome.desktop.interface color-scheme 'prefer-dark' >/dev/null 2>&1 || true
    gsettings set org.gnome.desktop.interface gtk-theme 'Kali-Dark' >/dev/null 2>&1 || true
    gsettings set org.gnome.desktop.interface icon-theme 'Flat-Remix-Blue-Dark' >/dev/null 2>&1 || true
    gsettings set org.gnome.desktop.interface font-name 'Hack Nerd Font 11' >/dev/null 2>&1 || true
    gsettings set org.gnome.desktop.interface monospace-font-name 'Hack Nerd Font Mono 11' >/dev/null 2>&1 || true
  fi
}

apply_dark_samurai_theme() {
  log "Aplicando estilo dark-samurai..."

  if command -v xfconf-query >/dev/null 2>&1; then
    xfconf-query -c xsettings -p /Net/ThemeName -s "Kali-Dark" >/dev/null 2>&1 || true
    xfconf-query -c xsettings -p /Net/IconThemeName -s "Adwaita" >/dev/null 2>&1 || true
    xfconf-query -c xsettings -p /Gtk/CursorThemeName -s "Adwaita" >/dev/null 2>&1 || true
    xfconf-query -c xsettings -p /Gtk/FontName -s "Hack Nerd Font 11" >/dev/null 2>&1 || true
    xfconf-query -c xfwm4 -p /general/theme -s "Kali-Dark" >/dev/null 2>&1 || true
    xfconf-query -c xfwm4 -p /general/title_font -s "Hack Nerd Font Bold 10" >/dev/null 2>&1 || true
  fi

  if command -v gsettings >/dev/null 2>&1; then
    gsettings set org.gnome.desktop.interface color-scheme 'prefer-dark' >/dev/null 2>&1 || true
    gsettings set org.gnome.desktop.interface gtk-theme 'Kali-Dark' >/dev/null 2>&1 || true
    gsettings set org.gnome.desktop.interface icon-theme 'Adwaita' >/dev/null 2>&1 || true
    gsettings set org.gnome.desktop.interface font-name 'Hack Nerd Font 11' >/dev/null 2>&1 || true
    gsettings set org.gnome.desktop.interface monospace-font-name 'Hack Nerd Font Mono 11' >/dev/null 2>&1 || true
  fi
}
