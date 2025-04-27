; switch_to_pm.asm
global switch_to_pm
; Incluir la función de impresión de PM aquí o hacerla global
%include "print_string_pm.asm"

[bits 16]
switch_to_pm:
    cli                         ; 1. Deshabilitar interrupciones

;%ifdef USE_DEBUG_PRINT
;    mov si, DEBUG_MSG_GDT_LOAD
;    call print_string
;%endif

    lgdt [gdt_descriptor]       ; 2. Cargar GDTR (gdt_descriptor definido en gdt.asm)

    ; 3. Activar Modo Protegido (Bit PE en CR0)
    mov eax, cr0
    or eax, 1
    mov cr0, eax

    ; 4. Salto Largo para limpiar pipeline y cargar CS
    ;    Usamos los valores fijos de los selectores
    jmp 0x08 : init_pm          ; Salto a: Selector Codigo (0x08) : Offset de init_pm

; --- Código de Modo Protegido ---
[bits 32]
init_pm:
    ; 5. Cargar registros de segmento de datos y pila con el selector de Datos (0x10)
    mov ax, 0x10                ; AX = Selector Datos R/W
    mov ds, ax
    mov es, ax
    mov fs, ax
    mov gs, ax
    mov ss, ax

    ; 6. Configurar la pila en modo protegido
    ;    La dirección base del stack (0x90000) es arbitraria pero debe ser válida
    mov esp, 0x90000            ; Usar un área de memoria segura

    ; 7. Llamar a la rutina principal de PM
    call BEGIN_PM               ; Salta a la etiqueta en pm.asm

; Esta etiqueta DEBE existir y ser alcanzable desde el `call BEGIN_PM` anterior
BEGIN_PM:
    mov ebx, MSG_PROT_MODE      ; MSG_PROT_MODE debe estar accesible (en pm.asm)
    call print_string_pm        ; La función está incluida arriba

    ; Colgarse aquí o realizar las pruebas de escritura
.hang_pm:
    cli
    hlt
    jmp .hang_pm
