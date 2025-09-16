# Script de Configuração de Ambiente de Desenvolvimento

Este script automatiza o processo de configuração de um ambiente de desenvolvimento no macOS, permitindo que você configure facilmente seu perfil de trabalho ou pessoal. Ele lida com a instalação de ferramentas essenciais, configuração de chaves SSH, personalização do shell ZSH com o tema Dracula, instalação de aplicativos via Homebrew e muito mais.

### Funcionalidades

- **Atualização do Bash:** Verifica se a versão do Bash é compatível (>= 4.0). Caso contrário, o script atualiza o Bash para a versão mais recente via Homebrew.
- **Verificação e Instalação de Dependências:**
  - Homebrew
  - `jq` (ferramenta para manipulação de JSON)
- **Instalação de Aplicativos:** Instala aplicativos listados no arquivo de configuração `config_{perfil}.json` via Homebrew Cask.
- **Node.js:** Instala a versão LTS do Node.js usando o NVM (Node Version Manager).
- **Docker & Colima:** Instala Docker e configura o Colima para uso com Docker em um ambiente macOS.
- **Configuração do ZSH com Dracula:** Personaliza o shell ZSH com o tema Dracula e instala plugins como `zsh-autosuggestions` e `zsh-syntax-highlighting`.
- **Geração de Chaves SSH:** Gera múltiplas chaves SSH conforme configurado no arquivo `config_{perfil}.json` e as adiciona ao agente SSH.
- **Configuração do Git:** Configura o nome de usuário, e-mail e editor do Git a partir do arquivo de configuração.

### Requisitos

- **macOS**
- **Homebrew** (será instalado automaticamente se não estiver presente)
- **jq** (será instalado automaticamente se não estiver presente)

### Como Usar

1. Faça o download do script.
2. Defina o perfil que você deseja configurar (`trabalho` ou `pessoal`) como argumento ao executar o script. Exemplo:
    ```bash
    ./setup.sh trabalho
    ```
3. O script irá:
   - Atualizar o Bash se necessário.
   - Verificar e instalar as dependências.
   - Instalar e configurar os aplicativos e ferramentas de acordo com o perfil selecionado.
4. Ao final, o perfil será configurado com sucesso, e você verá uma mensagem de conclusão.

### Arquivo de Configuração

O arquivo `config_{perfil}.json` é utilizado para definir quais aplicativos, configurações e chaves SSH serão aplicadas para o perfil selecionado. Ele deve estar no mesmo diretório do script e seguir o formato:

```json
{
    "apps": {
        "visual-studio-code": true,
        "intellij-idea": false,
        "mongodb-compass": true
    },
    "install_node": true,
    "install_docker": true,
    "configure_zsh": true,
    "ssh_keys": [
        {
            "name": "github",
            "email": "youremail@example.com",
            "keyname": "id_ed25519_github"
        }
    ],
    "configure_git": {
        "enabled": true,
        "name": "Seu Nome",
        "email": "youremail@example.com"
    }
}
