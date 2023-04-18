	org 0x7c00

; switch to svga
; 
; * find out if mode is supported

vbe_info_block equ 0x1000
mode_info_block equ 0x1200

	xor ax,ax
	mov es,ax
	mov di,vbe_info_block
	mov word [di + 0],('V' + 'B' * 256)
	mov word [di + 2],('E' + '2' * 256)
	mov ax,0x4f00
	int 0x10
	cmp ax,0x004f
	jne no_vesa

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
	mov es,ax
	mov ax,bx
video_loop:
	mov bx,ax
	cmp word [bx],0xffff
	je no_mode
	push ax
	mov cx,[bx]
	mov ax,0x4f01
	mov di,mode_info_block
	int 0x10
	mov ax,'\n'
	call print_ch
	mov ax,[mode_info_block+0x12]
	call print_num
	cmp ax,1024
	jne next_entry
	mov ax,'*'
	call print_ch
	mov ax,[mode_info_block+0x14]
	call print_num
	cmp ax,768
	jne next_entry
	mov ax,':'
	call print_ch
	mov al,[mode_info_block+0x19]
	call print_num
	cmp al,0xff
	jne next_entry
	pop ax
	jmp found_mode

next_entry:
	pop ax
	inc ax
	inc ax
	jmp video_loop
	
; * error message and end, if not supported

no_vesa:
	mov bx,no_vesa_msg
	jmp print_str

no_mode:
	mov bx,no_mode_msg
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

print_ch:
    push ax
    push bx
    mov ah,0x0e
    mov bx,0x000f
    int 0x10
    pop bx
    pop ax
    ret

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

; * switch to mode

found_mode:
	mov bx,(ax)
	mov ax,0x4f02
	int 0x10
	jmp no_mode

; load boot image
;
; * set all colors to black
; * load image directly into frame buffer segment
; * fade in colors

; load interpreter
;
; * load interpreter into RAM
; * jump into interpreter

	jmp no_vesa

no_vesa_msg:
	db "no vesa card found", 0x00

no_mode_msg:
	db "found no matching graphic mode", 0x00

	times 510 - ($ - $$) db 0
	db 0x55, 0xaa
