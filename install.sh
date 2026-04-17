#!/bin/bash

#############################################################################
# Script para instalar Niri e Noctalia Shell no Arch Linux
# 
# Niri: Compositor Wayland moderno e flexível
# Noctalia Shell: Shell configurável para Niri
#
# Uso: sudo bash install-niri-noctalia.sh
#############################################################################

set -e  # Parar se algum comando falhar

# Cores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # Sem cor

# Funções de logging
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[✓]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[AVISO]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERRO]${NC} $1"
}

# Verificar se é root
check_root() {
    if [[ $EUID -ne 0 ]]; then
        log_error "Este script deve ser executado como root (use sudo)"
        exit 1
    fi
}

# Verificar se é Arch Linux
check_arch() {
    if ! grep -qi "arch" /etc/os-release; then
        log_warning "Este script foi criado para Arch Linux"
        log_info "Pressione Enter para continuar ou Ctrl+C para cancelar..."
        read
    fi
}

# Atualizar pacotes do sistema
update_system() {
    log_info "Atualizando banco de dados de pacotes..."
    pacman -Sy --noconfirm
    log_success "Sistema atualizado"
}

# Instalar dependências de compilação base
install_build_deps() {
    log_info "Instalando dependências de compilação..."
    
    local build_deps=(
        "base-devel"
        "git"
        "cargo"
        "rust"
    )
    
    for pkg in "${build_deps[@]}"; do
        if ! pacman -Q "$pkg" &> /dev/null; then
            log_info "Instalando $pkg..."
            pacman -S "$pkg" --noconfirm
        else
            log_success "$pkg já instalado"
        fi
    done
}

# Instalar dependências do Niri
install_niri_deps() {
    log_info "Instalando dependências do Niri..."
    
    local niri_deps=(
        "wayland"
        "libxkbcommon"
        "xwayland"
        "pipewire"
        "wireplumber"
        "seatd"
        "mesa"
        "libglvnd"
        "fontconfig"
        "freetype2"
        "libxcb"
        "xcb-proto"
        "xcb-util"
        "xcb-util-image"
        "xcb-util-keysyms"
        "xcb-util-renderutil"
        "xcb-util-wm"
        "libxrandr"
        "libxinerama"
        "libxcursor"
        "libxi"
        "libxext"
        "libx11"
        "pango"
        "glib2"
        "dbus"
    )
    
    for pkg in "${niri_deps[@]}"; do
        if ! pacman -Q "$pkg" &> /dev/null; then
            log_info "Instalando $pkg..."
            pacman -S "$pkg" --noconfirm
        else
            log_success "$pkg já instalado"
        fi
    done
}

# Instalar dependências de runtime
install_runtime_deps() {
    log_info "Instalando dependências de runtime..."
    
    local runtime_deps=(
        "alsa-lib"
        "libpulse"
        "jack"
        "openssl"
        "curl"
    )
    
    for pkg in "${runtime_deps[@]}"; do
        if ! pacman -Q "$pkg" &> /dev/null; then
            log_info "Instalando $pkg..."
            pacman -S "$pkg" --noconfirm
        else
            log_success "$pkg já instalado"
        fi
    done
}

# Instalar AUR Helper (yay ou paru)
install_aur_helper() {
    log_info "Verificando AUR helper..."
    
    # Verificar se já existe yay ou paru
    if command -v yay &> /dev/null; then
        log_success "yay já instalado"
        return 0
    elif command -v paru &> /dev/null; then
        log_success "paru já instalado"
        return 0
    fi
    
    log_info "Nenhum AUR helper encontrado. Instalando yay..."
    
    # Criar usuário para compilação se não existir
    local build_user="aur_builder"
    if ! id "$build_user" &>/dev/null; then
        log_info "Criando usuário de compilação: $build_user"
        useradd -m -G wheel "$build_user" 2>/dev/null || true
    fi
    
    # Permitir sudo sem senha para o usuário de compilação
    if ! grep -q "^$build_user ALL=(ALL) NOPASSWD: ALL" /etc/sudoers.d/* 2>/dev/null; then
        echo "$build_user ALL=(ALL) NOPASSWD: ALL" | sudo tee /etc/sudoers.d/"$build_user" > /dev/null
        chmod 440 /etc/sudoers.d/"$build_user"
        log_info "Permissões sudo configuradas para $build_user"
    fi
    
    # Preparar diretório de compilação
    local build_dir="/tmp/yay-build-$$"
    mkdir -p "$build_dir"
    cd "$build_dir"
    
    log_info "Clonando yay-bin do AUR..."
    if ! sudo -u "$build_user" git clone https://aur.archlinux.org/yay-bin.git 2>/dev/null; then
        log_warning "yay-bin não disponível, tentando yay..."
        if ! sudo -u "$build_user" git clone https://aur.archlinux.org/yay.git 2>/dev/null; then
            log_error "Falha ao clonar yay do AUR"
            return 1
        fi
        build_dir="$build_dir/yay"
    else
        build_dir="$build_dir/yay-bin"
    fi
    
    log_info "Compilando yay... isso pode levar alguns minutos"
    cd "$build_dir"
    
    # Configurar git para o usuário de compilação (necessário em algumas máquinas)
    sudo -u "$build_user" git config --global user.email "builder@localhost" 2>/dev/null || true
    sudo -u "$build_user" git config --global user.name "AUR Builder" 2>/dev/null || true
    
    # Compilar e instalar
    if sudo -u "$build_user" makepkg -si --noconfirm 2>&1 | tee /tmp/yay-build.log; then
        log_success "yay instalado com sucesso"
        
        # Limpar arquivos de compilação
        cd /tmp
        rm -rf "$build_dir"
        
        return 0
    else
        log_error "Falha na compilação do yay"
        log_info "Log: cat /tmp/yay-build.log"
        return 1
    fi
}

# Instalar Niri do AUR
install_niri() {
    log_info "Instalando Niri..."
    
    if command -v niri &> /dev/null; then
        log_success "Niri já está instalado"
        return 0
    fi
    
    # Garantir que temos um AUR helper
    if ! command -v yay &> /dev/null && ! command -v paru &> /dev/null; then
        log_warning "Nenhum AUR helper disponível"
        if ! install_aur_helper; then
            log_error "Não foi possível instalar AUR helper"
            return 1
        fi
    fi
    
    # Usar yay ou paru
    local aur_cmd="yay"
    if ! command -v yay &> /dev/null && command -v paru &> /dev/null; then
        aur_cmd="paru"
    fi
    
    log_info "Usando $aur_cmd para instalar Niri..."
    if $aur_cmd -S niri --noconfirm; then
        log_success "Niri instalado com sucesso"
        return 0
    else
        log_error "Falha na instalação do Niri com $aur_cmd"
        return 1
    fi
}

# Instalar Noctalia Shell
install_noctalia() {
    log_info "Instalando Noctalia Shell..."
    
    if command -v noctalia &> /dev/null; then
        log_success "Noctalia Shell já está instalado"
        return 0
    fi
    
    # Garantir que temos um AUR helper
    if ! command -v yay &> /dev/null && ! command -v paru &> /dev/null; then
        log_warning "Nenhum AUR helper disponível"
        if ! install_aur_helper; then
            log_error "Não foi possível instalar AUR helper"
            return 1
        fi
    fi
    
    # Usar yay ou paru
    local aur_cmd="yay"
    if ! command -v yay &> /dev/null && command -v paru &> /dev/null; then
        aur_cmd="paru"
    fi
    
    log_info "Tentando instalar noctalia-shell com $aur_cmd..."
    
    # Noctalia Shell pode não estar disponível em todos os momentos
    if $aur_cmd -S noctalia-shell --noconfirm 2>&1; then
        log_success "Noctalia Shell instalado com sucesso"
        return 0
    else
        log_warning "Noctalia Shell pode não estar disponível no AUR no momento"
        log_info "Você pode instalar manualmente depois com: $aur_cmd -S noctalia-shell"
        return 0
    fi
}

# Configurar ambiente Wayland
configure_wayland() {
    log_info "Configurando variáveis de ambiente Wayland..."
    
    local wayland_env="/etc/environment.d/wayland.conf"
    
    if [ ! -f "$wayland_env" ]; then
        mkdir -p /etc/environment.d
        cat > "$wayland_env" << 'EOF'
# Variáveis de ambiente para Wayland
QT_QPA_PLATFORM=wayland
GDK_BACKEND=wayland
CLUTTER_BACKEND=wayland
EOF
        log_success "Variáveis de ambiente Wayland configuradas"
    else
        log_warning "Arquivo de configuração Wayland já existe"
    fi
}

# Adicionar sessão Niri ao SDDM/LightDM
setup_session() {
    log_info "Configurando sessão de desktop Niri..."
    
    local niri_desktop="/usr/share/wayland-sessions/niri.desktop"
    
    if [ ! -f "$niri_desktop" ]; then
        mkdir -p /usr/share/wayland-sessions
        cat > "$niri_desktop" << 'EOF'
[Desktop Entry]
Name=Niri
Comment=Niri compositor
Exec=niri
Type=Application
EOF
        log_success "Sessão Niri adicionada"
    else
        log_success "Sessão Niri já configurada"
    fi
}

# Instalar display manager opcional
install_display_manager() {
    log_info "Verificando display manager..."
    
    if ! pacman -Q sddm &> /dev/null && ! pacman -Q lightdm &> /dev/null; then
        log_warning "Nenhum display manager encontrado"
        read -p "Deseja instalar SDDM? (s/n) " -n 1 -r
        echo
        
        if [[ $REPLY =~ ^[Ss]$ ]]; then
            pacman -S sddm --noconfirm
            systemctl enable sddm
            log_success "SDDM instalado e habilitado"
        fi
    else
        log_success "Display manager já instalado"
    fi
}

# Criar arquivo de configuração base do Niri
setup_niri_config() {
    log_info "Criando arquivo de configuração do Niri..."
    
    local niri_config="$HOME/.config/niri/config.kdl"
    local niri_dir="$HOME/.config/niri"
    
    if [ ! -d "$niri_dir" ]; then
        mkdir -p "$niri_dir"
        
        cat > "$niri_config" << 'EOF'
// Configuração básica do Niri
// Para mais opções, consulte: https://github.com/YaLTeR/niri

input {
    keyboard {
        xkb {
            layout "br"  // Layout de teclado brasileiro
        }
    }
    
    touchpad {
        tap
        natural-scroll
    }
}

output "eDP-1" {
    scale 1.0
}

// Espaços de trabalho
workspace "1" {
    // Configurações da área de trabalho
}

// Atalhos de teclado
binds {
    Mod+T { spawn "alacritty"; }
    Mod+D { spawn "rofi" "-show" "drun"; }
    Mod+Q { close-window; }
    Mod+Escape { power-off-monitors; }
}

// Tema e aparência
preferred-scale 1.0
EOF
        
        log_success "Arquivo de configuração do Niri criado em $niri_config"
    else
        log_warning "Diretório de configuração do Niri já existe"
    fi
}

# Resumo final
print_summary() {
    echo ""
    echo -e "${GREEN}╔════════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${GREEN}║${NC}           Instalação concluída com sucesso!                   ${GREEN}║${NC}"
    echo -e "${GREEN}╚════════════════════════════════════════════════════════════════╝${NC}"
    echo ""
    echo "Próximos passos:"
    echo "  1. Faça logout da sessão atual"
    echo "  2. Na tela de login, selecione 'Niri' como sessão"
    echo "  3. Faça login normalmente"
    echo ""
    echo "Configurações:"
    echo "  • Configuração do Niri: ~/.config/niri/config.kdl"
    echo "  • Variáveis Wayland: /etc/environment.d/wayland.conf"
    echo ""
    echo "Links úteis:"
    echo "  • Niri: https://github.com/YaLTeR/niri"
    echo "  • Documentação: https://github.com/YaLTeR/niri/wiki"
    echo ""
}

# Função principal
main() {
    echo -e "${BLUE}"
    echo "╔════════════════════════════════════════════════════════════════╗"
    echo "║        Instalador de Niri + Noctalia Shell para Arch Linux     ║"
    echo "╚════════════════════════════════════════════════════════════════╝"
    echo -e "${NC}"
    echo ""
    
    check_root
    check_arch
    
    update_system
    install_build_deps
    install_aur_helper          # ← NOVO: Instalar AUR helper primeiro
    install_niri_deps
    install_runtime_deps
    install_niri
    install_noctalia
    configure_wayland
    setup_session
    install_display_manager
    setup_niri_config
    
    print_summary
}

# Executar função principal
main
