; print_string.asm
global print_string
[bits 16]                       ; Asegurar modo 16 bits

; Imprime la cadena terminada en null apuntada por SI
; Usa BIOS servicio 0x10 / AH=0x0E (teletipo)
print_string:
    pusha                       ; Guardar todos los registros generales
.next_char:
    lodsb                       ; AL = [DS:SI], SI++
    or al, al                   ; Poner flags (es AL cero?)
    jz .done                    ; Si AL es 0, saltar a .done

    mov ah, 0x0E                ; Función Teletype BIOS
    mov bh, 0                   ; Número de página 0
    ; BL = Atributo (color) se puede dejar por defecto o poner: mov bl, 0x07
    int 0x10                    ; Llamar interrupción de video

    jmp .next_char              ; Ir al siguiente carácter
.done:
    popa                        ; Restaurar registros
    ret                         ; Volver