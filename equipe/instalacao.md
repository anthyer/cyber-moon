# Instalação do ambiente

Passo a passo para sair do zero até conseguir rodar o jogo e trabalhar com o agente.

## 1. Godot 4.7

O projeto usa Godot 4.7, renderizador GL Compatibility, física Jolt. Versão diferente de
4.x pode abrir o projeto e reimportar tudo, gerando um diff enorme e inútil. Confira a
versão antes de abrir.

Na máquina do Antonio o Godot é flatpak, e o caminho do executável é
`/var/lib/flatpak/exports/bin/org.godotengine.Godot`. Instalação por flatpak:

```bash
flatpak install flathub org.godotengine.Godot
```

Se você instalar de outro jeito (binário do site, pacote da distro, Windows), descubra o
caminho do executável e guarde, porque o passo 3 precisa dele.

Teste rápido, que também importa os assets:

```bash
GODOT=<caminho do seu executavel>
"$GODOT" --headless --path game --import
"$GODOT" --path game
```

O jogo tem que abrir na cena do playground com o personagem no meio do mapa.

## 2. Clonar e abrir

```bash
git clone <url do repositorio> cyber-moon
cd cyber-moon
```

O projeto Godot fica em `game/`, não na raiz. Ao abrir pelo gerenciador de projetos do
Godot, aponte para `game/`, não para a pasta do repositório.

## 3. O servidor MCP do Godot

O MCP é o que deixa o agente rodar o jogo, ler o console de erro e parar o processo
sozinho, sem você ficar copiando log na mão. Ele já vem configurado no `.mcp.json`
versionado na raiz do repositório, então não tem nada para instalar manualmente: na
primeira vez que você abrir o agente na pasta do projeto, ele vai perguntar se você
confia no servidor MCP do projeto. Aceite.

O `.mcp.json` está assim:

```json
{
  "mcpServers": {
    "godot": {
      "type": "stdio",
      "command": "npx",
      "args": ["-y", "@coding-solo/godot-mcp"],
      "env": {
        "GODOT_PATH": "/var/lib/flatpak/exports/bin/org.godotengine.Godot"
      }
    }
  }
}
```

**Se o seu Godot não for flatpak, mude o `GODOT_PATH`** para o caminho do seu
executável. Essa é a única linha que provavelmente precisa mudar na sua máquina.

Precisa ter Node.js instalado, porque o servidor roda via `npx`. Confira com
`node --version`. Qualquer versão LTS recente serve.

Para checar se funcionou, peça ao agente para rodar o projeto. Se ele conseguir subir o
jogo e depois te dizer o que apareceu no console, está tudo certo.

## 4. Nada a instalar para o corte de áudio

O `ferramentas/dividir_passos.py` corta um clipe com vários passos em arquivos separados
usando só a biblioteca padrão do Python, sem ffmpeg e sem pacote extra. Se `python3
--version` responde, está pronto.

Ele aceita `.wav` PCM de 8, 16 ou 32 bits, mono ou estéreo. Se o seu clipe vier em `.mp3`
ou em `.wav` de 24 bits, converta para `.wav` de 16 bits antes, em qualquer editor de
áudio (o Audacity resolve, e você vai querer ele instalado de qualquer forma para conferir
os cortes de ouvido).

## 5. Epidemic Sound, se for o caso

**Pergunta para você responder antes de começar o plano 02: você usa Epidemic Sound?**

Se usa, dá para conectar a plataforma ao agente por MCP e passar a buscar, ouvir e
baixar trilha e efeito direto pela conversa, em vez de garimpar no site e baixar na mão.
Isso vale muito a pena para a música de estação e para os ambientes, que são muitos
arquivos.

Como o catálogo de servidores MCP muda com o tempo, o caminho é: procure pelo servidor
MCP oficial da Epidemic Sound, ou por um cliente da API deles, e peça ao agente para te
guiar na configuração. O formato é o mesmo do bloco acima: mais uma entrada dentro de
`mcpServers` no `.mcp.json`, com a credencial da sua conta.

**Não coloque credencial no `.mcp.json` versionado.** Ela iria para o repositório junto.
Use uma variável de ambiente da sua máquina e referencie ela, ou configure esse servidor
no escopo do usuário em vez do escopo do projeto.

Se você não usa Epidemic Sound, ignore este passo. O plano 02 funciona igual, você só vai
providenciar os arquivos de outra fonte.

## 6. OBS, para o vídeo

Só depois de terminar os planos 01 e 02. Veja `gravacao-de-video-obs.md`.

## Checklist final

- [ ] `godot --version` mostra 4.7
- [ ] `godot --path game` abre o jogo e o personagem anda com WASD
- [ ] `node --version` responde
- [ ] o agente consegue rodar o jogo e ler o console pelo MCP
- [ ] você respondeu a pergunta do Epidemic Sound
