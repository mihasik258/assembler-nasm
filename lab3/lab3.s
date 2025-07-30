bits 64

%define LEN 10
%define LEN2 LEN*2

section .data
    open_error_msg      db "Ошибка открытия файла", 0xA, 0
    open_error_len      equ $-open_error_msg

    read_error_msg      db "Ошибка чтения из файла", 0xA, 0
    read_error_len      equ $-read_error_msg

    close_error_msg     db "Ошибка закрытия файла", 0xA, 0
    close_error_len     equ $-close_error_msg

    env_error_msg       db "FILE не установлена", 0xA, 0
    env_error_len       equ $-env_error_msg
    
    file_eq db "FILE=", 0
    
section .bss
	buffer resb LEN
	new_buffer resb LEN2
section .text
    global _start

%macro handle_error 2
    mov rax, 1
    mov rdi, 2
    mov rsi, %1
    mov rdx, %2
    syscall
    mov rax, 60
    mov rdi, 1
    syscall
%endmacro

_start:
    pop rax
next_argv:
    pop rbx
    cmp rbx, 0
    jne next_argv

find_file_env:
    pop rsi
    test rsi, rsi
    jz env_not_found

    mov rdi, file_eq
    mov rcx, 5
    repe cmpsb
    jne find_file_env

    mov rdi, rsi

    mov rax, 2
    xor rsi, rsi
    syscall
    cmp rax, 0
    jl open_error
    mov r12, rax

read_buffer:
    mov rax, 0
    mov rdi, r12
    mov rsi, buffer
    mov rdx, LEN
    syscall 
    mov r13, rax 
    cmp rax, 0
    je end
    
preparation:
    mov r14, -1 ; индекс начала слова
    mov r15, 0 ; количество слов в строке
    mov r8, 0 ; индекс текущего символа
    mov r10, 0 ; текущий индекс в выходном буфере
    jmp go_through_buffer

zeroing_word_amount:
    xor r15, r15
    jmp incrementation

next_symbol:
    cmp byte[buffer + r8], 10
    je zeroing_word_amount 
    
incrementation:
    inc r8
    cmp r8, r13 
    je check_end
    jmp go_through_buffer
        


check_end:
	cmp r10, 0
	jle read_buffer
	mov rax, 1
    mov rdi, 1
    mov rsi, new_buffer
    mov rdx, r10
    mov r10, 0 
    cmp byte[buffer + r8], 10
    je  add_newline
	syscall
    cmp r14, -1
    je read_buffer_without_indent
    mov rcx, r8
    sub rcx, r14
    mov r8, 0
    
copy:
    mov al, [buffer + r14] ; копируем обрезанное слово
    mov [buffer + r8], al
    inc r8
    inc r14
    cmp r8, rcx
    jne copy
    
read_buffer_with_indent:
    mov rax, 0
    mov rdi, r12
    mov rsi, buffer
    add rsi, r8
    mov rdx, LEN
    sub rdx, r8
    syscall 
    mov r13, rax
    add r13, r8
    mov r14, 0 ; индекс начала слова
	jmp preparation_for_partly
    
read_buffer_without_indent: 
    mov rax, 0
    mov rdi, r12
    mov rsi, buffer
    mov rdx, LEN
    syscall 
    mov r13, rax 

preparation_for_partly:
    mov r8, 0 ; индекс текущего символа
        
go_through_buffer:
    cmp byte[buffer + r8], 32
    je check_word_end
    cmp byte[buffer + r8], 9
    je check_word_end
    cmp byte[buffer + r8], 10
    je check_word_end
    cmp r14, 0
    jl word_beginning ; встретился первый символ слова
    jmp next_symbol

check_word_end:
    cmp r14, 0
    jge encountered_word ;
    cmp byte[buffer + r8], 10
    je add_newline ;je
    jmp next_symbol

word_beginning:
    mov r14, r8
    jmp next_symbol

encountered_word:
    mov rcx, r8
   	sub rcx, r14 
   	cmp r15, 0
    je check
    
print_space:
    mov byte[new_buffer + r10], ' '
    inc r10

check:
	mov r9, rcx
	test r9, 1
	jnz copy_second

copy_first:
	mov rsi, buffer
	add rsi, r14
	mov rdi, new_buffer
	add rdi, r10
	mov rcx, r9
	rep movsb
	add r10, r9
copy_second:
	mov rsi, buffer
	add rsi, r14
	mov rdi, new_buffer
	add rdi, r10
	mov rcx, r9
	rep movsb
	add r10, r9
	inc r15

reset_word_index:
    mov r14, -1
    cmp byte[buffer + r8], 10
    jne next_symbol

add_newline:
    mov byte[new_buffer + r10], 10
    inc r10
    mov rax, 1
    mov rdi, 1
    mov rsi, new_buffer
    mov rdx, r10
    syscall
    mov r10, 0 
    jmp next_symbol
end:
    mov rax, 3
    mov rdi, r12
    syscall
    jmp exit
    
exit:
    mov rax, 60
    mov rdi, 0
    syscall

env_not_found:
    handle_error env_error_msg, env_error_len
open_error:
    handle_error open_error_msg, open_error_len
close_error:
    handle_error close_error_msg, close_error_len
