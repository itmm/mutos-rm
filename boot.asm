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
	mov ax,[mode_info_block+0x12]
	cmp ax,1024
	jne next_entry
	mov ax,[mode_info_block+0x14]
	cmp ax,768
	jne next_entry
	mov al,[mode_info_block+0x19]
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
	jmp error_msg_loop

no_mode:
	mov bx,no_mode_msg

error_msg_loop:
	mov al,[bx]
	or al,al
	jz end_of_error_msg
	push bx
	mov ah,0x0e
	mov bx,0x000f
	int 0x10
	pop bx
	inc bx
	jmp error_msg_loop

end_of_error_msg:
	jmp $

print_num:
    push ax
    mov cx,10
    div cx
    jz .no_recur
    jsr print_num
.no_recur:
    mov ax,cx
    
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
