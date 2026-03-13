
<p align="center">

<svg width="180" height="180" viewBox="0 0 200 200">
<rect width="200" height="200" rx="25" fill="#0b0e14"/>
<text x="50%" y="52%" dominant-baseline="middle" text-anchor="middle"
font-family="monospace" font-size="70" fill="#7aa2f7">
KPS
</text>
</svg>

</p>

<h1 align="center">
Kali-Parrot Setup
</h1>

<p align="center">
Bootstrap profesional para entornos de <b>Pentesting, CTF y Bug Bounty</b> en Kali Linux y Parrot Security OS.
</p>

---

<p align="center">

![Kali Linux](https://img.shields.io/badge/Kali-Linux-557C94?style=for-the-badge&logo=kalilinux)
![Parrot OS](https://img.shields.io/badge/Parrot-OS-00A3E0?style=for-the-badge&logo=linux)
![Shell](https://img.shields.io/badge/Shell-Bash-4EAA25?style=for-the-badge&logo=gnu-bash)
![License](https://img.shields.io/badge/license-MIT-blue?style=for-the-badge)
![Maintained](https://img.shields.io/badge/maintained-yes-success?style=for-the-badge)

</p>

<p align="center">

![Stars](https://img.shields.io/github/stars/NexusFireMan/Kali-Parrot-Setup?style=social)
![Forks](https://img.shields.io/github/forks/NexusFireMan/Kali-Parrot-Setup?style=social)
![Issues](https://img.shields.io/github/issues/NexusFireMan/Kali-Parrot-Setup)
[![Ko-fi](https://img.shields.io/badge/Ko--fi-Support-FF5E5B?style=for-the-badge&logo=kofi&logoColor=white)](https://ko-fi.com/C0C61UHTB1)

</p>

---

# 🧠 ¿Qué es Kali-Parrot Setup?

**Kali-Parrot Setup** es un bootstrap automatizado para crear un entorno profesional de pentesting en:

- Kali Linux
- Parrot Security OS

Configura automáticamente:

- terminal
- herramientas
- workflow
- widgets
- entorno visual

El objetivo es disponer de un **entorno reproducible y optimizado para hacking ético** en cuestión de minutos.

---

# ⚡ Características principales

### 🖥 Terminal profesional

- ZSH
- Oh My Zsh
- Powerlevel10k
- zsh-autosuggestions
- zsh-syntax-highlighting
- plugin sudo

---

### 🧰 Herramientas útiles

Incluye:

- bat
- lsd
- flameshot
- kitty
- gomap
- xclip
- feh

---

### 🎯 Workflow de pentesting

Funciones incluidas:

```
settarget <IP>
showtarget
cleartarget
```

Esto permite trabajar con un objetivo activo.

Ejemplo:

```
settarget 10.10.10.55
```

---

### 🗂 Creación automática de estructura de laboratorio

```
testGo <machine>
```

Genera:

```
enum/
   nmap/
   web/

burst/
post/
tmp/
```

---

### 🔎 ExtractPorts

Extrae puertos desde un resultado de Nmap.

```
extractPorts scan.txt
```

También copia los puertos al portapapeles si está instalado `xclip`.

---

# 📊 Widget de red para panel

El proyecto incluye un widget que muestra información clave durante el pentesting.

```
🌐 LAN
🐳 Docker
🎯 TARGET
🔒 VPN
```

Ejemplo:

```
🌐 192.168.1.25   🐳 172.17.0.1   🎯 10.10.10.55   🔒 10.10.14.3
```

---

### XFCE

Usa plugin **Generic Monitor**

![Widget XFCE](pics/image.png)
![Configuración Generic Monitor](pics/image1.png)

---

### Plasma

Soporta:

- widget Command Output
- Plasmoid nativo

Nota: si reinstalas el plasmoid, normalmente tendrás que quitarlo y volverlo a añadir al panel para que Plasma recargue la versión nueva.

---

# 🎨 Tema visual Dark Katana

Modo opcional con estilo oscuro.

Incluye:

- tema Kali-Dark
- iconos Flat-Remix-Blue-Dark
- paleta terminal estilo Katana
- configuración optimizada de Kitty

Activación:

```
./install.sh --dark-katana
```

---

# ⚔️ Tema visual Dark Samurai

Modo opcional con una estética más sobria y gris.

Incluye:

- fondo `assets/fondo.jpg`
- tema Kali-Dark
- iconos Adwaita
- paleta de Kitty en grises
- opacidad y tabs ajustados a un look más silencioso

Activación:

```
./install.sh --dark-samurai
```

---

# 🆚 Comparativa de estilos

| Modo | Fondo | Iconos | Kitty | Sensación visual |
|------|-------|--------|-------|------------------|
| `--dark-katana` | `Walpaper.jpg` / `Wallpaper.jpg` | `Flat-Remix-Blue-Dark` | paleta azul/verde con acentos vivos | más técnico, contrastado y agresivo |
| `--dark-samurai` | `fondo.jpg` | `Adwaita` | paleta gris y más sobria | más silencioso, gris y atmosférico |

Ambos modos mantienen la misma base funcional: Zsh, Powerlevel10k, alias, widget, Flameshot, Kitty y resto del workflow.

---

# 🚀 Instalación

Clonar repositorio

```
git clone https://github.com/NexusFireMan/Kali-Parrot-Setup
cd Kali-Parrot-Setup
```

Dar permisos

```
chmod +x install.sh
```

Ejecutar

```
./install.sh
```

Modo visual:

```
./install.sh --dark-katana
```

Modo samurai:

```
./install.sh --dark-samurai
```

---

# 🧩 Arquitectura del proyecto

```
Kali-Parrot-Setup
│
├── install.sh
│
├── lib
│   ├── common.sh
│   ├── bat.sh
│   ├── desktop.sh
│   ├── wallpaper.sh
│   ├── kitty.sh
│   └── zsh.sh
│
├── templates
│   ├── kitty configs
│   ├── zsh configs
│   ├── plasmoid templates
│   └── panel scripts
│
├── assets
│   └── wallpaper
│
└── pics
    └── screenshots
```

---

# 💾 Backups automáticos

Antes de modificar el sistema se crean backups en:

```
~/.config/kali-parrot-setup/backups/
```

Incluye:

- .zshrc
- .p10k.zsh
- configuraciones de XFCE
- configuraciones de root
- backups de panel, atajos y fondo cuando aplica

---

# 🖥 Compatibilidad

| Escritorio | Soporte |
|-------------|--------|
| XFCE | completo |
| Plasma 5 | completo |
| Plasma 6 | completo |
| MATE | parcial |
| GNOME | básico |

Notas:

- `XFCE`: soporta wallpaper, atajo `PrtSc` y widget `Generic Monitor`.
- `Plasma 5/6`: soporta `Command Output`, plasmoid nativo y reasignación de `PrtSc` desde Spectacle a Flameshot.
- `MATE`: soporta el atajo `PrtSc`, pero el widget del panel queda manual.
- `GNOME`: el atajo `PrtSc` se configura en modo best-effort y no se añade widget equivalente.

---

# 🎯 Objetivo del proyecto

Este proyecto busca proporcionar un **entorno reproducible para pentesting**, evitando tener que configurar manualmente cada instalación de Kali o Parrot.

Pensado para:

- CTF
- HackTheBox
- TryHackMe
- Bug Bounty
- auditorías de seguridad

---

# 🤝 Contribuciones

Las contribuciones son bienvenidas.

Puedes abrir:

- Issues
- Pull Requests
- sugerencias de herramientas

---

# 📜 Licencia

MIT License

---

<p align="center">

Made with ☕ and Bash by  
<b>NexusFireMan</b>

</p>
