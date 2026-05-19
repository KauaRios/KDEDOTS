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

install_apps() {
	local pkgs=()

	command -v kitty &>/dev/null || pkgs+=(kitty)
	command -v fish &>/dev/null  || pkgs+=(fish)
	command -v fzf &>/dev/null   || pkgs+=(fzf)
	command -v starship &>/dev/null || pkgs+=(starship)
	command -v code &>/dev/null  || pkgs+=(code)

	if [[ ${#pkgs[@]} -eq 0 ]]; then
		ok "todos os apps já estão instalados"
		return
	fi

	info "Instalando: ${pkgs[*]}"
	if sudo pacman -S --noconfirm "${pkgs[@]}"; then
		ok "apps instalados"
	else
		warn "falha ao instalar alguns pacotes — continuando com symlinks"
	fi
}

create_symlink() {
	local src="$1"
	local dst="$2"

	if [ ! -e "$src" ]; then
		warn "fonte não existe: $src"
		return 1
	fi

	if [ -L "$dst" ] && [ "$(readlink -f "$dst")" = "$(readlink -f "$src")" ]; then
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

	if [ -L "$dst" ]; then
		ok "symlink criado: $dst → $src"
	else
		warn "falha ao criar symlink: $dst"
		return 1
	fi
}

create_symlinks() {
	echo ""
	info "Criando symlinks..."

	create_symlink "$SCRIPT_DIR/kitty/kitty.conf"      "$HOME/.config/kitty/kitty.conf"
	create_symlink "$SCRIPT_DIR/kitty/kitty-theme.conf" "$HOME/.config/kitty/kitty-theme.conf"
	create_symlink "$SCRIPT_DIR/fastfetch/config.jsonc" "$HOME/.config/fastfetch/config.jsonc"
	create_symlink "$SCRIPT_DIR/starship.toml"          "$HOME/.config/starship.toml"
	create_symlink "$SCRIPT_DIR/fish"                   "$HOME/.config/fish"

	info "Verificando symlinks criados..."
	local failed=0
	for dst in "$HOME/.config/kitty/kitty.conf" "$HOME/.config/kitty/kitty-theme.conf" "$HOME/.config/fastfetch/config.jsonc" "$HOME/.config/starship.toml" "$HOME/.config/fish"; do
		if [ -L "$dst" ]; then
			ok "OK: $dst"
		else
			warn "FALHA: $dst não é um symlink válido"
			failed=1
		fi
	done

	if [ $failed -ne 0 ]; then
		warn "Alguns symlinks falharam — verifique os logs acima"
		return 1
	fi
}

set_default_terminal() {
	local kwrite
	if command -v kwriteconfig6 &>/dev/null; then
		kwrite="kwriteconfig6"
	elif command -v kwriteconfig5 &>/dev/null; then
		kwrite="kwriteconfig5"
	else
		warn "kwriteconfig não encontrado (instale kde-cli-tools)"
		warn "Defina manualmente: TerminalApplication=kitty no ~/.config/kdeglobals"
		return
	fi

	$kwrite --file kdeglobals --group General --key TerminalApplication kitty
	$kwrite --file kdeglobals --group General --key TerminalService kitty.desktop
	ok "kitty definido como terminal padrão do KDE"
}

setup_fish() {
	if ! command -v fish &>/dev/null; then
		warn "fish não está instalado — pulando configuração"
		return
	fi

	local fish_conf="$HOME/.config/fish/config.fish"
	if [ -L "$fish_conf" ]; then
		info "Convertendo config.fish de symlink para arquivo editável..."
		local src
		src="$(readlink "$fish_conf")"
		rm "$fish_conf"
		cp "$src" "$fish_conf"
		ok "config.fish convertido"
	fi

	info "Instalando fisher e plugins de autocomplete..."
	fish -c "
		if not functions -q fisher
			curl -sL https://raw.githubusercontent.com/jorgebucaran/fisher/main/functions/fisher.fish | source
			fisher install jorgebucaran/fisher
		end
		fisher update
	" 2>/dev/null || warn "fisher/plugins: verifique manualmente"
	ok "fisher e plugins instalados"

	if [ "$SHELL" != "$(command -v fish)" ]; then
		info "Definindo fish como shell padrão..."
		if ! grep -qF "$(command -v fish)" /etc/shells 2>/dev/null; then
			echo "$(command -v fish)" | sudo tee -a /etc/shells
		fi
		sudo usermod -s "$(command -v fish)" "$(id -un)" || warn "Não foi possível definir fish como shell padrão"
		ok "fish definido como shell padrão (efetivo na próxima sessão)"
	fi
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

info "Diretório do script: $SCRIPT_DIR"
info "Home do usuário: $HOME"

install_apps
create_symlinks
setup_fish
set_default_terminal
set_wallpaper

echo ""
ok "Pronto!"
