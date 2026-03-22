#!/usr/bin/env bash
# módulo: fonts — Nerd Fonts, emoji, Microsoft core fonts

install_fonts() {
    section "Fontes"

    # Nerd Fonts (ícones para waybar/terminal)
    info "Instalando Nerd Fonts..."
    yay -S --needed --noconfirm \
        ttf-jetbrains-mono-nerd \
        ttf-firacode-nerd \
        ttf-nerd-fonts-symbols \
        2>>"$LOG_FILE"

    # Fontes do sistema
    info "Fontes do sistema..."
    sudo pacman -S --needed --noconfirm \
        noto-fonts \
        noto-fonts-cjk \
        noto-fonts-emoji \
        ttf-liberation \
        ttf-dejavu \
        2>>"$LOG_FILE"

    # Microsoft core fonts (compatibilidade com documentos)
    info "Microsoft core fonts..."
    yay -S --needed --noconfirm ttf-ms-fonts 2>>"$LOG_FILE" || \
        warn "Microsoft fonts não instaladas (AUR temporariamente indisponível)"

    # Atualiza cache de fontes
    fc-cache -f 2>>"$LOG_FILE"
    log "Fontes instaladas e cache atualizado"
}
