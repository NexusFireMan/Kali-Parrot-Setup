#!/usr/bin/env bash

configure_kitty_katana() {
  local kitty_dir="${HOME}/.config/kitty"
  local kitty_conf="${kitty_dir}/kitty.conf"
  local katana_theme="${kitty_dir}/katana-dark.conf"
  local theme_template="${TEMPLATE_DIR}/kitty-katana-dark.conf"
  local managed_template="${TEMPLATE_DIR}/kitty-managed.conf.tmpl"
  local start="# >>> kali-parrot-kitty >>>"
  local end="# <<< kali-parrot-kitty <<<"
  local tmp
  local zsh_bin

  zsh_bin="$(command -v zsh || true)"
  [[ -n "${zsh_bin}" ]] || zsh_bin="/bin/zsh"

  mkdir -p "${kitty_dir}"
  backup_file "${kitty_conf}"
  require_file "${theme_template}"
  require_file "${managed_template}"
  cp -f "${theme_template}" "${katana_theme}"

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

  render_template "${managed_template}" "ZSH_BIN=${zsh_bin}" >> "${kitty_conf}"
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

  configure_kitty_katana
}
