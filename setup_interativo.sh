#!/usr/bin/env bash

# -------- Atualiza o Bash se for versão antiga --------

BASH_VERSION_MAJOR=$(echo "$BASH_VERSION" | cut -d. -f1)

if [ "$BASH_VERSION_MAJOR" -lt 4 ]; then
  echo "🔁 Atualizando Bash para versão moderna via Homebrew..."
  brew install bash

  if [ -x "/usr/local/bin/bash" ]; then
    echo "✅ Novo Bash instalado em /usr/local/bin/bash. Reexecutando script..."
    exec /usr/local/bin/bash "$0" "$@"
  else
    echo "❌ Novo Bash não encontrado. Abortando."
    exit 1
  fi
fi

# -------- Verifica perfil --------

if [ -z "$1" ]; then
    echo "❗ Uso: $0 [trabalho|pessoal]"
    exit 1
fi

PERFIL="$1"
CONFIG_FILE="config_${PERFIL}.json"

if [ ! -f "$CONFIG_FILE" ]; then
    echo "❌ Arquivo de configuração '$CONFIG_FILE' não encontrado."
    exit 1
fi

# -------- Funções --------

print_titulo() {
    echo ""
    echo "======================================"
    echo "🔧 $1"
    echo "======================================"
}

# -------- Verifica brew e jq --------

print_titulo "🔍 Verificações iniciais"

if ! command -v brew &> /dev/null; then
    echo "🍺 Instalando Homebrew..."
    NONINTERACTIVE=1 /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    eval "$(/opt/homebrew/bin/brew shellenv)"
else
    echo "✅ Homebrew já instalado."
fi

if ! command -v jq &> /dev/null; then
    echo "📦 Instalando jq..."
    brew install jq
fi

brew update

# -------- Instala apps --------

print_titulo "📦 Instalando aplicativos"

declare -A app_map=(
    ["visual-studio-code"]="visual-studio-code"
    ["intellij-idea"]="intellij-idea"
    ["mongodb-compass"]="mongodb-compass"
    ["dbeaver-community"]="dbeaver-community"
    ["cursor"]="cursor"
    ["google-chrome"]="google-chrome"
    ["postman"]="postman"
)

for app_key in "${!app_map[@]}"; do
    enabled=$(jq -r ".apps.\"$app_key\"" "$CONFIG_FILE")
    if [ "$enabled" = "true" ]; then
        echo "➡️ Instalando ${app_map[$app_key]}"
        brew install --cask "${app_map[$app_key]}"
    else
        echo "⏭ Pulando ${app_map[$app_key]}"
    fi
done

# -------- Node.js com NVM --------

if [ "$(jq -r '.install_node' "$CONFIG_FILE")" = "true" ]; then
    print_titulo "🟩 Instalando Node.js via NVM"
    if [ ! -d "$HOME/.nvm" ]; then
        curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.5/install.sh | bash
        echo 'export NVM_DIR="$HOME/.nvm"' >> ~/.zshrc
        echo '[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"' >> ~/.zshrc
        source ~/.zshrc
    fi
    export NVM_DIR="$HOME/.nvm"
    [ -s "$NVM_DIR/nvm.sh" ] && source "$NVM_DIR/nvm.sh"
    nvm install --lts
    nvm use --lts
fi

# -------- Docker + Colima --------

if [ "$(jq -r '.install_docker' "$CONFIG_FILE")" = "true" ]; then
    print_titulo "🐳 Instalando Docker + Colima"
    brew install docker docker-compose colima
    colima start --cpu 4 --memory 4 --disk 60 --mount-type=virtiofs --runtime docker
    docker info > /dev/null 2>&1 && echo "✅ Docker funcionando com Colima" || echo "❌ Docker não respondeu"
fi

# -------- ZSH + Dracula --------

if [ "$(jq -r '.configure_zsh' "$CONFIG_FILE")" = "true" ]; then
    print_titulo "💅 Configurando ZSH com Dracula"
    if [ ! -d "$HOME/.oh-my-zsh" ]; then
        sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
    fi

    git clone https://github.com/dracula/zsh.git "$HOME/.oh-my-zsh/custom/themes/dracula" 2>/dev/null
    sed -i '' 's/ZSH_THEME=.*/ZSH_THEME="dracula"/' ~/.zshrc

    brew install zsh-autosuggestions zsh-syntax-highlighting

    grep -qxF "source /opt/homebrew/share/zsh-autosuggestions/zsh-autosuggestions.zsh" ~/.zshrc || echo "source /opt/homebrew/share/zsh-autosuggestions/zsh-autosuggestions.zsh" >> ~/.zshrc
    grep -qxF "source /opt/homebrew/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh" ~/.zshrc || echo "source /opt/homebrew/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh" >> ~/.zshrc

    source ~/.zshrc
fi

# -------- Múltiplas chaves SSH --------

ssh_keys=$(jq -c '.ssh_keys[]?' "$CONFIG_FILE")
if [ -n "$ssh_keys" ]; then
    print_titulo "🔐 Gerando múltiplas chaves SSH"
    mkdir -p ~/.ssh
    touch ~/.ssh/config

    while IFS= read -r key_config; do
        name=$(echo "$key_config" | jq -r '.name')
        email=$(echo "$key_config" | jq -r '.email')
        keyname=$(echo "$key_config" | jq -r '.keyname')
        keypath="$HOME/.ssh/$keyname"

        if [ -f "$keypath" ]; then
            echo "✅ Chave '$keyname' já existe."
        else
            echo "🔑 Criando chave: $keyname ($email)"
            ssh-keygen -t ed25519 -C "$email" -f "$keypath" -N ""
            eval "$(ssh-agent -s)"
            ssh-add --apple-use-keychain "$keypath"

            cat <<EOT >> ~/.ssh/config

Host $name
  HostName github.com
  User git
  IdentityFile ~/.ssh/$keyname
  AddKeysToAgent yes
  UseKeychain yes
EOT
        fi

        echo "📋 Chave pública '$name':"
        cat "${keypath}.pub"
        echo ""
    done <<< "$ssh_keys"
else
    echo "⏭ Nenhuma chave SSH configurada."
fi

# -------- Configuração do Git --------

if [ "$(jq -r '.configure_git.enabled' "$CONFIG_FILE")" = "true" ]; then
    print_titulo "⚙️ Configurando Git"
    git_name=$(jq -r '.configure_git.name' "$CONFIG_FILE")
    git_email=$(jq -r '.configure_git.email' "$CONFIG_FILE")

    git config --global user.name "$git_name"
    git config --global user.email "$git_email"
    git config --global init.defaultBranch main
    git config --global core.editor "code --wait"
fi

echo ""
echo "🎉 Setup do perfil '$PERFIL' concluído com sucesso!"

