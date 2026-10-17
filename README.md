# Addons de nook

Addons para [nook](https://github.com/fate-9x/nook): paneles que se añaden a la barra (minijuegos,
herramientas…) y que solo se cargan al abrirlos. Se instalan desde la configuración de nook, en la
sección **Addons**.

## Cómo es un addon

Cada addon está en `addons/<id>/`:

| Archivo | Qué es |
|---|---|
| `addon.json` | El manifiesto: nombre, versión, tamaño del panel, icono y herramientas MCP. |
| `panel.slint` | La interfaz, en [Slint](https://slint.dev). |
| `logica.rhai` | Lo que hace, en [Rhai](https://rhai.rs). Opcional. |

### `addon.json`

```json
{
  "id": "dado",
  "nombre": { "es": "Dado", "en": "Dice" },
  "descripcion": { "es": "Tira un dado.", "en": "Roll a die." },
  "version": "0.1.0",
  "nook_minimo": "1.1.0",
  "panel": { "ancho": 300, "alto": 132 },
  "icono": "M5 3h14a2 2 0 0 1 2 2v14…",
  "herramientas": [
    { "nombre": "tirar", "descripcion": "Tira el dado.", "parametros": { "type": "object", "properties": {} } }
  ]
}
```

- `id`: el nombre de su carpeta (minúsculas, números y `-`).
- `nook_minimo` (opcional): la primera versión de nook con la que funciona. Las anteriores lo
  muestran como incompatible y no lo dejan instalar.
- `icono`: un trazado SVG relleno en una caja de 24×24; nook lo pinta del color del tema.
- `herramientas`: lo que puede usar la IA del usuario por MCP (ver más abajo). Los parámetros son
  un JSON Schema.

### `panel.slint`

Exporta un componente `Panel` que hereda de `Window` y tiene el fondo transparente:

```slint
import { Tema } from "@nook/tema.slint";
import { BotonTexto } from "@nook/controles.slint";

export component Panel inherits Window {
    background: transparent;
    in property <int> numero;
    callback tirar();
    BotonTexto { texto: "Tirar"; clicked => { root.tirar(); } }
}
```

- `@nook/tema.slint` tiene los colores del usuario (`Tema.fondo`, `Tema.acento`, `Tema.texto`,
  `Tema.texto-suave`…); `@nook/controles.slint` e `@nook/iconos.slint`, los botones e iconos de
  nook.
- Solo se pueden usar archivos de la propia carpeta del addon.

### `logica.rhai`

Cada `callback` del panel llama a la función del script con el mismo nombre (con `_` en vez de
`-`). Las funciones tienen en `this` el estado del addon, que dura mientras nook está abierto:

```rhai
fn tirar() {
    let n = (azar() * 6.0).to_int() + 1;
    poner("numero", n);
}
```

| Función | Qué hace |
|---|---|
| `poner("propiedad", valor)`, `leer("propiedad")` | Cambia o lee una propiedad del panel. |
| `guardar(valor)`, `cargar()` | Datos que se conservan al cerrar nook. |
| `azar()` | Un número entre 0 y 1. |
| `tras(milisegundos, "funcion")` | Llama a esa función pasado ese tiempo. |
| `personaje("rebote")`, `personaje("aviso")` | El personaje de nook reacciona. |
| `idioma()` | `"es"`, `"en"`, `"ja"` o `"ko"`. |
| `cerrar()` | Cierra el panel. |
| `avisar("evento", valor)` | Despierta a una herramienta MCP que espera ese evento. |
| `esperar("evento", segundos)` | Lo que devuelve una herramienta MCP para esperar un `avisar`. |

Para llamar a otra función del script que use `this`, llámala como método: `this.mostrar()`
(si no, no recibe el estado).

Si existe, `al_abrir()` se llama cada vez que se abre el panel. El panel puede haberse creado de
nuevo (al abrir otro addon y volver, por ejemplo): pon en él lo que tenga que mostrar a partir de
`this`.

El script no puede leer ni escribir archivos ni conectarse a la red, y tiene un límite de
operaciones por llamada.

### Herramientas MCP

nook hace de servidor MCP (`nook.exe --mcp`) para la IA del usuario (Claude Desktop, Claude
Code…). Por cada herramienta del manifiesto, la IA ve `<id>__<nombre>`, y al usarla nook llama a
`herramienta_<nombre>(argumentos)` del script. Lo que devuelve (un texto o un mapa) es la respuesta
para la IA.

Para esperar algo del usuario (su jugada, por ejemplo), la herramienta devuelve
`esperar("evento", segundos)`. La respuesta llega cuando el script llama a
`avisar("evento", valor)`, con ese valor (como mucho 50 segundos; si no, la IA recibe que vuelva a
intentarlo).

## Probar un addon

Copia su carpeta a `%APPDATA%\nook\addons\<id>\` y abre nook: sale en la tira de la barra. Los
errores del panel o del script se ven en el propio panel.

## Publicar una versión

1. Cambia `version` en su `addon.json` y súbelo a `main`.
2. Crea y sube el tag `<id>-vX.Y.Z` (`git tag dado-v0.1.0`, `git push origin dado-v0.1.0`).

El workflow regenera `catalogo.json`, que es lo que lee nook.
