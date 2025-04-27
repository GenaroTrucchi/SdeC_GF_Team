; pm.asm (Modificado para ELF, archivo principal)

section .text                   ; Todo irá a la sección .text por defecto

global _start                   ; Hacer _start visible para el linker

;%define USE_DEBUG_PRINT ; Descomentar para imprimir antes/después de GDT load

[bits 16]
_start:
    ; ---- Inicializar segmentos ----
    xor ax, ax
    mov ds, ax
    mov es, ax
    mov ss, ax

    mov bp, 0x9000              ; Base de la pila (lejos del código)
    mov sp, bp                  ; Puntero de pila

    ; Imprimir mensaje inicial
    mov si, MSG_REAL_MODE
    call print_string           ; Incluido abajo

    ; Llamar a la rutina que hace la transición
    call switch_to_pm           ; Incluida abajo

    ; Si switch_to_pm retornara (no debería), colgarse
    cli
.hang_final:
    hlt
    jmp .hang_final

; --- Inclusión de otros archivos ---
%include "print_string.asm"     ; Funciones de impresión Modo Real
%include "gdt.asm"             ; Definición de GDT y descriptor GDTR
%include "switch_to_pm.asm"   ; Código para cambiar de modo y rutina PM

; --- Datos (terminarán en la sección .text también) ---
MSG_REAL_MODE db "Comienza en 16-bit Modo Real", 0
MSG_PROT_MODE db "Paso exitosamente a 32-bit Modo protegido", 0

; --- La pila se reserva implícitamente por el linker en .bss o .text ---
; --- Relleno y firma serán manejados por el linker script ---