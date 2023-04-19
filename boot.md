# µTOS Bootblock

Dieses Dokument beschreibt `boot.asm`, den Bootblock von µTOS. Generell hat ein
Bootblock für PCs mit BIOS die folgende Form:

```asm
    org 0x7c00
start:
end:
    jmp $
	times 510 - ($ - $$) db 0
	db 0x55, 0xaa
```

Zwischen `start:` und `end:` fügen wir das Programm in 16-Bit 8086-Assembler ein.
Generell plane ich folgende Schritte:

```asm
// ...
start:
; switch to svga
; load splash screen
; load interpreter
; run interpreter
// ...
```

Nicht gerade viel, aber wir haben auch nur 510 Bytes im Bootblock zur freien
Verfügung.

## SVGA aktivieren

Um das Programm klein zu halten, wird nur eine Auflösung unterstützt:
1024 × 768 Punkte bei 256 Farben. Folgende Schritte sind durchzuführen:

```asm
// ...
; switch to svga
; * find out if mode is supported
; * find the correct mode
; * switch to mode
// ...
```

Zuerst wird ein Interrupt ausgeführt, um die SVGA Info-Struktur auszulesen.
Dies ist auch ein Zeichen, ob eine entsprechende Karte unterstützt wird.
Die Struktur ist 512 gross. Wir nehmen dafür den RAM-Bereich ab `0x1000`.

Die ersten Bytes werden auf `VBE2` gesetzt. Daran erkennt das BIOS, dass
wir die Version 2 der Struktur erwarten und 512 statt ursprünglich nur 256 Byte
zur Verfügung stellen.

Wenn das Auslesen nicht geklappt hat, wird eine Fehlermeldung ausgegeben und das
Starten des Systems abgebrochen.

```asm
// ...
; * find out if mode is supported

vbe_info_block equ 0x1000

	xor ax,ax
	mov ds,ax
	mov es,ax
	mov di,vbe_info_block
	mov word [di + 0],('V' + 'B' * 256)
	mov word [di + 2],('E' + '2' * 256)
	mov ax,0x4f00
	int 0x10
	cmp ax,0x004f
	jne no_vesa
// ...
```

Für die Fehlermeldung wird eine weitere Funktion verwendet, um Zeichenketten auszugeben:

```asm
// ...
    jmp $

no_vesa:
    mov ax,cs
    mov ds,ax
    mov bx,no_vesa_msg
    call print_str
    jmp $
    
no_vesa_msg:
    db "no vesa card found", 0x00
// ...
```

Eine Zeichenkette wird Zeichen für Zeichen ausgegeben:

```asm
// ...
    jmp $
    
print_str:
    push ax
    push bx
.loop:
    mov al,[bx]
    or al,al
    jz .end
    call print_ch
    inc bx
    jmp .loop
.end:
    pop bx
    pop ax
    ret
// ...
```

Ein Zeichen wird über den passenden Interrupt ausgegeben:

```asm
// ...
    jmp $
print_ch:
    push ax
    push bx
    mov ah,0x0e
    mov bx,0x000f
    int 0x10
    pop bx
    pop ax
    ret
// ...
```

Nachdem die Info-Struktur erfolgreich gelesen wurde, müssen wir nun den passenden Mode ermitteln.
Dazu gibt es einen Zeiger in der Info-Struktur, der auf eine Liste der unterstützten Modi zeigt.

Anhand der Felder der Info-Struktur ermitteln wir den Offset zu diesem Zeiger als `0x0e`:

```asm
// ...
; * find the correct mode

vbe_info equ 0x00
vbe_version equ 0x04
oem_string_ptr equ 0x06
capabilities equ 0x0a
video_mode_ptr equ 0x0e
// ...
```

In einer Schleife gehen wir durch die Modi, bis wir den passenden Mode gefunden haben, oder wir das Ende der
Liste erreicht haben:

```asm
// ...
video_mode_ptr equ 0x0e

	mov bx,vbe_info_block+video_mode_ptr
	mov ax,[bx]
	inc bx
	inc bx
	mov bx,[bx]
	mov ds,ax
.loop:
    cmp word [bx],0xffff
    je no_mode
    ; check current mode
    inc bx
    inc bx
    jmp .loop
// ...
```

Wenn der passende Mode nicht gefunden wurde, gibt es wieder eine Fehlermeldung:

```asm
// ...
    jmp $
    
no_mode:
    mov ax,cs
    mov ds,ax
    mov bx,no_mode_msg
    call print_str
    jmp $
    
no_mode_msg:
    db "found no matching graphic mode", 0x00
// ...
```

Um die Details eines Mode abzulegen wird auch wieder Speicher benötigt. Dafür nehmen wir die 256 Byte, die hinter
der Info-Struktur liegen. Mit einem Interrupt holen wir die Informationen:

```asm
// ...
    ; check current mode
    
mode_info_block equ 0x1200

    mov bx,ax
    push ax
    mov cx,[bx]
    mov ax,0x4f01
    mov di,mode_info_block
    int 0x10
    ; check mode info block
// ...
```

Zu Debug-Zwecken geben wir für jeden Mode die gefundenen Informationen mit aus:

```asm
// ...
    ; check mode info block
    mov ax,'\n'
    call print_ch
    mov ax,[mode_info_block+0x12]
    call print_num
    cmp ax,1024
    jne .next_entry
    mov ax,'*'
    call print_ch
    mov ax,[mode_info_block+0x14]
    call print_num
    cmp ax,768
    jne .next_entry
    mov ax,':'
    call print_ch
    mov al,[mode_info_block+0x19]
    call print_num
    cmp al,0xff
    jz found_mode
.next_entry:
// ...
```

Es fehlt noch die Funktion, um Zahlen auszugeben:

```asm
// ...
    jmp $
print_num:
    push ax
    push cx
    call .recur
    pop cx
    pop ax
    ret

.recur:
    mov cx,10
    div cx
    jz .no_recur
    push cx
    call .recur
    pop cx
.no_recur:
    mov ax,cx
    add ax,'0'
    jmp print_ch
    
// ...
```

Wir haben den richtigen Mode gefunden und können ihn aktivieren:

```asm
// ...
; * switch to mode

found_mode:
    mov bx,(ax)
    mov ax,0x4f02
    int 0x10
// ...
```

## Splash-Screen laden

```asm
// ...
; load splash screen
;
; * set all colors to black
; * load image directly into frame buffer segment
; * fade in colors
// ...
```

## Interpreter laden und ausführen

```asm
// ...
; load interpreter
; run interpreter
// ...
```