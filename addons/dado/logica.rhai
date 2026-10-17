// Dado: cada tirada sale en el panel y se guarda en el historial (las últimas 8).

fn textos() {
    let todos = #{
        es: #{ boton: "Tirar", tu: "Lo has tirado tú", ia: "Lo ha tirado tu IA", ultimas: "Últimas: " },
        en: #{ boton: "Roll", tu: "You rolled it", ia: "Your AI rolled it", ultimas: "Last: " },
        ja: #{ boton: "振る", tu: "あなたが振りました", ia: "AIが振りました", ultimas: "履歴: " },
        ko: #{ boton: "굴리기", tu: "내가 굴렸습니다", ia: "AI가 굴렸습니다", ultimas: "기록: " },
    };
    todos[idioma()] ?? todos.es
}

fn al_abrir() {
    if this.historial == () {
        this.historial = cargar() ?? [];
    }
    poner("texto-boton", textos().boton);
    this.mostrar();
}

fn mostrar() {
    let texto = "";
    if !this.historial.is_empty() {
        texto = textos().ultimas;
        for n in this.historial {
            texto += `${n}  `;
        }
    }
    poner("historial", texto);
}

fn lanzar(quien) {
    let n = (azar() * 6.0).to_int() + 1;
    this.historial.insert(0, n);
    this.historial.truncate(8);
    guardar(this.historial);
    poner("numero", n);
    poner("quien", quien);
    this.mostrar();
    if n == 6 {
        personaje("rebote");
    }
    n
}

// Botón del panel.
fn tirar() {
    this.lanzar(textos().tu);
}

// Herramienta MCP `tirar`: la usa la IA del usuario.
fn herramienta_tirar(argumentos) {
    if this.historial == () {
        this.historial = cargar() ?? [];
    }
    let n = this.lanzar(textos().ia);
    `Ha salido un ${n}.`
}
