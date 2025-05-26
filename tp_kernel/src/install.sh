#!/bin/bash

set -e  # Terminar si algo falla

MODNAME="hello"
TARGET_DIR="/lib/modules/$(uname -r)/extra"

echo "[*] Instalando módulo $MODNAME en $TARGET_DIR"
mkdir -p "$TARGET_DIR"
cp "$MODNAME.ko" "$TARGET_DIR/"
depmod -a

echo "[+] Módulo instalado correctamente."
