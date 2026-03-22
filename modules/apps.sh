#!/usr/bin/env bash
# módulo: apps — aplicativos essenciais para uso diário

install_apps() {
    section "Aplicativos essenciais"

    # Navegador
    info "Firefox..."
    sudo pacman -S --needed --noconfirm firefox 2>>"$LOG_FILE"

    # Editor de texto
    info "Editores de texto..."
    sudo pacman -S --needed --noconfirm \
        gedit \
        neovim \
        2>>"$LOG_FILE"

    # Multimídia
    info "Multimídia..."
    sudo pacman -S --needed --noconfirm \
        vlc \
        mpv \
        eog \
        2>>"$LOG_FILE"

    # Imagem
    info "Edição de imagem..."
    sudo pacman -S --needed --noconfirm \
        gimp \
        inkscape \
        2>>"$LOG_FILE"

    # Comunicação
    info "Comunicação..."
    yay -S --needed --noconfirm \
        discord \
        2>>"$LOG_FILE"

    # Utilitários de sistema
    info "Utilitários..."
    sudo pacman -S --needed --noconfirm \
        baobab \
        gnome-calculator \
        qbittorrent \
        2>>"$LOG_FILE"

    # Codecs e suporte a formatos
    info "Codecs..."
    sudo pacman -S --needed --noconfirm \
        ffmpeg \
        gst-plugins-good gst-plugins-bad gst-plugins-ugly \
        gst-libav \
        2>>"$LOG_FILE"

    log "Aplicativos instalados"
}
