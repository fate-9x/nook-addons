// Batalla naval: tu flota contra la de nook (que dispara buscando barcos y, cuando toca uno,
// sigue hasta hundirlo) o contra la de tu IA, que juega por MCP.
//
// Los tableros son listas de 100 casillas (fila * 10 + columna) con: 0 agua, 1 barco, 2 agua
// tocada, 3 barco tocado y 4 barco hundido. `this.mio` es el del usuario y `this.suyo` el del
// rival; `this.barcos_mios` y `this.barcos_suyos`, las casillas de cada barco, en el orden de
// `flota()`. Los barcos van en línea recta y no se tocan (tampoco en diagonal).

// ---- Datos ----

// Largo de cada barco: portaaviones, acorazado, crucero, submarino y destructor.
fn flota() { [5, 4, 3, 3, 2] }

fn letras() { "ABCDEFGHIJ" }

fn textos() {
    let todos = #{
        es: #{
            tu_flota: "Tu flota", rival: "Rival", nook: "nook", tu_ia: "Tu IA",
            recolocar: "Recolocar", empezar: "Empezar", abandonar: "Abandonar", nueva: "Nueva partida",
            colocar: "Coloca tu flota y pulsa Empezar.",
            colocar_ia: "Pulsa Empezar o pide a tu IA que empiece la partida.",
            te_toca: "Te toca: dispara al rival.",
            piensa: "El rival está apuntando…",
            espera_ia: "Esperando el disparo de tu IA…",
            ganado: "¡Has ganado en {n} disparos!",
            perdido: "Has perdido: han hundido tu flota.",
            tu: "Tú", el: "Rival",
            agua: "agua", tocado: "tocado", hundido: "¡hundido!",
            marcador: "Ganadas {g} · Perdidas {p}", mejor: " · Récord: {r}",
            barcos: ["portaaviones", "acorazado", "crucero", "submarino", "destructor"],
        },
        en: #{
            tu_flota: "Your fleet", rival: "Rival", nook: "nook", tu_ia: "Your AI",
            recolocar: "Shuffle", empezar: "Start", abandonar: "Give up", nueva: "New game",
            colocar: "Arrange your fleet and press Start.",
            colocar_ia: "Press Start, or ask your AI to start the game.",
            te_toca: "Your turn: fire at the rival.",
            piensa: "The rival is taking aim…",
            espera_ia: "Waiting for your AI's shot…",
            ganado: "You won in {n} shots!",
            perdido: "You lost: your fleet was sunk.",
            tu: "You", el: "Rival",
            agua: "miss", tocado: "hit", hundido: "sunk!",
            marcador: "Won {g} · Lost {p}", mejor: " · Best: {r}",
            barcos: ["carrier", "battleship", "cruiser", "submarine", "destroyer"],
        },
        ja: #{
            tu_flota: "自分の艦隊", rival: "相手", nook: "nook", tu_ia: "あなたのAI",
            recolocar: "並べ直す", empezar: "開始", abandonar: "降参", nueva: "新しいゲーム",
            colocar: "艦隊を配置して「開始」を押してください。",
            colocar_ia: "「開始」を押すか、AIにゲームを始めてもらいましょう。",
            te_toca: "あなたの番です。相手を撃ってください。",
            piensa: "相手が狙いを定めています…",
            espera_ia: "AIの攻撃を待っています…",
            ganado: "{n}発で勝利しました！",
            perdido: "負けました。艦隊が全滅しました。",
            tu: "あなた", el: "相手",
            agua: "外れ", tocado: "命中", hundido: "撃沈！",
            marcador: "{g}勝 {p}敗", mejor: " · 最少 {r}発",
            barcos: ["空母", "戦艦", "巡洋艦", "潜水艦", "駆逐艦"],
        },
        ko: #{
            tu_flota: "내 함대", rival: "상대", nook: "nook", tu_ia: "내 AI",
            recolocar: "다시 배치", empezar: "시작", abandonar: "포기", nueva: "새 게임",
            colocar: "함대를 배치하고 시작을 누르세요.",
            colocar_ia: "시작을 누르거나 AI에게 게임을 시작해 달라고 하세요.",
            te_toca: "내 차례: 상대를 쏘세요.",
            piensa: "상대가 조준하고 있습니다…",
            espera_ia: "AI의 공격을 기다리는 중…",
            ganado: "{n}발 만에 승리했습니다!",
            perdido: "패배: 함대가 모두 격침되었습니다.",
            tu: "나", el: "상대",
            agua: "빗나감", tocado: "명중", hundido: "격침!",
            marcador: "{g}승 {p}패", mejor: " · 최고 {r}발",
            barcos: ["항공모함", "전함", "순양함", "잠수함", "구축함"],
        },
    };
    todos[idioma()] ?? todos.es
}

// Nombres de los barcos en lo que se le dice a la IA.
fn barcos_ia() { ["portaaviones", "acorazado", "crucero", "submarino", "destructor"] }

// Pone los valores en los huecos de un texto ("{n}").
fn rellenar(plantilla, valores) {
    let texto = plantilla;
    for clave in valores.keys() {
        texto.replace(`{${clave}}`, `${valores[clave]}`);
    }
    texto
}

// ---- Tableros ----

fn vacio() {
    let tablero = [];
    tablero.pad(100, 0);
    tablero
}

// "B7" de la casilla 61.
fn casilla(i) {
    `${letras()[i % 10]}${i / 10 + 1}`
}

// La casilla de un texto como "B7" (o -1 si no es ninguna).
fn leer_casilla(texto) {
    if type_of(texto) != "string" { return -1; }
    let s = texto.to_upper();
    s.replace(" ", "");
    if s.len() < 2 || s.len() > 3 { return -1; }
    let columna = letras().index_of(s[0]);
    if columna < 0 { return -1; }
    let fila = s.sub_string(1);
    for f in 1..=10 {
        if fila == `${f}` { return (f - 1) * 10 + columna; }
    }
    -1
}

// Las casillas de un barco escrito como "A1-E1" (vacío si no está en línea recta).
fn leer_barco(texto) {
    if type_of(texto) != "string" { return []; }
    let partes = texto.split("-");
    if partes.len() != 2 { return []; }
    let a = leer_casilla(partes[0]);
    let b = leer_casilla(partes[1]);
    if a < 0 || b < 0 { return []; }
    if a > b {
        let x = a;
        a = b;
        b = x;
    }
    let casillas = [];
    if a / 10 == b / 10 {
        for i in a..=b { casillas.push(i); }
    } else if a % 10 == b % 10 {
        let i = a;
        while i <= b {
            casillas.push(i);
            i += 10;
        }
    }
    casillas
}

// Si un barco cabe en esas casillas sin solaparse ni tocar a otro.
fn cabe(tablero, casillas) {
    for i in casillas {
        let f = i / 10;
        let c = i % 10;
        for df in -1..=1 {
            for dc in -1..=1 {
                let ff = f + df;
                let cc = c + dc;
                if ff >= 0 && ff < 10 && cc >= 0 && cc < 10 && tablero[ff * 10 + cc] != 0 {
                    return false;
                }
            }
        }
    }
    true
}

// Una flota colocada al azar: #{ tablero, barcos }.
fn flota_al_azar() {
    loop {
        let tablero = vacio();
        let barcos = [];
        for largo in flota() {
            for intento in 0..100 {
                let horizontal = azar() < 0.5;
                let columnas = if horizontal { 11 - largo } else { 10 };
                let filas = if horizontal { 10 } else { 11 - largo };
                let c = (azar() * columnas.to_float()).to_int();
                let f = (azar() * filas.to_float()).to_int();
                let casillas = [];
                for k in 0..largo {
                    casillas.push(if horizontal { f * 10 + c + k } else { (f + k) * 10 + c });
                }
                if cabe(tablero, casillas) {
                    for i in casillas { tablero[i] = 1; }
                    barcos.push(casillas);
                    break;
                }
            }
        }
        if barcos.len() == flota().len() {
            return #{ tablero: tablero, barcos: barcos };
        }
    }
}

// La flota que propone la IA (["A1-E1", …]), o un texto con lo que tiene mal.
fn leer_flota(lista) {
    let ejemplo = "Por ejemplo: [\"A1-E1\", \"C3-C6\", \"H2-H4\", \"E8-G8\", \"J9-J10\"].";
    if type_of(lista) != "array" || lista.len() != 5 {
        return `La flota tiene que ser una lista de 5 barcos como "inicio-fin". ${ejemplo}`;
    }
    let propuestos = [];
    for texto in lista {
        let casillas = leer_barco(texto);
        if casillas.is_empty() {
            return `No entiendo el barco "${texto}": tiene que ir en línea recta, como "A1-E1" o "C3-C6". ${ejemplo}`;
        }
        propuestos.push(casillas);
    }
    let tablero = vacio();
    let barcos = [];
    let usados = [];
    for largo in flota() {
        let k = -1;
        for j in 0..propuestos.len() {
            if k < 0 && !usados.contains(j) && propuestos[j].len() == largo { k = j; }
        }
        if k < 0 {
            return `Los barcos tienen que ser de 5, 4, 3, 3 y 2 casillas. ${ejemplo}`;
        }
        usados.push(k);
        if !cabe(tablero, propuestos[k]) {
            return `Los barcos no pueden solaparse ni tocarse (tampoco en diagonal). ${ejemplo}`;
        }
        for i in propuestos[k] { tablero[i] = 1; }
        barcos.push(propuestos[k]);
    }
    #{ tablero: tablero, barcos: barcos }
}

// Dispara a la casilla `i`: #{ tablero, resultado ("agua", "tocado" o "hundido"), barco }.
fn disparo(tablero, barcos, i) {
    let resultado = "agua";
    let barco = -1;
    if tablero[i] == 0 {
        tablero[i] = 2;
    } else if tablero[i] == 1 {
        tablero[i] = 3;
        resultado = "tocado";
        for k in 0..barcos.len() {
            if barcos[k].contains(i) {
                barco = k;
                let hundido = true;
                for j in barcos[k] {
                    if tablero[j] != 3 { hundido = false; }
                }
                if hundido {
                    for j in barcos[k] { tablero[j] = 4; }
                    resultado = "hundido";
                }
            }
        }
    }
    #{ tablero: tablero, resultado: resultado, barco: barco }
}

// El tablero como lo ve quien le dispara: sin los barcos que no ha tocado.
fn vista(tablero) {
    let v = [];
    for x in tablero {
        v.push(if x == 1 { 0 } else { x });
    }
    v
}

// Barcos que siguen a flote.
fn vivos(tablero, barcos) {
    let n = 0;
    for barco in barcos {
        let a_flote = false;
        for i in barco {
            if tablero[i] == 1 { a_flote = true; }
        }
        if a_flote { n += 1; }
    }
    n
}

// Si alguna de las 8 casillas de alrededor es de un barco hundido (entonces es agua seguro).
fn junto_a_hundido(v, i) {
    let f = i / 10;
    let c = i % 10;
    for df in -1..=1 {
        for dc in -1..=1 {
            let ff = f + df;
            let cc = c + dc;
            if ff >= 0 && ff < 10 && cc >= 0 && cc < 10 && v[ff * 10 + cc] == 4 { return true; }
        }
    }
    false
}

// Donde dispara nook (v: lo que sabe del tablero del usuario). Si hay un barco tocado sin
// hundir, junto a él (primero siguiendo la línea de los tocados); si no, busca en damero.
fn elegir(v, paridad) {
    let mejores = [];
    let puntos = 0;
    for i in 0..100 {
        if v[i] != 3 { continue; }
        let f = i / 10;
        let c = i % 10;
        for d in [[0, 1], [0, -1], [1, 0], [-1, 0]] {
            let ff = f + d[0];
            let cc = c + d[1];
            if ff < 0 || ff > 9 || cc < 0 || cc > 9 { continue; }
            let j = ff * 10 + cc;
            if v[j] != 0 || junto_a_hundido(v, j) { continue; }
            let bf = f - d[0];
            let bc = c - d[1];
            let p = if bf >= 0 && bf <= 9 && bc >= 0 && bc <= 9 && v[bf * 10 + bc] == 3 { 2 } else { 1 };
            if p > puntos {
                puntos = p;
                mejores = [];
            }
            if p == puntos { mejores.push(j); }
        }
    }
    if mejores.is_empty() {
        let libres = [];
        for i in 0..100 {
            if v[i] == 0 && !junto_a_hundido(v, i) { libres.push(i); }
        }
        for i in libres {
            if (i / 10 + i % 10) % 2 == paridad { mejores.push(i); }
        }
        if mejores.is_empty() { mejores = libres; }
    }
    if mejores.is_empty() {
        for i in 0..100 {
            if v[i] == 0 { mejores.push(i); }
        }
    }
    mejores[(azar() * mejores.len().to_float()).to_int()]
}

// El tablero en texto, para la IA.
fn rejilla(tablero, simbolos) {
    let s = "   A B C D E F G H I J\n";
    for f in 0..10 {
        if f < 9 { s += " "; }
        s += `${f + 1} `;
        for c in 0..10 {
            s += simbolos[tablero[f * 10 + c]];
            if c < 9 { s += " "; }
        }
        s += "\n";
    }
    s
}

// Un disparo en texto, para la IA ("C4: hundido (destructor)").
fn tiro_ia(tiro) {
    let texto = `${casilla(tiro.casilla)}: ${tiro.resultado}`;
    if tiro.resultado == "hundido" { texto += ` (${barcos_ia()[tiro.barco]})`; }
    texto
}

// ---- Partida ----

fn iniciar() {
    if this.fase != () { return; }
    let estadisticas = cargar();
    if type_of(estadisticas) != "map" { estadisticas = #{}; }
    this.estadisticas = estadisticas;
    this.rival = "nook";
    this.mensaje = "";
    this.reiniciar();
}

// Vuelve a colocar la flota del usuario, para una partida nueva.
fn reiniciar() {
    this.fase = "colocar";
    this.turno = "usuario";
    this.colocar_mia();
    this.suyo = vacio();
    this.barcos_suyos = [];
    this.tiro_usuario = ();
    this.tiro_rival = ();
    this.ultimo = "";
    this.disparos = 0;
    this.disparos_ia = 0;
}

fn colocar_mia() {
    let f = flota_al_azar();
    this.mio = f.tablero;
    this.barcos_mios = f.barcos;
}

// Empieza la partida con la flota del rival. Dispara primero el usuario.
fn comenzar(rival) {
    this.suyo = rival.tablero;
    this.barcos_suyos = rival.barcos;
    this.fase = "jugando";
    this.turno = "usuario";
    this.tiro_usuario = ();
    this.tiro_rival = ();
    this.ultimo = "";
    this.disparos = 0;
    this.disparos_ia = 0;
    this.paridad = if azar() < 0.5 { 0 } else { 1 };
    this.mostrar();
}

// El rival dispara al tablero del usuario.
fn recibir(i) {
    let r = disparo(this.mio, this.barcos_mios, i);
    this.mio = r.tablero;
    this.tiro_rival = #{ casilla: i, resultado: r.resultado, barco: r.barco };
    this.ultimo = "rival";
    if vivos(this.mio, this.barcos_mios) == 0 {
        this.terminar("perdido");
    } else {
        this.turno = "usuario";
    }
    this.mostrar();
    this.tiro_rival
}

// Fin de la partida: "ganado" o "perdido" (para el usuario). Se apunta en las estadísticas.
fn terminar(resultado) {
    this.fase = "fin";
    this.resultado = resultado;
    let e = this.estadisticas[this.rival] ?? #{};
    let ganadas = e.ganadas ?? 0;
    let perdidas = e.perdidas ?? 0;
    let mejor = e.mejor ?? 0;
    if resultado == "ganado" {
        ganadas += 1;
        if mejor == 0 || this.disparos < mejor { mejor = this.disparos; }
    } else {
        perdidas += 1;
    }
    this.estadisticas[this.rival] = #{ ganadas: ganadas, perdidas: perdidas, mejor: mejor };
    guardar(this.estadisticas);
}

// Turno de nook (sin IA): un momento después de que dispare el usuario.
fn turno_nook() {
    if this.fase != "jugando" || this.turno != "rival" || this.rival != "nook" { return; }
    this.recibir(elegir(vista(this.mio), this.paridad));
}

// ---- Panel ----

fn al_abrir() {
    this.iniciar();
    this.mostrar();
}

fn mostrar() {
    let t = textos();
    poner("texto-mio", t.tu_flota);
    poner("texto-rival", t.rival);
    poner("texto-nook", t.nook);
    poner("texto-ia", t.tu_ia);
    poner("texto-recolocar", t.recolocar);
    poner("texto-empezar", t.empezar);
    poner("texto-abandonar", t.abandonar);
    poner("texto-nueva", t.nueva);
    poner("mio", this.mio);
    // Los barcos del rival se ven al terminar.
    poner("rival", if this.fase == "fin" { this.suyo } else { vista(this.suyo) });
    poner("ultima-mia", if this.tiro_rival == () { -1 } else { this.tiro_rival.casilla });
    poner("ultima-rival", if this.tiro_usuario == () { -1 } else { this.tiro_usuario.casilla });
    poner("fase", if this.fase == "colocar" { 0 } else if this.fase == "jugando" { 1 } else { 2 });
    poner("mi-turno", this.fase == "jugando" && this.turno == "usuario");
    poner("rival-ia", this.rival == "ia");
    poner("estado", this.texto_estado(t));
    poner("mensaje", if this.mensaje == "" { "" } else { `${t.tu_ia}: ${this.mensaje}` });
    let e = this.estadisticas[this.rival] ?? #{};
    let marcador = rellenar(t.marcador, #{ g: e.ganadas ?? 0, p: e.perdidas ?? 0 });
    if (e.mejor ?? 0) > 0 { marcador += rellenar(t.mejor, #{ r: e.mejor }); }
    poner("marcador", marcador);
}

// El último disparo y, debajo, de quién es el turno (o cómo ha acabado).
fn texto_estado(t) {
    let turno = if this.fase == "colocar" {
        if this.rival == "ia" { t.colocar_ia } else { t.colocar }
    } else if this.fase == "jugando" {
        if this.turno == "usuario" { t.te_toca } else if this.rival == "nook" { t.piensa } else { t.espera_ia }
    } else if this.resultado == "ganado" {
        rellenar(t.ganado, #{ n: this.disparos })
    } else {
        t.perdido
    };
    if this.fase == "colocar" || this.ultimo == "" { return turno; }
    let tiro = if this.ultimo == "usuario" { this.tiro_usuario } else { this.tiro_rival };
    let quien = if this.ultimo == "usuario" { t.tu } else { t.el };
    let resultado = t[tiro.resultado];
    if tiro.resultado == "hundido" { resultado += ` (${t.barcos[tiro.barco]})`; }
    `${quien} → ${casilla(tiro.casilla)}: ${resultado}` + "\n" + turno
}

fn recolocar() {
    if this.fase != "colocar" { return; }
    this.colocar_mia();
    this.mostrar();
}

fn elegir_rival(ia) {
    if this.fase != "colocar" { return; }
    this.rival = if ia { "ia" } else { "nook" };
    this.mostrar();
}

// Botón Empezar: la flota del rival (nook o tu IA) va al azar.
fn empezar() {
    if this.fase != "colocar" { return; }
    this.comenzar(flota_al_azar());
}

fn abandonar() {
    if this.fase != "jugando" { return; }
    if this.rival == "ia" { avisar("disparo", "El usuario ha abandonado la partida. Usa empezar para jugar otra."); }
    this.reiniciar();
    this.mensaje = "";
    this.mostrar();
}

fn nueva_partida() {
    this.reiniciar();
    this.mensaje = "";
    this.mostrar();
}

// Disparo del usuario a una casilla del tablero del rival.
fn disparar(i) {
    if this.fase != "jugando" || this.turno != "usuario" || this.suyo[i] >= 2 { return; }
    let r = disparo(this.suyo, this.barcos_suyos, i);
    this.suyo = r.tablero;
    this.disparos += 1;
    this.tiro_usuario = #{ casilla: i, resultado: r.resultado, barco: r.barco };
    this.ultimo = "usuario";
    if r.resultado == "hundido" { personaje("rebote"); }
    if vivos(this.suyo, this.barcos_suyos) == 0 {
        this.terminar("ganado");
        this.mostrar();
        if this.rival == "ia" {
            avisar("disparo", `El usuario ha disparado en ${tiro_ia(this.tiro_usuario)} y ha hundido tu último barco: has perdido la partida. Usa empezar para jugar otra.`);
        }
        return;
    }
    this.turno = "rival";
    this.mostrar();
    if this.rival == "nook" {
        tras(1100, "turno_nook");
    } else {
        avisar("disparo", this.texto_turno_ia());
    }
}

// ---- Herramientas MCP (la IA del usuario como rival) ----

// La partida vista por la IA: nunca con los barcos del usuario.
fn informe() {
    let turno = if this.fase == "fin" { "la partida ha terminado" }
        else if this.turno == "rival" { "tuyo (usa disparar)" }
        else { "del usuario (usa esperar_turno)" };
    // (Los textos entre ` no entienden "\n": los saltos de línea van aparte.)
    let s = `Turno: ${turno}.` + "\n";
    s += `Te quedan ${vivos(this.suyo, this.barcos_suyos)} de 5 barcos; al usuario le quedan ${vivos(this.mio, this.barcos_mios)} de 5.` + "\n";
    if this.tiro_usuario != () { s += `Último disparo del usuario: ${tiro_ia(this.tiro_usuario)}.` + "\n"; }
    if this.tiro_rival != () { s += `Tu último disparo: ${tiro_ia(this.tiro_rival)}.` + "\n"; }
    s += "\nTu tablero (# tu barco, X tocado, * hundido, o agua donde disparó el usuario):\n";
    s += rejilla(this.suyo, ".#oX*");
    s += "\nTus disparos al tablero del usuario (. sin disparar, o agua, X tocado, * hundido):\n";
    s += rejilla(vista(this.mio), "..oX*");
    s += "\n" + `Idioma del usuario: ${idioma()} (úsalo con decir).`;
    s
}

// Lo que se le dice a la IA cuando le toca.
fn texto_turno_ia() {
    `El usuario ha disparado en ${tiro_ia(this.tiro_usuario)}. Te toca: usa disparar.` + "\n\n" + this.informe()
}

fn sin_partida() {
    if this.fase == "jugando" && this.rival == "nook" {
        "El usuario está jugando contra nook. Cuando acabe, usa empezar para jugar contra él."
    } else {
        "No hay ninguna partida contra ti en marcha: usa empezar."
    }
}

fn final_ia() {
    if this.resultado == "ganado" {
        "La partida ha terminado: el usuario ha hundido toda tu flota y has perdido. Usa empezar para jugar otra."
    } else {
        "La partida ha terminado: has hundido toda la flota del usuario y has ganado. Usa empezar para jugar otra."
    }
}

fn herramienta_empezar(argumentos) {
    this.iniciar();
    if this.fase == "jugando" && !(argumentos.reiniciar ?? false) {
        return `Ya hay una partida en marcha contra ${if this.rival == "ia" { "ti" } else { "nook" }}. Usa ver_partida, o empezar con reiniciar: true para empezar otra.`;
    }
    let rival = if argumentos.flota == () { flota_al_azar() } else { leer_flota(argumentos.flota) };
    if type_of(rival) == "string" { return rival; }
    if this.fase != "colocar" {
        if this.fase == "jugando" && this.rival == "ia" { avisar("disparo", "La partida se ha reiniciado."); }
        this.reiniciar();
    }
    this.rival = "ia";
    this.comenzar(rival);
    `Partida empezada: tableros de 10×10, columnas A-J y filas 1-10. Dispara primero el usuario: usa esperar_turno.` + "\n\n" + this.informe()
}

fn herramienta_ver_partida(argumentos) {
    this.iniciar();
    if this.rival != "ia" || this.fase == "colocar" { return this.sin_partida(); }
    let s = this.informe();
    if this.fase == "fin" { s = this.final_ia() + "\n\n" + s; }
    s
}

fn herramienta_disparar(argumentos) {
    this.iniciar();
    if this.rival == "ia" && this.fase == "fin" { return this.final_ia(); }
    if this.rival != "ia" || this.fase != "jugando" { return this.sin_partida(); }
    if this.turno != "rival" { return "No es tu turno: el usuario todavía no ha disparado. Usa esperar_turno."; }
    let i = leer_casilla(argumentos.casilla ?? "");
    if i < 0 { return "Casilla no válida: usa una letra de la A a la J y un número del 1 al 10, como \"B7\"."; }
    if this.mio[i] >= 2 { return `Ya habías disparado en ${casilla(i)}: elige otra casilla.`; }
    this.disparos_ia += 1;
    let tiro = this.recibir(i);
    if this.fase == "fin" {
        return `${tiro_ia(tiro)}. Era el último barco del usuario: ¡has ganado la partida en ${this.disparos_ia} disparos!`;
    }
    `${tiro_ia(tiro)}. Ahora dispara el usuario: usa esperar_turno.`
}

fn herramienta_esperar_turno(argumentos) {
    this.iniciar();
    if this.rival == "ia" && this.fase == "jugando" {
        if this.turno == "rival" { return this.texto_turno_ia(); }
        return esperar("disparo", 45);
    }
    if this.rival == "ia" && this.fase == "fin" { return this.final_ia(); }
    // Sin partida: espera por si el usuario empieza una contra su IA desde el panel.
    if this.fase == "colocar" { return esperar("disparo", 45); }
    this.sin_partida()
}

fn herramienta_decir(argumentos) {
    this.iniciar();
    let mensaje = argumentos.mensaje ?? "";
    if type_of(mensaje) != "string" { mensaje = `${mensaje}`; }
    mensaje.trim();
    if mensaje.len() > 100 {
        mensaje.truncate(100);
        mensaje += "…";
    }
    this.mensaje = mensaje;
    this.mostrar();
    "Mensaje puesto en el panel."
}
