#!/usr/bin/env bash

# Cores
COR_RESET=$'\e[0m'
COR_VERDE=$'\e[1;32m'
COR_AMARELO=$'\e[1;33m'
COR_VERMELHO=$'\e[1;31m'

# Icones
ICONE="🔷"
SEPARADOR="━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
SUCESSO="✅"
ERRO="❌"
INFO="ℹ️"
ALERTA="⚠️"
VERIFICAR="🔍"
INSTALAR="⏳"
INSTALADO="📦"

# Funções
configurar_repos_terceiros() {
    # Verifica e instala/ativa repositórios de terceiros:
    # RPM Fusion (free, nonfree, tainted free, tainted nonfree),
    # COPR (dnf-plugins-core), Flathub (flatpak), OnlyOffice, Microsoft packages.
    local fedora_ver
    fedora_ver="$(rpm -E '%{fedora}')"

    local url_rpmf_free="https://download1.rpmfusion.org/free/fedora/rpmfusion-free-release-${fedora_ver}.noarch.rpm"
    local url_rpmf_nonfree="https://download1.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-${fedora_ver}.noarch.rpm"
    local url_rpmf_tainted_free="https://download1.rpmfusion.org/free/fedora/rpmfusion-free-release-tainted-${fedora_ver}.noarch.rpm"
    local url_rpmf_tainted_nonfree="https://download1.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-tainted-${fedora_ver}.noarch.rpm"

    local url_microsoft="https://packages.microsoft.com/config/fedora/${fedora_ver}/packages-microsoft-prod.rpm"
    local url_onlyoffice_repo="https://download.onlyoffice.com/repo/centos/onlyoffice.repo"
    local ok

    # helper: executar dnf install remoto com feedback
    instalar_remoto() {
        local src="$1" nome="$2"
        printf "%s %s%s %s%s\n" "$VERIFICAR" "${COR_AMARELO}" "Instalando repo:" "${COR_RESET}" "${nome}"
        if sudo dnf install -y "${src}" >/dev/null 2>&1; then
            printf "  %s %s%s%s\n" "$SUCESSO" "${COR_VERDE}" "OK:" "${COR_RESET} ${nome}"
            return 0
        else
            printf "  %s %s%s%s\n" "$ERRO" "${COR_VERMELHO}" "Falha:" "${COR_RESET} ${nome}"
            return 1
        fi
    }

    # RPM Fusion Free
    if rpm -q rpmfusion-free-release >/dev/null 2>&1; then
        printf "%s %s%s%s\n" "$INSTALADO" "${COR_VERDE}" "RPM Fusion Free já instalado." "${COR_RESET}"
    else
        instalar_remoto "${url_rpmf_free}" "RPM Fusion Free"
    fi

    # RPM Fusion Non-free
    if rpm -q rpmfusion-nonfree-release >/dev/null 2>&1; then
        printf "%s %s%s%s\n" "$INSTALADO" "${COR_VERDE}" "RPM Fusion Non-free já instalado." "${COR_RESET}"
    else
        instalar_remoto "${url_rpmf_nonfree}" "RPM Fusion Non-free"
    fi

    # RPM Fusion Tainted Free
    if rpm -q rpmfusion-free-release-tainted >/dev/null 2>&1; then
        printf "%s %s%s%s\n" "$INSTALADO" "${COR_VERDE}" "RPM Fusion Free (tainted) já instalado." "${COR_RESET}"
    else
        instalar_remoto "${url_rpmf_tainted_free}" "RPM Fusion Free (tainted)"
    fi

    # RPM Fusion Tainted Non-free
    if rpm -q rpmfusion-nonfree-release-tainted >/dev/null 2>&1; then
        printf "%s %s%s%s\n" "$INSTALADO" "${COR_VERDE}" "RPM Fusion Non-free (tainted) já instalado." "${COR_RESET}"
    else
        instalar_remoto "${url_rpmf_tainted_nonfree}" "RPM Fusion Non-free (tainted)"
    fi

    # COPR
    repos_copr=("kylegospo/webapp-manager" "aquacash5/nerd-fonts")

    for repo in "${repos_copr[@]}"; do
        if dnf copr list | grep -qw "$repo"; then
            printf "%s %s%s%s\n" "$INSTALADO" "${COR_VERDE}" "Repositório COPR '$repo' já habilitado." "${COR_RESET}"
        else
            sudo dnf -y copr enable "$repo"
        fi
    done

    # Flathub (flatpak remote)
    if command -v flatpak >/dev/null 2>&1; then
        if flatpak remote-list --columns=name | grep -i -q '^flathub$'; then
            printf "%s %s%s%s\n" "$INSTALADO" "${COR_VERDE}" "Flathub já configurado." "${COR_RESET}"
        else
            printf "%s %s%s %s%s\n" "$VERIFICAR" "${COR_AMARELO}" "Adicionando:" "${COR_RESET}" "Flathub"
            if sudo flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo >/dev/null 2>&1; then
                printf "  %s %s%s%s\n" "$SUCESSO" "${COR_VERDE}" "Adicionado:" "${COR_RESET} Flathub"
            else
                printf "  %s %s%s%s\n" "$ERRO" "${COR_VERMELHO}" "Falha ao adicionar Flathub." "${COR_RESET}"
            fi
        fi
    else
        printf "%s %s%s%s\n" "$ALERTA" "${COR_AMARELO}" "flatpak não encontrado. Pule Flathub." "${COR_RESET}"
    fi

    # Visual Studio Code repo
    if [ -f /etc/yum.repos.d/vscode.repo ]; then
        printf "%s %s%s%s\n" "$INSTALADO" "${COR_VERDE}" "vscode.repo já configurado." "${COR_RESET}"
    else
        printf "%s %s%s %s%s\n" "$VERIFICAR" "${COR_AMARELO}" "Adicionando repo:" "${COR_RESET}" "Visual Studio Code"
        if sudo tee /etc/yum.repos.d/vscode.repo >/dev/null <<'EOF'
[code]
name=Visual Studio Code
baseurl=https://packages.microsoft.com/yumrepos/vscode
enabled=1
gpgcheck=1
gpgkey=https://packages.microsoft.com/keys/microsoft.asc
EOF
        then
            printf "  %s %s%s%s\n" "$SUCESSO" "${COR_VERDE}" "vscode.repo criado." "${COR_RESET}"
        else
            printf "  %s %s%s%s\n" "$ERRO" "${COR_VERMELHO}" "Falha ao criar vscode.repo." "${COR_RESET}"
        fi
    fi
}

info_sistema() {
    local ARQUITETURA KERNEL VERSAO_FEDORA DISTRO_PRETTY

    ARQUITETURA=$(uname -m)
    KERNEL=$(uname -r)
    VERSAO_FEDORA=$(versao_fedora)

    printf "%s" "$SEPARADOR"
    printf "\n${COR_VERDE}%s %s${COR_RESET}\n" "$ICONE" "Informações do sistema"
    printf "%s\n\n" "$SEPARADOR"
    printf "  %s %s%s%s\n" "🖥️ " "${COR_VERDE}Fedora:${COR_RESET}" " " "${VERSAO_FEDORA}"
    printf "  %s %s%s%s\n" "🐧" "${COR_VERDE}Kernel:${COR_RESET}" " " "${KERNEL}"
    printf "  %s %s%s%s\n" "🧩" "${COR_VERDE}Arquitetura:${COR_RESET}" " " "${ARQUITETURA}"
    printf "\n%s\n\n" "$SEPARADOR"
    }

inserir_texto() {
    local caminho="$1"
    local texto="$2"

    # Verifica se o arquivo existe; se não, cria
    if [ ! -f "$caminho" ]; then
        printf "%s %s%s %s%s\n" "$VERIFICAR" "${COR_AMARELO}" "Verificando arquivo " "$caminho" "${COR_RESET}"
    fi

    # Verifica se o texto já existe no arquivo
    if grep -Fxq "$texto" "$caminho"; then
        printf "%s %s%s %s%s\n" "$INSTALADO" "${COR_VERDE}" "Arquivo já está configurado: " "$caminho" "${COR_RESET}"
    else
        echo "$texto" >> "$caminho"
        printf "%s %s%s %s%s\n" "$SUCESSO" "${COR_VERDE}" "Arquivo " "$caminho" "${COR_RESET}"
    fi
}

instalar_flatpak() {
    # Uso: verificar_instalar_flatpak app.id.one app.id.two ...
    # Pode sobrescrever remoto/modo com as env vars: FLATPAK_REMOTE, FLATPAK_MODE
    local remoto="flathub"
    local modo="${FLATPAK_MODE:-user}"
    local app
    local falhas=0

    if [ $# -eq 0 ]; then
        printf "%s %s%s%s\n" "$ERRO" "${COR_VERMELHO}" "Nenhum app Flatpak informado." "${COR_RESET}"
        return 1
    fi

    if ! command -v flatpak >/dev/null 2>&1; then
        printf "%s %s%s%s\n" "$ERRO" "${COR_VERMELHO}" "flatpak não encontrado." "${COR_RESET}"
        return 2
    fi

    for app in "$@"; do
        printf "%s %s%s %s%s\n" "$VERIFICAR" "${COR_AMARELO}" "Verificando Flatpak:" "${COR_RESET}" "${app}"

        if flatpak list --app --columns=application 2>/dev/null | grep -Fxq "$app"; then
            printf "  %s %s%s%s\n" "$INSTALADO" "${COR_VERDE}" "Flatpak já instalado:" "${COR_RESET} ${app}"
            continue
        fi

        printf "%s %s%s %s%s\n" "$INSTALAR" "${COR_AMARELO}" "Instalando Flatpak:" "${COR_RESET}" "${app}"
        if [ "$modo" = "system" ]; then
            if flatpak install -y "${remoto}" "${app}" >/dev/null 2>&1; then
                printf "  %s %s%s%s\n" "$SUCESSO" "${COR_VERDE}" "Instalado (system):" "${COR_RESET} ${app}"
            else
                printf "  %s %s%s%s\n" "$ERRO" "${COR_VERMELHO}" "Falha ao instalar (system):" "${COR_RESET} ${app}"
            fi
        else
            if flatpak install -y "${remoto}" "${app}" >/dev/null 2>&1; then
                printf "  %s %s%s%s\n" "$SUCESSO" "${COR_VERDE}" "Instalado:" "${COR_RESET} ${app}"
            else
                printf "  %s %s%s%s\n" "$ERRO" "${COR_VERMELHO}" "Falha ao instalar:" "${COR_RESET} ${app}"
            fi
        fi
    done

    printf "\n%s\n\n" "$SEPARADOR"
    return 0
}

instalar_rpm() {
    local pacote="$1"

    if [ -z "$pacote" ]; then
        printf "%s %s%s%s\n" "$ERRO" "${COR_VERMELHO}" "Nenhum pacote informado." "${COR_RESET}"
        return 1
    fi

    if ! command -v dnf >/dev/null 2>&1; then
        printf "%s %s%s%s\n" "$ERRO" "${COR_VERMELHO}" "dnf não encontrado." "${COR_RESET}"
        return 2
    fi

    printf "%s %s%s %s%s\n" "$INSTALAR" "${COR_AMARELO}" "Instalando:" "${COR_RESET}" "${pacote}"
    if sudo dnf install -y "${pacote}"; then
        printf "  %s %s%s%s\n" "$SUCESSO" "${COR_VERDE}" "Instalado:" "${COR_RESET} ${pacote}"
        return 0
    else
        printf "  %s %s%s%s\n" "$ERRO" "${COR_VERMELHO}" "Falha ao instalar:" "${COR_RESET} ${pacote}"
        return 3
    fi
}

instalar_rpm_lote() {
    # Recebe lista de pacotes; para cada pacote: verifica com verificar_pacote_rpm
    # e se não estiver instalado chama instalar_rpm <pacote>
    local pacote instalados=0 falhas=0 total=0

    if [ $# -eq 0 ]; then
        printf "%s %s%s%s\n" "$ERRO" "${COR_VERMELHO}" "Nenhum pacote informado." "${COR_RESET}"
        return 1
    fi

    for pacote in "$@"; do
        total=$((total+1))
        printf "%s %s%s %s%s\n" "$VERIFICAR" "${COR_AMARELO}" "Verificando:" "${COR_RESET}" "${pacote}"

        if verificar_pacote_rpm "$pacote"; then
            printf "  %s %s%s%s\n" "$INSTALADO" "${COR_VERDE}" "Já instalado:" "${COR_RESET} ${pacote}"
            continue
        fi

        printf "  %s %s%s %s%s\n" "$INSTALAR" "${COR_AMARELO}" "Instalando:" "${COR_RESET}" "${pacote}"
        if instalar_rpm "$pacote"; then
            instalados=$((instalados+1))
        else
            falhas=$((falhas+1))
        fi
    done

    printf "\n%s\n\n" "$SEPARADOR"
    return 0
}

remover_pacote_rpm() {
    local pacote="$1"

    if [ -z "$pacote" ]; then
        printf "%s %s%s%s\n" "$ERRO" "${COR_VERMELHO}" "Nenhum pacote informado." "${COR_RESET}"
        return 1
    fi

    printf "%s %s%s %s%s\n" "$INSTALAR" "${COR_AMARELO}" "Removendo:" "${COR_RESET}" "${pacote}"
    if sudo dnf remove -y "${pacote}"; then
        printf "  %s %s%s%s\n" "$SUCESSO" "${COR_VERDE}" "Removido:" "${COR_RESET} ${pacote}"
        return 0
    else
        printf "  %s %s%s%s\n" "$ERRO" "${COR_VERMELHO}" "Falha ao remover:" "${COR_RESET} ${pacote}"
        return 2
    fi
}

trocar_shell() {
    # Obtém o shell padrão atual
    shell_atual=$(getent passwd "$USER" | cut -d: -f7)

    # Caminho completo do fish
    fish_path=$(command -v fish)

    # Verifica se já é o shell padrão
    if [ "$shell_atual" = "$fish_path" ]; then
        printf "  %s %s%s%s\n" "$INSTALADO" "${COR_VERDE}" "O shell padrão já é o 'fish'" "${COR_RESET}"

    else
        printf "\U0001f504 Alterando o shell padrão de '$shell_atual' para '$fish_path'...\n"
        chsh -s "$fish_path"
        if [ $? -eq 0 ]; then
            printf "  %s %s%s%s\n" "$SUCESSO" "${COR_VERDE}" "Shell padrão alterado com sucesso para 'fish'!" "${COR_RESET}"
        else
            printf "  %s %s%s%s\n" "$ERRO" "${COR_VERMELHO}" "Falha ao alterar o shell. Verifique se você tem permissão para usar o comando 'chsh'." "${COR_RESET}"
        fi
    fi
}

verificar_pacote_rpm() {
    local pacote="$1"

     # uso incorreto
    if [ -z "$pacote" ]; then
        return 2
    fi

    # verifica via rpm
    if rpm -q --quiet "$pacote" >/dev/null 2>&1; then
        return 0
    fi

    return 1
}

verificar_remover_lote() {
    local pacote removidos=0

    if [ $# -eq 0 ]; then
        printf "%s %s%s%s\n" "$ERRO" "${COR_VERMELHO}" "Nenhum pacote informado." "${COR_RESET}"
        return 1
    fi

    for pacote in "$@"; do
        printf "%s %s%s %s%s\n" "$VERIFICAR" "${COR_AMARELO}" "Verificando:" "${COR_RESET}" "${pacote}"
        if verificar_pacote_rpm "$pacote"; then
            printf "  %s %s%s%s\n" "$INSTALADO" "${COR_VERDE}" "Instalado:" "${COR_RESET} ${pacote}"
            remover_pacote_rpm "$pacote"
            if [ $? -eq 0 ]; then
                removidos=$((removidos+1))
            else
                printf "  %s %s%s%s\n" "$ERRO" "${COR_VERMELHO}" "Falha ao remover:" "${COR_RESET} ${pacote}"
            fi
        else
            printf "  %s %s%s%s\n" "$INFO" "${COR_AMARELO}" " Não está instalado:" "${COR_RESET} ${pacote}"
        fi
    done
    printf "\n%s\n\n" "$SEPARADOR"
    return 0
}

versao_fedora() {
    fed=$(rpm -E '%{fedora}' 2>/dev/null) || fed="?"
    if [ -z "$fed" ]; then
        fed=$(awk '/Fedora/{print $3; exit}' /etc/fedora-release 2>/dev/null || echo "?")
    fi
    echo "$fed"
}


# Informações do Sistema
info_sistema

# Remover programas não utilizados
verificar_remover_lote okular nheko libreoffice

# Configurar repositórios
configurar_repos_terceiros
sudo dnf check-update
sudo dnf upgrade -y --refresh
flatpak update --appstream

# Instalar pacotes rpm
instalar_rpm_lote cabextract code curl fish fira-code-nerd-fonts git onlyoffice-desktopeditors xorg-x11-font-utils unzip

instalar_flatpak com.bitwarden.desktop com.microsoft.Teams org.onlyoffice.desktopeditors

#Configurar fish com oh-my-posh
trocar_shell "$USER"

curl -s https://ohmyposh.dev/install.sh | bash -s

if [ ! -d "$HOME/.config/oh-my-posh/themes" ]; then
    mkdir -p "$HOME/.config/oh-my-posh/themes"
    cp -f theme/oh-my-posh/blue-owl.omp.json $HOME/.config/oh-my-posh/themes/blue-owl.omp.json
fi

inserir_texto "$HOME/.config/fish/config.fish" "$HOME/.local/bin/oh-my-posh init fish --config $HOME/.config/oh-my-posh/themes/blue-owl.omp.json | source"

