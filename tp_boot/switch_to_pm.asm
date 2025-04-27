; switch_to_pm.asm

global switch_to_pm     ; Hacer visible la etiqueta switch_to_pm para pm.asm
global BEGIN_PM        ; Hacer visible la etiqueta BEGIN_PM para pm.asm

; Incluir la función de impresión de PM
%include "print_string_pm.asm" ; Asegúrate que esta función también sea global o visible

[bits 16]
switch_to_pm:
    cli                         ; 1. Deshabilitar interrupciones

    lgdt [gdt_descriptor]       ; 2. Cargar GDTR (gdt_descriptor definido en gdt.asm)

    ; 3. Activar Modo Protegido (Bit PE en CR0)
    mov eax, cr0
    or eax, 0x01                ; Usar 0x01 en lugar de 1 por claridad hexadecimal
    mov cr0, eax

    ; 4. Salto Largo para limpiar pipeline y cargar CS
    jmp 0x08 : init_pm          ; Salto a: Selector Codigo (0x08) : Offset de init_pm

; --- Código de Modo Protegido ---
[bits 32]
init_pm:
    ; 5. Cargar registros de segmento de datos y pila con el selector de Datos R/W (0x10)
    mov ax, 0x10                ; AX = Selector Datos R/W
    mov ds, ax
    mov es, ax
    mov fs, ax
    mov gs, ax
    mov ss, ax                  ; Importante para la pila

    ; 6. Configurar la pila en modo protegido
    mov esp, 0x90000            ; Establecer puntero de pila

    ; 7. Llamar a la rutina principal de PM (donde imprimiremos y haremos el test)
    call BEGIN_PM               ; Salta a la etiqueta BEGIN_PM (definida abajo)

; --- Rutina Principal en Modo Protegido ---
; Definimos BEGIN_PM aquí para tener todo junto
BEGIN_PM:
    ; Imprimir mensaje de éxito en Modo Protegido
    mov ebx, MSG_PROT_MODE      ; Puntero a la cadena (definida en pm.asm)
    call print_string_pm        ; Imprimir

    ; --- Prueba de Escritura ---

    ; Prueba 1: Usando Segmento R/W (DS ya tiene 0x10)
    ; Escribir un valor en una dirección de memoria (ej: 0x2000)
    mov dword [0x2000], 0xCAFEBABE ; DEBERÍA FUNCIONAR

    ; Prueba 2: Usando Segmento Read-Only (Selector 0x18)
    ; (Asegúrate que el descriptor 3 en gdt.asm esté descomentado y tenga 0x90)
    mov ax, 0x18                ; AX = Selector Datos Read-Only
    mov ds, ax                  ; Cambiar DS para usar el segmento R/O
    mov dword [0x3000], 0xDEADBEEF ; <<< ESTA INSTRUCCIÓN DEBE CAUSAR #GP

    ; --- Código Inalcanzable (si #GP ocurre) ---
    ; Si por alguna razón (error en GDT?) la escritura R/O no causa #GP,
    ; llegaría aquí. Podríamos imprimir un error o colgar de forma distinta.
.write_protection_failed:
    ; (Aquí podrías intentar imprimir un mensaje como "Error R/O Write!")
    ; Por simplicidad, solo nos colgamos con un color diferente o patrón
    mov edi, 0xb8000 + 1600      ; Otra línea
    mov ax, 0x4f45  ; 'E' Roja sobre Negro
    mov [edi], ax
    mov ax, 0x4f52  ; 'R' Roja
    mov [edi+2], ax
    mov ax, 0x4f52  ; 'R' Roja
    mov [edi+4], ax
.hang_error:
    cli
    hlt
    jmp .hang_error

; Incluir la función print_string_pm (ya incluida al principio)
; %include "print_string_pm.asm"