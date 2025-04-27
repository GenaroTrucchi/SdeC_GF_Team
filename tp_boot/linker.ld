/* linker.ld - Para generar ELF intermedio */
OUTPUT_FORMAT(elf32-i386)  /* <<--- CAMBIADO A ELF */
OUTPUT_ARCH(i386)         /* Añadir por claridad */
ENTRY(_start)

SECTIONS
{
    . = 0x7C00; /* Dirección virtual/física base */

    .text : AT(ADDR(.text)) /* Cargar en la dirección física correcta */
    {
        *(.text) *(.data) *(.rodata*) /* Combina secciones aquí */
    }

    .bss : AT(ADDR(.bss)) ALIGN(4) /* Sección BSS si la hubiera */
    {
         *(.bss) *(COMMON)
    }

     /* NO pongas la firma aquí, déjaselo a objcopy o a un paso final */
     /* El tamaño lo gestiona objcopy al extraer */
}