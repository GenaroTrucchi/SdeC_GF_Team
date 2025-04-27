; gdt.asm

; NASM maneja esto en la sección actual (.text por defecto aquí)

; ------- GDT (Global Descriptor Table) ---------------------
; Es importante que gdt_start esté alineado, aunque ALIGN no funciona
; bien en -f bin, en ELF sí. Podríamos añadir ALIGN 8 aquí.
; ALIGN 8 ; Opcional, asegura alineación a 8 bytes
gdt_start:
    ; Descriptor 0: Nulo (Obligatorio) - 8 bytes
    gdt_null:
    dd 0x0                      ; dd = Define Double word (4 bytes)
    dd 0x0

    ; Descriptor 1: Segmento de Código (0x08) - 8 bytes
    ; Base=0, Limit=4GB(FFFFF pages), Access=0x9A, Flags=0xCF (32bit, 4K Gran)
    gdt_code:
    dw 0xFFFF                   ; Limite (0-15)
    dw 0x0000                   ; Base (0-15)
    db 0x00                     ; Base (16-23)
    db 0x9A                     ; Access Byte (Present=1, DPL=0, Code, Read/Execute)
    db 0xCF                     ; Flags(G=1, D=1 -> 32bit) + Limit(16-19)=1111
    db 0x00                     ; Base (24-31)

    ; Descriptor 2: Segmento de Datos (0x10) - 8 bytes
    ; Base=0, Limit=4GB, Access=0x92 (Data, Read/Write), Flags=0xCF
    gdt_data:
    dw 0xFFFF                   ; Limite (0-15)
    dw 0x0000                   ; Base (0-15)
    db 0x00                     ; Base (16-23)
    db 0x92                     ; Access Byte (Present=1, DPL=0, Data, Read/Write)
    db 0xCF                     ; Flags(G=1, D=1 -> 32bit) + Limit(16-19)=1111
    db 0x00                     ; Base (24-31)

    ; >> Puedes añadir aquí el descriptor Read-Only si lo necesitas para el test <<
    ; Descriptor 3: Datos Read-Only (0x18) - 8 bytes (Opcional para test)
    ; gdt_data_ro:
    ; dw 0xFFFF
    ; dw 0x0000
    ; db 0x00
    ; db 0x90                     ; Access Byte (Present=1, DPL=0, Data, Write=0 -> R/O)
    ; db 0xCF
    ; db 0x00

gdt_end:

; ------- Descriptor GDTR -----------------------------------
gdt_descriptor:
    dw gdt_end - gdt_start - 1  ; Límite (tamaño en bytes - 1)
    dd gdt_start                ; Dirección base lineal (será calculada por linker)

; --- Selectores (Calculados automáticamente por el linker) ---
; No usamos 'equ' aquí porque las direcciones finales las decide el linker.
; Los selectores fijos (0x08, 0x10, 0x18) se usarán directamente en switch_to_pm.
; CODE_SELECTOR equ 0x08 ; Usar el valor directamente
; DATA_SELECTOR equ 0x10 ; Usar el valor directamente
; DATA_RO_SELECTOR equ 0x18 ; (Si se añade descriptor 3)