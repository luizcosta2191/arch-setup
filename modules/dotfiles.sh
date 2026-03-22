#!/usr/bin/env bash
# módulo: dotfiles — copia configs prontas para ~/.config

install_dotfiles() {
    section "Dotfiles"

    local cfg="$HOME/.config"
    local src="$DOTFILES_DIR"

    # Faz backup de configs existentes
    local backup="$HOME/.config-backup-$(date +%Y%m%d%H%M%S)"
    local needs_backup=false

    for dir in hypr waybar rofi kitty dunst; do
        [[ -d "$cfg/$dir" ]] && needs_backup=true && break
    done

    if $needs_backup; then
        info "Fazendo backup das configs existentes em $backup..."
        mkdir -p "$backup"
        for dir in hypr waybar rofi kitty dunst; do
            [[ -d "$cfg/$dir" ]] && cp -r "$cfg/$dir" "$backup/" 2>>"$LOG_FILE"
        done
        log "Backup salvo em $backup"
    fi

    # Copia configs
    mkdir -p "$cfg"
    for dir in hypr waybar rofi kitty dunst fish; do
        if [[ -d "$src/$dir" ]]; then
            cp -r "$src/$dir" "$cfg/"
            log "Config copiada: $dir"
        fi
    done

    log "Dotfiles aplicados"
}
