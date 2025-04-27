#!/bin/bash
# ============================================================================
# Script para compilar, linkear, extraer, PADDEAR/FIRMAR y correr un bootloader
# ============================================================================
# Herramientas:
#   - NASM: ensamblar a objeto ELF
#   - LD: linkear objeto ELF a ejecutable ELF final
#   - OBJCOPY: extraer binario crudo del ELF final
#   - DD: paddear/escribir firma en binario crudo
#   - QEMU: emular el binario crudo
# ============================================================================

# Nombre base para los archivos (sin extensión)
BASENAME="pm"

# Limpiar archivos antiguos (opcional pero recomendado)
echo ">> Limpiando archivos anteriores..."
rm -f ${BASENAME}.o ${BASENAME}.elf ${BASENAME}.img ${BASENAME}_final.img

# 1. Ensamblar el archivo principal a ELF
echo ">> Ensamblando ${BASENAME}.asm a ${BASENAME}.o..."
nasm -f elf ${BASENAME}.asm -o ${BASENAME}.o
if [ $? -ne 0 ]; then echo "!! Error de ensamblaje."; exit 1; fi

# 2. Linkear el objeto usando LD y el script (que genera ELF)
echo ">> Linkeando ${BASENAME}.o a ${BASENAME}.elf..."
ld -m elf_i386 -T linker.ld -o ${BASENAME}.elf ${BASENAME}.o
if [ $? -ne 0 ]; then echo "!! Error de linkeo."; exit 1; fi

# 3. Extraer el binario crudo (.img) desde el ELF (.elf)
echo ">> Extrayendo binario ${BASENAME}.img desde ${BASENAME}.elf..."
objcopy -O binary ${BASENAME}.elf ${BASENAME}.img
if [ $? -ne 0 ]; then echo "!! Error de objcopy."; exit 1; fi
echo "   Tamaño extraído: $(stat -c%s "${BASENAME}.img") bytes."

# 4. Padear a 512 bytes y añadir firma MBR usando DD
echo ">> Ajustando tamaño a 512 bytes y añadiendo firma..."
# Crear un archivo de 512 bytes lleno de ceros
dd if=/dev/zero of=${BASENAME}_final.img bs=1 count=512 status=none
# Copiar el contenido extraído de pm.img al inicio del archivo paddado
dd if=${BASENAME}.img of=${BASENAME}_final.img conv=notrunc status=none
# Escribir la firma 0xAA55 (bytes 55 AA) en los offsets 510 y 511
printf '\x55\xAA' | dd of=${BASENAME}_final.img bs=1 seek=510 conv=notrunc status=none
if [ $? -ne 0 ]; then echo "!! Error ajustando tamaño/firma con dd."; exit 1; fi

# 5. Verificar tamaño y firma del archivo FINAL (Opcional pero recomendado)
echo ">> Verificando ${BASENAME}_final.img..."
filesize=$(stat -c%s "${BASENAME}_final.img")
if [ "$filesize" -ne 512 ]; then
    echo "!! Error: ${BASENAME}_final.img tiene tamaño ${filesize} bytes, se esperaban 512."
    exit 1 # Detener si el tamaño es incorrecto
fi
last_two=$(tail -c 2 "${BASENAME}_final.img" | od -A n -t x1 | sed 's/ //g')
if [ "$last_two" != "55aa" ]; then
    echo "!! Error: Firma MBR incorrecta o faltante en ${BASENAME}_final.img (encontrado: ${last_two})."
    exit 1 # Detener si la firma es incorrecta
fi
echo "   Tamaño y firma final OK."

# 6. Ejecutar el BINARIO FINAL PADDADO/FIRMADO en QEMU
echo ">> Ejecutando ${BASENAME}_final.img en QEMU..."
# ¡¡ ASEGÚRATE DE USAR EL ARCHIVO FINAL !!
qemu-system-i386 -fda ${BASENAME}_final.img -boot a

echo ">> Script finalizado."