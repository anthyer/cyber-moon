# Documento de Design de Jogo

Revisão: 0.0.1

- Visão Geral
  - Tema / Cenário / Gênero
  - Mecânicas Principais (Resumo)
  - Plataformas-alvo
  - Modelo de Monetização (Resumo/Documento)
  - Escopo do Projeto
  - Influências (Resumo)
    - Stardew Valley
    - Cyberpunk 2077
    - Rune Factory
    - Harvest Moon
  - O Pitch de Elevador
  - Descrição do Projeto (Resumo)
  - Descrição do Projeto (Detalhada)
- O que diferencia este projeto?
  - Mecânicas Principais (Detalhadas)
    - Coleta de Recursos e Fazenda
    - Ciclo de Dias
    - Combate RPG
    - Sistema de Relacionamento
- História e Gameplay
  - História (Resumo)
  - História (Detalhada)
  - Gameplay (Resumo)
  - Gameplay (Detalhado)
- Assets Necessários
  - 2D
  - 3D
  - Som
  - Código
  - Animação
- Cronograma
  - Prototipagem
  - Desenvolvimento Principal
  - Testes e Polimento
  - Entrega Final


# Visão Geral


## Tema / Cenário / Gênero

Um mundo distópico de estética cyberpunk onde campos e natureza ainda resistem à expansão urbana implacável. O jogador assume o papel de um fazendeiro que precisa cultivar a terra, coletar recursos e proteger sua propriedade enquanto a cidade avança. O gênero é uma mistura de simulação de fazenda, RPG e narrativa com progressão baseada em marcos.

## Mecânicas Principais (Resumo)

  - Coleta de recursos e cultivo da fazenda
  - Ciclo de dias com progressão de tempo
  - Combate RPG simples
  - Sistema de relacionamento com NPCs

## Plataformas-alvo
  - WebGL
  - Android (Implementação futura)

## Modelo de Monetização (Resumo/Documento)
  - Projeto acadêmico - sem monetização planejada no momento

## Escopo do Projeto
  - Escala de Tempo do Jogo
    - Custo: Projeto sem fins lucrativos (acadêmico)
    - Prazo estimado: Um semestre letivo
  - Tamanho da Equipe
    - Equipe Principal
      - Antonio Marcos da Silva
        - Desenvolvimento e design
        - Sem custo (trabalho voluntário/acadêmico)
      - Bernardo Silva Bombazaro
        - Desenvolvimento e design
        - Sem custo (trabalho voluntário/acadêmico)
    - Equipe de Marketing
      - Não aplicável (projeto acadêmico)
    - Licenças / Hardware / Outros Custos
      - Motor gráfico: Godot engine (Open-source)
    - Custo Total: sem custo financeiro previsto

## Influências (Resumo)
  - Stardew Valley
    - Mídia: Jogo
    - Principal referência de loop de gameplay: cultivo, ciclo de dias, interação com NPCs e progressão da fazenda. A estrutura de progressão por marcos foi diretamente inspirada neste jogo.
  - Cyberpunk 2077
    - Mídia: Jogo
    - Referência estética e temática. O universo distópico, a tensão entre natureza e tecnologia e a atmosfera neon do mundo cyberpunk são fortemente inspirados neste título.
  - Rune Factory
    - Mídia: Jogo
    - Referência para a integração de combate RPG dentro de um jogo de fazendinha. A ideia de unir combate e simulação de fazenda vem deste jogo.
  - Harvest Moon
    - Mídia: Jogo
    - Precursor clássico do gênero fazendinha. Referência para o sistema de relacionamento, ciclo de dias e o sentimento nostálgico que o jogo busca evocar.

## O Pitch de Elevador

Um fazendeiro luta para salvar seus campos da expansão de uma metrópole cyberpunk - cultivando, combatendo e forjando laços com os últimos habitantes da fronteira entre a cidade e a natureza.

## Descrição do Projeto (Resumo):

CyberMoon é um jogo de simulação de fazenda com temática cyberpunk, onde o jogador deve cultivar recursos, gerenciar o tempo e construir relacionamentos para sobreviver em um mundo onde a cidade consome tudo ao redor. A progressão da história é travada por marcos de recursos acumulados, criando uma tensão constante entre o ritmo tranquilo da fazenda e as ameaças externas.

O jogo combina mecânicas clássicas de fazendinha - como o ciclo de dias e o sistema de relacionamento - com elementos de RPG simples, incluindo combate, em um cenário distópico de visual neon e cell shading.

## Descrição do Projeto (Detalhada)

CyberMoon é ambientado em um futuro distópico onde megacidades avançam sem controle sobre territórios naturais. O jogador interpreta um fazendeiro que herda um pedaço de terra nos campos que ainda resistem à expansão urbana. Seu objetivo central é evoluir a fazenda e, ao mesmo tempo, barrar o avanço da cidade sobre os campos que ainda restam.

A progressão da história é desbloqueada conforme o jogador acumula recursos e atinge marcos específicos - quanto mais a fazenda prospera, mais a narrativa avança e novos desafios surgem. Isso cria uma sensação orgânica de evolução, onde o esforço do jogador tem impacto direto no mundo ao redor.

O jogo adota uma câmera top-down com renderização 3D simples e cell shading, garantindo uma identidade visual marcante que une a estética nostálgica das fazendinhas clássicas com o visual neon e futurista do universo cyberpunk. A jogabilidade é acessível, mas com profundidade suficiente para manter o engajamento a longo prazo.

Além do cultivo, o jogador pode interagir com NPCs habitantes da região, construindo relacionamentos que influenciam a narrativa e oferecem recompensas. O combate RPG simples aparece em situações de conflito com ameaças da cidade, adicionando variedade ao loop de gameplay sem sobrecarregar o jogador com sistemas complexos.

# O que diferencia este projeto?
  - Fusão de fazendinha clássica com estética cyberpunk distópica
  - Progressão narrativa travada por marcos de recursos acumulados
  - Combate RPG integrado ao loop de simulação de fazenda
  - Tensão temática entre natureza e expansão urbana como eixo central da história
  - Visual diferenciado com câmera top-down e 3D simples

## Mecânicas Principais (Detalhadas)
  - Coleta de Recursos e Cultivo da Fazenda
    - Detalhes: O jogador coleta recursos do ambiente (minerais, plantas, itens tecnológicos) e os utiliza para cultivar e expandir sua fazenda. Os recursos também desbloqueiam marcos de progressão na história.
    - Como funciona: O jogador interage com o ambiente usando ferramentas, planta e colhe culturas em ciclos, e processa recursos para criar itens mais avançados. A fazenda cresce conforme o jogador investe tempo e recursos nela.
  - Ciclo de Dias
    - Detalhes: O tempo avança continuamente durante o gameplay. Cada dia tem um limite de energia/ações para o personagem, forçando o jogador a priorizar tarefas. Eventos e NPCs seguem rotinas baseadas no ciclo.
    - Como funciona: O dia começa ao amanhecer e termina quando o jogador vai dormir ou quando a energia acaba. Dormir avança o tempo para o próximo dia, restaura a energia e pode salvar o progresso. Estações do ano influenciam o que pode ser cultivado.
  - Combate RPG
    - Detalhes: Encontros de combate simples ocorrem quando o jogador explora áreas sob influência da cidade ou defende sua fazenda de ameaças. O sistema é acessível, sem profundidade excessiva.
    - Como funciona: O combate é em tempo real. O jogador possui atributos básicos (vida, ataque, defesa) que evoluem com o progresso. Inimigos são agentes ou criaturas enviadas pela expansão urbana.
  - Sistema de Relacionamento
    - Detalhes: O jogador pode interagir com NPCs que habitam a região, oferecendo presentes, conversando e participando de eventos. Relacionamentos mais fortes desbloqueiam diálogos, itens e elementos de história.
    - Como funciona: Cada NPC possui um medidor de afinidade que aumenta conforme o jogador interage positivamente. Níveis mais altos de afinidade revelam histórias pessoais dos personagens e podem influenciar o desfecho da narrativa.

# História e Gameplay

## História (Resumo)

Em um futuro próximo, megacidades se expandem consumindo campos e natureza. O jogador herda uma fazenda nos últimos territórios livres e precisa cultivá-la enquanto enfrenta o avanço implacável da cidade. Através de recursos acumulados e laços forjados com os habitantes locais, o fazendeiro tenta barrar a expansão e salvar o que ainda resta de natural naquele mundo.

## História (Detalhada)

O mundo de CyberMoon é dominado por corporações que controlam megacidades em constante expansão. Os campos que outrora existiam ao redor dessas cidades foram sendo engolidos pela urbanização, e os poucos que resistem são considerados territórios marginais - habitados por pessoas que recusaram a integração ao sistema urbano.

O protagonista herda uma fazenda localizada nessa zona de fronteira. Sem saber ao certo o que o aguarda, ele descobre que a cidade planeja expandir seus domínios até aquelas terras. Os habitantes locais - pequenos fazendeiros, técnicos renegados e nômades tecnológicos - dependem desse território para sobreviver fora do controle corporativo.

A progressão da história é desbloqueada conforme o protagonista acumula recursos e atinge marcos que fortalecem a comunidade local. A narrativa avança revelando os planos da corporação, os segredos dos NPCs e os desafios crescentes que a expansão traz. O clímax envolve um confronto direto com as forças da cidade, cujo desfecho depende das escolhas e do progresso do jogador ao longo do jogo.

## Gameplay (Resumo)

O jogador administra sua fazenda coletando recursos, cultivando plantações e gerenciando energia ao longo dos dias. Em paralelo, interage com NPCs, constrói relacionamentos e enfrenta combates contra ameaças da cidade. A progressão é guiada por marcos de recursos que desbloqueiam novos capítulos da história.

## Gameplay (Detalhado)

O loop central de gameplay consiste em: acordar, planejar as atividades do dia, coletar recursos, cultivar a fazenda, interagir com NPCs e, quando necessário, combater inimigos. A energia do personagem limita as ações diárias, forçando o jogador a tomar decisões estratégicas sobre onde investir seu tempo.

A fazenda é o hub principal do jogo. Ela pode ser expandida e melhorada com os recursos coletados, e seu nível de desenvolvimento determina quais partes da história se tornam acessíveis. Culturas diferentes exigem condições específicas de estação e ferramentas, adicionando camadas de planejamento ao gameplay.

O sistema de relacionamento complementa o loop de fazenda: visitar NPCs, oferecer presentes e participar de eventos aumenta a afinidade com cada personagem. Relacionamentos fortes revelam informações sobre a história e podem oferecer ajuda durante combates ou eventos especiais.

O combate aparece em zonas de exploração fora da fazenda, onde o protagonista enfrenta agentes da corporação ou criaturas resultantes da poluição tecnológica. O sistema é simples e direto, servindo como uma quebra de ritmo ao gameplay de simulação sem se tornar o foco principal da experiência.

# Assets Necessários

## 2D
  - Texturas
    - Texturas de ambiente (campos, terra cultivada, zonas urbanas)
    - Texturas de interface (HUD, menus, ícones de itens)
    - Sprites de itens e recursos
  - Dados de heightmap (se aplicável)
    - Mapa de elevação básico para a região da fazenda e arredores

## 3D
  - Lista de Personagens
    - Protagonista (fazendeiro)
    - NPCs habitantes da região (mínimo 3-5 personagens)
    - Inimigos (agentes da corporação, criaturas)
  - Lista de Arte Ambiental
    - Modelos de fazenda (casa, celeiro, campos de plantio)
    - Modelos de vegetação (árvores, arbustos, culturas)
    - Elementos urbanos cyberpunk (muros, estruturas metálicas, neon)
    - Itens coletáveis e ferramentas

## Som
  - Lista de Sons (Ambiente)
    - Exterior
      - Campos e natureza (vento, pássaros, folhagem)
      - Zona de fronteira urbana (ruído distante de cidade, estática)
      - Zonas urbanas (tráfego, máquinas, neon buzzing)
    - Interior
      - Casa da fazenda (ambiente calmo, fogueira)
      - Áreas subterrâneas/industriais (máquinas, goteiras)
  - Lista de Sons (Jogador)
    - Sons de Movimento do Personagem
      - Passos em terra/grama
      - Passos em metal/concreto
    - Sons de Colisão / Impacto
      - Impacto de ferramentas no solo
      - Impacto de combate
    - Sons de Dano / Morte do Personagem
      - Som de dano recebido
      - Som de derrota

## Código
  - Scripts do Personagem (Pawn do Jogador / Controlador)
    - Script de movimento do jogador
    - Script de gerenciamento de energia
    - Script de inventário e itens
  - Scripts Ambientais (Executam em segundo plano)
    - Script de ciclo de dias e estações
    - Script de progressão de marcos da história
  - Scripts de NPC
    - Script de rotina de NPC (baseado no ciclo de dias)
    - Script de sistema de relacionamento e afinidade
    - Script de comportamento de inimigos (combate)

## Animação
  - Animações de Ambiente
    - Culturas crescendo
    - Elementos neon piscando
  - Animações de Personagem
    - Jogador
      - Andar, correr
      - Usar ferramentas (plantar, colher, minerar)
      - Atacar, defender, tomar dano
      - Interagir com NPCs
    - NPCs
      - Rotinas de idle e caminhada
      - Reações a interações com o jogador
      - Animações de combate (inimigos)

# Cronograma
  - Prototipagem
    - Prazo: Semanas 1-3
      - Marco 1: Cena base com câmera top-down e movimento do personagem
      - Marco 2: Loop de ciclo de dias funcional
      - Marco 3: Mecânica básica de coleta de recursos
  - Desenvolvimento Principal
    - Prazo: Semanas 4-10
      - Marco 1: Sistema de fazenda e cultivo completo
      - Marco 2: Sistema de relacionamento com NPCs implementado
      - Marco 3: Sistema de combate RPG implementado
      - Marco 4: Progressão de história com marcos de recursos
  - Testes e Polimento
    - Prazo: Semanas 11-13
      - Marco 1: Testes internos de todas as mecânicas
      - Marco 2: Correção de bugs e balanceamento
      - Marco 3: Polimento visual e de áudio
  - Entrega Final
    - Prazo: Semana 14
      - Marco 1: Build final preparada
      - Marco 2: Apresentação do projeto
