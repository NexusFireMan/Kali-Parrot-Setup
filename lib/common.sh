#!/usr/bin/env bash

init_colors() {
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
}

print_banner() {
  printf '\n'
  printf '%b' "${C_CYAN}${C_BOLD}"
  cat <<'BANNER'
 _  __    _ _      ____                       _
| |/ /_ _| (_)    |  _ \ __ _ _ __ _ __ ___ | |_
| ' / _` | | |____| |_) / _` | '__| '__/ _ \| __|
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

require_file() {
  local file="$1"
  if [[ ! -f "${file}" ]]; then
    err "Fichero requerido no encontrado: ${file}"
    exit 1
  fi
}

render_template() {
  local template="$1"
  shift
  local expr=()
  local pair key val
  for pair in "$@"; do
    key="${pair%%=*}"
    val="${pair#*=}"
    expr+=(-e "s|__${key}__|${val}|g")
  done
  sed "${expr[@]}" "${template}"
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
