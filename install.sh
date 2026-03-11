#!/usr/bin/env bash
set -euo pipefail

# Minimal bootstrap for Kali/Parrot terminal customization.
# Installs packages, Oh My Zsh, Powerlevel10k, plugins, and Hack Nerd Font.

SCRIPT_NAME="$(basename "$0")"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
RUN_TS="$(date +%Y%m%d-%H%M%S)"
BACKUP_DIR="${HOME}/.config/kali-parrot-setup/backups/${RUN_TS}"
DARK_KATANA=0
TOTAL_STEPS=5
CURRENT_STEP=0

if [[ -t 1 ]]; then
  C_RESET='\033[0m'
  C_BOLD='\033[1m'
  C_CYAN='\033[36m'
  C_BLUE='\033[34m'
  C_GREEN='\033[32m'
  C_YELLOW='\033[33m'
  C_RED='\033[31m'
else
  C_RESET=''
  C_BOLD=''
  C_CYAN=''
  C_BLUE=''
  C_GREEN=''
  C_YELLOW=''
  C_RED=''
fi

print_banner() {
  printf '\n'
  printf '%b' "${C_CYAN}${C_BOLD}"
  cat <<'BANNER'
 _  __     _ _      ____                      _
| |/ /__ _| (_)    |  _ \ __ _ _ __ _ __ ___ | |_
| ' /  _` | | |____| |_) / _` | '__| '__/ _ \| __|
| . \ (_| | | |____|  __/ (_| | |  | | | (_) | |_
|_|\_\__,_|_|_|    |_|   \__,_|_|  |_|  \___/ \__|
BANNER
  printf '%b\n' "${C_RESET}"
  printf '%b\n' "${C_BLUE}>>> Setup para Kali/Parrot - $(date '+%Y-%m-%d %H:%M:%S')${C_RESET}"
}

log() {
  printf '%b[%s]%b %s\n' "${C_CYAN}" "$SCRIPT_NAME" "${C_RESET}" "$*"
}

ok() {
  printf '%b[%s]%b %s\n' "${C_GREEN}" "$SCRIPT_NAME" "${C_RESET}" "$*"
}

warn() {
  printf '%b[%s] WARN%b %s\n' "${C_YELLOW}" "$SCRIPT_NAME" "${C_RESET}" "$*"
}

section() {
  CURRENT_STEP=$((CURRENT_STEP + 1))
  printf '\n%b[%s]%b %b[%d/%d]%b %b%s%b\n' \
    "${C_BLUE}${C_BOLD}" "$SCRIPT_NAME" "${C_RESET}" \
    "${C_CYAN}" "${CURRENT_STEP}" "${TOTAL_STEPS}" "${C_RESET}" \
    "${C_BOLD}" "$*" "${C_RESET}"
}

err() {
  printf '%b[%s] ERROR%b: %s\n' "${C_RED}" "$SCRIPT_NAME" "${C_RESET}" "$*" >&2
}

require_cmd() {
  local cmd="$1"
  if ! command -v "$cmd" >/dev/null 2>&1; then
    err "Comando requerido no encontrado: $cmd"
    exit 1
  fi
}

backup_file() {
  local src="$1"
  if [[ -f "${src}" ]]; then
    mkdir -p "${BACKUP_DIR}"
    cp -a "${src}" "${BACKUP_DIR}/$(basename "${src}").bak"
    log "Backup creado: ${BACKUP_DIR}/$(basename "${src}").bak"
  fi
}

backup_root_file() {
  local src="$1"
  local dst_name="$2"
  if ${SUDO} test -f "${src}"; then
    mkdir -p "${BACKUP_DIR}"
    ${SUDO} cp -a "${src}" "${BACKUP_DIR}/${dst_name}"
    ${SUDO} chown "$(id -u):$(id -g)" "${BACKUP_DIR}/${dst_name}" >/dev/null 2>&1 || true
    log "Backup root creado: ${BACKUP_DIR}/${dst_name}"
  fi
}

upsert_user_p10k_source_block() {
  local file="$1"
  local start="# >>> kali-parrot-p10k-source >>>"
  local end="# <<< kali-parrot-p10k-source <<<"
  local tmp

  tmp="$(mktemp)"
  awk -v start="${start}" -v end="${end}" '
    $0 == start { in_block=1; next }
    $0 == end { in_block=0; next }
    !in_block { print }
  ' "${file}" > "${tmp}"
  mv "${tmp}" "${file}"

  cat >> "${file}" <<'P10K_SOURCE_BLOCK'
# >>> kali-parrot-p10k-source >>>
if [[ $EUID -eq 0 ]]; then
  [[ -f /root/.p10k.zsh ]] && source /root/.p10k.zsh
else
  [[ -f ~/.p10k.zsh ]] && source ~/.p10k.zsh
fi
# <<< kali-parrot-p10k-source <<<
P10K_SOURCE_BLOCK
}

upsert_root_p10k_source_block() {
  local file="$1"
  local start="# >>> kali-parrot-p10k-source >>>"
  local end="# <<< kali-parrot-p10k-source <<<"
  local tmp

  tmp="$(${SUDO} mktemp)"
  ${SUDO} awk -v start="${start}" -v end="${end}" '
    $0 == start { in_block=1; next }
    $0 == end { in_block=0; next }
    !in_block { print }
  ' "${file}" | ${SUDO} tee "${tmp}" >/dev/null
  ${SUDO} mv "${tmp}" "${file}"

  ${SUDO} tee -a "${file}" >/dev/null <<'P10K_ROOT_SOURCE_BLOCK'
# >>> kali-parrot-p10k-source >>>
[[ -f /root/.p10k.zsh ]] && source /root/.p10k.zsh
# <<< kali-parrot-p10k-source <<<
P10K_ROOT_SOURCE_BLOCK
}

upsert_ohmyzsh_bootstrap_block() {
  local file="$1"
  local start="# >>> kali-parrot-ohmyzsh-bootstrap >>>"
  local end="# <<< kali-parrot-ohmyzsh-bootstrap <<<"
  local tmp

  tmp="$(mktemp)"
  awk -v start="${start}" -v end="${end}" '
    $0 == start { in_block=1; next }
    $0 == end { in_block=0; next }
    !in_block { print }
  ' "${file}" > "${tmp}"
  mv "${tmp}" "${file}"

  cat >> "${file}" <<'OHMYZSH_BOOTSTRAP'
# >>> kali-parrot-ohmyzsh-bootstrap >>>
export ZSH="$HOME/.oh-my-zsh"
ZSH_THEME="powerlevel10k/powerlevel10k"
plugins=(git sudo zsh-autosuggestions zsh-syntax-highlighting)
if [[ -f "$ZSH/oh-my-zsh.sh" ]]; then
  source "$ZSH/oh-my-zsh.sh"
fi
# <<< kali-parrot-ohmyzsh-bootstrap <<<
OHMYZSH_BOOTSTRAP
}

set_wallpaper() {
  local wallpaper="$1"
  local applied=0
  local uri="file://${wallpaper}"
  local xfce_desktop_xml="${HOME}/.config/xfce4/xfconf/xfce-perchannel-xml/xfce4-desktop.xml"

  if [[ ! -f "${wallpaper}" ]]; then
    log "No se encontró fondo en ${wallpaper}; se omite configuración de wallpaper."
    return 0
  fi

  if command -v xfconf-query >/dev/null 2>&1; then
    backup_file "${xfce_desktop_xml}"
    mapfile -t xfce_props < <(xfconf-query -c xfce4-desktop -l 2>/dev/null | grep -E '/last-image$' || true)
    if [[ ${#xfce_props[@]} -gt 0 ]]; then
      for prop in "${xfce_props[@]}"; do
        xfconf-query -c xfce4-desktop -p "${prop}" -s "${wallpaper}" >/dev/null 2>&1 || true
      done
      mapfile -t xfce_style < <(xfconf-query -c xfce4-desktop -l 2>/dev/null | grep -E '/image-style$' || true)
      for prop in "${xfce_style[@]}"; do
        xfconf-query -c xfce4-desktop -p "${prop}" -s 5 >/dev/null 2>&1 || true
      done
      applied=1
    fi
  fi

  if command -v gsettings >/dev/null 2>&1; then
    gsettings set org.gnome.desktop.background picture-uri "${uri}" >/dev/null 2>&1 || true
    gsettings set org.gnome.desktop.background picture-uri-dark "${uri}" >/dev/null 2>&1 || true
    gsettings set org.mate.background picture-filename "${wallpaper}" >/dev/null 2>&1 || true
    applied=1
  fi

  if command -v plasma-apply-wallpaperimage >/dev/null 2>&1; then
    plasma-apply-wallpaperimage "${wallpaper}" >/dev/null 2>&1 || true
    applied=1
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

set_flameshot_prtsc() {
  local applied=0
  local xfce_kb_xml="${HOME}/.config/xfce4/xfconf/xfce-perchannel-xml/xfce4-keyboard-shortcuts.xml"

  if command -v xfconf-query >/dev/null 2>&1; then
    backup_file "${xfce_kb_xml}"
    xfconf-query -c xfce4-keyboard-shortcuts -p "/commands/custom/Print" -n -t string -s "flameshot gui" >/dev/null 2>&1 || \
      xfconf-query -c xfce4-keyboard-shortcuts -p "/commands/custom/Print" -s "flameshot gui" >/dev/null 2>&1 || true
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
  # Common offender on Kali/Parrot when bspwm completions are manually installed.
  local bspc_completion="/usr/local/share/zsh/site-functions/_bspc"
  if [[ -e "${bspc_completion}" ]]; then
    ${SUDO} chown root:root "${bspc_completion}" >/dev/null 2>&1 || true
    ${SUDO} chmod 644 "${bspc_completion}" >/dev/null 2>&1 || true
    log "Permisos compfix ajustados: ${bspc_completion}"
  fi
}

ensure_bat_fallback() {
  mkdir -p "${HOME}/.local/bin"
  if command -v bat >/dev/null 2>&1; then
    return 0
  fi
  if command -v batcat >/dev/null 2>&1; then
    ln -sf "$(command -v batcat)" "${HOME}/.local/bin/bat"
    log "Comando bat habilitado via symlink a batcat."
  else
    log "No se encontró ni bat ni batcat."
  fi
}

install_bat_official() {
  local arch target api_url release_url tmp_dir bat_bin

  if command -v bat >/dev/null 2>&1; then
    ok "bat ya está disponible en PATH."
    return 0
  fi

  case "$(uname -m)" in
    x86_64) target="x86_64-unknown-linux-gnu" ;;
    aarch64|arm64) target="aarch64-unknown-linux-gnu" ;;
    *)
      warn "Arquitectura no soportada por instalador oficial automático de bat: $(uname -m)"
      ensure_bat_fallback
      return 0
      ;;
  esac

  api_url="https://api.github.com/repos/sharkdp/bat/releases/latest"
  release_url="$(
    curl -fsSL "${api_url}" \
      | grep -Eo "https://[^\"]*bat-v[^\"]*-${target}\\.tar\\.gz" \
      | head -n1 || true
  )"

  if [[ -z "${release_url}" ]]; then
    warn "No se pudo localizar release oficial de bat para ${target}. Usando fallback."
    ensure_bat_fallback
    return 0
  fi

  tmp_dir="$(mktemp -d)"
  curl -fsSL "${release_url}" -o "${tmp_dir}/bat.tar.gz"
  tar -xzf "${tmp_dir}/bat.tar.gz" -C "${tmp_dir}"
  bat_bin="$(find "${tmp_dir}" -type f -name bat | head -n1 || true)"

  if [[ -n "${bat_bin}" ]]; then
    mkdir -p "${HOME}/.local/bin"
    install -m 0755 "${bat_bin}" "${HOME}/.local/bin/bat"
    ok "bat instalado desde release oficial de sharkdp/bat."
  else
    warn "No se encontró binario bat en la release descargada. Usando fallback."
    ensure_bat_fallback
  fi

  rm -rf "${tmp_dir}"
}

setup_xfce_top_panel_netinfo() {
  local script_path="${HOME}/.local/bin/xfce-panel-netinfo.sh"
  local xfce_panel_xml="${HOME}/.config/xfce4/xfconf/xfce-perchannel-xml/xfce4-panel.xml"

  mkdir -p "${HOME}/.local/bin"
  cat > "${script_path}" <<'PANEL_NETINFO'
#!/usr/bin/env bash
set -u

TARGET_FILE="${HOME}/.config/target"

first_ipv4_from_iface() {
  local iface="$1"
  command -v ip >/dev/null 2>&1 || return 1
  ip -4 -o addr show "${iface}" 2>/dev/null | awk '{print $4}' | cut -d/ -f1 | head -n1
}

local_ipv4() {
  command -v ip >/dev/null 2>&1 || return 1
  ip -4 route get 1.1.1.1 2>/dev/null | awk '{for(i=1;i<=NF;i++) if($i=="src"){print $(i+1); exit}}'
}

target_ipv4() {
  local target=""
  [[ -s "${TARGET_FILE}" ]] && target="$(<"${TARGET_FILE}")"
  [[ -n "${target}" ]] || return 1

  if [[ "${target}" =~ ^([0-9]{1,3}\.){3}[0-9]{1,3}$ ]]; then
    printf '%s\n' "${target}"
    return 0
  fi

  getent ahostsv4 "${target}" 2>/dev/null | awk '{print $1; exit}'
}

LAN="$(local_ipv4 || true)"
DOCKER="$(first_ipv4_from_iface docker0 || true)"
TARGET_IP="$(target_ipv4 || true)"
VPN="$(first_ipv4_from_iface tun0 || true)"
[[ -n "${VPN}" ]] || VPN="$(first_ipv4_from_iface turn0 || true)"
[[ -n "${VPN}" ]] || VPN="$(first_ipv4_from_iface wg0 || true)"

[[ -n "${LAN}" ]] || LAN="-"
[[ -n "${DOCKER}" ]] || DOCKER="-"
[[ -n "${TARGET_IP}" ]] || TARGET_IP="-"
[[ -n "${VPN}" ]] || VPN="-"

ICON_LAN="<span foreground='#4FC3F7'>󰌗</span>"
ICON_DOCKER="<span foreground='#64B5F6'></span>"
ICON_TARGET="<span foreground='#FFB74D'>󰓾</span>"
ICON_VPN="<span foreground='#81C784'>󰏗</span>"
TEXT="${ICON_LAN} ${LAN}  ${ICON_DOCKER} ${DOCKER}  ${ICON_TARGET} ${TARGET_IP}  ${ICON_VPN} ${VPN}"
printf '<txt>%s</txt>\n' "${TEXT}"
printf '<tool>%s</tool>\n' "${TEXT}"
PANEL_NETINFO
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

configure_kitty_katana() {
  local kitty_dir="${HOME}/.config/kitty"
  local kitty_conf="${kitty_dir}/kitty.conf"
  local katana_theme="${kitty_dir}/katana-dark.conf"
  local include_line="include katana-dark.conf"

  mkdir -p "${kitty_dir}"
  backup_file "${kitty_conf}"

  cat > "${katana_theme}" <<'KITTY_THEME'
# Katana dark palette
foreground            #d8dee9
background            #0b0e14
selection_foreground  #0b0e14
selection_background  #7aa2f7
cursor                #7aa2f7
cursor_text_color     #0b0e14

# black
color0  #1b1f27
color8  #4b5263
# red
color1  #f7768e
color9  #ff899d
# green
color2  #9ece6a
color10 #b9f27c
# yellow
color3  #e0af68
color11 #ffd280
# blue
color4  #7aa2f7
color12 #9bb8ff
# magenta
color5  #bb9af7
color13 #d3b5ff
# cyan
color6  #7dcfff
color14 #9fe1ff
# white
color7  #c0caf5
color15 #e5e9f0
KITTY_THEME

  if [[ ! -f "${kitty_conf}" ]]; then
    printf "%s\n" "${include_line}" > "${kitty_conf}"
  elif ! grep -qxF "${include_line}" "${kitty_conf}"; then
    printf "\n%s\n" "${include_line}" >> "${kitty_conf}"
  fi
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

configure_root_zsh() {
  local root_home="/root"
  local root_zsh_dir="${root_home}/.oh-my-zsh"
  local root_custom="${root_zsh_dir}/custom"
  local root_zshrc="${root_home}/.zshrc"
  local root_p10k="${root_home}/.p10k.zsh"

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

  ${SUDO} tee "${root_p10k}" >/dev/null <<'ROOT_P10K'
# >>> kali-parrot-setup-root-p10k >>>
# Root-specific Powerlevel10k config: skull + red accents.

typeset -g POWERLEVEL9K_MODE='nerdfont-complete'
typeset -g POWERLEVEL9K_PROMPT_ON_NEWLINE=false
typeset -g POWERLEVEL9K_MULTILINE_FIRST_PROMPT_PREFIX=''
typeset -g POWERLEVEL9K_MULTILINE_LAST_PROMPT_PREFIX=''

typeset -g POWERLEVEL9K_LEFT_PROMPT_ELEMENTS=(
  os_icon
  dir
  vcs
  context
  command_execution_time
  status
)
typeset -g POWERLEVEL9K_RIGHT_PROMPT_ELEMENTS=()

typeset -g POWERLEVEL9K_BACKGROUND=
typeset -g POWERLEVEL9K_LEFT_SEGMENT_SEPARATOR=''
typeset -g POWERLEVEL9K_RIGHT_SEGMENT_SEPARATOR=''
typeset -g POWERLEVEL9K_LEFT_SUBSEGMENT_SEPARATOR=' '
typeset -g POWERLEVEL9K_RIGHT_SUBSEGMENT_SEPARATOR=' '

typeset -g POWERLEVEL9K_OS_ICON_CONTENT_EXPANSION='☠'
typeset -g POWERLEVEL9K_OS_ICON_FOREGROUND=196
typeset -g POWERLEVEL9K_DIR_FOREGROUND=196
typeset -g POWERLEVEL9K_VCS_CLEAN_FOREGROUND=76
typeset -g POWERLEVEL9K_VCS_MODIFIED_FOREGROUND=220
typeset -g POWERLEVEL9K_STATUS_OK_FOREGROUND=76
typeset -g POWERLEVEL9K_STATUS_ERROR_FOREGROUND=196

typeset -g POWERLEVEL9K_SHORTEN_STRATEGY=truncate_to_unique
typeset -g POWERLEVEL9K_SHORTEN_DIR_LENGTH=2

typeset -g POWERLEVEL9K_STATUS_EXTENDED_STATES=true
typeset -g POWERLEVEL9K_STATUS_OK=true
# <<< kali-parrot-setup-root-p10k <<<
ROOT_P10K

  ${SUDO} chown root:root "${root_p10k}"
  ${SUDO} chmod 600 "${root_p10k}"
}

if [[ "${EUID}" -eq 0 ]]; then
  err "No ejecutes este script como root. Usa un usuario normal con sudo."
  exit 1
fi

while [[ $# -gt 0 ]]; do
  case "$1" in
    --dark-katana)
      DARK_KATANA=1
      shift
      ;;
    *)
      err "Opción no reconocida: $1"
      err "Uso: ./${SCRIPT_NAME} [--dark-katana]"
      exit 1
      ;;
  esac
done

require_cmd sudo

SUDO="sudo"
APT_PACKAGES=(
  zsh
  kitty
  lsd
  flameshot
  xclip
  golang-go
  git
  curl
  wget
  unzip
  fontconfig
)

ZSH_DIR="${HOME}/.oh-my-zsh"
ZSH_CUSTOM="${ZSH_CUSTOM:-${ZSH_DIR}/custom}"
ZSHRC="${HOME}/.zshrc"
P10K_FILE="${HOME}/.p10k.zsh"
FONT_DIR="${HOME}/.local/share/fonts/HackNerdFont"
REPO_WALLPAPER_FILE="${SCRIPT_DIR}/assets/Walpaper.jpg"
WALLPAPER_FILE="${HOME}/Pictures/Walpaper.jpg"

print_banner
section "Paquetes base"
log "Actualizando índices de paquetes..."
${SUDO} apt update

log "Instalando paquetes base..."
${SUDO} apt install -y "${APT_PACKAGES[@]}"

section "Ajustes del sistema y panel"
log "Corrigiendo permisos comunes de zsh completions..."
fix_common_compfix_permissions

log "Instalando plugin opcional para panel XFCE..."
install_optional_xfce_panel_plugin

log "Instalando bat desde repositorio oficial..."
install_bat_official

log "Configurando atajo de captura con Flameshot..."
set_flameshot_prtsc

log "Configurando widget de red en barra superior (XFCE)..."
setup_xfce_top_panel_netinfo

section "Oh My Zsh y plugins"
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

section "Configuracion de shell"
# "zsh-sudo" se cubre con el plugin nativo "sudo" de Oh My Zsh.
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
  cat > "${P10K_FILE}" <<'P10K_MANAGED'
# >>> kali-parrot-setup-p10k >>>
# Minimal Powerlevel10k config: left side with content, right side empty.

typeset -g POWERLEVEL9K_MODE='nerdfont-complete'
typeset -g POWERLEVEL9K_PROMPT_ON_NEWLINE=false
typeset -g POWERLEVEL9K_MULTILINE_FIRST_PROMPT_PREFIX=''
typeset -g POWERLEVEL9K_MULTILINE_LAST_PROMPT_PREFIX=''

typeset -g POWERLEVEL9K_LEFT_PROMPT_ELEMENTS=(
  os_icon
  dir
  vcs
  context
  command_execution_time
  status
)
typeset -g POWERLEVEL9K_RIGHT_PROMPT_ELEMENTS=()

typeset -g POWERLEVEL9K_BACKGROUND=
typeset -g POWERLEVEL9K_LEFT_SEGMENT_SEPARATOR=''
typeset -g POWERLEVEL9K_RIGHT_SEGMENT_SEPARATOR=''
typeset -g POWERLEVEL9K_LEFT_SUBSEGMENT_SEPARATOR=' '
typeset -g POWERLEVEL9K_RIGHT_SUBSEGMENT_SEPARATOR=' '

typeset -g POWERLEVEL9K_OS_ICON_FOREGROUND=250
typeset -g POWERLEVEL9K_DIR_FOREGROUND=39
typeset -g POWERLEVEL9K_VCS_CLEAN_FOREGROUND=76
typeset -g POWERLEVEL9K_VCS_MODIFIED_FOREGROUND=220
typeset -g POWERLEVEL9K_STATUS_OK_FOREGROUND=76
typeset -g POWERLEVEL9K_STATUS_ERROR_FOREGROUND=203

typeset -g POWERLEVEL9K_SHORTEN_STRATEGY=truncate_to_unique
typeset -g POWERLEVEL9K_SHORTEN_DIR_LENGTH=2

typeset -g POWERLEVEL9K_STATUS_EXTENDED_STATES=true
typeset -g POWERLEVEL9K_STATUS_OK=true
# <<< kali-parrot-setup-p10k <<<
P10K_MANAGED
else
  log "Detectada config personalizada en ${P10K_FILE}; no se sobrescribe."
fi

upsert_user_p10k_source_block "${ZSHRC}"

log "Instalando gomap..."
mkdir -p "${HOME}/.local/bin"
GOBIN="${HOME}/.local/bin" go install github.com/NexusFireMan/gomap/v2@latest

log "Aplicando aliases y mejoras de terminal en .zshrc..."
ZSH_MANAGED_START="# >>> kali-parrot-setup >>>"
ZSH_MANAGED_END="# <<< kali-parrot-setup <<<"

TMP_ZSHRC="$(mktemp)"
awk -v start="${ZSH_MANAGED_START}" -v end="${ZSH_MANAGED_END}" '
  $0 == start { in_block=1; next }
  $0 == end { in_block=0; next }
  !in_block { print }
' "${ZSHRC}" > "${TMP_ZSHRC}"
mv "${TMP_ZSHRC}" "${ZSHRC}"

cat >> "${ZSHRC}" <<'ZSH_MANAGED_BLOCK'

# >>> kali-parrot-setup >>>
# Path local bin (incluye gomap)
export PATH="$HOME/.local/bin:$PATH"

# Custom Aliases
# -----------------------------------------------

# bat
alias cat='bat'
alias catn='bat --style=plain'
alias catnp='bat --style=plain --paging=never'

# ls
alias ll='lsd -lh --group-dirs=first'
alias la='lsd -a --group-dirs=first'
alias l='lsd --group-dirs=first'
alias lla='lsd -lha --group-dirs=first'
alias ls='lsd --group-dirs=first'

# servidor HTTP rapido
alias pyserver='python3 -m http.server 80'

# ZSH History
HISTFILE=~/.zsh_history
HISTSIZE=10000
SAVEHIST=10000
setopt histignorealldups sharehistory

# Use modern completion system
autoload -Uz compinit
compinit

zstyle ':completion:*' auto-description 'specify: %d'
zstyle ':completion:*' completer _expand _complete _correct _approximate
zstyle ':completion:*' format 'Completing %d'
zstyle ':completion:*' group-name ''
zstyle ':completion:*' menu select=2
eval "$(dircolors -b)"
zstyle ':completion:*:default' list-colors ${(s.:.)LS_COLORS}
zstyle ':completion:*' list-colors ''
zstyle ':completion:*' list-prompt %SAt %p: Hit TAB for more, or the character to insert%s
zstyle ':completion:*' matcher-list '' 'm:{a-z}={A-Z}' 'm:{a-zA-Z}={A-Za-z}' 'r:|[._-]=* r:|=* l:|=*'
zstyle ':completion:*' menu select=long
zstyle ':completion:*' select-prompt %SScrolling active: current selection at %p%s
zstyle ':completion:*' use-compctl false
zstyle ':completion:*' verbose true

zstyle ':completion:*:*:kill:*:processes' list-colors '=(#b) #([0-9]#)*=0=01;31'
zstyle ':completion:*:kill:*' command 'ps -u $USER -o pid,%cpu,tty,cputime,cmd'

# --------------------------------------------
# Configuracion de TARGET global persistente
# --------------------------------------------

# Ruta del archivo que guarda el target actual
TARGET_FILE="${HOME}/.config/target"

# Si el archivo existe y no esta vacio, carga la variable
if [[ -s "$TARGET_FILE" ]]; then
  export TARGET="$(<"$TARGET_FILE")"
fi

# Establece un nuevo TARGET y lo guarda
settarget() {
  if [[ -z "$1" ]]; then
    echo "Uso: settarget <valor>"
    return 1
  fi

  mkdir -p "$(dirname "$TARGET_FILE")"
  echo "$1" > "$TARGET_FILE"
  export TARGET="$1"
  echo "TARGET establecido: $TARGET"
}

# Borra el TARGET actual
cleartarget() {
  : > "$TARGET_FILE"
  unset TARGET
  echo "TARGET enviado con San Pedro"
}

# Muestra el valor actual
showtarget() {
  if [[ -z "${TARGET:-}" ]]; then
    echo "TARGET no establecido"
  else
    echo "TARGET = $TARGET"
  fi
}

# Alias comodo
alias tshow='showtarget'

# ------------------------------------
# Creacion de carpetas para maquina
# ------------------------------------
function testGo(){
  if [[ -z "${1:-}" ]]; then
    echo "Uso: testGo <nombre_maquina>"
    return 1 2>/dev/null || exit 1
  fi

  MAQUINA="$1"

  if [[ -d "$MAQUINA" ]]; then
    echo "[!] El directorio $MAQUINA ya existe"
    return 1 2>/dev/null || exit 1
  fi

  if mkdir -p "$MAQUINA"/{enum/nmap,enum/web,burst,tmp,post} && cd "$MAQUINA/enum/nmap"; then
    echo "[+] Directorio creado. Listo, dale con la silla"
  else
    echo "[-] Error al crear directorios"
    return 1 2>/dev/null || exit 1
  fi
}

# -----------------------------------------
# Extraccion de puertos en nmap grepeable
# -----------------------------------------
function extractPorts(){
  if [[ -z "${1:-}" || ! -f "$1" ]]; then
    echo "[-] Uso: extractPorts <archivo_nmap>"
    return 1 2>/dev/null || exit 1
  fi

  local ports="$(grep -oP '\d{1,5}/open' "$1" | awk -F/ '{print $1}' | xargs | tr ' ' ',')"
  local ip_address="$(grep -oP '\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}' "$1" | sort -u | head -n 1)"

  if [[ -z "$ip_address" ]]; then
    echo "[-] No se encontro direccion IP en el archivo"
    return 1 2>/dev/null || exit 1
  fi

  echo -e "\n[+] Informacion extraida...\n"
  echo -e "\t[*] Direccion IP: $ip_address"
  echo -e "\t[*] Puertos abiertos: $ports\n"

  if command -v xclip &> /dev/null; then
    echo "$ports" | tr -d '\n' | xclip -sel clip
    echo "[+] Puertos copiados al portapapeles"
  else
    echo "[!] xclip no instalado - puertos no copiados"
  fi
}
# <<< kali-parrot-setup <<<
ZSH_MANAGED_BLOCK

configure_root_zsh

section "Fuentes y wallpaper"
log "Instalando Hack Nerd Font..."
TMP_DIR="$(mktemp -d)"
trap 'rm -rf "${TMP_DIR}"' EXIT

mkdir -p "${FONT_DIR}"
wget -qO "${TMP_DIR}/Hack.zip" "https://github.com/ryanoasis/nerd-fonts/releases/latest/download/Hack.zip"
unzip -o -q "${TMP_DIR}/Hack.zip" -d "${FONT_DIR}"

fc-cache -f "${HOME}/.local/share/fonts" >/dev/null 2>&1 || true

log "Copiando wallpaper desde el repositorio..."
ensure_repo_wallpaper "${REPO_WALLPAPER_FILE}" "${WALLPAPER_FILE}"

log "Configurando fondo de pantalla por defecto..."
set_wallpaper "${WALLPAPER_FILE}"

if [[ "${DARK_KATANA}" -eq 1 ]]; then
  apply_dark_katana_theme
else
  log "Modo dark-katana desactivado (usa --dark-katana para habilitarlo)."
fi

CURRENT_SHELL="$(getent passwd "${USER}" | cut -d: -f7)"
ZSH_BIN="$(command -v zsh || true)"
if [[ -n "${ZSH_BIN}" && "${CURRENT_SHELL}" != "${ZSH_BIN}" ]]; then
  log "Cambiando shell por defecto a zsh..."
  if chsh -s "${ZSH_BIN}" "${USER}"; then
    ok "Shell por defecto actualizada a zsh."
  else
    err "No se pudo cambiar la shell automáticamente. Ejecuta: chsh -s ${ZSH_BIN}"
  fi
fi

ok "Instalación completada."
log "Abre una nueva terminal y ejecuta 'p10k configure' si quieres ajustar Powerlevel10k."
