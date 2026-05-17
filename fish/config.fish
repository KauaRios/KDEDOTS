# ~/.config/fish/config.fish

# 1. Remove a mensagem padrão chata do Fish



set -g fish_greeting



# 2. Tenta carregar as otimizações do CachyOS (se o usuário estiver no CachyOS)
if test -f /usr/share/cachyos-fish-config/cachyos-config.fish
    source /usr/share/cachyos-fish-config/cachyos-config.fish
end

# 3. GARANTE o Fastfetch em qualquer distro (Arch, Fedora, VM, etc)
# Só roda se o fastfetch estiver instalado e se NÃO estiver no CachyOS
# (para evitar que apareça duas vezes no CachyOS)
if command -q fastfetch
    if not test -f /usr/share/cachyos-fish-config/cachyos-config.fish
        fastfetch
    end
end

# Suas outras configs (starship, aliases, etc)
starship init fish | source
function up
    # 1. Inicia o agente SSH de forma silenciosa
    eval (ssh-agent -c) > /dev/null

    # 2. Copia a chave do seu Ventoy para a RAM (/tmp)
    # Certifique-se que o caminho do pendrive está correto (kauadev)
    cp /run/media/kauadev/Ventoy/.keys/id_ed25519 /tmp/id_tmp

    # 3. Ajusta a permissão para o SSH não reclamar
    chmod 600 /tmp/id_tmp

    # 4. Tenta adicionar a chave e realizar as operações de Git
    if ssh-add /tmp/id_tmp
        # Remove a chave temporária assim que ela entra na RAM
        rm /tmp/id_tmp

        echo "🚀 Iniciando Sync..."
        git add .
        git commit -m "update: notes"
        git push origin main

        # 5. Mata o agente SSH para limpar a memória
        ssh-agent -k > /dev/null
        echo "✅ Tudo no GitHub e RAM limpa!"
    else
        # Caso você erre a senha ou o pendrive não esteja lá
        rm /tmp/id_tmp
        ssh-agent -k > /dev/null
        echo "❌ Operação cancelada ou falha na autenticação."
    end
end
