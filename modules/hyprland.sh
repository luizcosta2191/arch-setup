#!/usr/bin/env bash
# módulo: hyprland — compositor Wayland + barra + dock + launcher + terminal

install_hyprland() {
    section "Hyprland + Waybar + Dock"

    # Hyprland e utilitários Wayland
    info "Instalando Hyprland..."
    sudo pacman -S --needed --noconfirm \
        hyprland hypridle hyprlock hyprpaper \
        xorg-xwayland \
        2>>"$LOG_FILE"
    log "Hyprland instalado"

    # Waybar (barra superior)
    info "Instalando Waybar..."
    sudo pacman -S --needed --noconfirm \
        waybar \
        2>>"$LOG_FILE"
    log "Waybar instalado"

    # nwg-dock (dock inferior)
    info "Instalando nwg-dock..."
    yay -S --needed --noconfirm nwg-dock-hyprland 2>>"$LOG_FILE"
    log "nwg-dock instalado"

    # Rofi (launcher)
    info "Instalando Rofi..."
    yay -S --needed --noconfirm rofi-lbonn-wayland-git 2>>"$LOG_FILE"
    log "Rofi instalado"

    # Kitty (terminal)
    info "Instalando Kitty..."
    sudo pacman -S --needed --noconfirm kitty 2>>"$LOG_FILE"
    log "Kitty instalado"

    # Dunst (notificações)
    info "Instalando Dunst..."
    sudo pacman -S --needed --noconfirm dunst libnotify 2>>"$LOG_FILE"
    log "Dunst instalado"

    # Thunar (explorador de arquivos)
    sudo pacman -S --needed --noconfirm \
        thunar thunar-archive-plugin thunar-volman \
        gvfs gvfs-mtp tumbler \
        file-roller \
        2>>"$LOG_FILE"
    log "Thunar instalado"

    # Imagem de fundo padrão
    mkdir -p "$HOME/.config/hypr"
    if [[ ! -f "$HOME/.config/hypr/wallpaper.jpg" ]]; then
        info "Baixando wallpaper padrão..."
        wget -qO "$HOME/.config/hypr/wallpaper.jpg" \
            "https://raw.githubusercontent.com/catppuccin/wallpapers/main/minimalistic/catppuccin-triangles.png" \
            2>>"$LOG_FILE" || warn "Não foi possível baixar o wallpaper — use um manualmente"
    fi

    log "Hyprland stack completo!"
}
