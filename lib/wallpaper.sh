#!/usr/bin/env bash

set_wallpaper() {
  local wallpaper="$1"
  local applied=0
  local xfce_applied=0
  local gnome_applied=0
  local mate_applied=0
  local kde_applied=0
  local uri="file://${wallpaper}"
  local xfce_desktop_xml="${HOME}/.config/xfce4/xfconf/xfce-perchannel-xml/xfce4-desktop.xml"
  local desktop_env="${XDG_CURRENT_DESKTOP:-}"
  local xfce_props=()
  local xfce_image_path_props=()
  local xfce_roots=()

  if [[ ! -f "${wallpaper}" ]]; then
    log "No se encontró fondo en ${wallpaper}; se omite configuración de wallpaper."
    return 0
  fi

  if command -v xfconf-query >/dev/null 2>&1; then
    backup_file "${xfce_desktop_xml}"
    mapfile -t xfce_props < <(xfconf-query -c xfce4-desktop -l 2>/dev/null | grep -E '/last-image$' || true)
    mapfile -t xfce_image_path_props < <(xfconf-query -c xfce4-desktop -l 2>/dev/null | grep -E '/image-path$' || true)
    mapfile -t xfce_roots < <(
      xfconf-query -c xfce4-desktop -l 2>/dev/null \
        | grep -Eo '/backdrop/screen[0-9]+/monitor[^/]+' \
        | sort -u || true
    )
    if [[ ${#xfce_roots[@]} -eq 0 ]]; then
      xfce_roots=(
        "/backdrop/screen0/monitor0"
        "/backdrop/screen0/monitorHDMI-0"
        "/backdrop/screen0/monitorVirtual-1"
      )
    fi

    xfconf-query -c xfce4-desktop -p "/backdrop/single-workspace-mode" --create -t bool -s true >/dev/null 2>&1 || true
    xfconf-query -c xfce4-desktop -p "/backdrop/single-workspace-number" --create -t int -s 0 >/dev/null 2>&1 || true

    # First, force all existing last-image properties discovered in this session.
    # This covers fresh and customized XFCE desktop channel layouts.
    if [[ ${#xfce_props[@]} -gt 0 ]]; then
      local prop style_prop
      for prop in "${xfce_props[@]}"; do
        xfconf-query -c xfce4-desktop -p "${prop}" --create -t string -s "${wallpaper}" >/dev/null 2>&1 && xfce_applied=1 || true
        style_prop="${prop%/last-image}/image-style"
        xfconf-query -c xfce4-desktop -p "${style_prop}" --create -t int -s 5 >/dev/null 2>&1 || true
      done
    fi

    # Some Kali profiles rely on image-path instead of last-image.
    if [[ ${#xfce_image_path_props[@]} -gt 0 ]]; then
      local image_prop
      for image_prop in "${xfce_image_path_props[@]}"; do
        xfconf-query -c xfce4-desktop -p "${image_prop}" --create -t string -s "${wallpaper}" >/dev/null 2>&1 && xfce_applied=1 || true
      done
    fi

    for root in "${xfce_roots[@]}"; do
      xfconf-query -c xfce4-desktop -p "${root}/workspace0/last-image" --create -t string -s "${wallpaper}" >/dev/null 2>&1 && xfce_applied=1 || true
      xfconf-query -c xfce4-desktop -p "${root}/workspace0/image-style" --create -t int -s 5 >/dev/null 2>&1 || true
      xfconf-query -c xfce4-desktop -p "${root}/last-image" --create -t string -s "${wallpaper}" >/dev/null 2>&1 && xfce_applied=1 || true
      xfconf-query -c xfce4-desktop -p "${root}/image-path" --create -t string -s "${wallpaper}" >/dev/null 2>&1 && xfce_applied=1 || true
      xfconf-query -c xfce4-desktop -p "${root}/image-style" --create -t int -s 5 >/dev/null 2>&1 || true
    done

    if [[ "${xfce_applied}" -eq 1 ]]; then
      xfdesktop --reload >/dev/null 2>&1 || {
        xfdesktop --quit >/dev/null 2>&1 || true
        nohup xfdesktop >/dev/null 2>&1 &
      }
      # Extra refresh nudge used by some Kali XFCE builds.
      pkill -USR1 xfdesktop >/dev/null 2>&1 || true
      applied=1
    fi
  fi

  if command -v gsettings >/dev/null 2>&1 && [[ "${desktop_env}" == *"GNOME"* ]]; then
    gsettings set org.gnome.desktop.background picture-uri "${uri}" >/dev/null 2>&1 && gnome_applied=1 || true
    gsettings set org.gnome.desktop.background picture-uri-dark "${uri}" >/dev/null 2>&1 || true
    [[ "${gnome_applied}" -eq 1 ]] && applied=1
  fi

  if command -v gsettings >/dev/null 2>&1 && [[ "${desktop_env}" == *"MATE"* ]]; then
    gsettings set org.mate.background picture-filename "${wallpaper}" >/dev/null 2>&1 && mate_applied=1 || true
    [[ "${mate_applied}" -eq 1 ]] && applied=1
  fi

  if command -v plasma-apply-wallpaperimage >/dev/null 2>&1 && [[ "${desktop_env}" == *"KDE"* ]]; then
    plasma-apply-wallpaperimage "${wallpaper}" >/dev/null 2>&1 && kde_applied=1 || true
    [[ "${kde_applied}" -eq 1 ]] && applied=1
  fi

  if [[ "${applied}" -eq 1 ]]; then
    log "Fondo aplicado: ${wallpaper}"
  else
    log "No se detectó método compatible para aplicar wallpaper automáticamente."
  fi
}

ensure_repo_wallpaper() {
  local repo_wallpaper="$1"
  local dest_wallpaper="$2"

  if [[ ! -f "${repo_wallpaper}" ]]; then
    log "No se encontró wallpaper en repo: ${repo_wallpaper}"
    return 0
  fi

  mkdir -p "$(dirname "${dest_wallpaper}")"
  cp -f "${repo_wallpaper}" "${dest_wallpaper}"
  log "Wallpaper copiado a ${dest_wallpaper}"
}

resolve_repo_wallpaper() {
  local candidates=(
    "${SCRIPT_DIR}/assets/Walpaper.jpg"
    "${SCRIPT_DIR}/assets/Wallpaper.jpg"
    "${SCRIPT_DIR}/assets/wallpaper.jpg"
  )
  local f

  for f in "${candidates[@]}"; do
    if [[ -f "${f}" ]]; then
      printf '%s\n' "${f}"
      return 0
    fi
  done
  return 1
}
