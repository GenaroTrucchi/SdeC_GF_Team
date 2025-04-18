; gini_calc.asm – Convierte float → int (floor) y suma 1
; Ensamblar:  nasm -f elf32 gini_calc.asm -g

section .text
    global calculate_gini_int          ; firma: int calculate_gini_int(float)

; int calculate_gini_int(float x)
calculate_gini_int:
    push    ebp
    mov     ebp, esp

    sub     esp, 4              ; espacio temporal para el entero
    fld     dword [ebp+8]       ; cargar argumento float
    fistp   dword [esp]         ; convertir a int (trunc) y guardar
    mov     eax, [esp]          ; mover a eax (valor de retorno)
    add     eax, 1
    leave                       ; restaura ebp y esp
    ret
