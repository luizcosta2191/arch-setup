#!/usr/bin/env bash
# módulo: base — yay, pipewire, bluetooth, xdg, serviços essenciais

install_base() {
    section "Base do sistema"

    # Atualiza sistema
    info "Atualizando sistema..."
    sudo pacman -Syu --noconfirm 2>>"$LOG_FILE"
    log "Sistema atualizado"

    # Dependências de build
    info "Instalando dependências de build..."
    sudo pacman -S --needed --noconfirm \
        base-devel git wget curl unzip zip \
        2>>"$LOG_FILE"

    # yay (AUR helper)
    if ! command -v yay &>/dev/null; then
        info "Instalando yay (AUR helper)..."
        local tmp=$(mktemp -d)
        git clone https://aur.archlinux.org/yay-bin.git "$tmp/yay" 2>>"$LOG_FILE"
        (cd "$tmp/yay" && makepkg -si --noconfirm 2>>"$LOG_FILE")
        rm -rf "$tmp"
        log "yay instalado"
    else
        log "yay já instalado — pulando"
    fi

    # PipeWire (áudio)
    section "Áudio (PipeWire)"
    sudo pacman -S --needed --noconfirm \
        pipewire pipewire-alsa pipewire-pulse pipewire-jack \
        wireplumber pavucontrol \
        2>>"$LOG_FILE"
    systemctl --user enable --now pipewire pipewire-pulse wireplumber 2>>"$LOG_FILE" || true
    log "PipeWire configurado"

    # Bluetooth
    section "Bluetooth"
    sudo pacman -S --needed --noconfirm \
        bluez bluez-utils blueman \
        2>>"$LOG_FILE"
    sudo systemctl enable --now bluetooth 2>>"$LOG_FILE"
    log "Bluetooth ativado"

    # NetworkManager
    if ! systemctl is-enabled NetworkManager &>/dev/null; then
        sudo pacman -S --needed --noconfirm networkmanager nm-connection-editor 2>>"$LOG_FILE"
        sudo systemctl enable --now NetworkManager 2>>"$LOG_FILE"
        log "NetworkManager ativado"
    else
        log "NetworkManager já ativo — pulando"
    fi

    # Utilitários essenciais
    info "Instalando utilitários essenciais..."
    sudo pacman -S --needed --noconfirm \
        brightnessctl playerctl \
        grim slurp swappy wl-clipboard \
        polkit-kde-agent \
        xdg-utils xdg-user-dirs xdg-desktop-portal \
        xdg-desktop-portal-hyprland \
        qt5-wayland qt6-wayland \
        gnome-keyring libsecret \
        man-db man-pages \
        htop btop tree jq ripgrep fd bat \
        p7zip unrar \
        2>>"$LOG_FILE"

    # Cria diretórios XDG do usuário
    xdg-user-dirs-update 2>>"$LOG_FILE" || true
    log "Utilitários instalados"

    # SDDM (gerenciador de login)
    section "Display Manager (SDDM)"
    sudo pacman -S --needed --noconfirm sddm 2>>"$LOG_FILE"
    sudo systemctl enable sddm 2>>"$LOG_FILE"
    log "SDDM ativado"
}
