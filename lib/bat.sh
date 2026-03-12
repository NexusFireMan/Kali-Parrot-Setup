#!/usr/bin/env bash

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
  local target api_url release_url tmp_dir bat_bin

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
