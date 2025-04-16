section .text
global calcular_conversion

calcular_conversion:
    ; Entrada: valor en el stack (primer argumento)
    ; Salida: resultado en EAX

    push ebp
    mov ebp, esp

    mov eax, [ebp+8]    ; Cargar el primer argumento (valor)
    add eax, 10         ; Ejemplo: sumar 10 al valor

    pop ebp
    ret