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
    openbox-themes \
    obconf-qt \
    python-pyxdg \
    polybar \
    rofi \
    kitty \
    nitrogen \
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
    tela-circle-icon-theme-dracula-git

log "Aplicativos AUR instalados"

# ------------------------------------------------------------------------------
# Tema Catppuccin — Rofi
# ------------------------------------------------------------------------------
section "Configurando tema Catppuccin para Rofi"

mkdir -p "$HOME/.config/rofi"

if [ ! -d "$HOME/.config/rofi/catppuccin" ]; then
    git clone https://github.com/catppuccin/rofi "$HOME/.config/rofi/catppuccin"
fi

cat > "$HOME/.config/rofi/config.rasi" << 'EOF'
@import "catppuccin/mocha.rasi"

configuration {
    modi:           "drun,run,window";
    show-icons:     true;
    icon-theme:     "Tela-circle-dracula";
    drun-display-format: "{name}";
    display-drun:   "Apps";
    display-run:    "Run";
    display-window: "Windows";
}

window {
    width: 520px;
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

mkdir -p "$HOME/.config/polybar"

cat > "$HOME/.config/polybar/config.ini" << 'EOF'
[colors]
base     = #1e1e2e
mantle   = #181825
crust    = #11111b
text     = #cdd6f4
subtext1 = #bac2de
subtext0 = #a6adc8
surface2 = #585b70
surface1 = #45475a
surface0 = #313244
blue     = #89b4fa
lavender = #b4befe
sapphire = #74c7ec
sky      = #89dceb
teal     = #94e2d5
green    = #a6e3a1
yellow   = #f9e2af
peach    = #fab387
maroon   = #eba0ac
red      = #f38ba8
mauve    = #cba6f7
pink     = #f5c2e7
flamingo = #f2cdcd
rosewater= #f5e0dc

[bar/main]
width            = 100%
height           = 30
radius           = 0
background       = ${colors.mantle}
foreground       = ${colors.text}
line-size        = 2
padding-left     = 1
padding-right    = 2
module-margin    = 1
separator        = 
font-0           = JetBrainsMono Nerd Font:size=10:weight=bold;2
font-1           = JetBrainsMono Nerd Font:size=14;3
modules-left     = openbox-menu workspaces xwindow
modules-center   = date
modules-right    = pulseaudio network battery tray
wm-restack       = openbox
override-redirect= true
bottom           = false
cursor-click     = pointer
cursor-scroll    = ns-resize
tray-position    = right
tray-padding     = 4

[module/openbox-menu]
type             = custom/text
content          =  Menu
content-foreground = ${colors.mauve}
content-padding  = 1
click-left       = rofi -show drun

[module/workspaces]
type             = custom/script
exec             = echo ""
interval         = 1

[module/xwindow]
type             = internal/xwindow
label            = %title:0:60:...%
label-foreground = ${colors.subtext1}

[module/date]
type             = internal/date
interval         = 1
date             = %A, %d %b
time             = %H:%M
label            =  %date%   %time%
label-foreground = ${colors.text}

[module/pulseaudio]
type             = internal/pulseaudio
format-volume    = <ramp-volume> <label-volume>
label-volume     = %percentage%%
label-volume-foreground = ${colors.text}
label-muted      =  muted
label-muted-foreground  = ${colors.surface2}
ramp-volume-0    = 
ramp-volume-1    = 
ramp-volume-2    = 
ramp-volume-foreground  = ${colors.blue}
click-right      = pavucontrol

[module/network]
type             = internal/network
interface-type   = wireless
interval         = 3
format-connected =  <label-connected>
label-connected  = %essid%
label-connected-foreground = ${colors.green}
format-disconnected =  offline
label-disconnected-foreground = ${colors.red}

[module/battery]
type             = internal/battery
battery          = BAT0
adapter          = AC
full-at          = 99
format-charging  = <animation-charging> <label-charging>
format-discharging = <ramp-capacity> <label-discharging>
format-full      =  <label-full>
label-charging-foreground   = ${colors.yellow}
label-discharging-foreground= ${colors.text}
label-full-foreground       = ${colors.green}
ramp-capacity-0  = 
ramp-capacity-1  = 
ramp-capacity-2  = 
ramp-capacity-3  = 
ramp-capacity-4  = 
ramp-capacity-foreground = ${colors.peach}
animation-charging-0 = 
animation-charging-1 = 
animation-charging-2 = 
animation-charging-3 = 
animation-charging-4 = 
animation-charging-foreground = ${colors.yellow}
animation-charging-framerate  = 750

[module/tray]
type             = internal/tray
tray-size        = 16
tray-padding     = 4
EOF

cat > "$HOME/.config/polybar/launch.sh" << 'EOF'
#!/bin/bash
killall -q polybar
while pgrep -u $UID -x polybar > /dev/null; do sleep 0.5; done
polybar main 2>&1 | tee -a /tmp/polybar.log & disown
EOF

chmod +x "$HOME/.config/polybar/launch.sh"
log "Polybar configurado"

# ------------------------------------------------------------------------------
# Openbox — configuração base
# ------------------------------------------------------------------------------
section "Configurando Openbox"

mkdir -p "$HOME/.config/openbox"

# Copiar configs padrão se não existirem
if [ ! -f "$HOME/.config/openbox/rc.xml" ]; then
    cp /etc/xdg/openbox/rc.xml "$HOME/.config/openbox/rc.xml"
fi
if [ ! -f "$HOME/.config/openbox/menu.xml" ]; then
    cp /etc/xdg/openbox/menu.xml "$HOME/.config/openbox/menu.xml"
fi

# autostart
cat > "$HOME/.config/openbox/autostart" << 'EOF'
# PipeWire
pipewire &
pipewire-pulse &
wireplumber &

# Polkit
/usr/lib/polkit-gnome/polkit-gnome-authentication-agent-1 &

# Compositor
picom --daemon &

# Barra
$HOME/.config/polybar/launch.sh &

# Dock
plank &

# Notificações
dunst &

# Papel de parede
nitrogen --restore &

# XDG autostart
dex --autostart --environment Openbox
EOF

# Adicionar keybinds ao rc.xml (Super para Rofi, Super+E para Thunar)
# Insere antes de </keyboard>
if ! grep -q "rofi" "$HOME/.config/openbox/rc.xml"; then
    sed -i 's|</keyboard>|    <keybind key="super">\n      <action name="Execute"><command>rofi -show drun</command></action>\n    </keybind>\n    <keybind key="super+e">\n      <action name="Execute"><command>thunar</command></action>\n    </keybind>\n    <keybind key="super+t">\n      <action name="Execute"><command>kitty</command></action>\n    </keybind>\n    <keybind key="super+l">\n      <action name="Execute"><command>rofi -show window</command></action>\n    </keybind>\n</keyboard>|' \
        "$HOME/.config/openbox/rc.xml"
fi

log "Openbox configurado"

# ------------------------------------------------------------------------------
# Picom — compositor
# ------------------------------------------------------------------------------
section "Configurando Picom"

mkdir -p "$HOME/.config/picom"

cat > "$HOME/.config/picom/picom.conf" << 'EOF'
# Sombras
shadow = true;
shadow-radius = 12;
shadow-opacity = 0.5;
shadow-offset-x = -12;
shadow-offset-y = -12;
shadow-exclude = [
    "name = 'Notification'",
    "class_g = 'Plank'",
    "class_g = 'Polybar'"
];

# Fade
faded = true;
fade-in-step = 0.05;
fade-out-step = 0.05;
fade-exclude = [];

# Transparência
inactive-opacity = 0.95;
active-opacity = 1.0;
frame-opacity = 1.0;
inactive-opacity-override = false;
opacity-rule = [
    "95:class_g = 'kitty'"
];

# Backend
backend = "glx";
vsync = true;
glx-no-stutter = true;

# Rounded corners
corner-radius = 10;
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

cat > "$HOME/.config/gtk-3.0/settings.ini" << 'EOF'
[Settings]
gtk-theme-name=catppuccin-mocha-standard-mauve-dark
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
EOF

cp "$HOME/.config/gtk-3.0/settings.ini" "$HOME/.config/gtk-4.0/settings.ini"

# xsettingsd para forçar tema em apps X11
if command -v xsettingsd &>/dev/null || yay -S --noconfirm --needed xsettingsd; then
    mkdir -p "$HOME/.config"
    cat > "$HOME/.config/xsettingsd" << 'EOF'
Net/ThemeName "catppuccin-mocha-standard-mauve-dark"
Net/IconThemeName "Tela-circle-dracula"
Gtk/FontName "Noto Sans 11"
Gtk/CursorThemeName "Adwaita"
EOF
fi

log "Tema GTK e ícones aplicados"

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
mkdir -p "$HOME/.config/plank/dock1/launchers"

for app in thunar kitty google-chrome-stable discord telegram-desktop qbittorrent steam spotify code sublime_text; do
    if [ -f "/usr/share/applications/${app}.desktop" ]; then
        echo -e "[PlankDockItemPreferences]\nLauncher=file:///usr/share/applications/${app}.desktop" \
            > "$HOME/.config/plank/dock1/launchers/${app}.dockitem"
    fi
done

log "Plank configurado"

# ------------------------------------------------------------------------------
# .xinitrc
# ------------------------------------------------------------------------------
section "Configurando .xinitrc"

cat > "$HOME/.xinitrc" << 'EOF'
#!/bin/bash
export GTK_THEME=catppuccin-mocha-standard-mauve-dark
export QT_QPA_PLATFORMTHEME=qt5ct
export QT_AUTO_SCREEN_SCALE_FACTOR=0

# XDG dirs
xdg-user-dirs-update &

# Configurações de teclado (ajuste o layout se necessário)
setxkbmap -layout br &

exec openbox-session
EOF

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
  ║    Super       → Rofi (launcher)             ║
  ║    Super + T   → Kitty (terminal)            ║
  ║    Super + E   → Thunar (arquivos)           ║
  ║    Super + L   → Rofi (window switcher)      ║
  ║                                              ║
  ║  Wallpaper: coloque wallpaper.jpg ou         ║
  ║  wallpaper.png na pasta do repositório       ║
  ║  antes de executar o script.                 ║
  ║                                              ║
  ╚══════════════════════════════════════════════╝
EOF
echo -e "${NC}"
