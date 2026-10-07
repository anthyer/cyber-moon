# Plano 18: Chat entre jogadores (CyberMoon Chat)

**Prioridade.** Feature de nuvem para a disciplina de Infraestrutura e Serviços de Nuvem.
Não depende de nenhum dos planos 01-17 para funcionar, e pode ser feita em paralelo.

**Objetivo:** jogadores conectados via WebGL podem se comunicar em tempo real através de um chat global, usando conexões WebSocket gerenciadas pelo AWS API Gateway. O jogador abre o chat com uma tecla, digita e envia. A mensagem aparece para todos os outros jogadores conectados em menos de 300 ms.

**Abordagem:** Infraestrutura Serverless provisionada como código usando **Pulumi**. Back-end na AWS (VPC, API Gateway WebSocket, Lambda, DynamoDB, Cognito e SES). No Godot, um autoload `ChatManager` centraliza a conexão WebSocket e repassa mensagens via `EventBus`.

**Status Sprints 1 e 2 (Concluídas / Em andamento):**
- Infraestrutura básica inicial usando Pulumi (criação do bucket S3 e DNS na AWS).
- Preparação do repositório, cena básica do Godot (Playground) e barramento de eventos (`EventBus`).
- **Front-end Godot (UI e Lógica do Chat):** A criação do painel (`chat.tscn`), do `ChatManager` e dos sinais de `EventBus` já está sendo desenvolvida no lado do cliente. As próximas sprints têm foco exclusivo na infraestrutura AWS (back-end).

---

## Sprint 3: Banco de Dados e Lambda
Nesta Sprint, o foco é construir a comunicação base do chat em tempo real via WebSocket e banco de dados.

### Tarefa 3.1: Tabelas no DynamoDB (via Pulumi)
Criar no script do Pulumi (`pulumi-start-aws/__main__.py`):
- [ ] **Tabela `cybermoon-conexoes`:** Para conexões ativas. Partition key: `connection_id` (String). Billing: On-demand.
- [ ] **Tabela `cybermoon-mensagens`:** Para o histórico de mensagens. Partition key: `sala_id` (String), Sort key: `enviada_em` (String). Billing: On-demand. Habilitar **TTL** (Time to Live) no atributo `expira_em`.

### Tarefa 3.2: Funções Lambda do Chat
- [ ] **`on_connect.py`:** Lambda que registra o `connection_id` no DynamoDB.
- [ ] **`on_disconnect.py`:** Lambda que remove o `connection_id` do DynamoDB na desconexão.
- [ ] **`send_message.py`:** Lambda que lê uma mensagem enviada, grava na tabela de mensagens e distribui para todos os `connection_id`s ativos na tabela de conexões.
- [ ] **Deploy via Pulumi:** Definir a criação destas Lambdas e atribuir IAM Roles que permitam acesso ao DynamoDB e permissão ao API Gateway (`execute-api:ManageConnections`).

### Tarefa 3.3: API Gateway WebSocket
- [ ] Provisionar via Pulumi uma **WebSocket API** (`cybermoon-chat`).
- [ ] Criar rotas: `$connect` -> Lambda `on_connect`, `$disconnect` -> Lambda `on_disconnect`, `sendmessage` -> Lambda `send_message`.
- [ ] Realizar deploy para um Stage (ex: `prod`) e exportar a URL WSS resultante no console do Pulumi. (A URL será passada ao front-end para conexão).

---

## Sprint 4: VPC, Cognito e SES
Nesta Sprint, adicionamos isolamento de rede para os recursos de banco, autenticação dos jogadores e envio de e-mails.

### Tarefa 4.1: Rede Privada (VPC)
- [ ] **Configuração Pulumi VPC:** Criar uma VPC dedicada para a infraestrutura, com subnets públicas e privadas.
- [ ] **VPC Endpoints:** Configurar um Gateway Endpoint para o DynamoDB, permitindo que as Lambdas acessem o banco de dados de forma segura sem sair para a internet pública.
- [ ] **Lambdas na VPC:** Configurar as funções Lambda do chat para executarem dentro das subnets privadas da VPC.

### Tarefa 4.2: Amazon Cognito (Autenticação)
- [ ] Criar um **User Pool** no Cognito via Pulumi para login dos jogadores via E-mail e Senha.
- [ ] Criar um **App Client** configurado para comunicação segura sem Client Secret (visto que web apps não o ocultam perfeitamente).
- [ ] **Lambda Authorizer:** Criar `authorizer.py` que valide os tokens JWT do Cognito. Integrar ao API Gateway para proteger a rota `$connect`.

### Tarefa 4.3: Amazon SES (Notificações por E-mail)
- [ ] Configurar e validar uma identidade de domínio/e-mail no **Amazon SES** via Pulumi.
- [ ] Criar uma **Lambda de Post Confirmation Trigger** conectada ao Cognito. Quando o usuário terminar o cadastro, a Lambda usa o SES para enviar um "E-mail de Boas-Vindas ao CyberMoon".
- [ ] Configurar permissões de `ses:SendEmail` na Role do IAM responsável por essa execução.

---

## Sprint 5: CI/CD (Testes e Deploy Automatizado)
Nesta Sprint, garantimos a integridade do projeto com testes e criamos os fluxos automatizados de implantação via GitHub Actions.

### Tarefa 5.1: Testes Automatizados (Back-end)
- [ ] **Setup Pytest:** Criar uma estrutura de testes (`tests/`) para o código em Python das Lambdas.
- [ ] **Mock de AWS (Moto):** Escrever testes de integração que validem a lógica (ex: salvar mensagem simulando o DynamoDB, TTLs e restrições de payload sem custo extra na AWS).

### Tarefa 5.2: Pipeline de CI (Continuous Integration)
- [ ] **Workflow do GitHub Actions:** Criar o arquivo `.github/workflows/ci.yml`.
- [ ] Configurar o job para instalar o Python, instalar as dependências e rodar o `pytest` a cada Pull Request ou push na branch principal.
- [ ] Reprovar e impedir merges caso existam testes falhos.

### Tarefa 5.3: Pipeline de CD (Continuous Deployment)
- [ ] **Workflow do GitHub Actions:** Criar o arquivo `.github/workflows/cd.yml`.
- [ ] **Autenticação OIDC:** Adicionar configuração sem chaves de longa duração no GitHub usando integração IAM OIDC Provider para segurança da AWS.
- [ ] **Deploy de Infraestrutura:** Configurar um step que aciona `pulumi up --yes` para aplicar as modificações da VPC, Lambdas, SES, etc, automaticamente quando houver merge na branch `main`.
- [ ] **Deploy do Jogo:** Usar versão Headless do Godot no Action para construir a exportação WebGL (`build/web/`) e usar `aws s3 sync` para atualizar imediatamente a versão online hospedada no S3.

---

## Resumo dos Serviços AWS Integrados (Cloud)
1. **S3 + Route53:** Hospedagem da versão WebGL exportada e resolução DNS. (Sprints 1 e 2)
2. **Lambda + API Gateway (WebSocket):** Backend interativo para trocar e enviar mensagens sem depender de servidores persistentes. (Sprint 3)
3. **DynamoDB:** Armazenamento distribuído e flexível (NoSQL) guardando salas, conexões em tempo real e chats (com TTL). (Sprint 3)
4. **VPC:** Criação de rede na nuvem (Virtual Private Cloud) fechando o trânsito da aplicação com segurança a nível de rotas. (Sprint 4)
5. **Cognito:** Serviço gerenciado de Identidades, cadastros e geração de Tokens JWT. (Sprint 4)
6. **SES (Simple Email Service):** Comunicação corporativa disparando e-mail customizado. (Sprint 4)
7. **Integração CI/CD:** GitHub associado à IAM Policies garantindo deploys limpos com testes unitários locais antes da nuvem. (Sprint 5)
