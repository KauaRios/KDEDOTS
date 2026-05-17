#!/usr/bin/env bash
#
# kdedots - Instalador de configurações KDE
# Cria symlinks, instala pacotes e define wallpaper
#

set -euo pipefail

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

info() { echo -e "${CYAN}[..]${NC} $1"; }
ok()   { echo -e "${GREEN}[ok]${NC} $1"; }
warn() { echo -e "${YELLOW}[!]${NC}  $1"; }

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

install_kitty() {
	if command -v kitty &>/dev/null; then
		ok "kitty já está instalado"
		return
	fi
	info "Instalando kitty..."
	sudo pacman -S --noconfirm kitty
	ok "kitty instalado"
}

create_symlink() {
	local src="$1"
	local dst="$2"

	if [ -L "$dst" ] && [ "$(readlink "$dst")" = "$src" ]; then
		ok "symlink já existe: $dst → $src"
		return
	fi

	if [ -e "$dst" ]; then
		local backup="${dst}_backup"
		warn "$dst já existe, movendo para $backup"
		mv "$dst" "$backup"
	fi

	mkdir -p "$(dirname "$dst")"
	ln -sf "$src" "$dst"
	ok "symlink: $dst → $src"
}

create_symlinks() {
	echo ""
	info "Criando symlinks..."

	create_symlink "$SCRIPT_DIR/kitty/kitty.conf"      "$HOME/.config/kitty/kitty.conf"
	create_symlink "$SCRIPT_DIR/kitty/kitty-theme.conf" "$HOME/.config/kitty/kitty-theme.conf"
	create_symlink "$SCRIPT_DIR/fastfetch/config.jsonc" "$HOME/.config/fastfetch/config.jsonc"
	create_symlink "$SCRIPT_DIR/starship.toml"          "$HOME/.config/starship.toml"
}

set_wallpaper() {
	local wp_src="$SCRIPT_DIR/wallpapers/wallpaper.png"

	if [ ! -f "$wp_src" ]; then
		warn "Arquivo de wallpaper não encontrado: $wp_src"
		return
	fi

	local wp_dir="$HOME/Imagens/wallpapers"
	local wp_dst="$wp_dir/wallpaper.png"

	if [ ! -f "$wp_dst" ]; then
		mkdir -p "$wp_dir"
		cp "$wp_src" "$wp_dst"
		ok "Wallpaper copiado para $wp_dst"
	fi

	if command -v plasma-apply-wallpaperimage &>/dev/null; then
		plasma-apply-wallpaperimage -s All "$wp_dst"
		ok "Wallpaper aplicado em todos os monitores"
	else
		warn "plasma-apply-wallpaperimage não encontrado (instale plasma-workspace)"
		warn "Copie manualmente ou execute após instalar o KDE"
	fi
}

echo ""
echo -e "${CYAN}╔══════════════════════════════════════════╗${NC}"
echo -e "${CYAN}║         kdedots — instalador KDE         ║${NC}"
echo -e "${CYAN}╚══════════════════════════════════════════╝${NC}"

install_kitty
create_symlinks
set_wallpaper

echo ""
ok "Pronto!"
