/* link.ld - Para MBR usando NASM ELF y ld */
OUTPUT_FORMAT(binary)   /* Salida binaria cruda */
ENTRY(_start)           /* Punto de entrada definido en pm.asm */

SECTIONS
{
    /* Dirección de carga para el MBR */
    . = 0x7C00;

    /* Sección principal donde irá todo */
    .text : AT(0x7C00)
    {
        *(.text)
        *(.data)
        *(.rodata*)
        *(.bss)
        *(COMMON)
    }

    /* Forzar tamaño a 510 bytes primero */
    . = 0x7c00 + 510;

    /* Ahora manualmente agregar firma */
    .signature :
    {
        BYTE(0x55)
        BYTE(0xAA)
    }

    /* Opcional: Verificación estricta */
    /* ASSERT(. == 0x7c00 + 512, "Error: MBR debe ser 512 bytes!") */
}
