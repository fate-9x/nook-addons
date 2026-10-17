"""Genera el archivo .nookaddon de una versión de un addon: el addon entero en un solo archivo,
para añadirlo a mano en Nookly ("Añadir addon…" en la configuración, o arrastrándolo a la barra).

    python herramientas/nookaddon.py dado-v0.1.0      # deja dist/dado-0.1.0.nookaddon

Toma los archivos del tag (como el catálogo), así que sale igual en cualquier equipo. El workflow
lo adjunta a la release de ese tag.
"""

import json
import re
import subprocess
import sys
from pathlib import Path

RAIZ = Path(__file__).resolve().parent.parent
FORMATO = 1


def git(*argumentos: str) -> bytes:
    return subprocess.run(["git", *argumentos], cwd=RAIZ, check=True, capture_output=True).stdout


def generar(tag: str) -> Path:
    coincide = re.fullmatch(r"([a-z0-9][a-z0-9-]*)-v(\d+\.\d+\.\d+)", tag)
    if not coincide:
        raise SystemExit(f"{tag}: no es un tag de addon (<id>-vX.Y.Z)")
    id_addon, version = coincide.groups()
    carpeta = f"addons/{id_addon}"
    archivos = {}
    for ruta in git("ls-tree", "--name-only", tag, f"{carpeta}/").decode().split():
        archivos[Path(ruta).name] = git("show", f"{tag}:{ruta}").decode("utf-8")
    manifiesto = json.loads(archivos["addon.json"])
    if manifiesto["id"] != id_addon or manifiesto["version"] != version:
        raise SystemExit(f"{tag}: addon.json dice {manifiesto['id']} {manifiesto['version']}")
    destino = RAIZ / "dist" / f"{id_addon}-{version}.nookaddon"
    destino.parent.mkdir(exist_ok=True)
    destino.write_text(json.dumps({"formato": FORMATO, "archivos": archivos}, ensure_ascii=False, indent=1), encoding="utf-8")
    print(destino.relative_to(RAIZ))
    return destino


if __name__ == "__main__":
    for tag in sys.argv[1:]:
        generar(tag)
