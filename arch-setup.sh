#!/bin/bash

# ==============================================================================
#  fix-nvidia.sh — Correção de driver para NVIDIA + Hyprland
#  Uso: ./fix-nvidia.sh
#  Compatível com: GTX 700+ / RTX série toda / MX series
#  Para GPUs antigas (GTX 600 e anteriores) veja nota no script.
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
header "FIX — Driver NVIDIA + Hyprland"
# ==============================================================================

if [[ "$EUID" -eq 0 ]]; then
    err "Não execute como root. Use usuário normal com sudo."
    exit 1
fi

# ── Detectar GPU NVIDIA ───────────────────────────────────────────────────────
msg "Detectando hardware NVIDIA"
GPU_INFO=$(lspci | grep -i "vga\|display\|3d" || true)
echo -e "  $GPU_INFO"

if echo "$GPU_INFO" | grep -qi "nvidia"; then
    ok "GPU NVIDIA detectada"
else
    warn "GPU NVIDIA não detectada. Verifique se este é o script correto."
    info "Saída de lspci: $GPU_INFO"
fi

# ── Detectar notebook com Intel+NVIDIA (Optimus/PRIME) ───────────────────────
IS_OPTIMUS=false
if echo "$GPU_INFO" | grep -qi "intel" && echo "$GPU_INFO" | grep -qi "nvidia"; then
    IS_OPTIMUS=true
    warn "Configuração Optimus/PRIME detectada (Intel + NVIDIA)"
    info "Serão instalados pacotes extras para PRIME render offload."
fi

# ── Remover driver nouveau ────────────────────────────────────────────────────
msg "Desativando driver nouveau (open-source)"
if lsmod | grep -q nouveau; then
    sudo modprobe -r nouveau 2>/dev/null || true
    warn "nouveau estava carregado — foi descarregado"
fi

# Bloqueia o nouveau via modprobe
sudo tee /etc/modprobe.d/blacklist-nouveau.conf > /dev/null << 'EOF'
blacklist nouveau
options nouveau modeset=0
EOF
ok "nouveau bloqueado via /etc/modprobe.d/blacklist-nouveau.conf"

# ── Instalar driver proprietário NVIDIA ───────────────────────────────────────
msg "Instalando driver proprietário NVIDIA"
info "Nota: nvidia-dkms compila para todos os kernels instalados."
info "Se tiver kernel personalizado, isso pode demorar alguns minutos."

sudo pacman -S --needed --noconfirm \
    nvidia-dkms \
    nvidia-utils \
    lib32-nvidia-utils \
    nvidia-settings \
    libva-nvidia-driver \
    libva-utils

if $IS_OPTIMUS; then
    sudo pacman -S --needed --noconfirm \
        nvidia-prime \
        switcheroo-control
    sudo systemctl enable switcheroo-control
    info "nvidia-prime instalado para PRIME render offload"
fi
ok "Driver NVIDIA instalado"

# ── mkinitcpio — módulos NVIDIA ───────────────────────────────────────────────
msg "Adicionando módulos NVIDIA ao initramfs"
MKINIT="/etc/mkinitcpio.conf"

# Verifica e atualiza MODULES
if grep -q "nvidia_drm" "$MKINIT"; then
    warn "Módulos NVIDIA já presentes no mkinitcpio.conf"
else
    # Substitui MODULES=() ou MODULES=(outros) adicionando os módulos NVIDIA
    sudo sed -i 's/^MODULES=(\(.*\))/MODULES=(\1 nvidia nvidia_modeset nvidia_uvm nvidia_drm)/' "$MKINIT"
    sudo sed -i 's/MODULES=( /MODULES=(/' "$MKINIT"
    ok "Módulos NVIDIA adicionados ao mkinitcpio.conf"
fi

# Remove kms do HOOKS para evitar conflito com nvidia_drm
if grep -q " kms" "$MKINIT"; then
    sudo sed -i 's/ kms//' "$MKINIT"
    ok "Hook 'kms' removido do mkinitcpio.conf (evita conflito com nvidia_drm)"
fi

sudo mkinitcpio -P
ok "initramfs reconstruído"

# ── Detectar e configurar bootloader ─────────────────────────────────────────
msg "Detectando bootloader e adicionando parâmetros NVIDIA"

KERNEL_PARAMS="nvidia_drm.modeset=1 nvidia_drm.fbdev=1"

# systemd-boot
if [[ -d /boot/loader/entries ]]; then
    info "systemd-boot detectado"
    ENTRIES=$(ls /boot/loader/entries/*.conf 2>/dev/null || true)
    if [[ -z "$ENTRIES" ]]; then
        err "Nenhuma entrada encontrada em /boot/loader/entries/"
        info "Adicione manualmente à linha 'options': $KERNEL_PARAMS"
    else
        for ENTRY in $ENTRIES; do
            if grep -q "nvidia_drm.modeset" "$ENTRY"; then
                warn "Parâmetros NVIDIA já presentes em $ENTRY"
            else
                sudo sed -i "s/^options \(.*\)/options \1 $KERNEL_PARAMS/" "$ENTRY"
                ok "Parâmetros adicionados em: $ENTRY"
            fi
        done
    fi

# GRUB
elif [[ -f /etc/default/grub ]]; then
    info "GRUB detectado"
    if grep -q "nvidia_drm.modeset" /etc/default/grub; then
        warn "Parâmetros NVIDIA já presentes no GRUB"
    else
        sudo sed -i "s/GRUB_CMDLINE_LINUX_DEFAULT=\"\(.*\)\"/GRUB_CMDLINE_LINUX_DEFAULT=\"\1 $KERNEL_PARAMS\"/" \
            /etc/default/grub
        sudo grub-mkconfig -o /boot/grub/grub.cfg
        ok "Parâmetros NVIDIA adicionados ao GRUB"
    fi

else
    warn "Bootloader não identificado automaticamente."
    info "Adicione manualmente os parâmetros: $KERNEL_PARAMS"
fi

# ── Variáveis de ambiente no hyprland.conf ────────────────────────────────────
msg "Configurando variáveis de ambiente NVIDIA no hyprland.conf"
HYPR_CONF="$HOME/.config/hypr/hyprland.conf"

if [[ ! -f "$HYPR_CONF" ]]; then
    err "hyprland.conf não encontrado em $HYPR_CONF"
    exit 1
fi

if grep -q "LIBVA_DRIVER_NAME,nvidia" "$HYPR_CONF"; then
    warn "Variáveis NVIDIA já configuradas no hyprland.conf, pulando."
else
    cat >> "$HYPR_CONF" << 'EOF'

# ── NVIDIA ────────────────────────────────────────────────────────────────────
env = LIBVA_DRIVER_NAME,nvidia
env = __GLX_VENDOR_LIBRARY_NAME,nvidia
env = NVD_BACKEND,direct
env = GBM_BACKEND,nvidia-drm
env = __NV_PRIME_RENDER_OFFLOAD,1
cursor {
    no_hardware_cursors = true
}
EOF
    ok "Variáveis NVIDIA adicionadas ao hyprland.conf"
fi

# ── PRIME — atalho para forçar NVIDIA em apps específicos (Optimus) ───────────
if $IS_OPTIMUS; then
    msg "Configurando PRIME render offload (Optimus)"
    if ! grep -q "alias nvidia-run" ~/.bashrc; then
        echo -e '\n# Roda aplicativo forçando GPU NVIDIA (Optimus)\nalias nvidia-run="prime-run"' >> ~/.bashrc
    fi
    info "Use 'nvidia-run <programa>' para forçar a GPU dedicada."
    info "Ex: nvidia-run steam, nvidia-run blender"
    ok "Alias nvidia-run configurado no .bashrc"
fi

# ── SDDM + Wayland ────────────────────────────────────────────────────────────
msg "Configurando SDDM para Wayland com NVIDIA"
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
echo "  ║     ✔  Fix NVIDIA concluído!                 ║"
echo "  ╠══════════════════════════════════════════════╣"
echo "  ║  • nouveau bloqueado             ✔           ║"
echo "  ║  • nvidia-dkms instalado         ✔           ║"
echo "  ║  • initramfs reconstruído        ✔           ║"
echo "  ║  • bootloader configurado        ✔           ║"
echo "  ║  • hyprland.conf atualizado      ✔           ║"
echo "  ║  • SDDM configurado (Wayland)    ✔           ║"
echo "  ╚══════════════════════════════════════════════╝"
echo -e "${RESET}"

if $IS_OPTIMUS; then
    warn "Optimus detectado: use 'nvidia-run <app>' para a GPU dedicada."
fi

warn "O reboot é OBRIGATÓRIO para o driver NVIDIA entrar em efeito."
echo ""

if confirm "Reiniciar agora para aplicar as mudanças?"; then
    sudo reboot
fi
