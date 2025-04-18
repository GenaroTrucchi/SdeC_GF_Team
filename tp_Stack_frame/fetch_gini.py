#!/usr/bin/env python3
"""fetch_gini.py – Obtiene el índice GINI más reciente (2011‑2020) para Argentina desde la API del Banco Mundial
y lo envía al programa C de 32 bits mediante stdin. Luego imprime el entero (floor+1) que retorna.
Requisitos: requests (`pip install requests`).
"""
import json
import subprocess
import sys
from pathlib import Path

import requests

URL = (
    "https://api.worldbank.org/v2/en/country/ARG/indicator/"
    "SI.POV.GINI?format=json&date=2011:2020&per_page=50&page=1"
)

def get_latest_gini():
    """Devuelve el valor GINI más reciente como float."""
    try:
        resp = requests.get(URL, timeout=10)
        resp.raise_for_status()
    except requests.RequestException as exc:
        print(f"Error al solicitar la API: {exc}", file=sys.stderr)
        sys.exit(1)

    data = resp.json()
    if len(data) < 2:
        print("Estructura JSON inesperada", file=sys.stderr)
        sys.exit(1)

    series = data[1]
    # ordenar por año descendente y devolver el primero no nulo
    for entry in sorted(series, key=lambda x: int(x["date"]), reverse=True):
        val = entry["value"]
        if val is not None:
            return float(val)

    print("No se encontró un valor GINI válido", file=sys.stderr)
    sys.exit(1)


def main():
    gini_val = get_latest_gini()

    proc = subprocess.run(
        ["./build/gini_processor"],
        input=f"{gini_val}\n".encode("utf-8"),
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
    )

    if proc.returncode != 0:
        print("gini_processor falló:", proc.stderr.decode(), file=sys.stderr)
        sys.exit(proc.returncode)

    result = proc.stdout.decode().strip()
    print(f"GINI (floor+1) = {result}")


if __name__ == "__main__":
    main()
