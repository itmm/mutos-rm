	org 0x7c00

; switch to svga
; 
; * find out if mode is supported
; * error message and end, if not supported
; * switch to mode

; load boot image
;
; * set all colors to black
; * load image directly into frame buffer segment
; * fade in colors

; load interpreter
;
; * load interpreter into RAM
; * jump into interpreter

	times 510 - ($ - $$) db 0
	db 0x55, 0xaa
