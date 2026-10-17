"""Genera catalogo.json: la lista de addons que nook ofrece para instalar.

De cada addon se publica la versión de su último tag (`<id>-vX.Y.Z`): nook descarga sus archivos
de ese tag (así no cambian) y comprueba el SHA-256 de cada uno con el del catálogo.
"""

import hashlib
import json
import re
import subprocess
from pathlib import Path

RAIZ = Path(__file__).resolve().parent.parent


def git(*argumentos: str) -> bytes:
    return subprocess.run(["git", *argumentos], cwd=RAIZ, check=True, capture_output=True).stdout


def ultimo_tag(id_addon: str) -> str | None:
    patron = re.compile(rf"^{re.escape(id_addon)}-v(\d+)\.(\d+)\.(\d+)$")
    tags = []
    for tag in git("tag", "--list", f"{id_addon}-v*").decode().split():
        if coincide := patron.match(tag):
            tags.append((tuple(int(n) for n in coincide.groups()), tag))
    return max(tags)[1] if tags else None


def entrada(id_addon: str, tag: str) -> dict:
    carpeta = f"addons/{id_addon}"
    nombres = git("ls-tree", "--name-only", tag, f"{carpeta}/").decode().split()
    archivos = {}
    for ruta in nombres:
        contenido = git("show", f"{tag}:{ruta}")
        archivos[Path(ruta).name] = hashlib.sha256(contenido).hexdigest()
    manifiesto = json.loads(git("show", f"{tag}:{carpeta}/addon.json"))
    if manifiesto["id"] != id_addon:
        raise SystemExit(f"{carpeta}/addon.json tiene el id {manifiesto['id']!r}")
    version_tag = tag.removeprefix(f"{id_addon}-v")
    if manifiesto["version"] != version_tag:
        raise SystemExit(f"{tag}: addon.json dice la versión {manifiesto['version']}")
    return {
        "id": id_addon,
        "nombre": manifiesto["nombre"],
        "descripcion": manifiesto.get("descripcion", {}),
        "version": manifiesto["version"],
        "nook_minimo": manifiesto.get("nook_minimo"),
        "icono": manifiesto.get("icono", ""),
        "tag": tag,
        "archivos": archivos,
    }


def main() -> None:
    addons = []
    for carpeta in sorted((RAIZ / "addons").iterdir()):
        if carpeta.is_dir() and (tag := ultimo_tag(carpeta.name)):
            addons.append(entrada(carpeta.name, tag))
    catalogo = {"version": 1, "addons": addons}
    texto = json.dumps(catalogo, ensure_ascii=False, indent=2) + "\n"
    (RAIZ / "catalogo.json").write_text(texto, encoding="utf-8")
    print("catalogo.json: " + ", ".join(f"{a['id']} {a['version']}" for a in addons))


if __name__ == "__main__":
    main()
