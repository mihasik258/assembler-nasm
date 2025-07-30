%ifndef SORTORDER
	%define SORTORDER 0
%endif

BITS 64

section .data
    rows  db 4
    cols  db 3

align 2
matrix:
    dw 32568, -32567, 32568
    dw -32567, -32567, -32567
    dw 32568, 32568, 32568
    dw 32568, -32567, -32567
new_m:
	times 12 dw 0
sums:
    dd 0, 0, 0, 0, 0
index:
 	dd 0, 1, 2, 3, 4


section .text
    global _start
_start:
    movzx   eax, byte [rows]
    mov     r8d, eax         ; r8d = число строк
    movzx   eax, byte [cols]
    mov     r9d, eax         ; r9d = число столбцов
    xor     rcx, rcx         ; rcx = индекс строки
sum_loop:
    cmp     rcx, r8
    jge     sums_done	; если прошли все строки то сортируем
    mov     rax, rcx
    imul    rax, r9
    shl     rax, 1           ; сдвиг влево
    lea     rdi, [matrix + rax] ; начало строки
    xor     rax, rax
    xor     rdx, rdx
    xor     rbx, rbx
    mov     rsi, r9 ; столбцы
sum_inner:
    cmp     rsi, 0
    je      sum_inner_end
    movsx   edx, word [rdi]
    add     ebx, edx
    add     rdi, 2
    dec     rsi
    jmp     sum_inner
sum_inner_end:
    mov     [sums + rcx*4], ebx
    inc     rcx
    jmp     sum_loop
sums_done:
    cmp     r8d, 2 ; меньше 2 не сортируем
    jl      sorting_done
    mov     eax, [sums]          ; row0
    mov     edx, [sums + 4]      ; row1
    cmp     eax, edx
    %if SORTORDER == 0
    	jle     pair_initial_done
    %ELSE
    	jge     pair_initial_done
	%endif
asc_pair_initial:
    cmp     eax, edx
    jle     pair_initial_done
do_swap_initial:
    mov     [sums + 4], eax
    mov     [sums], edx
    mov     eax, [index]          ; row0
    mov     edx, [index + 4]      ; row1
    mov     [index + 4], eax
    mov     [index], edx
pair_initial_done:
    ; Основной внешний цикл по парам.
    ; rcx индекс обрабатываемой пары
    mov     rcx, 2      ; i
pair_insertion_outer:
    cmp     rcx, r8
    jge     sorting_done
    mov     rax, rcx
    inc     rax
    cmp     rax, r8
    jl      pair_has_two
    ; Если остался один элемент – вставляем его стандартно:
    mov 	r12d, [sums + rcx*4]
    mov 	r13, rcx
    dec 	r13		; j
.next:
    call 	insert_loop2
    inc     rcx
    jmp     pair_insertion_outer_done
pair_has_two:
    ; Обрабатываем пару: элементы с индексами rcx и rcx+1
    ; Сначала упорядочим пару относительно друг друга
    mov     eax, [sums + rcx*4]         ; первый элемент пары
    mov     edx, [sums + (rcx+1)*4]       ; второй элемент пары
    ; Для убывающего – хотим: первый >= второй
    cmp     edx, eax
    %if SORTORDER == 0
    	jle     insert_ascending
    %else
    	jge     insert_ascending
    %endif
do_pair_swap:
    ; Меняем местами элементы пары
    mov     [sums + (rcx+1)*4], eax
    mov     [sums + rcx*4], edx
    mov     eax, [index + rcx*4]         ; первый элемент пары
    mov     edx, [index + (rcx+1)*4]       ; второй элемент пары
    mov     [index + (rcx+1)*4], eax
    mov     [index + rcx*4], edx
insert_ascending:
    mov     rbx, rcx       ; больший элемент находится по индексу rcx i
    mov 	r11d, [sums + rbx*4]
    mov     r14d, [index + rbx*4]
    inc     rbx            ; меньший элемент – по индексу rcx+1
    mov 	r12d, [sums + rbx*4]
    mov     r15d, [index + rbx*4]
    mov 	r13, rcx
    dec 	r13		; j
.insert:
    call insert_element
pair_insertion_outer_done:
    add     rcx, 2
    jmp     pair_insertion_outer

sorting_done:
	call   	new_matrix
    mov     eax, 60
    xor     rdi, rdi
    syscall


insert_element:
insert_loop:
    cmp     r13, 0
    jl      insert_done
    mov     eax, [sums + r13*4]           ; текущая сумма
    cmp     r11d, eax
    %if SORTORDER == 0
    	jg      insert_done
    %else  
    	jl      insert_done
    %endif
do_swap_insert:
    ; Меняем местами суммы
    mov 	rbx, r13
    inc 	rbx
    inc 	rbx 		; j+2
    mov     [sums + rbx*4], eax
	mov     eax, [index + r13*4]
	mov     [index + rbx*4], eax
insert_continue:
    dec     r13
    jmp     insert_loop
insert_done:
	mov 	rax, 0
	mov 	rbx, r13
	inc  	rbx
	inc 	rbx
	mov 	[sums + rbx*4], r11d
	mov 	[index + rbx*4], r14d
insert_loop2:
    cmp     r13, 0
    jl      insert_done2
    mov     eax, [sums + r13*4]           ; текущая сумма
    cmp     r12d, eax
    %if SORTORDER == 0
    	jg 		insert_done2
    %else
    	jl     insert_done2
    %endif
do_swap_insert2:
    ; Меняем местами суммы
    mov 	rbx, r13
    inc 	rbx		; j+1
    mov     [sums + rbx*4], eax
    mov     eax, [index + r13*4]
    mov     [index + rbx*4], eax
insert_continue2:
    dec     r13
    jmp     insert_loop2
insert_done2:
	mov 	rbx, r13
	inc  	rbx
	mov 	[sums + rbx*4], r12d
	mov 	[index + rbx*4], r15d
.done:
	ret

new_matrix:
	xor rsi, rsi
	lea rdi, [new_m]
	mov edx, r9d
	shl edx, 1
	xor r11, r11
collect_loop:
	cmp rsi, r8
	jge collect_done
	mov eax, [index+rsi*4]
	imul eax, edx
	lea r11, [matrix + rax]
	xor r12, r12
copy_row1:
	cmp r12, rdx
	jge row_copied1
	mov bx, [r11+r12]
	mov [rdi+r12], bx
	inc r12
	jmp copy_row1
row_copied1:
	add rdi, rdx
	inc rsi
	jmp collect_loop
collect_done:
	ret
