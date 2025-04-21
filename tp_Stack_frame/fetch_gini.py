#!/usr/bin/env python3
"""
@file fetch_gini.py
@brief Consulta el índice GINI más reciente para Argentina desde la API del Banco Mundial.
       Luego lo pasa al programa C (gini_processor) por stdin y muestra el resultado entero (floor + 1).

@details Requiere la librería `requests` (instalable con `pip install requests`). El valor GINI se obtiene en formato JSON,
se selecciona el más reciente disponible (entre 2011 y 2020), y se entrega como entrada al ejecutable C,
que devuelve el valor convertido a entero truncado más uno, que se imprime por consola.
"""

import json
import subprocess
import sys
from pathlib import Path
import requests

# URL de la API del Banco Mundial para el índice GINI de Argentina (2011–2020)
URL = (
    "https://api.worldbank.org/v2/en/country/ARG/indicator/"
    "SI.POV.GINI?format=json&date=2011:2020&per_page=50&page=1"
)

def get_latest_gini():
    """
    @brief Obtiene el valor GINI más reciente no nulo desde la API del Banco Mundial.

    @return float Valor GINI más reciente.
    @retval None Si ocurre un error, imprime mensaje y termina el programa.
    """
    try:
        resp = requests.get(URL, timeout=10)
        resp.raise_for_status()  # lanza excepción si hubo error HTTP
    except requests.RequestException as exc:
        print(f"Error al solicitar la API: {exc}", file=sys.stderr)
        sys.exit(1)

    data = resp.json()
    if len(data) < 2:
        print("Estructura JSON inesperada", file=sys.stderr)
        sys.exit(1)

    series = data[1]

    # Ordena por año (descendente) y devuelve el primer valor no nulo
    for entry in sorted(series, key=lambda x: int(x["date"]), reverse=True):
        val = entry["value"]
        if val is not None:
            return float(val)

    print("No se encontró un valor GINI válido", file=sys.stderr)
    sys.exit(1)


def main():
    """
    @brief Función principal. Obtiene el valor GINI y lo envía al ejecutable C.
           Luego imprime el valor procesado por consola.
    """
    # 1) Llama a get_latest_gini() para recuperar el último índice GINI (float).
    gini_val = get_latest_gini()

    # 2) Ejecuta el binario de 32 bits `gini_processor` y le pasa
    #    el valor GINI por STDIN (convertido a bytes y terminado en '\n').
    proc = subprocess.run(
        ["./build/gini_processor"],        # Comando a ejecutar
        input=f"{gini_val}\n".encode("utf-8"),  # STDIN que recibe el programa C
        stdout=subprocess.PIPE,            # Captura STDOUT del proceso
        stderr=subprocess.PIPE,            # Captura STDERR del proceso
    )

    # 3) Si el programa C devolvió un código distinto de 0, muestra
    #    el error y finaliza con el mismo código de salida.
    if proc.returncode != 0:
        print("gini_processor falló:", proc.stderr.decode(), file=sys.stderr)
        sys.exit(proc.returncode)

    # 4) Decodifica la salida del programa C, quita espacios en blanco
    #    y la imprime con la etiqueta solicitada.
    result = proc.stdout.decode().strip()
    print(f"GINI (floor+1) = {result}")


# 5) Punto de entrada estándar en Python: si el archivo se ejecuta
#    directamente (no importado), se llama a main().
if __name__ == "__main__":
    main()

