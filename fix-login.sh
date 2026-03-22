# Adicionar em todos os arquivos de perfil possíveis
for f in ~/.bash_profile ~/.profile ~/.zprofile; do
    if ! grep -q "exec startx" "$f" 2>/dev/null; then
        cat >> "$f" << 'EOF'

# Iniciar Openbox automaticamente ao logar no tty1
if [ -z "$DISPLAY" ] && [ "$(tty)" = "/dev/tty1" ]; then
    exec startx
fi
EOF
        echo "Adicionado: $f"
    fi
done

sudo reboot
