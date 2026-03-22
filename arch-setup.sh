#!/bin/bash
# =============================================================================
#  Arch Linux Setup Script
#  Ambiente: Openbox + Polybar + Plank + Rofi + Kitty
#  Tema: Catppuccin Mocha + Tela-circle-dracula
# =============================================================================

set -e

# ------------------------------------------------------------------------------
# Cores para output
# ------------------------------------------------------------------------------
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

log()     { echo -e "${GREEN}[✓]${NC} $1"; }
info()    { echo -e "${BLUE}[→]${NC} $1"; }
warn()    { echo -e "${YELLOW}[!]${NC} $1"; }
error()   { echo -e "${RED}[✗]${NC} $1"; exit 1; }
section() { echo -e "\n${PURPLE}══════════════════════════════════════════${NC}"; \
            echo -e "${CYAN}  $1${NC}"; \
            echo -e "${PURPLE}══════════════════════════════════════════${NC}\n"; }

# ------------------------------------------------------------------------------
# Verificações iniciais
# ------------------------------------------------------------------------------
section "Verificações iniciais"

[[ $EUID -eq 0 ]] && error "Não execute este script como root. Use seu usuário normal."

if ! ping -c 1 archlinux.org &>/dev/null; then
    error "Sem conexão com a internet. Verifique sua rede."
fi

log "Usuário: $(whoami)"
log "Diretório do script: $SCRIPT_DIR"

# ------------------------------------------------------------------------------
# pacman.conf — downloads paralelos, Color e ILoveCandy
# ------------------------------------------------------------------------------
section "Configurando pacman.conf"

sudo sed -i 's/^#ParallelDownloads.*/ParallelDownloads = 5/' /etc/pacman.conf

if ! grep -q "^Color" /etc/pacman.conf; then
    sudo sed -i 's/^#Color/Color/' /etc/pacman.conf
fi

if ! grep -q "^ILoveCandy" /etc/pacman.conf; then
    sudo sed -i '/^Color/a ILoveCandy' /etc/pacman.conf
fi

log "pacman.conf configurado"

# ------------------------------------------------------------------------------
# Atualizar sistema
# ------------------------------------------------------------------------------
section "Atualizando sistema"

sudo pacman -Syu --noconfirm
log "Sistema atualizado"

# ------------------------------------------------------------------------------
# Dependências base
# ------------------------------------------------------------------------------
section "Instalando dependências base"

sudo pacman -S --noconfirm --needed \
    base-devel \
    git \
    curl \
    wget \
    nano \
    xorg \
    xorg-xinit \
    xorg-server \
    xdg-utils \
    xdg-user-dirs \
    polkit \
    polkit-gnome

log "Dependências base instaladas"

# ------------------------------------------------------------------------------
# Yay (AUR helper)
# ------------------------------------------------------------------------------
section "Instalando Yay"

if ! command -v yay &>/dev/null; then
    info "Clonando e compilando yay..."
    cd /tmp
    git clone https://aur.archlinux.org/yay.git
    cd yay
    makepkg -si --noconfirm
    cd "$SCRIPT_DIR"
    log "Yay instalado"
else
    log "Yay já está instalado"
fi

# ------------------------------------------------------------------------------
# Flatpak
# ------------------------------------------------------------------------------
section "Instalando Flatpak"

sudo pacman -S --noconfirm --needed flatpak
flatpak remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo
log "Flatpak configurado com Flathub"

# ------------------------------------------------------------------------------
# Ambiente Desktop
# ------------------------------------------------------------------------------
section "Instalando ambiente desktop"

sudo pacman -S --noconfirm --needed \
    openbox \
    obconf-qt \
    python-pyxdg \
    polybar \
    rofi \
    kitty \
    thunar \
    thunar-archive-plugin \
    thunar-volman \
    gvfs \
    gvfs-mtp \
    file-roller \
    plank \
    picom \
    dunst \
    lxappearance \
    qt5ct \
    xdotool \
    wmctrl \
    ttf-jetbrains-mono-nerd \
    noto-fonts \
    noto-fonts-emoji

# nitrogen não está no pacman oficial — instalar via AUR
yay -S --noconfirm --needed nitrogen

log "Ambiente desktop instalado"

# ------------------------------------------------------------------------------
# PipeWire (áudio)
# ------------------------------------------------------------------------------
section "Configurando áudio (PipeWire)"

sudo pacman -S --noconfirm --needed \
    pipewire \
    pipewire-pulse \
    pipewire-audio \
    wireplumber \
    pavucontrol

systemctl --user enable pipewire
systemctl --user enable pipewire-pulse
systemctl --user enable wireplumber

log "PipeWire configurado"

# ------------------------------------------------------------------------------
# Codecs e GStreamer
# ------------------------------------------------------------------------------
section "Instalando codecs"

sudo pacman -S --noconfirm --needed \
    gstreamer \
    gst-plugins-base \
    gst-plugins-good \
    gst-plugins-bad \
    gst-plugins-ugly \
    gst-libav \
    ffmpeg

log "Codecs instalados"

# ------------------------------------------------------------------------------
# Aplicativos — pacman
# ------------------------------------------------------------------------------
section "Instalando aplicativos (pacman)"

sudo pacman -S --noconfirm --needed \
    discord \
    telegram-desktop \
    qbittorrent \
    steam \
    audacity \
    vlc \
    viewnior \
    evince \
    gnome-disk-utility \
    gufw \
    fwupd \
    ntfs-3g \
    timeshift

log "Aplicativos pacman instalados"

# ------------------------------------------------------------------------------
# Aplicativos — AUR (yay)
# ------------------------------------------------------------------------------
section "Instalando aplicativos (AUR)"

yay -S --noconfirm --needed \
    google-chrome \
    sublime-text-4 \
    bitwarden \
    heroic-games-launcher-bin \
    spotify \
    visual-studio-code-bin \
    catppuccin-gtk-theme-mocha \
    tela-circle-icon-theme-dracula-git \
    catppuccin-mocha-openbox-theme-git

log "Aplicativos AUR instalados"

# ------------------------------------------------------------------------------
# Tema Catppuccin — Rofi
# ------------------------------------------------------------------------------
section "Configurando tema Catppuccin para Rofi"

mkdir -p "$HOME/.config/rofi/themes"

# Clonar tema Catppuccin para Rofi e copiar o mocha
git clone --depth=1 https://github.com/catppuccin/rofi /tmp/catppuccin-rofi

# O repo tem vários layouts — pegar o primeiro arquivo mocha encontrado
MOCHA_FILE=$(find /tmp/catppuccin-rofi -name "*mocha*" | head -1)
if [ -n "$MOCHA_FILE" ]; then
    cp "$MOCHA_FILE" "$HOME/.config/rofi/themes/catppuccin-mocha.rasi"
    log "Tema Catppuccin Mocha copiado: $MOCHA_FILE"
else
    warn "Arquivo mocha.rasi não encontrado — Rofi usará tema padrão"
fi
rm -rf /tmp/catppuccin-rofi

cat > "$HOME/.config/rofi/config.rasi" << 'EOF'
@import "themes/catppuccin-mocha.rasi"

configuration {
    modi:                "drun,run,window";
    show-icons:          true;
    icon-theme:          "Tela-circle-dracula";
    drun-display-format: "{name}";
    display-drun:        "Apps";
    display-run:         "Run";
    display-window:      "Windows";
    /* Sem keybindings customizados — usa padrões do Rofi para evitar conflitos */
}

window {
    width:         520px;
    border-radius: 12px;
}

element {
    border-radius: 8px;
}
EOF

log "Rofi configurado com Catppuccin Mocha"

# ------------------------------------------------------------------------------
# Tema Catppuccin — Kitty
# ------------------------------------------------------------------------------
section "Configurando Kitty"

mkdir -p "$HOME/.config/kitty"

curl -sL "https://raw.githubusercontent.com/catppuccin/kitty/main/themes/mocha.conf" \
    -o "$HOME/.config/kitty/catppuccin-mocha.conf"

cat > "$HOME/.config/kitty/kitty.conf" << 'EOF'
include catppuccin-mocha.conf

# Fonte
font_family      JetBrainsMono Nerd Font
font_size        12.0
bold_font        auto
italic_font      auto
bold_italic_font auto

# Visual
background_opacity  0.95
window_padding_width 12
hide_window_decorations yes

# Abas
tab_bar_style           powerline
tab_powerline_style     slanted
tab_title_template      "{index}: {title}"
active_tab_font_style   bold

# Cursor
cursor_shape            beam
cursor_blink_interval   0.5

# Scroll
scrollback_lines        10000

# Bell
enable_audio_bell       no
EOF

log "Kitty configurado"


# ------------------------------------------------------------------------------
# Polybar — Catppuccin Mocha
# ------------------------------------------------------------------------------
section "Configurando Polybar"

sudo pacman -S --noconfirm --needed wmctrl bluez bluez-utils
yay -S --noconfirm --needed blueman network-manager-applet 2>/dev/null || true

mkdir -p "$HOME/.config/polybar"
mkdir -p "$HOME/.config/polybar/scripts"

# ── config.ini ────────────────────────────────────────────────────────────────
cat > "$HOME/.config/polybar/config.ini" << 'POLYEOF'
[colors]
base      = #1e1e2e
mantle    = #181825
crust     = #11111b
text      = #cdd6f4
subtext1  = #bac2de
subtext0  = #a6adc8
surface2  = #585b70
surface1  = #45475a
surface0  = #313244
blue      = #89b4fa
lavender  = #b4befe
sapphire  = #74c7ec
sky       = #89dceb
teal      = #94e2d5
green     = #a6e3a1
yellow    = #f9e2af
peach     = #fab387
maroon    = #eba0ac
red       = #f38ba8
mauve     = #cba6f7
pink      = #f5c2e7
flamingo  = #f2cdcd
rosewater = #f5e0dc

[bar/main]
width               = 100%
height              = 32
radius              = 0
background          = ${colors.mantle}
foreground          = ${colors.text}
line-size           = 2
padding-left        = 2
padding-right       = 2
module-margin-left  = 1
module-margin-right = 1
; aspas são obrigatórias em fontes com espaço no nome
font-0              = "JetBrainsMono Nerd Font:size=10:weight=bold;3"
font-1              = "JetBrainsMono Nerd Font:size=13;4"
modules-left        = openbox-menu xworkspaces xwindow
modules-center      = date
modules-right       = bluetooth network pulseaudio battery powermenu tray
wm-restack          = openbox
override-redirect   = true
bottom              = false
cursor-click        = pointer
cursor-scroll       = ns-resize
tray-position       = right
tray-padding        = 4
tray-background     = ${colors.mantle}

; ─── ESQUERDA ─────────────────────────────────────────────────────────────────

[module/openbox-menu]
type               = custom/text
content            = "  Menu "
content-foreground = ${colors.mauve}
content-background = ${colors.surface0}
content-padding    = 1
click-left         = rofi -show drun

[module/xworkspaces]
type                      = internal/xworkspaces
pin-workspaces            = false
show-urgent               = true

label-active              = "%name%"
label-active-foreground   = ${colors.crust}
label-active-background   = ${colors.mauve}
label-active-padding      = 1

label-occupied            = "%name%"
label-occupied-foreground = ${colors.text}
label-occupied-background = ${colors.surface0}
label-occupied-padding    = 1

label-urgent              = "%name%"
label-urgent-foreground   = ${colors.crust}
label-urgent-background   = ${colors.red}
label-urgent-padding      = 1

label-empty               = "%name%"
label-empty-foreground    = ${colors.surface2}
label-empty-padding       = 1

[module/xwindow]
type                   = internal/xwindow
label                  = "  %title:0:50:...% "
label-foreground       = ${colors.subtext1}
label-empty            = "  Desktop "
label-empty-foreground = ${colors.surface2}

; ─── CENTRO ───────────────────────────────────────────────────────────────────

[module/date]
type             = internal/date
interval         = 1
date             = %A, %d %b
time             = %H:%M
label            = "  %date%    %time% "
label-foreground = ${colors.text}

; ─── DIREITA ──────────────────────────────────────────────────────────────────

[module/bluetooth]
type              = custom/script
exec              = ~/.config/polybar/scripts/bluetooth.sh
interval          = 3
click-left        = blueman-manager
format-foreground = ${colors.sapphire}

[module/network]
type                                 = internal/network
interface-type                       = wireless
interval                             = 3
format-connected                     = "<label-connected>"
format-connected-prefix              = "  "
format-connected-prefix-foreground   = ${colors.green}
label-connected                      = "%essid% "
label-connected-foreground           = ${colors.green}
format-disconnected                  = "<label-disconnected>"
format-disconnected-prefix           = "  "
format-disconnected-prefix-foreground = ${colors.red}
label-disconnected                   = "offline "
label-disconnected-foreground        = ${colors.red}
click-left                           = nm-connection-editor

[module/pulseaudio]
type                    = internal/pulseaudio
use-ui-max              = true
interval                = 2
format-volume           = "<ramp-volume><label-volume>"
label-volume            = "%percentage%% "
label-volume-foreground = ${colors.text}
label-muted             = "  muted "
label-muted-foreground  = ${colors.surface2}
ramp-volume-0           = "  "
ramp-volume-1           = "  "
ramp-volume-2           = "  "
ramp-volume-foreground  = ${colors.blue}
click-right             = pavucontrol
click-middle            = pactl set-sink-mute @DEFAULT_SINK@ toggle

[module/battery]
type                          = internal/battery
battery                       = BAT0
adapter                       = AC
full-at                       = 99
poll-interval                 = 5
format-charging               = "<animation-charging><label-charging>"
format-discharging            = "<ramp-capacity><label-discharging>"
format-full                   = "  <label-full>"
format-full-foreground        = ${colors.green}
label-charging                = "%percentage%% "
label-charging-foreground     = ${colors.yellow}
label-discharging             = "%percentage%% "
label-discharging-foreground  = ${colors.text}
label-full                    = "Full "
ramp-capacity-0               = "  "
ramp-capacity-1               = "  "
ramp-capacity-2               = "  "
ramp-capacity-3               = "  "
ramp-capacity-4               = "  "
ramp-capacity-foreground      = ${colors.peach}
animation-charging-0          = "  "
animation-charging-1          = "  "
animation-charging-2          = "  "
animation-charging-3          = "  "
animation-charging-4          = "  "
animation-charging-foreground = ${colors.yellow}
animation-charging-framerate  = 750

[module/powermenu]
type               = custom/text
content            = "  "
content-foreground = ${colors.red}
content-padding    = 1
click-left         = ~/.config/polybar/scripts/powermenu.sh

[module/tray]
type            = internal/tray
tray-size       = 16
tray-padding    = 4
tray-background = ${colors.mantle}
POLYEOF

# ── Script bluetooth ──────────────────────────────────────────────────────────
cat > "$HOME/.config/polybar/scripts/bluetooth.sh" << 'BTEOF'
#!/bin/bash
BT_STATUS=$(bluetoothctl show 2>/dev/null | grep "Powered" | awk '{print $2}')
if [ "$BT_STATUS" = "yes" ]; then
    CONNECTED=$(bluetoothctl devices Connected 2>/dev/null | head -1 | cut -d' ' -f3-)
    if [ -n "$CONNECTED" ]; then
        echo "  $CONNECTED"
    else
        echo "  on"
    fi
else
    echo "  off"
fi
BTEOF
chmod +x "$HOME/.config/polybar/scripts/bluetooth.sh"

# ── Script power menu ─────────────────────────────────────────────────────────
cat > "$HOME/.config/polybar/scripts/powermenu.sh" << 'PWEOF'
#!/bin/bash
OPTS="  Desligar\n  Reiniciar\n  Encerrar sessão\n  Suspender"
CHOICE=$(echo -e "$OPTS" | rofi -dmenu -p "  Sistema" \
    -theme-str 'window { width: 240px; border-radius: 12px; }' \
    -theme-str 'listview { lines: 4; }' \
    -theme-str 'element { border-radius: 8px; }')

case "$CHOICE" in
    *"Desligar"*)        systemctl poweroff ;;
    *"Reiniciar"*)       systemctl reboot ;;
    *"Encerrar sessão"*) openbox --exit ;;
    *"Suspender"*)       systemctl suspend ;;
esac
PWEOF
chmod +x "$HOME/.config/polybar/scripts/powermenu.sh"

# ── Script para renomear desktops ─────────────────────────────────────────────
cat > "$HOME/.config/polybar/scripts/rename-desktops.sh" << 'RENEOF'
#!/bin/bash
# Força os nomes dos desktops via xprop, necessário pois o Openbox usa
# o locale do sistema (PT-BR) para nomear por padrão
python3 - << 'PYEOF'
import subprocess
names = ["●", "●", "●", "●"]
# _NET_DESKTOP_NAMES é uma lista de strings null-terminated em UTF-8
data = " ".join(names) + " "
encoded = ",".join(str(b) for b in data.encode('utf-8'))
subprocess.run([
    "xprop", "-root",
    "-f", "_NET_DESKTOP_NAMES", "8u",
    "-set", "_NET_DESKTOP_NAMES", data
], check=False)
PYEOF
RENEOF
chmod +x "$HOME/.config/polybar/scripts/rename-desktops.sh"

# ── launch.sh ────────────────────────────────────────────────────────────────
cat > "$HOME/.config/polybar/launch.sh" << 'LAUNCHEOF'
#!/bin/bash
killall -q polybar
while pgrep -u $UID -x polybar > /dev/null; do sleep 0.5; done
polybar main 2>&1 | tee -a /tmp/polybar.log & disown
LAUNCHEOF
chmod +x "$HOME/.config/polybar/launch.sh"

# ── Openbox: 4 desktops + keybinds de workspace ───────────────────────────────
python3 - << 'PYEOF'
import os, re
home = os.path.expanduser('~')
path = home + '/.config/openbox/rc.xml'
with open(path) as f:
    c = f.read()

desktops = (
    "<desktops>\n"
    "    <number>4</number>\n"
    "    <firstdesk>1</firstdesk>\n"
    "    <names>\n"
    "      <name>●</name>\n"
    "      <name>●</name>\n"
    "      <name>●</name>\n"
    "      <name>●</name>\n"
    "    </names>\n"
    "    <popupTime>875</popupTime>\n"
    "  </desktops>"
)
c = re.sub(r'<desktops>.*?</desktops>', desktops, c, flags=re.DOTALL)

if 'GoToDesktop' not in c:
    ws = (
        "\n    <!-- Workspaces -->\n"
        "    <keybind key=\"W-1\"><action name=\"GoToDesktop\"><to>1</to></action></keybind>\n"
        "    <keybind key=\"W-2\"><action name=\"GoToDesktop\"><to>2</to></action></keybind>\n"
        "    <keybind key=\"W-3\"><action name=\"GoToDesktop\"><to>3</to></action></keybind>\n"
        "    <keybind key=\"W-4\"><action name=\"GoToDesktop\"><to>4</to></action></keybind>\n"
        "    <keybind key=\"W-S-1\"><action name=\"SendToDesktop\"><to>1</to></action></keybind>\n"
        "    <keybind key=\"W-S-2\"><action name=\"SendToDesktop\"><to>2</to></action></keybind>\n"
        "    <keybind key=\"W-S-3\"><action name=\"SendToDesktop\"><to>3</to></action></keybind>\n"
        "    <keybind key=\"W-S-4\"><action name=\"SendToDesktop\"><to>4</to></action></keybind>\n"
    )
    c = c.replace('</keyboard>', ws + '</keyboard>', 1)

with open(path, 'w') as f:
    f.write(c)
print("Openbox desktops e keybinds configurados")
PYEOF

log "Polybar configurado"

# ------------------------------------------------------------------------------
# Openbox — configuração base
# ------------------------------------------------------------------------------
section "Configurando Openbox"

mkdir -p "$HOME/.config/openbox"

# Sempre partir do rc.xml padrão para garantir estado limpo
cp /etc/xdg/openbox/rc.xml "$HOME/.config/openbox/rc.xml"
cp /etc/xdg/openbox/menu.xml "$HOME/.config/openbox/menu.xml"

# autostart — sem aspas no heredoc para expandir variáveis
POLYBAR_LAUNCH="$HOME/.config/polybar/launch.sh"

cat > "$HOME/.config/openbox/autostart" << AUTOEOF
# PipeWire
pipewire &
pipewire-pulse &
wireplumber &

# Polkit
/usr/lib/polkit-gnome/polkit-gnome-authentication-agent-1 &

# Compositor
sleep 0.5 && picom --daemon &

# Barra
sleep 0.8 && ${POLYBAR_LAUNCH} &

# Dock
sleep 1.2 && plank &

# Notificações
dunst &

# Papel de parede
nitrogen --restore &

# Forçar nomes dos desktops via script (sobrescreve o padrão em PT-BR do sistema)
sleep 1.5 && $HOME/.config/polybar/scripts/rename-desktops.sh &
AUTOEOF

# Inserir keybinds no rc.xml via python
# Openbox: <action name="Execute"> requer <command>, não <execute>
# Tecla Super = prefixo "W-" no Openbox
python3 - << 'PYEOF'
import os, re
home = os.path.expanduser('~')
path = home + '/.config/openbox/rc.xml'
with open(path) as f:
    c = f.read()

# Remover qualquer bloco de keybinds nosso anterior
c = re.sub(r'\s*<!-- Keybinds customizados -->.*?(?=</keyboard>)', '', c, flags=re.DOTALL)

kb = """
    <!-- Keybinds customizados -->
    <keybind key="W-space">
      <action name="Execute">
        <command>rofi -show drun</command>
      </action>
    </keybind>
    <keybind key="W-d">
      <action name="Execute">
        <command>rofi -show drun</command>
      </action>
    </keybind>
    <keybind key="W-t">
      <action name="Execute">
        <command>kitty</command>
      </action>
    </keybind>
    <keybind key="W-e">
      <action name="Execute">
        <command>thunar</command>
      </action>
    </keybind>
    <keybind key="W-l">
      <action name="Execute">
        <command>rofi -show window</command>
      </action>
    </keybind>
    <keybind key="W-F4">
      <action name="Close"/>
    </keybind>
"""

c = c.replace('</keyboard>', kb + '</keyboard>', 1)
with open(path, 'w') as f:
    f.write(c)
print("rc.xml keybinds configurados")
PYEOF

# Aplicar tema de decoração de janelas Catppuccin no rc.xml
python3 - << 'PYEOF2'
import os, re
home = os.path.expanduser('~')
path = home + '/.config/openbox/rc.xml'
with open(path) as f:
    c = f.read()
# Substituir o nome do tema na seção <theme>
c = re.sub(r'<name>.*?</name>', '<name>Catppuccin-Mocha</name>', c, count=1)
with open(path, 'w') as f:
    f.write(c)
print("Tema de janela Catppuccin aplicado no rc.xml")
PYEOF2

log "Openbox configurado"

# ------------------------------------------------------------------------------
# Picom — compositor
# ------------------------------------------------------------------------------
section "Configurando Picom"

mkdir -p "$HOME/.config/picom"

cat > "$HOME/.config/picom/picom.conf" << 'EOF'
# Backend — xrender é mais compatível e não causa janela fantasma
backend = "xrender";
vsync = false;

# Sombras
shadow = true;
shadow-radius = 10;
shadow-opacity = 0.4;
shadow-offset-x = -10;
shadow-offset-y = -10;
shadow-exclude = [
    "name = 'Notification'",
    "class_g = 'Plank'",
    "class_g = 'Polybar'",
    "_GTK_FRAME_EXTENTS@:c"
];

# Fade suave
faded = true;
fade-in-step = 0.08;
fade-out-step = 0.08;

# Transparência apenas para o terminal
inactive-opacity = 1.0;
active-opacity = 1.0;
opacity-rule = [
    "95:class_g = 'kitty' && focused",
    "90:class_g = 'kitty' && !focused"
];

# Rounded corners
corner-radius = 8;
rounded-corners-exclude = [
    "class_g = 'Polybar'",
    "class_g = 'Plank'"
];
EOF

log "Picom configurado"

# ------------------------------------------------------------------------------
# Dunst — notificações Catppuccin Mocha
# ------------------------------------------------------------------------------
section "Configurando Dunst"

mkdir -p "$HOME/.config/dunst"

cat > "$HOME/.config/dunst/dunstrc" << 'EOF'
[global]
    monitor = 0
    follow = mouse
    width = 320
    height = 100
    origin = top-right
    offset = 12x48
    scale = 0
    notification_limit = 5
    progress_bar = true
    indicate_hidden = yes
    transparency = 5
    separator_height = 2
    padding = 12
    horizontal_padding = 12
    text_icon_padding = 0
    frame_width = 2
    frame_color = "#313244"
    separator_color = frame
    sort = yes
    font = JetBrainsMono Nerd Font 10
    line_height = 0
    markup = full
    format = "<b>%s</b>\n%b"
    alignment = left
    vertical_alignment = center
    show_age_threshold = 60
    ellipsize = middle
    ignore_newline = no
    stack_duplicates = true
    hide_duplicate_count = false
    show_indicators = yes
    icon_theme = Tela-circle-dracula
    enable_recursive_icon_lookup = true
    icon_position = left
    min_icon_size = 32
    max_icon_size = 48
    corner_radius = 10
    mouse_left_click = close_current
    mouse_right_click = close_all

[urgency_low]
    background = "#1e1e2e"
    foreground = "#cdd6f4"
    frame_color = "#313244"
    timeout = 4

[urgency_normal]
    background = "#1e1e2e"
    foreground = "#cdd6f4"
    frame_color = "#89b4fa"
    timeout = 6

[urgency_critical]
    background = "#1e1e2e"
    foreground = "#f38ba8"
    frame_color = "#f38ba8"
    timeout = 0
EOF

log "Dunst configurado"

# ------------------------------------------------------------------------------
# GTK — aplicar tema e ícones
# ------------------------------------------------------------------------------
section "Aplicando tema GTK e ícones"

mkdir -p "$HOME/.config/gtk-3.0"
mkdir -p "$HOME/.config/gtk-4.0"

# Detectar o nome exato do tema instalado (varia por versão do pacote)
# O pacote catppuccin-gtk-theme-mocha instala em /usr/share/themes/
GTK_THEME_NAME=$(find /usr/share/themes -maxdepth 1 -type d -iname "catppuccin-mocha*mauve*" | head -1 | xargs basename 2>/dev/null)

if [ -z "$GTK_THEME_NAME" ]; then
    # Fallback: pegar qualquer tema mocha disponível
    GTK_THEME_NAME=$(find /usr/share/themes -maxdepth 1 -type d -iname "catppuccin-mocha*" | head -1 | xargs basename 2>/dev/null)
fi

if [ -z "$GTK_THEME_NAME" ]; then
    warn "Tema Catppuccin GTK não encontrado em /usr/share/themes"
    GTK_THEME_NAME="Adwaita"
else
    log "Tema GTK detectado: $GTK_THEME_NAME"
fi

cat > "$HOME/.config/gtk-3.0/settings.ini" << GTKEOF
[Settings]
gtk-theme-name=$GTK_THEME_NAME
gtk-icon-theme-name=Tela-circle-dracula
gtk-font-name=Noto Sans 11
gtk-cursor-theme-name=Adwaita
gtk-cursor-theme-size=24
gtk-toolbar-style=GTK_TOOLBAR_BOTH_HORIZ
gtk-toolbar-icon-size=GTK_ICON_SIZE_LARGE_TOOLBAR
gtk-button-images=1
gtk-menu-images=1
gtk-enable-event-sounds=0
gtk-enable-input-feedback-sounds=0
gtk-xft-antialias=1
gtk-xft-hinting=1
gtk-xft-hintstyle=hintfull
gtk-xft-rgba=rgb
GTKEOF

cp "$HOME/.config/gtk-3.0/settings.ini" "$HOME/.config/gtk-4.0/settings.ini"

# gsettings — aplica para apps GNOME/GTK sem precisar reiniciar
if command -v gsettings &>/dev/null; then
    gsettings set org.gnome.desktop.interface gtk-theme "$GTK_THEME_NAME" 2>/dev/null || true
    gsettings set org.gnome.desktop.interface icon-theme "Tela-circle-dracula" 2>/dev/null || true
    gsettings set org.gnome.desktop.interface font-name "Noto Sans 11" 2>/dev/null || true
    gsettings set org.gnome.desktop.interface cursor-theme "Adwaita" 2>/dev/null || true
    log "gsettings aplicados"
fi

# xsettingsd — aplica tema para apps X11 em tempo real
yay -S --noconfirm --needed xsettingsd 2>/dev/null || true
mkdir -p "$HOME/.config"
cat > "$HOME/.config/xsettingsd" << XEOF
Net/ThemeName "$GTK_THEME_NAME"
Net/IconThemeName "Tela-circle-dracula"
Gtk/FontName "Noto Sans 11"
Gtk/CursorThemeName "Adwaita"
Xft/Antialias 1
Xft/Hinting 1
Xft/HintStyle "hintfull"
Xft/RGBA "rgb"
XEOF

# Adicionar xsettingsd ao autostart do Openbox
if ! grep -q "xsettingsd" "$HOME/.config/openbox/autostart"; then
    echo "" >> "$HOME/.config/openbox/autostart"
    echo "# Aplica tema GTK em tempo real" >> "$HOME/.config/openbox/autostart"
    echo "xsettingsd &" >> "$HOME/.config/openbox/autostart"
fi

log "Tema GTK e ícones aplicados: $GTK_THEME_NAME"

# ------------------------------------------------------------------------------
# Papel de parede
# ------------------------------------------------------------------------------
section "Configurando papel de parede"

mkdir -p "$HOME/Pictures/wallpapers"

WALLPAPER_SRC="$SCRIPT_DIR/wallpaper.jpg"
WALLPAPER_DST="$HOME/Pictures/wallpapers/wallpaper.jpg"

if [ -f "$WALLPAPER_SRC" ]; then
    cp "$WALLPAPER_SRC" "$WALLPAPER_DST"
    log "Wallpaper copiado do repositório"
elif [ -f "$SCRIPT_DIR/wallpaper.png" ]; then
    cp "$SCRIPT_DIR/wallpaper.png" "$HOME/Pictures/wallpapers/wallpaper.png"
    WALLPAPER_DST="$HOME/Pictures/wallpapers/wallpaper.png"
    log "Wallpaper copiado do repositório"
else
    warn "Nenhum wallpaper encontrado no repositório (wallpaper.jpg ou wallpaper.png)"
    warn "Adicione um arquivo wallpaper.jpg ou wallpaper.png na pasta do repositório"
    WALLPAPER_DST=""
fi

mkdir -p "$HOME/.config/nitrogen"
if [ -n "$WALLPAPER_DST" ]; then
    cat > "$HOME/.config/nitrogen/bg-saved.cfg" << EOF
[xin_-1]
file=$WALLPAPER_DST
mode=5
bgcolor=#1e1e2e
EOF
fi

cat > "$HOME/.config/nitrogen/nitrogen.cfg" << EOF
[nitrogen]
view=icon
recurse=true
sort=alpha
icon_caps=false
dirs=$HOME/Pictures/wallpapers;
EOF

log "Nitrogen configurado"

# ------------------------------------------------------------------------------
# Plank — dock
# ------------------------------------------------------------------------------
section "Configurando Plank"

mkdir -p "$HOME/.config/plank/dock1"

cat > "$HOME/.config/plank/dock1/settings" << 'EOF'
[PlankDockPreferences]
#Whether to show only windows of the current workspace.
CurrentWorkspaceOnly=false
#The size of dock icons (in pixels).
IconSize=48
#If true, the dock won't hide.
PinnedOnly=false
#Whether to automatically hide the dock.
HideMode=1
#Time (in ms) to wait before unhiding the dock.
UnhideDelay=0
#The type of zoom effect.
ZoomEnabled=true
#The zoomed size of dock icons.
ZoomPercent=150
#The position for the dock on the monitor.
Position=3
#The monitor number for the dock.
Monitor=
#Whether to lock all items on the dock, preventing changes.
LockItems=false
#The alignment for the dock on the monitor's edge.
Alignment=3
#The number of items offset from center.
Offset=0
#The name of the theme to use for the dock.
Theme=Transparent
#The type of items to show in the dock.
ItemsAlignment=3
EOF

# Launchers do plank
# O Plank lê .dockitem com o path completo do .desktop
# Precisamos descobrir o nome real de cada .desktop antes de criar o item
mkdir -p "$HOME/.config/plank/dock1/launchers"

create_dockitem() {
    local desktop_name="$1"
    local desktop_path="/usr/share/applications/${desktop_name}.desktop"
    local item_name="${desktop_name%%.*}"  # remove extensão se tiver

    if [ -f "$desktop_path" ]; then
        cat > "$HOME/.config/plank/dock1/launchers/${item_name}.dockitem" << DOCKEOF
[PlankDockItemPreferences]
Launcher=file://${desktop_path}
DOCKEOF
        echo "  dockitem criado: ${item_name}"
    else
        echo "  .desktop não encontrado: ${desktop_path}"
    fi
}

# Mapear nome do .desktop de cada app
for desktop in     "thunar"     "kitty"     "google-chrome"     "discord"     "telegram-desktop"     "qbittorrent"     "steam"     "spotify"     "code"     "sublime_text"     "org.gnome.Nautilus"     "org.gnome.FileRoller"
do
    create_dockitem "$desktop"
done

log "Plank configurado"

# ------------------------------------------------------------------------------
# .xinitrc
# ------------------------------------------------------------------------------
section "Configurando .xinitrc"

# .xinitrc com tema detectado dinamicamente
GTK_THEME_XINITRC=$(find /usr/share/themes -maxdepth 1 -type d -iname "catppuccin-mocha*mauve*" | head -1 | xargs basename 2>/dev/null)
[ -z "$GTK_THEME_XINITRC" ] && GTK_THEME_XINITRC="Adwaita"

cat > "$HOME/.xinitrc" << XINITEOF
#!/bin/bash
export GTK_THEME=${GTK_THEME_XINITRC}
export GTK2_RC_FILES=\$HOME/.gtkrc-2.0
export QT_QPA_PLATFORMTHEME=qt5ct
export QT_AUTO_SCREEN_SCALE_FACTOR=0
export XDG_SESSION_TYPE=x11
export XDG_CURRENT_DESKTOP=openbox

# XDG dirs
xdg-user-dirs-update &

# Configurações de teclado
setxkbmap -layout br

# Iniciar Openbox
exec openbox-session
XINITEOF

# Criar .gtkrc-2.0 para apps GTK2 legados
cat > "$HOME/.gtkrc-2.0" << GTKEOF2
gtk-theme-name="${GTK_THEME_XINITRC}"
gtk-icon-theme-name="Tela-circle-dracula"
gtk-font-name="Noto Sans 11"
gtk-cursor-theme-name="Adwaita"
gtk-cursor-theme-size=24
GTKEOF2

log ".xinitrc configurado"

# ------------------------------------------------------------------------------
# xdg-user-dirs
# ------------------------------------------------------------------------------
xdg-user-dirs-update
log "Diretórios XDG criados"

# ------------------------------------------------------------------------------
# Habilitar serviços
# ------------------------------------------------------------------------------
section "Habilitando serviços"

sudo systemctl enable fwupd
sudo systemctl enable ufw
sudo ufw enable

log "Serviços habilitados"

# ------------------------------------------------------------------------------
# Resumo final
# ------------------------------------------------------------------------------
section "Instalação concluída!"

echo -e "${GREEN}"
cat << 'EOF'
  ╔══════════════════════════════════════════════╗
  ║      Setup concluído com sucesso!            ║
  ╠══════════════════════════════════════════════╣
  ║                                              ║
  ║  Para iniciar o ambiente:                    ║
  ║    startx                                    ║
  ║                                              ║
  ║  Atalhos configurados:                       ║
  ║    Super + Space → Rofi (launcher)           ║
  ║    Super + D     → Rofi (launcher)           ║
  ║    Super + T     → Kitty (terminal)          ║
  ║    Super + E     → Thunar (arquivos)         ║
  ║    Super + L     → Rofi (window switcher)    ║
  ║                                              ║
  ║  Wallpaper: coloque wallpaper.jpg ou         ║
  ║  wallpaper.png na pasta do repositório       ║
  ║  antes de executar o script.                 ║
  ║                                              ║
  ║  Se algo não carregar, clique com botão      ║
  ║  direito no desktop → Reconfigure           ║
  ║                                              ║
  ╚══════════════════════════════════════════════╝
EOF
echo -e "${NC}"
