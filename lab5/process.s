section .text
    global grayscale_asm

;   RDI = img, RSI = width, RDX = height, RCX = channels
;   R8D = x1 R9D = y1 R10D = x2 R11D = y2

grayscale_asm:
    push    rbp
    mov     rbp, rsp
    mov     ebx, esi
    imul    esi, edx            ; ESI = width * height
    test    esi, esi
    jle     .done
    mov     r10d, [rbp+16]   ; x2
    mov     r11d, [rbp+24]   ; y2
    pop 	rbp
    mov     r13d, ecx           
    xor     r12d, r12d          ; r12d = i

.loop_pixels:
	mov 	eax, r12d
	xor 	edx, edx
	div 	ebx
	mov 	r14d, edx ;x
	mov 	r15d, eax ;y
	
	cmp 	r14d, r8d
	jl		.skip
	cmp 	r14d, r10d
	jg 		.skip
	cmp 	r15d, r9d
	jl 		.skip
	cmp 	r15d, r11d
	jg 		.skip

	push 	r8
	push 	r9
	push 	r10
	push 	r11
	
    movzx   eax, byte [rdi]        ; eax = R
    movzx   ecx, byte [rdi+1]      ; ecx = G
    movzx   r11d, byte [rdi+2]     ; r11d = B

    ; max -> r8d
    mov     r8d, eax
    cmp     r8d, ecx
    cmovl   r8d, ecx
    cmp     r8d, r11d
    cmovl   r8d, r11d

    ; min -> r9d
    mov     r9d, eax
    cmp     r9d, ecx
    cmovg   r9d, ecx
    cmp     r9d, r11d
    cmovg   r9d, r11d

    ; gray = (max+min)/2 -> r10d
    lea     r10d, [r8d + r9d]
    shr     r10d, 1

    mov     al,  r10b
    mov     byte [rdi],     al
    mov     byte [rdi+1],   al
    mov     byte [rdi+2],   al

    pop 	r11
	pop 	r10
	pop 	r9
	pop 	r8

.skip:
    add     rdi, r13           
    inc     r12d
    cmp     r12d, esi
    jl      .loop_pixels

.done:
    ret
