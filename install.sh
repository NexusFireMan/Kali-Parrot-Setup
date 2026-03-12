#!/usr/bin/env bash
set -euo pipefail

SCRIPT_NAME="$(basename "$0")"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LIB_DIR="${SCRIPT_DIR}/lib"
TEMPLATE_DIR="${SCRIPT_DIR}/templates"
RUN_TS="$(date +%Y%m%d-%H%M%S)"
BACKUP_DIR="${HOME}/.config/kali-parrot-setup/backups/${RUN_TS}"

DARK_KATANA=0
TOTAL_STEPS=5
CURRENT_STEP=0

# shellcheck source=lib/common.sh
source "${LIB_DIR}/common.sh"
# shellcheck source=lib/bat.sh
source "${LIB_DIR}/bat.sh"
# shellcheck source=lib/desktop.sh
source "${LIB_DIR}/desktop.sh"
# shellcheck source=lib/wallpaper.sh
source "${LIB_DIR}/wallpaper.sh"
# shellcheck source=lib/kitty.sh
source "${LIB_DIR}/kitty.sh"
# shellcheck source=lib/zsh.sh
source "${LIB_DIR}/zsh.sh"

init_colors

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
P10K_USER_TEMPLATE="${TEMPLATE_DIR}/p10k-user.zsh"
ZSH_MANAGED_TEMPLATE="${TEMPLATE_DIR}/zsh-managed-block.zsh"
FONT_DIR="${HOME}/.local/share/fonts/HackNerdFont"
WALLPAPER_FILE="${HOME}/Pictures/Walpaper.jpg"
WALLPAPER_FILE_ALT="${HOME}/Pictures/Wallpaper.jpg"

install_base_packages() {
  log "Actualizando índices de paquetes..."
  ${SUDO} apt update

  log "Instalando paquetes base..."
  ${SUDO} apt install -y "${APT_PACKAGES[@]}"
}

install_hack_nerd_font() {
  local tmp_dir

  log "Instalando Hack Nerd Font..."
  tmp_dir="$(mktemp -d)"
  trap 'rm -rf "${tmp_dir}"' RETURN

  mkdir -p "${FONT_DIR}"
  wget -qO "${tmp_dir}/Hack.zip" "https://github.com/ryanoasis/nerd-fonts/releases/latest/download/Hack.zip"
  unzip -o -q "${tmp_dir}/Hack.zip" -d "${FONT_DIR}"
  fc-cache -f "${HOME}/.local/share/fonts" >/dev/null 2>&1 || true
}

print_banner

section "Paquetes base"
install_base_packages

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
install_ohmyzsh_and_plugins_user

section "Configuracion de shell"
configure_user_zsh
install_gomap
configure_root_zsh

section "Fuentes y wallpaper"
install_hack_nerd_font

log "Copiando wallpaper desde el repositorio..."
if REPO_WALLPAPER_FILE="$(resolve_repo_wallpaper)"; then
  ensure_repo_wallpaper "${REPO_WALLPAPER_FILE}" "${WALLPAPER_FILE}"
  ensure_repo_wallpaper "${REPO_WALLPAPER_FILE}" "${WALLPAPER_FILE_ALT}"
else
  warn "No se encontró wallpaper en assets/ (Walpaper.jpg/Wallpaper.jpg)."
fi

log "Configurando fondo de pantalla por defecto..."
if [[ -f "${WALLPAPER_FILE}" ]]; then
  set_wallpaper "${WALLPAPER_FILE}"
elif [[ -f "${WALLPAPER_FILE_ALT}" ]]; then
  set_wallpaper "${WALLPAPER_FILE_ALT}"
fi

if [[ "${DARK_KATANA}" -eq 1 ]]; then
  apply_dark_katana_theme
else
  log "Modo dark-katana desactivado (usa --dark-katana para habilitarlo)."
fi

ensure_default_shell_zsh

ok "Instalación completada."
log "Abre una nueva terminal y ejecuta 'p10k configure' si quieres ajustar Powerlevel10k."
