#!/bin/bash

# ==============================================================================
#  fix-intel.sh — Correção de driver para Intel + Hyprland
#  Uso: ./fix-intel.sh
#  Compatível com: Intel HD / UHD / Iris / Arc
# ==============================================================================

set -e

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

header() {
    echo -e "\n${CYAN}${BOLD}"
    echo "  ╔══════════════════════════════════════════════╗"
    printf  "  ║  %-44s║\n" "$1"
    echo "  ╚══════════════════════════════════════════════╝"
    echo -e "${RESET}"
}

confirm() {
    read -n1 -rp "$(echo -e "${BOLD}  ➜  $1 (s/n): ${RESET}")" ans
    echo
    [[ "$ans" =~ ^[sSyY]$ ]]
}

# ==============================================================================
header "FIX — Driver Intel + Hyprland"
# ==============================================================================

if [[ "$EUID" -eq 0 ]]; then
    err "Não execute como root. Use usuário normal com sudo."
    exit 1
fi

# ── Detectar GPU Intel ────────────────────────────────────────────────────────
msg "Detectando hardware Intel"
GPU_INFO=$(lspci | grep -i "vga\|display\|3d" || true)
echo -e "  $GPU_INFO"

if echo "$GPU_INFO" | grep -qi "intel"; then
    ok "GPU Intel detectada"
else
    warn "GPU Intel não detectada. Verifique se este é o script correto."
    info "Saída de lspci: $GPU_INFO"
fi

# ── Detectar geração (Arc vs integrada) ──────────────────────────────────────
IS_ARC=false
if echo "$GPU_INFO" | grep -qi "arc\|alchemist\|battlemage"; then
    IS_ARC=true
    info "GPU Intel Arc detectada — instalando pacotes extras"
fi

# ── Pacotes base Intel ────────────────────────────────────────────────────────
msg "Instalando drivers Intel (mesa + vulkan)"
sudo pacman -S --needed --noconfirm \
    mesa \
    lib32-mesa \
    vulkan-intel \
    lib32-vulkan-intel \
    intel-media-driver \
    libva-intel-driver \
    libva-utils

if $IS_ARC; then
    info "Instalando pacotes extras para Intel Arc..."
    sudo pacman -S --needed --noconfirm \
        intel-compute-runtime \
        level-zero-loader
fi
ok "Drivers Intel instalados"

# ── Variáveis de ambiente no hyprland.conf ────────────────────────────────────
msg "Configurando variáveis de ambiente para Intel"
HYPR_CONF="$HOME/.config/hypr/hyprland.conf"

if [[ ! -f "$HYPR_CONF" ]]; then
    err "hyprland.conf não encontrado em $HYPR_CONF"
    exit 1
fi

# Remove bloco NVIDIA se existir (migração)
if grep -q "LIBVA_DRIVER_NAME,nvidia" "$HYPR_CONF"; then
    warn "Encontradas configurações NVIDIA — removendo..."
    sed -i '/# ── NVIDIA/,/^}/d' "$HYPR_CONF"
fi

if grep -q "LIBVA_DRIVER_NAME,iHD" "$HYPR_CONF"; then
    warn "Variáveis Intel já configuradas, pulando."
else
    cat >> "$HYPR_CONF" << 'EOF'

# ── Intel ─────────────────────────────────────────────────────────────────────
env = LIBVA_DRIVER_NAME,iHD
env = VDPAU_DRIVER,va_gl
env = __GLX_VENDOR_LIBRARY_NAME,mesa
EOF
    ok "Variáveis Intel adicionadas ao hyprland.conf"
fi

# ── mkinitcpio — módulo i915 ──────────────────────────────────────────────────
msg "Verificando módulos no initramfs"
MKINIT="/etc/mkinitcpio.conf"

if grep -q "i915" "$MKINIT"; then
    warn "Módulo i915 já presente no mkinitcpio.conf"
else
    sudo sed -i 's/^MODULES=(\(.*\))/MODULES=(\1 i915)/' "$MKINIT"
    # Limpa espaço duplo se MODULES estava vazio
    sudo sed -i 's/MODULES=( /MODULES=(/' "$MKINIT"
    sudo mkinitcpio -P
    ok "Módulo i915 adicionado e initramfs reconstruído"
fi

# ── SDDM + Wayland ────────────────────────────────────────────────────────────
msg "Configurando SDDM para Wayland"
sudo mkdir -p /etc/sddm.conf.d/
sudo tee /etc/sddm.conf.d/hyprland.conf > /dev/null << 'EOF'
[General]
DisplayServer=wayland
GreeterEnvironment=QT_WAYLAND_SHELL_INTEGRATION=layer-shell

[Wayland]
CompositorCommand=Hyprland
EOF
ok "SDDM configurado para Wayland"

# ── Layout teclado BR no SDDM ─────────────────────────────────────────────────
msg "Configurando layout de teclado BR no SDDM"
sudo tee /etc/sddm.conf.d/keyboard.conf > /dev/null << 'EOF'
[X11]
XkbLayout=br
EOF
ok "Layout BR configurado no SDDM"

# ── Conclusão ─────────────────────────────────────────────────────────────────
echo -e "\n${GREEN}${BOLD}"
echo "  ╔══════════════════════════════════════════════╗"
echo "  ║     ✔  Fix Intel concluído!                  ║"
echo "  ╚══════════════════════════════════════════════╝"
echo -e "${RESET}"

if confirm "Reiniciar agora para aplicar as mudanças?"; then
    sudo reboot
fi
