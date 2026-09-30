# Lembretes

Coisas que não cabem em nenhum plano ainda, mas que não podem se perder. Cada lembrete
diz o que falta, por que importa e por onde começar. Quando um lembrete virar plano em
`equipe/planos/`, apague daqui e aponte para o plano.

---

## Áudio: mais recursos sonoros e mais precisão

Anotado em 2026-09-29.

**O que falta.** O sistema de som (plano 02) está de pé, mas com pouco conteúdo e pouca
precisão:

- Passos: só existem três clipes de verdade (`footstep_grass_1`, `footstep_grass_2`,
  `footstep_concrete`) e um de água. Em `resources/audio/passos_padrao.tres`, `terra`
  reaproveita os clipes de grama e `pedra`, `asfalto`, `madeira` e `metal` tocam todos o
  mesmo `footstep_concrete.wav`. Cada superfície precisa do próprio conjunto, com duas ou
  mais variações para não soar repetido.
- A detecção de superfície depende da metadata `superficie` gravada pelo
  `post_import_kenney.gd` e de trechos do nome do nó. Há casos em que o som não bate com
  o chão pisado (histórico de commits de ajuste em grama e água mostra isso). Vale revisar
  a regra de detecção antes de colocar mais clipes em cima.
- O passo dispara pela fase do clipe de animação (`passos_do_jogador.gd`), mas as fases
  de contato foram estimadas. Conferir quadro a quadro em `walk` e `sprint` para
  o som cair exatamente quando o pé toca o chão.
- Ainda não existe: som de ambiente (o bus `Ambiente` está vazio), música por estação e
  por clima (o sinal `musica_solicitada` já espera por isso), som de interface, de
  combate e de passo de NPC e inimigo. A lista completa está no fim de
  `equipe/planos/02-som.md`.
- Os efeitos de ferramenta (`hoe`, `pickaxe`, `watering_can`, `punch`) e a colisão têm
  um clipe só cada.

**Como foi feito até aqui.** Os clipes vieram da plataforma **Epidemic Sound**. A
Epidemic Sound tem um servidor MCP oficial, que permite buscar, ouvir e baixar trilha e
efeito sem garimpar no site e baixar na mão. Ele ainda não está configurado no projeto
(o `.mcp.json` só tem o servidor do Godot). O passo a passo e o cuidado com credencial
estão em `equipe/instalacao.md`, seção 5. Resumo do cuidado: a chave da conta nunca vai
no `.mcp.json` versionado, fica em variável de ambiente ou no escopo do usuário.

**Por onde começar.** Configurar o MCP da Epidemic Sound, depois montar a lista de clipes
por superfície e por evento, e só então baixar. Arquivo novo segue
`pipeline_de_assets.md`: `.wav` para efeito curto em `assets/audio/sfx/`, `.ogg` para
música e ambiente em `assets/audio/music/`.

---

## Modelos 3D: refinar e puxar para o cyberpunk

Anotado em 2026-09-29.

**O que falta.** Toda a arte 3D vem de pacotes da Kenney (`city_kit_commercial`,
`city_kit_industrial`, `city_kit_roads`, `city_kit_suburban`, `cube_pets`,
`mini_characters` e `nature_kit`). Eles são limpos e consistentes entre si, mas o visual
é de cidade e fazenda comuns, com paleta clara e estilizada. Nada ali lê como
cyberpunk.

**Caminhos possíveis**, do mais barato ao mais caro:

- Material e iluminação: emissivo em janelas, placas e bordas, paleta mais escura
  com neon (ciano, magenta), céu noturno, névoa. O `post_import_kenney.gd` já é o ponto
  único que mexe em material na importação, então uma troca de paleta pode morar ali.
- Adereços de tema por cima dos modelos existentes: letreiros, cabos, antenas, painéis,
  hologramas simples.
- Substituir ou criar modelos próprios para as peças que mais aparecem (casa do
  jogador, plantação, personagem principal, que continua sendo um modelo da Kenney).

**Cuidado.** Qualquer pacote novo precisa passar pelo mesmo `import_script/path` descrito
em `pipeline_de_assets.md`, senão herda o metálico em 1.0 e fica sem colisão.
