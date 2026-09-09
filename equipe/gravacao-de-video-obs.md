# Gravação do vídeo de entrega

Bernardo, **depois de terminar os planos 01 e 02** você grava um vídeo mostrando o
resultado. Este documento vai do zero até o arquivo pronto.

Os dois vídeos anteriores estão em `docs/entrega-personagem.mp4` e `docs/entrega-mapa.mp4`.
Vale assistir os dois antes de gravar, para o seu ficar no mesmo formato.

## Instalar o OBS

**Linux, por flatpak:**

```bash
flatpak install flathub com.obsproject.Studio
```

**Linux, Ubuntu e derivados, pelo repositório oficial:**

```bash
sudo add-apt-repository ppa:obsproject/obs-studio
sudo apt update
sudo apt install obs-studio
```

**Windows:** baixe em obsproject.com e instale com as opções padrão.

Na primeira abertura o OBS oferece um assistente de configuração automática. **Escolha
"Otimizar apenas para gravação"**, não para transmissão. Aceite o que ele sugerir depois
disso.

## Configurar

Abra Configurações, e ajuste só estas quatro coisas. O resto do padrão serve.

**Saída**

- Modo de saída: Simples
- Caminho de gravação: escolha uma pasta que você ache depois
- Qualidade de gravação: Alta qualidade, tamanho médio
- Formato de gravação: `mp4`
- Codificador: se aparecer opção de hardware (NVENC, AMF, QSV), escolha ela. Se não,
  deixe x264.

**Vídeo**

- Resolução base e resolução de saída: 1920x1080 nas duas
- Valor de FPS: 60

Se o jogo engasgar durante a gravação, baixe a resolução de saída para 1280x720. Vídeo de
entrega com engasgo é pior que vídeo em resolução menor.

**Áudio**

Isto importa mais que o normal, porque metade do que você vai mostrar é som.

- Áudio da mesa (Desktop Audio): ligado, é o áudio do jogo
- Microfone: ligado só se você for narrar

Se o áudio do jogo não aparecer no medidor do OBS, o problema costuma ser isolamento do
flatpak. A saída mais rápida é instalar o OBS pelo repositório do sistema em vez do
flatpak, ou usar `pavucontrol` para apontar a captura do OBS para a saída do Godot.

**Teste o áudio antes de gravar o vídeo inteiro.** Grave 20 segundos, abra o arquivo e
confirme que dá para ouvir. Perder uma gravação boa por áudio mudo é frustrante.

## Montar a cena

Na janela principal, no painel Fontes, clique no mais:

1. **Captura de janela** (ou Captura de tela, se a de janela não pegar o Godot). Selecione
   a janela do jogo rodando. No Linux com Wayland, a captura de janela às vezes não
   funciona; nesse caso use captura de tela e deixe o jogo em tela cheia.
2. Se for narrar, **Captura de entrada de áudio** com o seu microfone.

Redimensione a fonte para preencher a tela toda. Clique com o botão direito na fonte,
Transformar, Ajustar à tela.

## O que gravar

Uns 2 a 4 minutos. Roteiro sugerido, na ordem:

**Colisão (plano 01)**

1. Ande pelo mapa e encoste numa árvore. Mostre que o personagem para.
2. Encoste num prédio, numa cerca e numa pedra.
3. Ande por cima de um tufo de grama, mostrando que decoração não bloqueia.
4. Vá até a borda do mapa e mostre que não cai.

**Som (plano 02)**

5. Ande na grama por uns segundos, com o áudio audível.
6. Ande até a rua e mostre o som de passo mudando de superfície.
7. Passe pela ponte de madeira, mostrando a terceira superfície.
8. Corra, para mostrar que o passo acelera junto com a animação.
9. Deixe a música de fundo aparecer em algum momento sem outro som por cima.

Se os clipes de áudio ainda não chegarem a tempo, grave assim mesmo mostrando o resto, e
diga no vídeo que o sistema está pronto e esperando os arquivos. Mas tente conseguir pelo
menos duas superfícies de passo, porque é a parte mais convincente da entrega.

## Dicas que salvam a gravação

- Feche notificação, chat e qualquer coisa que possa aparecer na tela.
- Não grave o desktop com arquivo pessoal à vista.
- Faça uma passada de ensaio sem gravar. Você vai descobrir o que quer mostrar.
- Se errar no meio, não pare. Corte depois, ou regrave só aquele trecho.
- Grave um trecho de teste de 20 segundos e assista antes de gravar o vídeo inteiro.

## Depois de gravar

O arquivo vai para `docs/`, seguindo o nome dos anteriores:

```
docs/entrega-colisao-e-som.mp4
```

Commit no padrão que o histórico já usa:

```bash
git add docs/entrega-colisao-e-som.mp4
git commit -m "docs(entregas): adiciona o video da entrega de colisao e som"
git push
```

Se o arquivo passar de uns 50 MB, comprima antes. Vídeo grande no git incomoda todo mundo
que clonar depois. Com ffmpeg instalado:

```bash
ffmpeg -i entrada.mp4 -vcodec libx264 -crf 28 -preset slow saida.mp4
```

Confira o resultado antes de trocar: `crf 28` costuma ficar bom para captura de jogo, mas
se ficar borrado use `crf 24`.
