// Copiloto: tu IA te pregunta en la barra (eliges una de sus respuestas o escribes la tuya) y te
// avisa cuando termina o te necesita, sin que tengas que mirar su ventana.
//
// `this.pregunta` es la que espera respuesta ("" si no hay), con sus `this.opciones`. Al
// responder, la respuesta va a la herramienta que espera y se queda también en `this.respondida`:
// cada espera dura como mucho unos 45 segundos, y si el usuario responde justo cuando la IA no
// esperaba, se la lleva al volver a preguntar lo mismo.

fn textos() {
    let todos = #{
        es: #{
            titulo: "Copiloto", pregunta: "Tu IA pregunta:",
            nada: "Cuando tu IA te pregunte algo o te avise, lo verás aquí.",
            respondido: "Has respondido: {r}", otra: "Otra respuesta…", enviar: "Enviar", ia: "Tu IA",
        },
        en: #{
            titulo: "Copilot", pregunta: "Your AI asks:",
            nada: "When your AI asks you something or lets you know, you'll see it here.",
            respondido: "You answered: {r}", otra: "Another answer…", enviar: "Send", ia: "Your AI",
        },
        ja: #{
            titulo: "コパイロット", pregunta: "AIからの質問:",
            nada: "AIからの質問やお知らせはここに表示されます。",
            respondido: "回答: {r}", otra: "別の回答…", enviar: "送信", ia: "AI",
        },
        ko: #{
            titulo: "코파일럿", pregunta: "AI의 질문:",
            nada: "AI의 질문이나 알림이 여기에 표시됩니다.",
            respondido: "내 답변: {r}", otra: "다른 답변…", enviar: "보내기", ia: "AI",
        },
    };
    todos[idioma()] ?? todos.es
}

// Un texto de la IA o del usuario, sin espacios a los lados y como mucho de `largo` caracteres.
fn recortar(valor, largo) {
    let s = if type_of(valor) == "string" { valor } else if type_of(valor) == "()" { "" } else { `${valor}` };
    s.trim();
    if s.len() > largo {
        s.truncate(largo);
        s += "…";
    }
    s
}

fn iniciar() {
    if type_of(this.pregunta) == "string" { return; }
    this.pregunta = "";
    this.opciones = [];
    this.respondida = ();
    this.ultima = "";
    this.mensaje = "";
}

// ---- Panel ----

fn al_abrir() {
    this.iniciar();
    this.mostrar();
}

fn mostrar() {
    let t = textos();
    let preguntando = this.pregunta != "";
    let texto = if preguntando {
        this.pregunta
    } else if this.ultima != "" {
        let s = t.respondido;
        s.replace("{r}", this.ultima);
        s
    } else {
        t.nada
    };
    poner("titulo", if preguntando { t.pregunta } else { t.titulo });
    poner("texto", texto);
    poner("opciones", this.opciones);
    poner("preguntando", preguntando);
    poner("mensaje", if this.mensaje == "" { "" } else { `${t.ia}: ${this.mensaje}` });
    poner("texto-otra", t.otra);
    poner("texto-enviar", t.enviar);
}

fn elegir(i) {
    if i >= 0 && i < this.opciones.len() { this.responder(this.opciones[i]); }
}

fn enviar(texto) {
    let r = recortar(texto, 500);
    if r == "" { return; }
    poner("libre", "");
    this.responder(r);
}

fn responder(r) {
    if this.pregunta == "" { return; }
    this.respondida = #{ pregunta: this.pregunta, respuesta: r };
    this.pregunta = "";
    this.opciones = [];
    this.ultima = r;
    this.mostrar();
    avisar("respuesta", `El usuario ha respondido: ${r}`);
}

// ---- Herramientas MCP ----

fn herramienta_preguntar(argumentos) {
    this.iniciar();
    let pregunta = recortar(argumentos.pregunta, 240);
    if pregunta == "" { return "Falta la pregunta."; }
    // La respuesta que llegó mientras la IA no esperaba.
    if type_of(this.respondida) == "map" && this.respondida.pregunta == pregunta {
        let r = this.respondida.respuesta;
        this.respondida = ();
        return `El usuario ha respondido: ${r}`;
    }
    // Si es la misma que ya espera respuesta, solo se sigue esperando.
    if pregunta != this.pregunta {
        let opciones = [];
        let lista = argumentos.opciones;
        if type_of(lista) == "array" {
            for o in lista {
                let texto = recortar(o, 50);
                if texto != "" && opciones.len() < 4 { opciones.push(texto); }
            }
        }
        this.pregunta = pregunta;
        this.opciones = opciones;
        this.respondida = ();
        this.ultima = "";
        this.mostrar();
        personaje("aviso");
    }
    esperar("respuesta", 45)
}

fn herramienta_avisar(argumentos) {
    this.iniciar();
    let mensaje = recortar(argumentos.mensaje, 200);
    if mensaje == "" { return "Falta el mensaje."; }
    this.mensaje = mensaje;
    this.mostrar();
    personaje("aviso");
    "Aviso puesto en la barra del usuario."
}
