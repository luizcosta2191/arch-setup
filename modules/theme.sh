#!/usr/bin/env bash
# módulo: theme — Catppuccin Mocha GTK + Papirus icons

install_theme() {
    section "Tema Catppuccin Mocha"

    # Catppuccin GTK
    info "Instalando tema GTK Catppuccin Mocha..."
    yay -S --needed --noconfirm \
        catppuccin-gtk-theme-mocha \
        2>>"$LOG_FILE" || {
        # fallback: instala manualmente
        warn "AUR indisponível, instalando manualmente..."
        local tmp=$(mktemp -d)
        wget -qO "$tmp/catppuccin.zip" \
            "https://github.com/catppuccin/gtk/releases/download/v1.0.3/catppuccin-mocha-blue-standard+default.zip" \
            2>>"$LOG_FILE"
        mkdir -p "$HOME/.themes"
        unzip -q "$tmp/catppuccin.zip" -d "$HOME/.themes/" 2>>"$LOG_FILE"
        rm -rf "$tmp"
    }

    # Papirus icons (melhor compatível com Catppuccin)
    info "Instalando Papirus icons..."
    sudo pacman -S --needed --noconfirm papirus-icon-theme 2>>"$LOG_FILE"

    # Catppuccin Papirus folders
    yay -S --needed --noconfirm papirus-folders-catppuccin-git 2>>"$LOG_FILE" || true
    command -v papirus-folders &>/dev/null && \
        papirus-folders -C cat-mocha-blue --theme Papirus-Dark 2>>"$LOG_FILE" || true

    # Cursor — Catppuccin
    yay -S --needed --noconfirm catppuccin-cursors-mocha 2>>"$LOG_FILE" || \
        sudo pacman -S --needed --noconfirm xcursor-breeze 2>>"$LOG_FILE"

    # Aplica tema via gsettings
    mkdir -p "$HOME/.config/gtk-3.0" "$HOME/.config/gtk-4.0"

    cat > "$HOME/.config/gtk-3.0/settings.ini" << 'EOF'
[Settings]
gtk-theme-name=catppuccin-mocha-blue-standard+default
gtk-icon-theme-name=Papirus-Dark
gtk-cursor-theme-name=catppuccin-mocha-dark-cursors
gtk-font-name=Noto Sans 11
gtk-application-prefer-dark-theme=1
EOF

    cat > "$HOME/.config/gtk-4.0/settings.ini" << 'EOF'
[Settings]
gtk-theme-name=catppuccin-mocha-blue-standard+default
gtk-icon-theme-name=Papirus-Dark
gtk-cursor-theme-name=catppuccin-mocha-dark-cursors
gtk-font-name=Noto Sans 11
gtk-application-prefer-dark-theme=1
EOF

    log "Tema Catppuccin Mocha aplicado"
}
