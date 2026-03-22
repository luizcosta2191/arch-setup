#!/usr/bin/env bash
# módulo: gaming — Steam, Proton, MangoHud, GameMode, Lutris

install_gaming() {
    section "Gaming"

    # Steam (requer multilib habilitado)
    if ! grep -q '^\[multilib\]' /etc/pacman.conf; then
        warn "multilib não está habilitado em /etc/pacman.conf"
        info "Habilitando multilib..."
        sudo sed -i '/^#\[multilib\]/{N;s/#\[multilib\]\n#Include/\[multilib\]\nInclude/}' /etc/pacman.conf
        sudo pacman -Sy --noconfirm 2>>"$LOG_FILE"
    fi

    info "Instalando Steam..."
    sudo pacman -S --needed --noconfirm \
        steam \
        lib32-mesa \
        lib32-vulkan-icd-loader \
        2>>"$LOG_FILE"

    # Driver Vulkan (detecta GPU)
    info "Drivers Vulkan..."
    if lspci | grep -qi nvidia; then
        sudo pacman -S --needed --noconfirm \
            nvidia nvidia-utils lib32-nvidia-utils \
            2>>"$LOG_FILE"
        log "NVIDIA: drivers instalados"
    elif lspci | grep -qi amd; then
        sudo pacman -S --needed --noconfirm \
            mesa vulkan-radeon lib32-vulkan-radeon \
            2>>"$LOG_FILE"
        log "AMD: mesa + vulkan-radeon instalados"
    else
        sudo pacman -S --needed --noconfirm \
            mesa vulkan-intel lib32-mesa \
            2>>"$LOG_FILE"
        log "Intel: mesa + vulkan-intel instalados"
    fi

    # MangoHud (overlay de performance)
    info "MangoHud..."
    sudo pacman -S --needed --noconfirm mangohud lib32-mangohud 2>>"$LOG_FILE"

    # GameMode (otimiza CPU/GPU durante jogos)
    info "GameMode..."
    sudo pacman -S --needed --noconfirm gamemode lib32-gamemode 2>>"$LOG_FILE"
    systemctl --user enable --now gamemoded 2>>"$LOG_FILE" || true

    # Lutris (gerenciador de jogos)
    info "Lutris..."
    sudo pacman -S --needed --noconfirm \
        lutris \
        wine-staging \
        winetricks \
        2>>"$LOG_FILE"

    # Proton-GE (melhor compatibilidade Steam)
    info "ProtonUp-Qt (gerencia versões Proton)..."
    yay -S --needed --noconfirm protonup-qt 2>>"$LOG_FILE"

    log "Stack gaming instalado"
    warn "Configure o Proton no Steam: Configurações → Steam Play → Habilitar para todos os jogos"
}
