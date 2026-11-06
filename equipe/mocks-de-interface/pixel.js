// Desenho em pixel art dos mocks: cenários de fundo, modelos dos moradores, mapas e a
// montagem dos slots. Tudo é desenhado em baixa resolução e ampliado sem suavizar, para
// ficar com a cara de pixel art sem precisar de imagem pronta.

"use strict";

// Sorteio com semente fixa, para o cenário sair igual toda vez que a página abre.
function criarSorteio(semente) {
  let estado = semente >>> 0;
  return function () {
    estado = (estado * 1664525 + 1013904223) >>> 0;
    return estado / 4294967296;
  };
}

function pintar(ctx, cor, x, y, largura, altura) {
  ctx.fillStyle = cor;
  ctx.fillRect(Math.round(x), Math.round(y), largura, altura);
}

// Céu em faixas, com uma linha pontilhada entre elas (o "dither" de pixel art).
function pintarCeu(ctx, largura, cores, topo, fundo) {
  const alturaDaFaixa = (fundo - topo) / cores.length;
  cores.forEach(function (cor, indice) {
    const y = topo + indice * alturaDaFaixa;
    pintar(ctx, cor, 0, y, largura, Math.ceil(alturaDaFaixa));
    if (indice > 0) {
      for (let x = indice % 2; x < largura; x += 2) {
        pintar(ctx, cores[indice - 1], x, y, 1, 1);
      }
    }
  });
}

function pintarEstrelas(ctx, sorteio, largura, altura, quantidade) {
  for (let i = 0; i < quantidade; i++) {
    const cor = sorteio() < 0.15 ? "#33f2ff" : "#c9d3ee";
    pintar(ctx, cor, sorteio() * largura, sorteio() * altura, 1, 1);
  }
}

// A Lua do título: disco com crateras e uma borda ciano, de neon.
function pintarLua(ctx, cx, cy, raio, fase) {
  for (let y = -raio; y <= raio; y++) {
    for (let x = -raio; x <= raio; x++) {
      const distancia = Math.sqrt(x * x + y * y);
      if (distancia > raio) continue;
      let cor = "#e9ecf7";
      if (distancia > raio - 1.2) cor = "#33f2ff";
      else if (x + y > raio * 0.6) cor = "#b9c1dd";
      const sombra = fase === "crescente" && Math.sqrt((x + raio * 0.55) ** 2 + y * y) < raio * 0.95;
      if (sombra) cor = distancia > raio - 1.2 ? "#1a6f7a" : "#141a33";
      pintar(ctx, cor, cx + x, cy + y, 1, 1);
    }
  }
  if (fase !== "crescente") {
    [[-4, -3, 3], [3, 2, 2], [-1, 5, 2], [5, -5, 1]].forEach(function (cratera) {
      pintar(ctx, "#9aa3c4", cx + cratera[0], cy + cratera[1], cratera[2], cratera[2]);
    });
  }
}

// Silhueta da cidade no horizonte, com janelas acesas em ciano, magenta e ouro.
function pintarCidade(ctx, sorteio, largura, base, alturaMaxima, corPredio, comJanelas) {
  let x = 0;
  const coresDeJanela = ["#33f2ff", "#ff40cc", "#ffd94d", "#33f2ff"];
  while (x < largura) {
    const larguraDoPredio = 6 + Math.floor(sorteio() * 12);
    const alturaDoPredio = 10 + Math.floor(sorteio() * alturaMaxima);
    pintar(ctx, corPredio, x, base - alturaDoPredio, larguraDoPredio, alturaDoPredio);
    if (sorteio() < 0.25) {
      pintar(ctx, corPredio, x + Math.floor(larguraDoPredio / 2), base - alturaDoPredio - 6, 1, 6);
      pintar(ctx, "#ff40cc", x + Math.floor(larguraDoPredio / 2), base - alturaDoPredio - 7, 1, 1);
    }
    if (comJanelas) {
      for (let jy = base - alturaDoPredio + 2; jy < base - 2; jy += 3) {
        for (let jx = x + 1; jx < x + larguraDoPredio - 1; jx += 2) {
          if (sorteio() < 0.18) pintar(ctx, coresDeJanela[Math.floor(sorteio() * 4)], jx, jy, 1, 1);
        }
      }
    }
    x += larguraDoPredio + Math.floor(sorteio() * 2);
  }
}

// Um pé de planta no talhão, em três tamanhos de crescimento.
function pintarBroto(ctx, x, y, estagio, corDoFruto) {
  const verde = "#5fbf3f";
  const verdeEscuro = "#3b7f2a";
  if (estagio === 0) {
    pintar(ctx, verde, x, y - 1, 1, 1);
    pintar(ctx, verdeEscuro, x - 1, y, 3, 1);
    return;
  }
  pintar(ctx, verdeEscuro, x, y - 3 - estagio, 1, 3 + estagio);
  pintar(ctx, verde, x - 2, y - 3 - estagio, 2, 1);
  pintar(ctx, verde, x + 1, y - 2 - estagio, 2, 1);
  pintar(ctx, verde, x - 1, y - 5 - estagio, 3, 2);
  if (estagio === 2 && corDoFruto) {
    pintar(ctx, corDoFruto, x - 2, y - 2, 2, 2);
    pintar(ctx, corDoFruto, x + 1, y - 4, 2, 2);
  }
}

function pintarTalhoes(ctx, sorteio, x0, y0, colunas, linhas, molhado) {
  const frutos = ["#ff8a3d", "#ffd94d", "#c23b8a", "#ff8a3d", null];
  for (let linha = 0; linha < linhas; linha++) {
    for (let coluna = 0; coluna < colunas; coluna++) {
      const x = x0 + coluna * 9;
      const y = y0 + linha * 8;
      const regado = molhado && (coluna + linha) % 3 !== 0;
      pintar(ctx, regado ? "#3f2a18" : "#6b4a2b", x, y, 8, 6);
      pintar(ctx, regado ? "#2c1d10" : "#57391f", x, y + 5, 8, 1);
      pintar(ctx, "#8a6a40", x, y, 8, 1);
      const estagio = Math.floor(sorteio() * 3);
      pintarBroto(ctx, x + 4, y + 4, estagio, frutos[(coluna + linha) % frutos.length]);
    }
  }
}

function pintarCasa(ctx, x, y, noite) {
  pintar(ctx, "#2a2f4a", x, y, 30, 18);
  pintar(ctx, "#3a4166", x, y, 30, 2);
  for (let i = 0; i < 8; i++) pintar(ctx, "#1d2138", x - 3 + i, y - 8 + i, 36 - i * 2, 1);
  pintar(ctx, "#5c3a2a", x + 3, y - 2, 24, 2);
  pintar(ctx, "#140f0c", x + 12, y + 8, 6, 10);
  pintar(ctx, noite ? "#ffd94d" : "#7f9bbf", x + 3, y + 5, 6, 4);
  pintar(ctx, noite ? "#ffd94d" : "#7f9bbf", x + 21, y + 5, 6, 4);
  pintar(ctx, "#33f2ff", x + 10, y + 3, 10, 1);
  pintar(ctx, "#1d2138", x + 24, y - 14, 3, 8);
  pintar(ctx, "#ff40cc", x + 25, y - 15, 1, 1);
}

function pintarCerca(ctx, x0, x1, y) {
  for (let x = x0; x < x1; x += 5) pintar(ctx, "#4a3420", x, y - 5, 1, 6);
  pintar(ctx, "#6b4a2b", x0, y - 4, x1 - x0, 1);
  pintar(ctx, "#6b4a2b", x0, y - 2, x1 - x0, 1);
}

function pintarEspantalho(ctx, x, y) {
  pintar(ctx, "#4a3420", x, y - 14, 1, 14);
  pintar(ctx, "#4a3420", x - 5, y - 11, 11, 1);
  pintar(ctx, "#d9a35b", x - 1, y - 17, 3, 3);
  pintar(ctx, "#33f2ff", x - 1, y - 16, 3, 1);
  pintar(ctx, "#5c3a66", x - 2, y - 10, 5, 5);
}

function pintarTorre(ctx, x, y, altura) {
  for (let i = 0; i < altura; i++) {
    const meia = Math.floor((altura - i) / 10) + 1;
    pintar(ctx, "#141830", x - meia, y - i, meia * 2 + 1, 1);
    if (i % 4 === 0) pintar(ctx, "#232a4d", x - meia, y - i, meia * 2 + 1, 1);
  }
  pintar(ctx, "#ff40cc", x, y - altura - 1, 1, 1);
  pintar(ctx, "#ff40cc", x - 2, y - altura + 6, 1, 1);
  pintar(ctx, "#ff40cc", x + 2, y - altura + 6, 1, 1);
}

const CENAS = {
  titulo: function (ctx, l, a) {
    const sorteio = criarSorteio(7);
    pintarCeu(ctx, l, ["#05060f", "#090b1d", "#110f2c", "#1b1238", "#2a1240", "#401447"], 0, 92);
    pintarEstrelas(ctx, sorteio, l, 70, 90);
    pintarCidade(ctx, sorteio, l, 92, 48, "#151634", false);
    pintarLua(ctx, 176, 30, 17);
    pintarCidade(ctx, sorteio, l, 94, 34, "#0b0c1f", true);
    pintarTorre(ctx, 42, 94, 50);
    pintar(ctx, "#2a1a1f", 0, 92, l, 3);
    pintar(ctx, "#1c1314", 0, 95, l, a - 95);
    pintarTalhoes(ctx, sorteio, 118, 100, 13, 4, true);
    pintarCerca(ctx, 108, 240, 99);
    pintarCasa(ctx, 64, 102, true);
    pintarEspantalho(ctx, 110, 130);
  },
  fazendaDia: function (ctx, l, a) {
    const sorteio = criarSorteio(11);
    pintarCeu(ctx, l, ["#3a6fa8", "#5b8fc2", "#86b0d4", "#c6c6c0", "#e4c08a", "#e8a865"], 0, 52);
    pintar(ctx, "#fff3c4", 200, 10, 10, 10);
    pintar(ctx, "#ffe08a", 199, 11, 12, 8);
    pintarCidade(ctx, sorteio, l, 52, 22, "#8b93ad", false);
    pintar(ctx, "#c9935a", 0, 52, l, 4);
    pintar(ctx, "#b98552", 0, 56, l, a - 56);
    for (let i = 0; i < 160; i++) pintar(ctx, sorteio() < 0.5 ? "#a87645" : "#d29f63", sorteio() * l, 56 + sorteio() * 80, 1, 1);
    pintarCasa(ctx, 20, 70, false);
    pintarTalhoes(ctx, sorteio, 70, 66, 15, 6, true);
    pintarCerca(ctx, 64, 210, 64);
    pintarEspantalho(ctx, 64, 118);
    // O jogador, de costas para a câmera, com o regador.
    pintar(ctx, "#2a2f4a", 118, 100, 5, 7);
    pintar(ctx, "#e0b48a", 119, 96, 3, 3);
    pintar(ctx, "#33f2ff", 118, 95, 5, 1);
    pintar(ctx, "#7f9bbf", 123, 102, 3, 2);
  },
  fazendaNoite: function (ctx, l, a) {
    const sorteio = criarSorteio(11);
    pintarCeu(ctx, l, ["#05060f", "#0a0c20", "#121233", "#1d1640", "#2b1a48", "#3a1d4a"], 0, 52);
    pintarEstrelas(ctx, sorteio, l, 44, 60);
    pintarLua(ctx, 204, 16, 7);
    pintarCidade(ctx, criarSorteio(11), l, 52, 22, "#0d0e24", true);
    pintar(ctx, "#2a1d24", 0, 52, l, 4);
    pintar(ctx, "#241a1c", 0, 56, l, a - 56);
    pintarCasa(ctx, 20, 70, true);
    pintarTalhoes(ctx, sorteio, 70, 66, 15, 6, false);
    pintarCerca(ctx, 64, 210, 64);
  },
  vila: function (ctx, l, a) {
    const sorteio = criarSorteio(3);
    pintarCeu(ctx, l, ["#1a1235", "#3a1a4a", "#6a2450", "#b0405a", "#e07a4a", "#f2a65a"], 0, 70);
    pintarCidade(ctx, sorteio, l, 70, 40, "#2a1638", true);
    pintar(ctx, "#3b2630", 0, 70, l, a - 70);
    // Fachada do mercado da Marta, com letreiro de neon.
    pintar(ctx, "#1d2138", 30, 40, 120, 70);
    pintar(ctx, "#2a2f4a", 30, 40, 120, 3);
    pintar(ctx, "#140f0c", 70, 80, 30, 30);
    pintar(ctx, "#ffd94d", 40, 60, 20, 12);
    pintar(ctx, "#ffd94d", 110, 60, 20, 12);
    for (let x = 48; x < 132; x += 2) pintar(ctx, "#ff40cc", x, 48, 1, 4);
    for (let x = 30; x < 150; x += 8) pintar(ctx, x % 16 === 6 ? "#5fbf3f" : "#e8e1c8", x, 74, 8, 3);
  },
  dungeon: function (ctx, l, a) {
    const sorteio = criarSorteio(5);
    pintar(ctx, "#07080f", 0, 0, l, a);
    for (let y = 0; y < 70; y += 6) {
      for (let x = (y / 6) % 2 ? 0 : 6; x < l; x += 12) {
        pintar(ctx, "#121628", x, y, 11, 5);
        pintar(ctx, "#181d33", x, y, 11, 1);
      }
    }
    pintar(ctx, "#2a3150", 0, 20, l, 3);
    pintar(ctx, "#3a4166", 0, 20, l, 1);
    pintar(ctx, "#2a3150", 0, 30, l, 2);
    for (let x = 10; x < l; x += 40) {
      pintar(ctx, "#33f2ff", x, 8, 6, 2);
      ctx.fillStyle = "rgba(51, 242, 255, 0.08)";
      ctx.beginPath();
      ctx.moveTo(x - 10, 70); ctx.lineTo(x + 3, 10); ctx.lineTo(x + 16, 70); ctx.fill();
    }
    for (let y = 70; y < a; y++) {
      const fileira = y - 70;
      pintar(ctx, fileira % 8 === 0 ? "#1b2138" : "#0e1120", 0, y, l, 1);
    }
    for (let x = 0; x < l; x += 16) pintar(ctx, "#1b2138", x, 70, 1, a - 70);
    for (let i = 0; i < 30; i++) pintar(ctx, "#ff40cc", sorteio() * l, 70 + sorteio() * 60, 1, 1);
    // Poça de água parada e os canos que vazam.
    pintar(ctx, "#123a52", 150, 110, 40, 6);
    pintar(ctx, "#33f2ff", 156, 111, 10, 1);
    // O jogador e a sombra do Compactador ao fundo.
    pintar(ctx, "#000", 112, 112, 8, 2);
    pintar(ctx, "#2a2f4a", 113, 103, 6, 9);
    pintar(ctx, "#e0b48a", 114, 98, 4, 4);
    pintar(ctx, "#33f2ff", 113, 98, 6, 1);
    pintar(ctx, "#1d2138", 96, 52, 48, 26);
    pintar(ctx, "#2a3150", 96, 52, 48, 3);
    pintar(ctx, "#ffd94d", 104, 60, 6, 3);
    pintar(ctx, "#ffd94d", 130, 60, 6, 3);
    for (let x = 98; x < 142; x += 4) pintar(ctx, "#3a4166", x, 74, 2, 6);
  },
  interior: function (ctx, l, a) {
    pintar(ctx, "#1a1420", 0, 0, l, a);
    for (let x = 0; x < l; x += 10) pintar(ctx, "#211a28", x, 0, 5, 80);
    pintar(ctx, "#3b2a22", 0, 80, l, a - 80);
    for (let y = 80; y < a; y += 6) pintar(ctx, "#2f2119", 0, y, l, 1);
    pintar(ctx, "#2a2f4a", 20, 40, 60, 40);
    pintar(ctx, "#ffd94d", 26, 46, 48, 3);
    pintar(ctx, "#33f2ff", 150, 20, 50, 30);
    pintar(ctx, "#0d2630", 152, 22, 46, 26);
  }
};

function desenharCenarios() {
  document.querySelectorAll("canvas.cenario").forEach(function (canvas) {
    canvas.width = 240;
    canvas.height = 135;
    const ctx = canvas.getContext("2d");
    const cena = CENAS[canvas.dataset.cena];
    if (cena) cena(ctx, 240, 135);
  });
}

// ---------- Modelos 3D dos moradores ----------
// No jogo a interface mostra o modelo 3D de verdade, num SubViewport com mundo próprio,
// como a caixa de conversa já faz. No mock, a prévia renderizada da Kenney faz o papel do
// modelo. O mapa segue o campo "modelo" de cada resources/npcs/*.tres; Bento e Téo ainda
// não têm modelo em main (plano 30), então usam um provisório.

const MODELOS = {
  jogador: "character_female_f",
  marta: "character_female_a",
  iara: "character_female_b",
  sol: "character_female_c",
  kenji: "character_male_c",
  vitor: "character_male_b",
  rafa: "character_male_d",
  bento: "character_male_e",
  teo: "character_male_a"
};

function montarModelos() {
  document.querySelectorAll("img[data-modelo]").forEach(function (imagem) {
    const arquivo = MODELOS[imagem.dataset.modelo] || MODELOS.jogador;
    imagem.src = "modelos/" + arquivo + ".png";
    imagem.alt = "";
  });
}

// ---------- Mapa visto de cima (minimapa e mapa grande) ----------

function desenharMapa(canvas) {
  const largura = 160;
  const altura = 100;
  canvas.width = largura;
  canvas.height = altura;
  const ctx = canvas.getContext("2d");
  const sorteio = criarSorteio(21);
  pintar(ctx, "#b98552", 0, 0, largura, altura);
  for (let i = 0; i < 500; i++) pintar(ctx, sorteio() < 0.5 ? "#a87645" : "#c9935a", sorteio() * largura, sorteio() * altura, 1, 1);
  // Rio seco e o lago.
  for (let y = 0; y < altura; y++) {
    const x = 30 + Math.round(Math.sin(y / 9) * 6);
    pintar(ctx, "#2a6a8a", x, y, 3, 1);
  }
  pintar(ctx, "#2a6a8a", 18, 70, 22, 12);
  pintar(ctx, "#33f2ff", 22, 73, 6, 1);
  // Estrada e viaduto.
  pintar(ctx, "#3a3346", 0, 46, largura, 5);
  for (let x = 2; x < largura; x += 8) pintar(ctx, "#ffd94d", x, 48, 4, 1);
  pintar(ctx, "#2a2f4a", 96, 0, 6, altura);
  // A fazenda, com os talhões.
  pintar(ctx, "#57391f", 46, 58, 34, 26);
  for (let y = 60; y < 82; y += 4) {
    for (let x = 48; x < 78; x += 5) pintar(ctx, (x + y) % 3 ? "#3f2a18" : "#5fbf3f", x, y, 4, 3);
  }
  // A vila, com as casas.
  [[110, 20], [120, 26], [132, 18], [116, 34], [140, 30], [128, 36]].forEach(function (casa) {
    pintar(ctx, "#1d2138", casa[0], casa[1], 7, 5);
    pintar(ctx, "#ffd94d", casa[0] + 2, casa[1] + 2, 2, 1);
  });
  // Trilhas.
  for (let x = 80; x < 110; x++) pintar(ctx, "#d9b07a", x, 60 - Math.floor((x - 80) / 3), 1, 1);
  // As três dungeons.
  pintar(ctx, "#ff40cc", 100, 52, 3, 3);
  pintar(ctx, "#5fbf3f", 146, 70, 3, 3);
  pintar(ctx, "#9b5cff", 150, 8, 3, 3);
}

function desenharMapas() {
  document.querySelectorAll("canvas.mapa").forEach(desenharMapa);
}

// ---------- Slots de inventário a partir de uma lista curta ----------
// Cada item da lista é "nome", "nome x12", "nome+2" (nível da arma) ou "-" (vazio),
// com "#foco", "#segurando", "#selecionado" ou "#trancado" no fim para o estado.

function montarSlot(texto, numero) {
  const partes = texto.trim().split("#");
  const estado = partes[1] || "";
  let base = partes[0].trim();
  let quantidade = "";
  let nivel = "";
  if (base.includes(" x")) {
    quantidade = base.split(" x")[1];
    base = base.split(" x")[0];
  }
  if (base.includes("+")) {
    nivel = "Nv" + base.split("+")[1];
    base = base.split("+")[0];
  }
  const slot = document.createElement("div");
  slot.className = "slot " + estado;
  if (numero) slot.innerHTML += '<span class="num">' + numero + "</span>";
  if (base && base !== "-") slot.innerHTML += '<img alt="" src="icones/' + base + '.png">';
  if (quantidade) slot.innerHTML += '<span class="qtd">' + quantidade + "</span>";
  if (nivel) slot.innerHTML += '<span class="nivel">' + nivel + "</span>";
  return slot;
}

function montarGrades() {
  document.querySelectorAll("[data-itens]").forEach(function (grade) {
    const numerar = grade.hasAttribute("data-numerar");
    grade.dataset.itens.split(",").forEach(function (texto, indice) {
      grade.appendChild(montarSlot(texto, numerar ? String((indice + 1) % 10) : ""));
    });
    if (grade.dataset.colunas) {
      grade.style.gridTemplateColumns = "repeat(" + grade.dataset.colunas + ", 48px)";
    }
  });
}

// ---------- Escala dos monitores ----------

function ajustarMonitores() {
  document.querySelectorAll(".monitor").forEach(function (monitor) {
    const quadro = monitor.querySelector(".quadro");
    quadro.style.transform = "scale(" + monitor.clientWidth / 960 + ")";
  });
}

window.addEventListener("DOMContentLoaded", function () {
  montarGrades();
  desenharCenarios();
  montarModelos();
  desenharMapas();
  ajustarMonitores();
  new ResizeObserver(ajustarMonitores).observe(document.body);
});
