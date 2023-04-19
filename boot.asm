    org 0x7c00
start:
; switch to svga
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
; * find the correct mode

vbe_info equ 0x00
vbe_version equ 0x04
oem_string_ptr equ 0x06
capabilities equ 0x0a
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
    
mode_info_block equ 0x1200

    mov bx,ax
    push ax
    mov cx,[bx]
    mov ax,0x4f01
    mov di,mode_info_block
    int 0x10
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
    inc bx
    inc bx
    jmp .loop
; * switch to mode

found_mode:
    mov bx,(ax)
    mov ax,0x4f02
    int 0x10
; load splash screen
;
; * set all colors to black
; * load image directly into frame buffer segment
; * fade in colors
; load interpreter
; run interpreter
end:
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
    
no_mode:
    mov ax,cs
    mov ds,ax
    mov bx,no_mode_msg
    call print_str
    jmp $
    
no_mode_msg:
    db "found no matching graphic mode", 0x00
print_ch:
    push ax
    push bx
    mov ah,0x0e
    mov bx,0x000f
    int 0x10
    pop bx
    pop ax
    ret
    
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

no_vesa:
    mov ax,cs
    mov ds,ax
    mov bx,no_vesa_msg
    call print_str
    jmp $
    
no_vesa_msg:
    db "no vesa card found", 0x00
	times 510 - ($ - $$) db 0
	db 0x55, 0xaa
