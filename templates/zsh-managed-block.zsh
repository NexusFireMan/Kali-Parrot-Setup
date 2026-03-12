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
