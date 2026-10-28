# Cyber Moon, demo para navegador

Esta pasta é o jogo pronto para a web. Basta copiar a pasta inteira para qualquer
servidor web (Apache, nginx, IIS, o servidor da rede do campus) e abrir o `index.html`
pelo endereço do servidor.

## O que o servidor precisa

- Servir arquivos estáticos por HTTP ou HTTPS. Não há banco de dados nem programa rodando
  no servidor.
- Entregar o `index.wasm` com o tipo `application/wasm`. Servidores atuais já fazem isso.
  Num Apache antigo que não faça, acrescente no `.htaccess` da pasta:

      AddType application/wasm .wasm

- Nada mais. A build foi exportada sem threads, então não precisa dos cabeçalhos
  especiais (COOP e COEP) que algumas builds de Godot pedem.

Abrir o `index.html` direto do disco (dando dois cliques) não funciona: o navegador
bloqueia o carregamento do jogo fora de um servidor. Para testar numa máquina só:

    cd build/web
    python3 -m http.server 8000

e abra http://localhost:8000 no navegador.

## Tamanho e navegadores

São cerca de 63 MB, baixados uma vez no primeiro acesso. Funciona em Chrome, Edge e
Firefox atuais, em computador. O som começa depois do primeiro clique na página, que é
regra dos navegadores.

## Como gerar de novo

A partir do projeto em `game/`, com os templates de exportação do Godot 4.7.2 instalados:

    godot --headless --path game --export-release "Web" ../build/web/index.html

O preset "Web" está em `game/export_presets.cfg`.
