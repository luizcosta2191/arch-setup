#!/usr/bin/env bash
# módulo: shell — Fish shell + Starship prompt

install_shell() {
    section "Fish shell + Starship"

    # Fish
    sudo pacman -S --needed --noconfirm fish 2>>"$LOG_FILE"

    # Starship prompt
    sudo pacman -S --needed --noconfirm starship 2>>"$LOG_FILE"

    # Define fish como shell padrão
    local fish_path
    fish_path="$(command -v fish)"
    if ! grep -q "$fish_path" /etc/shells; then
        echo "$fish_path" | sudo tee -a /etc/shells >/dev/null
    fi
    chsh -s "$fish_path" "$USER"
    log "Fish definido como shell padrão para $USER"

    # Configura Fish
    mkdir -p "$HOME/.config/fish/functions"

    cat > "$HOME/.config/fish/config.fish" << 'EOF'
# Starship prompt
starship init fish | source

# Variáveis de ambiente
set -gx EDITOR nvim
set -gx BROWSER firefox
set -gx XDG_CURRENT_DESKTOP Hyprland

# Aliases úteis
alias ls  'ls --color=auto'
alias ll  'ls -lah --color=auto'
alias la  'ls -A --color=auto'
alias ..  'cd ..'
alias ... 'cd ../..'

alias grep 'grep --color=auto'
alias cat  'bat --paging=never'
alias top  'btop'
alias vim  'nvim'

# yay shortcuts
alias yu  'yay -Syu --noconfirm'
alias yi  'yay -S'
alias yr  'yay -Rns'
alias ys  'yay -Ss'

# Hyprland
if test "$XDG_SESSION_TYPE" = "wayland"
    set -gx MOZ_ENABLE_WAYLAND 1
    set -gx QT_QPA_PLATFORM wayland
    set -gx ELECTRON_OZONE_PLATFORM_HINT auto
end

# PATH extras
fish_add_path "$HOME/.local/bin"
EOF

    # Starship config (tema Catppuccin Mocha)
    mkdir -p "$HOME/.config"
    cat > "$HOME/.config/starship.toml" << 'EOF'
"$schema" = 'https://starship.rs/config-schema.json'

format = """
[░▒▓](fg:#1e1e2e)\
[ 󰣇 ](bg:#1e1e2e fg:#cba6f7)\
[░▒▓](fg:#1e1e2e bg:#313244)\
[ $directory](bg:#313244 fg:#cdd6f4)\
[░▒▓](fg:#313244 bg:#45475a)\
$git_branch\
$git_status\
[░▒▓](fg:#45475a)\
$fill\
$cmd_duration\
[ $time ](fg:#cba6f7)
$character"""

[fill]
symbol = ' '

[directory]
style = "bg:#313244 fg:#89b4fa"
format = "[ $path ]($style)"
truncation_length = 3
truncate_to_repo = false

[git_branch]
symbol = ""
style = "bg:#45475a fg:#a6e3a1"
format = '[ $symbol $branch ]($style)'

[git_status]
style = "bg:#45475a fg:#f38ba8"
format = '[$all_status$ahead_behind ]($style)'

[time]
disabled = false
time_format = "%H:%M"
style = "fg:#b4befe"
format = '[ $time]($style)'

[cmd_duration]
style = "fg:#f9e2af"
format = '[$duration ]($style)'

[character]
success_symbol = '[❯](bold fg:#a6e3a1)'
error_symbol = '[❯](bold fg:#f38ba8)'
EOF

    log "Fish + Starship configurados"
}
