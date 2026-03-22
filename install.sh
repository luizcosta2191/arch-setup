#!/usr/bin/env bash
# =============================================================================
#  arch-setup — instalador interativo para Arch Linux
#  https://github.com/seu-usuario/arch-setup
# =============================================================================
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LOG_FILE="$SCRIPT_DIR/install.log"
DOTFILES_DIR="$SCRIPT_DIR/dotfiles"

# ── Cores ─────────────────────────────────────────────────────────────────────
RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'
BLUE='\033[0;34m'; CYAN='\033[0;36m'; BOLD='\033[1m'; RESET='\033[0m'

# ── Helpers ───────────────────────────────────────────────────────────────────
log()     { echo -e "${GREEN}[✔]${RESET} $*" | tee -a "$LOG_FILE"; }
warn()    { echo -e "${YELLOW}[!]${RESET} $*" | tee -a "$LOG_FILE"; }
error()   { echo -e "${RED}[✘]${RESET} $*" | tee -a "$LOG_FILE"; }
info()    { echo -e "${CYAN}[→]${RESET} $*" | tee -a "$LOG_FILE"; }
section() { echo -e "\n${BOLD}${BLUE}══ $* ══${RESET}\n" | tee -a "$LOG_FILE"; }

ask() {
    echo -en "${YELLOW}[?]${RESET} $* [s/N] "
    read -r resp
    [[ "$resp" =~ ^[Ss]$ ]]
}

die() { error "$*"; exit 1; }

# ── Verificações iniciais ─────────────────────────────────────────────────────
check_requirements() {
    [[ $EUID -eq 0 ]] && die "Não execute como root. O script pedirá sudo quando necessário."
    command -v pacman &>/dev/null || die "Este script requer Arch Linux com pacman."
    ping -c1 archlinux.org &>/dev/null || die "Sem conexão com a internet."
    log "Pré-requisitos OK"
}

# ── Banner ─────────────────────────────────────────────────────────────────────
banner() {
clear
cat << 'EOF'
   _____  ____  ____  _   __   _____ ______ _______ __  ______
  / _ \ \/ / / / / / / | / /  / ___// ____//_  __/ / / / / __ \
 / /_/ /\  / /_/ / /  |/ /   \__ \/ __/   / / / /_/ / /_/ / /_/ /
/_/ /_/ /_/\____/_/|_|_/   /___/_____/  /_/ \____/ .__/ /____/
                                                  /_/
   Instalador para Arch Linux  ·  Hyprland + Waybar + Dock
EOF
echo ""
}

# ── Seleção de módulos ────────────────────────────────────────────────────────
select_modules() {
    section "O que deseja instalar?"

    INSTALL_BASE=true       # sempre instalado
    INSTALL_HYPRLAND=false
    INSTALL_APPS=false
    INSTALL_FONTS=false
    INSTALL_THEME=false
    INSTALL_DOTFILES=false
    INSTALL_GAMING=false
    INSTALL_SHELL=false

    echo -e "  ${BOLD}Módulos disponíveis:${RESET}"
    echo ""

    ask "  [1] Hyprland + Waybar + nwg-dock (WM completo)" \
        && INSTALL_HYPRLAND=true
    ask "  [2] Aplicativos essenciais (Firefox, Thunar, VLC, etc.)" \
        && INSTALL_APPS=true
    ask "  [3] Fontes (Nerd Fonts, emoji, Microsoft)" \
        && INSTALL_FONTS=true
    ask "  [4] Tema GTK + ícones (Catppuccin Mocha)" \
        && INSTALL_THEME=true
    ask "  [5] Dotfiles (configs prontas para uso)" \
        && INSTALL_DOTFILES=true
    ask "  [6] Fish shell + Starship prompt" \
        && INSTALL_SHELL=true
    ask "  [7] Gaming (Steam, Proton, MangoHud, GameMode)" \
        && INSTALL_GAMING=true

    echo ""
    echo -e "  ${BOLD}Resumo do que será instalado:${RESET}"
    $INSTALL_BASE     && echo -e "  ${GREEN}✔${RESET} Base do sistema (yay, pipewire, bluetooth, etc.)"
    $INSTALL_HYPRLAND && echo -e "  ${GREEN}✔${RESET} Hyprland + Waybar + nwg-dock"
    $INSTALL_APPS     && echo -e "  ${GREEN}✔${RESET} Aplicativos essenciais"
    $INSTALL_FONTS    && echo -e "  ${GREEN}✔${RESET} Fontes"
    $INSTALL_THEME    && echo -e "  ${GREEN}✔${RESET} Tema Catppuccin"
    $INSTALL_DOTFILES && echo -e "  ${GREEN}✔${RESET} Dotfiles"
    $INSTALL_SHELL    && echo -e "  ${GREEN}✔${RESET} Fish + Starship"
    $INSTALL_GAMING   && echo -e "  ${GREEN}✔${RESET} Gaming"
    echo ""

    ask "Confirmar e iniciar instalação?" || { info "Cancelado."; exit 0; }
}

# ── Execução dos módulos ──────────────────────────────────────────────────────
run_modules() {
    source "$SCRIPT_DIR/modules/base.sh"
    install_base

    $INSTALL_HYPRLAND && {
        source "$SCRIPT_DIR/modules/hyprland.sh"
        install_hyprland
    }

    $INSTALL_APPS && {
        source "$SCRIPT_DIR/modules/apps.sh"
        install_apps
    }

    $INSTALL_FONTS && {
        source "$SCRIPT_DIR/modules/fonts.sh"
        install_fonts
    }

    $INSTALL_THEME && {
        source "$SCRIPT_DIR/modules/theme.sh"
        install_theme
    }

    $INSTALL_SHELL && {
        source "$SCRIPT_DIR/modules/shell.sh"
        install_shell
    }

    $INSTALL_GAMING && {
        source "$SCRIPT_DIR/modules/gaming.sh"
        install_gaming
    }

    $INSTALL_DOTFILES && {
        source "$SCRIPT_DIR/modules/dotfiles.sh"
        install_dotfiles
    }
}

# ── Finalização ───────────────────────────────────────────────────────────────
finish() {
    section "Instalação concluída!"
    log "Log salvo em: $LOG_FILE"
    echo ""
    echo -e "  ${BOLD}Próximos passos:${RESET}"
    echo -e "  1. Reinicie o sistema: ${CYAN}reboot${RESET}"
    echo -e "  2. Faça login — o Hyprland inicia automaticamente via SDDM"
    echo -e "  3. Atalhos básicos:"
    echo -e "     ${CYAN}SUPER + Q${RESET}       → terminal (kitty)"
    echo -e "     ${CYAN}SUPER + E${RESET}       → explorador de arquivos"
    echo -e "     ${CYAN}SUPER + R${RESET}       → launcher (rofi)"
    echo -e "     ${CYAN}SUPER + Shift + Q${RESET} → fechar janela"
    echo -e "     ${CYAN}SUPER + 1..9${RESET}    → workspaces"
    echo ""
}

# ── Main ──────────────────────────────────────────────────────────────────────
main() {
    banner
    check_requirements
    select_modules
    run_modules
    finish
}

main "$@"
