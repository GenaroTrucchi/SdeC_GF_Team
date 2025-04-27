[bits 32]

VIDEO_MEMORY equ 0xb8000            ; Base de la memoria de video
WHITE_ON_BLACK equ 0x0f             ; Atributo: blanco sobre negro
LINE_SIZE equ 480                   ; 80 columnas * 2 bytes por columna

; Imprime una cadena terminada en null apuntada por EBX
print_string_pm:
    pushad
    mov edx, VIDEO_MEMORY
    add edx, LINE_SIZE * 3           ; ⬅️ Esto mueve 3 filas hacia abajo

.loop:
    mov al, [ebx]
    mov ah, WHITE_ON_BLACK
    cmp al, 0
    je .done
    mov [edx], ax
    add ebx, 1
    add edx, 2
    jmp .loop

.done:
    popad
    ret
