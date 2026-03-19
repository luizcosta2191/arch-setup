#!/bin/bash

# ==============================================================================
#  arch-setup.sh
#  Uso: git clone <seu-repo> && cd <repo> && ./arch-setup.sh
#
#  Fluxo esperado:
#    1. Arch Linux minimal instalado
#    2. git clone do repositório
#    3. ./arch-setup.sh  (rodado de dentro da pasta do repo)
#
#  O repositório deve conter:
#    arch-setup.sh   ← este script
#    wallpaper.jpg   ← (ou .png / .jpeg) wallpaper que será copiado
#
#  Tema: Catppuccin Mocha | Clima em °C | Teclado BR | Sem binds ROG
# ==============================================================================

set -e

# ── Cores e helpers ────────────────────────────────────────────────────────────
BOLD="\e[1m"
GREEN="\e[32m"
YELLOW="\e[33m"
CYAN="\e[36m"
RED="\e[31m"
RESET="\e[0m"

msg()  { echo -e "\n${CYAN}${BOLD}━━━ $1 ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"; }
ok()   { echo -e "${GREEN}${BOLD}  ✔  $1${RESET}"; }
warn() { echo -e "${YELLOW}${BOLD}  ⚠  $1${RESET}"; }
info() { echo -e "     $1"; }
err()  { echo -e "${RED}${BOLD}  ✘  $1${RESET}"; }

confirm() {
    read -n1 -rp "$(echo -e "${BOLD}  ➜  $1 (s/n): ${RESET}")" ans
    echo
    [[ "$ans" =~ ^[sSyY]$ ]]
}

header() {
    echo -e "\n${CYAN}${BOLD}"
    echo "  ╔══════════════════════════════════════════════╗"
    printf  "  ║  %-44s║\n" "$1"
    echo "  ╚══════════════════════════════════════════════╝"
    echo -e "${RESET}"
}

# ── Diretório raiz do repositório ─────────────────────────────────────────────
# Sempre o diretório onde este script está, independente de onde for chamado
REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# ==============================================================================
# FASE 0 — VERIFICAÇÕES INICIAIS
# ==============================================================================
header "FASE 0 — Verificações Iniciais"

# Não rodar como root
if [[ "$EUID" -eq 0 ]]; then
    err "Não execute este script como root. Use um usuário normal com sudo."
    exit 1
fi

# Sudo disponível
if ! sudo -v &>/dev/null; then
    err "Este usuário não tem privilégios sudo."
    exit 1
fi
ok "Privilégios sudo confirmados"

# Confirma que está dentro do repositório (arquivo sentinela)
if [[ ! -f "$REPO_DIR/arch-setup.sh" ]]; then
    err "Execute o script de dentro do repositório clonado."
    exit 1
fi
ok "Repositório detectado em: $REPO_DIR"

# Detecta wallpaper no repositório (aceita .jpg, .jpeg ou .png)
WALLPAPER_SRC=""
for ext in jpg jpeg png; do
    if [[ -f "$REPO_DIR/wallpaper.$ext" ]]; then
        WALLPAPER_SRC="$REPO_DIR/wallpaper.$ext"
        WALLPAPER_EXT="$ext"
        break
    fi
done

if [[ -n "$WALLPAPER_SRC" ]]; then
    ok "Wallpaper encontrado: wallpaper.$WALLPAPER_EXT"
else
    warn "Nenhum wallpaper encontrado no repositório."
    info "Coloque wallpaper.jpg (ou .jpeg/.png) na raiz do repositório."
    info "O fundo ficará preto até você adicionar um wallpaper manualmente."
fi

# ==============================================================================
# FASE 1 — PÓS-INSTALAÇÃO DO ARCH
# ==============================================================================
header "FASE 1 — Pós-instalação do Arch Linux"

# ── pacman.conf ───────────────────────────────────────────────────────────────
msg "Otimizando pacman.conf"
PACMAN_CONF="/etc/pacman.conf"
[[ ! -f "$PACMAN_CONF" ]] && { err "$PACMAN_CONF não encontrado."; exit 1; }

sudo sed -i 's/^#Color/Color/'                                       "$PACMAN_CONF"
sudo sed -i 's/^#ParallelDownloads = [0-9]*/ParallelDownloads = 15/' "$PACMAN_CONF"
sudo sed -i 's/^ParallelDownloads = [0-9]*/ParallelDownloads = 15/'  "$PACMAN_CONF"
grep -q "^ILoveCandy" "$PACMAN_CONF" || \
    sudo sed -i '/^ParallelDownloads = 15/a ILoveCandy'              "$PACMAN_CONF"
ok "pacman.conf: Color + ParallelDownloads = 15 + ILoveCandy"

# ── makepkg ───────────────────────────────────────────────────────────────────
msg "Configurando makepkg"
MAKEPKG_BIN="/usr/bin/makepkg"
[[ ! -f "$MAKEPKG_BIN" ]] && { err "$MAKEPKG_BIN não encontrado."; exit 1; }

sudo sed -i '/EUID/ { N; N; N; s/error/warning/; s/exit $E_ROOT/#exit $E_ROOT/; }' "$MAKEPKG_BIN"
ok "makepkg configurado"

# ── Atualizar sistema ─────────────────────────────────────────────────────────
msg "Atualizando sistema"
sudo pacman -Syu --noconfirm
ok "Sistema atualizado"

# ── git + base-devel ──────────────────────────────────────────────────────────
msg "Instalando git e ferramentas de build"
sudo pacman -S --needed --noconfirm git base-devel devtools
ok "git + base-devel instalados"

# ── Yay ───────────────────────────────────────────────────────────────────────
msg "Instalando Yay (AUR helper)"
if command -v yay &>/dev/null; then
    warn "yay já instalado, pulando."
else
    cd /tmp
    rm -rf yay
    git clone https://aur.archlinux.org/yay.git
    cd yay
    makepkg -si --noconfirm
    yay -Y --gendb
    # Volta para o repo após instalar o yay
    cd "$REPO_DIR"
    ok "yay instalado"
fi

# ── Pacotes via pacman ────────────────────────────────────────────────────────
msg "Instalando pacotes via pacman"
sudo pacman -S --needed --noconfirm \
    gufw \
    ffmpeg \
    gst-plugins-ugly gst-plugins-good gst-plugins-base \
    gst-plugins-bad gst-libav gstreamer \
    fwupd \
    ntfs-3g \
    gnome-disk-utility \
    rhythmbox \
    vlc \
    remmina \
    timeshift \
    steam \
    gimp \
    shotwell \
    audacity \
    easytag \
    flatpak
ok "Pacotes pacman instalados"

# ── Flatpak + Flathub ─────────────────────────────────────────────────────────
msg "Configurando Flatpak + Flathub"
flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo

info "Instalando aplicativos Flatpak..."
flatpak install --noninteractive flathub \
    com.sublimetext.three \
    com.visualstudio.code \
    com.bitwarden.desktop \
    org.mozilla.Thunderbird \
    com.discordapp.Discord \
    org.telegram.desktop \
    org.onlyoffice.desktopeditors \
    net.agalwood.Motrix \
    com.spotify.Client \
    io.appflowy.AppFlowy
ok "Aplicativos Flatpak instalados"

# ── Pacotes AUR ───────────────────────────────────────────────────────────────
msg "Instalando pacotes AUR via yay"
yay -S --needed --noconfirm \
    google-chrome \
    heroic-games-launcher-bin
ok "Pacotes AUR instalados"

# ── Bluetooth ─────────────────────────────────────────────────────────────────
msg "Ativando Bluetooth"
sudo systemctl enable --now bluetooth.service
ok "Bluetooth ativado"

# ── Wi-Fi Powersave ───────────────────────────────────────────────────────────
if confirm "Desabilitar Wi-Fi powersave (recomendado para estabilidade)?"; then
    WIFI_CONF="/etc/NetworkManager/conf.d/wifi-powersave.conf"
    printf "[connection]\nwifi.powersave = 2\n" | sudo tee "$WIFI_CONF" > /dev/null
    sudo systemctl restart NetworkManager
    sleep 2
    ok "Wi-Fi powersave desabilitado"
fi

# ==============================================================================
# FASE 2 — HYPRLAND + CONFIGURAÇÕES
# ==============================================================================
header "FASE 2 — Instalação e Configuração do Hyprland"

# ── Pacotes do Hyprland ───────────────────────────────────────────────────────
msg "Instalando pacotes do Hyprland"
yay -S --needed --noconfirm \
    hyprland kitty waybar \
    swaybg swaylock-effects wofi wlogout mako thunar \
    ttf-jetbrains-mono-nerd noto-fonts-emoji \
    polkit-gnome python-requests starship \
    swappy grim slurp pamixer brightnessctl gvfs \
    bluez bluez-utils lxappearance xfce4-settings \
    dracula-gtk-theme dracula-icons-git \
    xdg-desktop-portal-hyprland

msg "Removendo portais XDG conflitantes"
yay -R --noconfirm xdg-desktop-portal-gnome xdg-desktop-portal-gtk 2>/dev/null || true
ok "Pacotes do Hyprland instalados"

# ── Diretórios ────────────────────────────────────────────────────────────────
msg "Criando diretórios de configuração"
mkdir -p ~/.config/hypr
mkdir -p ~/.config/kitty
mkdir -p ~/.config/waybar/scripts
mkdir -p ~/.config/mako
mkdir -p ~/.config/swaylock
mkdir -p ~/.config/wofi
mkdir -p ~/.config/gtk-3.0
ok "Diretórios criados"

# ── Wallpaper ─────────────────────────────────────────────────────────────────
msg "Copiando wallpaper"
if [[ -n "$WALLPAPER_SRC" ]]; then
    cp "$WALLPAPER_SRC" ~/.config/hypr/wallpaper.$WALLPAPER_EXT
    # Normaliza sempre para wallpaper.jpg no hyprland.conf (independente da extensão)
    WALLPAPER_DEST="~/.config/hypr/wallpaper.$WALLPAPER_EXT"
    ok "Wallpaper copiado para ~/.config/hypr/wallpaper.$WALLPAPER_EXT"
else
    WALLPAPER_DEST="~/.config/hypr/wallpaper.jpg"
    warn "Sem wallpaper — edite a linha 'exec = swaybg ...' no hyprland.conf depois."
fi

# ── hyprland.conf ─────────────────────────────────────────────────────────────
msg "Escrevendo hyprland.conf"
cat > ~/.config/hypr/hyprland.conf << EOF
# Monitores — modo automático
# Exemplo dual monitor: monitor=DP-1,2560x1440@165,0x0,1
monitor=,preferred,auto,auto

autogenerated = 0

# Autostart
exec-once = ~/.config/hypr/xdg-portal-hyprland
exec-once = dbus-update-activation-environment --systemd WAYLAND_DISPLAY XDG_CURRENT_DESKTOP
exec-once = systemctl --user import-environment WAYLAND_DISPLAY XDG_CURRENT_DESKTOP
exec-once = /usr/lib/polkit-gnome/polkit-gnome-authentication-agent-1
exec-once = waybar
exec-once = mako
exec       = swaybg -m fill -i $WALLPAPER_DEST

input {
    kb_layout    = br
    kb_variant   =
    kb_model     =
    kb_options   =
    kb_rules     =
    follow_mouse = 1
    sensitivity  = 0

    touchpad {
        natural_scroll = yes
    }
}

general {
    gaps_in             = 5
    gaps_out            = 20
    border_size         = 2
    col.active_border   = rgb(cdd6f4)
    col.inactive_border = rgba(595959aa)
    layout              = dwindle
}

misc {
    disable_hyprland_logo = yes
}

decoration {
    rounding = 10

    blur {
        enabled = true
        size    = 7
        passes  = 3
    }

    drop_shadow         = yes
    shadow_range        = 4
    shadow_render_power = 3
    col.shadow          = rgba(1a1a1aee)
}

animations {
    enabled = yes
    bezier  = myBezier, 0.05, 0.9, 0.1, 1.05

    animation = windows,    1, 7, myBezier
    animation = windowsOut, 1, 7, default, popin 80%
    animation = border,     1, 10, default
    animation = fade,       1, 7, default
    animation = workspaces, 1, 6, default
}

dwindle {
    pseudotile     = yes
    preserve_split = yes
}

master {
    new_is_master = true
}

gestures {
    workspace_swipe = on
}

# Transparência
windowrulev2 = opacity 0.8 0.8, class:^(kitty)$
windowrulev2 = opacity 0.8 0.8, class:^(thunar)$

# ─── Atalhos ──────────────────────────────────────────────────────────────────
\$mainMod = SUPER

bind = \$mainMod,       Q,     exec,           kitty
bind = \$mainMod SHIFT, X,     killactive,
bind = \$mainMod,       L,     exec,           swaylock
bind = \$mainMod,       M,     exec,           wlogout --protocol layer-shell
bind = \$mainMod SHIFT, M,     exit,
bind = \$mainMod,       E,     exec,           thunar
bind = \$mainMod,       V,     togglefloating,
bind = \$mainMod,       SPACE, exec,           wofi --show drun
bind = \$mainMod,       P,     pseudo,
bind = \$mainMod,       J,     togglesplit,
bind = \$mainMod,       S,     exec,           grim -g "\$(slurp)" - | swappy -f -

# Volume
bind = , XF86AudioMute,        exec, pamixer -t
bind = , XF86AudioLowerVolume, exec, pamixer -d 5
bind = , XF86AudioRaiseVolume, exec, pamixer -i 5
bind = , XF86AudioMicMute,     exec, pamixer --default-source -t

# Brilho
bind = , XF86MonBrightnessDown, exec, brightnessctl set 10%-
bind = , XF86MonBrightnessUp,   exec, brightnessctl set 10%+

# Foco
bind = \$mainMod, left,  movefocus, l
bind = \$mainMod, right, movefocus, r
bind = \$mainMod, up,    movefocus, u
bind = \$mainMod, down,  movefocus, d

# Workspaces
bind = \$mainMod, 1, workspace, 1
bind = \$mainMod, 2, workspace, 2
bind = \$mainMod, 3, workspace, 3
bind = \$mainMod, 4, workspace, 4
bind = \$mainMod, 5, workspace, 5
bind = \$mainMod, 6, workspace, 6
bind = \$mainMod, 7, workspace, 7
bind = \$mainMod, 8, workspace, 8
bind = \$mainMod, 9, workspace, 9
bind = \$mainMod, 0, workspace, 10

bind = \$mainMod SHIFT, 1, movetoworkspace, 1
bind = \$mainMod SHIFT, 2, movetoworkspace, 2
bind = \$mainMod SHIFT, 3, movetoworkspace, 3
bind = \$mainMod SHIFT, 4, movetoworkspace, 4
bind = \$mainMod SHIFT, 5, movetoworkspace, 5
bind = \$mainMod SHIFT, 6, movetoworkspace, 6
bind = \$mainMod SHIFT, 7, movetoworkspace, 7
bind = \$mainMod SHIFT, 8, movetoworkspace, 8
bind = \$mainMod SHIFT, 9, movetoworkspace, 9
bind = \$mainMod SHIFT, 0, movetoworkspace, 10

bind  = \$mainMod, mouse_down, workspace, e+1
bind  = \$mainMod, mouse_up,   workspace, e-1
bindm = \$mainMod, mouse:272,  movewindow
bindm = \$mainMod, mouse:273,  resizewindow
EOF
ok "hyprland.conf escrito"

# ── xdg-portal-hyprland ───────────────────────────────────────────────────────
msg "Escrevendo xdg-portal-hyprland"
cat > ~/.config/hypr/xdg-portal-hyprland << 'EOF'
#!/bin/bash
sleep 1
killall xdg-desktop-portal-hyprland 2>/dev/null || true
killall xdg-desktop-portal-wlr      2>/dev/null || true
killall xdg-desktop-portal          2>/dev/null || true
/usr/lib/xdg-desktop-portal-hyprland &
sleep 2
/usr/lib/xdg-desktop-portal &
EOF
chmod +x ~/.config/hypr/xdg-portal-hyprland
ok "xdg-portal-hyprland escrito"

# ── Kitty ─────────────────────────────────────────────────────────────────────
msg "Configurando Kitty"
cat > ~/.config/kitty/kitty.conf << 'EOF'
include ./mocha.conf
font_family      JetBrainsMono Nerd Font
font_size        15.0
bold_font        auto
italic_font      auto
bold_italic_font auto
mouse_hide_wait  2.0
cursor_shape     block
url_color        #0087bd
url_style        dotted
confirm_os_window_close 0
background_opacity 0.95
EOF

cat > ~/.config/kitty/mocha.conf << 'EOF'
# Catppuccin Mocha
foreground              #CDD6F4
background              #1E1E2E
selection_foreground    #1E1E2E
selection_background    #F5E0DC
cursor                  #F5E0DC
cursor_text_color       #1E1E2E
url_color               #F5E0DC
active_border_color     #B4BEFE
inactive_border_color   #6C7086
bell_border_color       #F9E2AF
wayland_titlebar_color  system
macos_titlebar_color    system
active_tab_foreground   #11111B
active_tab_background   #CBA6F7
inactive_tab_foreground #CDD6F4
inactive_tab_background #181825
tab_bar_background      #11111B
mark1_foreground #1E1E2E
mark1_background #B4BEFE
mark2_foreground #1E1E2E
mark2_background #CBA6F7
mark3_foreground #1E1E2E
mark3_background #74C7EC
color0  #45475A
color8  #585B70
color1  #F38BA8
color9  #F38BA8
color2  #A6E3A1
color10 #A6E3A1
color3  #F9E2AF
color11 #F9E2AF
color4  #89B4FA
color12 #89B4FA
color5  #F5C2E7
color13 #F5C2E7
color6  #94E2D5
color14 #94E2D5
color7  #BAC2DE
color15 #A6ADC8
EOF
ok "Kitty configurado"

# ── Waybar config ─────────────────────────────────────────────────────────────
msg "Configurando Waybar"
cat > ~/.config/waybar/config.jsonc << 'EOF'
{
    "layer": "top",
    "position": "top",
    "mod": "dock",
    "exclusive": true,
    "passthrough": false,
    "gtk-layer-shell": true,
    "height": 50,
    "modules-left":   ["clock", "custom/weather", "hyprland/workspaces"],
    "modules-center": ["hyprland/window"],
    "modules-right":  ["network", "bluetooth", "temperature", "battery", "backlight", "pulseaudio", "pulseaudio#microphone", "tray"],

    "hyprland/window": { "format": "{}" },

    "hyprland/workspaces": {
        "disable-scroll": true,
        "all-outputs": true,
        "on-click": "activate",
        "persistent-workspaces": {
            "1": [], "2": [], "3": [], "4": [], "5": [],
            "6": [], "7": [], "8": [], "9": [], "10": []
        }
    },

    "custom/weather": {
        "tooltip":     true,
        "format":      "{}",
        "interval":    30,
        "exec":        "~/.config/waybar/scripts/waybar-wttr.py",
        "return-type": "json"
    },

    "tray": { "icon-size": 18, "spacing": 10 },

    "clock": {
        "format":         "{: %H:%M   %a, %d/%m}",
        "tooltip-format": "<big>{:%Y %B}</big>\n<tt><small>{calendar}</small></tt>"
    },

    "backlight": {
        "device":         "intel_backlight",
        "format":         "{icon} {percent}%",
        "format-icons":   ["󰃞", "󰃟", "󰃠"],
        "on-scroll-up":   "brightnessctl set 1%+",
        "on-scroll-down": "brightnessctl set 1%-",
        "min-length":     6
    },

    "battery": {
        "states":          { "good": 95, "warning": 30, "critical": 20 },
        "format":          "{icon} {capacity}%",
        "format-charging": " {capacity}%",
        "format-plugged":  " {capacity}%",
        "format-alt":      "{time} {icon}",
        "format-icons":    ["󰂎","󰁺","󰁻","󰁼","󰁽","󰁾","󰁿","󰂀","󰂁","󰂂","󰁹"]
    },

    "pulseaudio": {
        "format":        "{icon} {volume}%",
        "tooltip":       false,
        "format-muted":  " Mudo",
        "on-click":      "pamixer -t",
        "on-scroll-up":  "pamixer -i 5",
        "on-scroll-down":"pamixer -d 5",
        "scroll-step":   5,
        "format-icons": {
            "headphone": "", "hands-free": "", "headset": "",
            "phone": "", "portable": "", "car": "",
            "default": ["", "", ""]
        }
    },

    "pulseaudio#microphone": {
        "format":              "{format_source}",
        "format-source":       " {volume}%",
        "format-source-muted": " Mudo",
        "on-click":            "pamixer --default-source -t",
        "on-scroll-up":        "pamixer --default-source -i 5",
        "on-scroll-down":      "pamixer --default-source -d 5",
        "scroll-step": 5
    },

    "temperature": {
        "thermal-zone":       1,
        "format":             "{temperatureC}°C ",
        "critical-threshold": 80,
        "format-critical":    "{temperatureC}°C "
    },

    "network": {
        "format-wifi":         "  {signalStrength}%",
        "format-ethernet":     "{ipaddr}/{cidr}",
        "tooltip-format":      "{essid} - {ifname} via {gwaddr}",
        "format-linked":       "{ifname} (Sem IP)",
        "format-disconnected": "Desconectado ⚠",
        "format-alt":          "{ifname}:{essid} {ipaddr}/{cidr}"
    },

    "bluetooth": {
        "format":                             " {status}",
        "format-disabled":                    "",
        "format-connected":                   " {num_connections}",
        "tooltip-format":                     "{device_alias}",
        "tooltip-format-connected":           " {device_enumerate}",
        "tooltip-format-enumerate-connected": "{device_alias}"
    }
}
EOF

cat > ~/.config/waybar/style.css << 'EOF'
* {
    border: none;
    border-radius: 0;
    font-family: "JetBrainsMono Nerd Font";
    font-weight: bold;
    font-size: 16px;
    min-height: 0;
}
window#waybar {
    background: rgba(21, 18, 27, 0);
    color: #cdd6f4;
}
tooltip {
    background: #1e1e2e;
    border-radius: 10px;
    border-width: 2px;
    border-style: solid;
    border-color: #11111b;
}
#workspaces button             { padding: 5px; color: #313244; margin-right: 5px; }
#workspaces button.active      { color: #a6adc8; }
#workspaces button.focused     { color: #a6adc8; background: #eba0ac; border-radius: 10px; }
#workspaces button.urgent      { color: #11111b; background: #a6e3a1; border-radius: 10px; }
#workspaces button:hover       { background: #11111b; color: #cdd6f4; border-radius: 10px; }
#custom-weather, #window, #clock, #battery, #pulseaudio,
#network, #bluetooth, #temperature, #workspaces, #tray, #backlight {
    background: #1e1e2e;
    opacity: 0.8;
    padding: 0px 10px;
    margin: 3px 0px;
    margin-top: 10px;
    border: 1px solid #181825;
}
#temperature           { border-radius: 10px 0px 0px 10px; }
#temperature.critical  { color: #eba0ac; }
#backlight             { border-radius: 10px 0px 0px 10px; }
#tray                  { border-radius: 10px; margin-right: 10px; }
#workspaces            { background: #1e1e2e; border-radius: 10px; margin-left: 10px; padding-right: 0px; padding-left: 5px; }
#window                { border-radius: 10px; margin-left: 60px; margin-right: 60px; }
#clock                 { color: #fab387; border-radius: 10px 0px 0px 10px; margin-left: 10px; border-right: 0px; }
#network               { color: #f9e2af; border-radius: 10px 0px 0px 10px; border-left: 0px; border-right: 0px; }
#bluetooth             { color: #89b4fa; border-radius: 0px 10px 10px 0px; margin-right: 10px; }
#pulseaudio            { color: #89b4fa; border-left: 0px; border-right: 0px; }
#pulseaudio.microphone { color: #cba6f7; border-left: 0px; border-right: 0px; border-radius: 0px 10px 10px 0px; margin-right: 10px; }
#battery               { color: #a6e3a1; border-radius: 0 10px 10px 0; margin-right: 10px; border-left: 0px; }
#custom-weather        { border-radius: 0px 10px 10px 0px; border-right: 0px; margin-left: 0px; }
EOF
ok "Waybar configurado"

# ── Script de clima ───────────────────────────────────────────────────────────
msg "Escrevendo script de clima (°C)"
cat > ~/.config/waybar/scripts/waybar-wttr.py << 'EOF'
#!/usr/bin/env python3

import json
import requests
from datetime import datetime

WEATHER_CODES = {
    '113': '☀️ ', '116': '⛅ ', '119': '☁️ ', '122': '☁️ ',
    '143': '☁️ ', '176': '🌧️', '179': '🌧️', '182': '🌧️',
    '185': '🌧️', '200': '⛈️ ', '227': '🌨️', '230': '🌨️',
    '248': '☁️ ', '260': '☁️ ', '263': '🌧️', '266': '🌧️',
    '281': '🌧️', '284': '🌧️', '293': '🌧️', '296': '🌧️',
    '299': '🌧️', '302': '🌧️', '305': '🌧️', '308': '🌧️',
    '311': '🌧️', '314': '🌧️', '317': '🌧️', '320': '🌨️',
    '323': '🌨️', '326': '🌨️', '329': '❄️ ', '332': '❄️ ',
    '335': '❄️ ', '338': '❄️ ', '350': '🌧️', '353': '🌧️',
    '356': '🌧️', '359': '🌧️', '362': '🌧️', '365': '🌧️',
    '368': '🌧️', '371': '❄️ ', '374': '🌨️', '377': '🌨️',
    '386': '🌨️', '389': '🌨️', '392': '🌧️', '395': '❄️ '
}

def format_time(time):
    return time.replace("00", "").zfill(2)

def format_chances(hour):
    chances = {
        "chanceoffog":      "Névoa",
        "chanceoffrost":    "Geada",
        "chanceofovercast": "Nublado",
        "chanceofrain":     "Chuva",
        "chanceofsnow":     "Neve",
        "chanceofsunshine": "Sol",
        "chanceofthunder":  "Trovoada",
        "chanceofwindy":    "Vento"
    }
    conditions = []
    for event, label in chances.items():
        if int(hour.get(event, 0)) > 0:
            conditions.append(f"{label} {hour[event]}%")
    return ", ".join(conditions)

try:
    weather  = requests.get("https://wttr.in/?format=j1", timeout=10).json()
    current  = weather['current_condition'][0]
    temp_c   = current['FeelsLikeC']
    temp_dis = current['temp_C']
    icon     = WEATHER_CODES.get(current['weatherCode'], '?')

    data = {}
    data['text'] = f" {icon} {temp_c}°C"

    desc = current['weatherDesc'][0]['value']
    data['tooltip']  = f"<b>{desc} {temp_dis}°C</b>\n"
    data['tooltip'] += f"Sensação: {temp_c}°C\n"
    data['tooltip'] += f"Vento: {current['windspeedKmph']} km/h\n"
    data['tooltip'] += f"Umidade: {current['humidity']}%\n"

    for i, day in enumerate(weather['weather']):
        data['tooltip'] += "\n<b>"
        if i == 0:   data['tooltip'] += "Hoje, "
        elif i == 1: data['tooltip'] += "Amanhã, "
        data['tooltip'] += f"{day['date']}</b>\n"
        data['tooltip'] += f"⬆️ {day['maxtempC']}°C  ⬇️ {day['mintempC']}°C  "
        data['tooltip'] += f"🌅 {day['astronomy'][0]['sunrise']}  🌇 {day['astronomy'][0]['sunset']}\n"
        for hour in day['hourly']:
            if i == 0 and int(format_time(hour['time'])) < datetime.now().hour - 2:
                continue
            h_icon    = WEATHER_CODES.get(hour['weatherCode'], '?')
            h_temp    = hour['FeelsLikeC'].ljust(3)
            h_desc    = hour['weatherDesc'][0]['value']
            h_chances = format_chances(hour)
            data['tooltip'] += f"{format_time(hour['time'])}h {h_icon} {h_temp}°C {h_desc}"
            if h_chances:
                data['tooltip'] += f", {h_chances}"
            data['tooltip'] += "\n"

    print(json.dumps(data))

except Exception as e:
    print(json.dumps({"text": "⚠️ clima", "tooltip": str(e)}))
EOF
chmod +x ~/.config/waybar/scripts/waybar-wttr.py
ok "Script de clima escrito (°C)"

# ── Swaylock ──────────────────────────────────────────────────────────────────
msg "Configurando Swaylock"
cat > ~/.config/swaylock/config << 'EOF'
daemonize
show-failed-attempts
clock
screenshot
effect-blur=9x5
effect-vignette=0.5:0.5
color=1f1d2e80
font="JetBrainsMono Nerd Font"
indicator
indicator-radius=200
indicator-thickness=20
line-color=1f1d2e
ring-color=191724
inside-color=1f1d2e
key-hl-color=eb6f92
separator-color=00000000
text-color=e0def4
text-caps-lock-color=""
line-ver-color=eb6f92
ring-ver-color=eb6f92
inside-ver-color=1f1d2e
text-ver-color=e0def4
ring-wrong-color=31748f
text-wrong-color=31748f
inside-wrong-color=1f1d2e
inside-clear-color=1f1d2e
text-clear-color=e0def4
ring-clear-color=9ccfd8
line-clear-color=1f1d2e
line-wrong-color=1f1d2e
bs-hl-color=31748f
grace=2
grace-no-mouse
grace-no-touch
datestr=%a, %d de %B
timestr=%H:%M
fade-in=0.2
ignore-empty-password
EOF
ok "Swaylock configurado"

# ── Mako ──────────────────────────────────────────────────────────────────────
msg "Configurando Mako (notificações)"
cat > ~/.config/mako/config << 'EOF'
background-color=#1e1e2e
text-color=#cdd6f4
border-color=#313244
border-radius=10
border-size=2
font=JetBrainsMono Nerd Font 12
padding=10
margin=10
width=350
height=150
layer=overlay
anchor=top-right
EOF
ok "Mako configurado"

# ── Starship ──────────────────────────────────────────────────────────────────
if confirm "Configurar o Starship (prompt customizado)?"; then
    cat > ~/.config/starship.toml << 'EOF'
format = """
[░▒▓](#a3aed2)\
[  ](bg:#a3aed2 fg:#090c0c)\
[](bg:#769ff0 fg:#a3aed2)\
$directory\
[](fg:#769ff0 bg:#394260)\
$git_branch\
$git_status\
[](fg:#394260 bg:#212736)\
$nodejs\
$rust\
$golang\
$php\
[](fg:#212736 bg:#1d2230)\
$time\
[ ](fg:#1d2230)\
\n$character"""

[directory]
style = "fg:#e3e5e5 bg:#769ff0"
format = "[ $path ]($style)"
truncation_length = 3
truncation_symbol = "…/"

[directory.substitutions]
"Documentos" = " "
"Downloads"  = " "
"Música"     = " "
"Imagens"    = " "

[git_branch]
symbol = ""
style  = "bg:#394260"
format = '[[ $symbol $branch ](fg:#769ff0 bg:#394260)]($style)'

[git_status]
style  = "bg:#394260"
format = '[[($all_status$ahead_behind )](fg:#769ff0 bg:#394260)]($style)'

[nodejs]
symbol = ""
style  = "bg:#212736"
format = '[[ $symbol ($version) ](fg:#769ff0 bg:#212736)]($style)'

[rust]
symbol = ""
style  = "bg:#212736"
format = '[[ $symbol ($version) ](fg:#769ff0 bg:#212736)]($style)'

[golang]
symbol = "ﳑ"
style  = "bg:#212736"
format = '[[ $symbol ($version) ](fg:#769ff0 bg:#212736)]($style)'

[php]
symbol = ""
style  = "bg:#212736"
format = '[[ $symbol ($version) ](fg:#769ff0 bg:#212736)]($style)'

[time]
disabled    = false
time_format = "%H:%M"
style       = "bg:#1d2230"
format      = '[[  $time ](fg:#a0a9cb bg:#1d2230)]($style)'
EOF

    grep -q "starship init" ~/.bashrc || \
        echo -e '\neval "$(starship init bash)"' >> ~/.bashrc
    ok "Starship configurado"
fi

# ==============================================================================
# FASE 3 — PÓS-CONFIGURAÇÃO
# ==============================================================================
header "FASE 3 — Pós-configuração"

# ── Tema escuro GTK ───────────────────────────────────────────────────────────
msg "Aplicando tema escuro GTK"
gsettings set org.gnome.desktop.interface color-scheme 'prefer-dark'
gsettings set org.gnome.desktop.interface gtk-theme    'Adwaita-dark'

GTK3_SETTINGS="$HOME/.config/gtk-3.0/settings.ini"
if ! grep -q "gtk-application-prefer-dark-theme" "$GTK3_SETTINGS" 2>/dev/null; then
    printf "[Settings]\ngtk-application-prefer-dark-theme=1\n" >> "$GTK3_SETTINGS"
else
    sed -i 's/gtk-application-prefer-dark-theme=0/gtk-application-prefer-dark-theme=1/' "$GTK3_SETTINGS"
fi
ok "Tema escuro GTK aplicado"

# ── Chromium: flags Wayland + PipeWire ────────────────────────────────────────
msg "Otimizando Chromium para Wayland e PipeWire"
CHROMIUM_FLAGS="$HOME/.config/chromium-flags.conf"
touch "$CHROMIUM_FLAGS"
grep -qF -- "--ozone-platform-hint=auto"               "$CHROMIUM_FLAGS" || \
    echo "--ozone-platform-hint=auto"               >> "$CHROMIUM_FLAGS"
grep -qF -- "--enable-features=WebRTCPipeWireCapturer" "$CHROMIUM_FLAGS" || \
    echo "--enable-features=WebRTCPipeWireCapturer" >> "$CHROMIUM_FLAGS"
ok "Flags do Chromium configuradas"

# ==============================================================================
# CONCLUSÃO
# ==============================================================================
echo -e "\n${GREEN}${BOLD}"
echo "  ╔══════════════════════════════════════════════╗"
echo "  ║         ✔  Setup concluído!                  ║"
echo "  ╠══════════════════════════════════════════════╣"
echo "  ║  Fase 1: Arch pós-instalação    ✔            ║"
echo "  ║  Fase 2: Hyprland + configs     ✔            ║"
echo "  ║  Fase 3: Pós-configuração       ✔            ║"
echo "  ╚══════════════════════════════════════════════╝"
echo -e "${RESET}"
warn "Faça logout e login (ou reinicie) para aplicar todas as mudanças GTK."
echo ""

if confirm "Iniciar o Hyprland agora?"; then
    exec Hyprland
fi
