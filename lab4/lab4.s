bits 64

section .data
msg1:   db "Input x", 10, 0
msg2:   db "%f", 0
msg3:   db "cos²(%.10g)=%.10g", 10, 0
msg4:   db "mycos²(%.10g)=%.10g", 10, 0
msg5:   db "Input precision", 10, 0
msg6:   db "(%.10g)=%.10g", 10, 0
file_mode:         db "w", 0
error_open_file:   db "Error open file.", 0
fmt_term: db "[%d] = %.10g", 10, 0


align 16
abs_mask: dd 0x7FFFFFFF, 0, 0, 0  ; Маска для получения абсолютного значения
two_pi:     dd 6.28318530717958647692

one         dd 1.0
two         dd 2.0
minus_one   dd -1.0
minus_four  dd -4.0
FileName:   dq 0

x equ 4
eps equ x + 4
x_2 equ eps + 4
sum equ x_2 + 4
step equ sum + 4
current equ step + 4

section .bss
arg_count: resd 1
arg_value: resq 1

section .text
extern printf
extern scanf
extern cosf
extern fopen, fclose, fprintf
extern fmodf
global main

mycos2:
    push rbp
    mov rbp, rsp
    sub rsp, current
    and rsp, -16
    ; xmm0 - x, xmm1 - epsilon
    movss xmm5, xmm1        ; Сохраняем точность в xmm5
    movss [rbp - x], xmm0
    movss [rbp - eps], xmm1
    movss xmm1, xmm0
    mulss xmm1, xmm1        ; xmm1 = x²

    movss xmm2, [one]       ; sum = 1.0

    movss xmm3, xmm1        ; current_term = x²
    mulss xmm3, [minus_one] ; current_term = -x²

    addss xmm2, xmm3        ; sum = 1 - x²

    movss xmm4, [two]       ; n = 2.0

    movss [rbp - step], xmm4
    movss [rbp - x_2], xmm1
    movss [rbp - sum], xmm2
    movss [rbp - current], xmm3


.loop:
    ; Вычисляем знаменатель 
    movss xmm6, [rbp - step]  
    addss xmm6, xmm6       
    movss xmm7, xmm6      
    subss xmm7, [one]       ; 2n - 1
    mulss xmm6, xmm7        ; (2n)(2n - 1)

    ; Вычисляем множитель (-4.0 * x²) / denominator
    movss xmm7, [minus_four]
    mulss xmm7, [rbp - x_2]       ; -4.0 * x²
    divss xmm7, xmm6        ; factor

    ; Обновляем current_term
    movss xmm10, [rbp - current]
    mulss xmm10, xmm7        ; current_term *= factor
    movss [rbp - current], xmm10

    movss xmm6, [rbp - current]
    andps xmm6, [abs_mask]
    ucomiss xmm6, [rbp - eps]
    jb .exit_loop

    ; Добавляем текущий член к сумме
    movss xmm2, [rbp - sum]
    addss xmm2, [rbp - current]
    movss [rbp - sum], xmm2
    subss xmm4, [one]     ; Вычитаем 1.0: n-1 (1.0, 2.0, ...)
	cvttss2si edx, xmm4      ; rdx = (int)n
	

	; Конвертируем current_term (в xmm3) в double
	cvtss2sd xmm0, [rbp - current]      ; xmm0 = (double)current_term
    cmp qword [FileName], 0
    je .no_file_loop
	addss xmm4, [one]     ; Вычитаем 1.0: n-1 (1.0, 2.0, ...)
	mov rdi, [FileName]      ; FILE*
	mov rsi, fmt_term        ; форматная строка
	mov rax, 1               ; количество XMM-аргументов
	call fprintf
.no_file_loop:
    ; Увеличиваем n
    movss xmm4, [rbp - step]
    addss xmm4, [one]
    movss [rbp - step], xmm4

    jmp .loop

.exit_loop:
    movss xmm0, [rbp - sum]
    leave
    ret

main:
    push rbp
    mov rbp, rsp
    sub rsp, 32
    ;and rsp, -16

    ; Проверка аргументов командной строки
    mov [arg_count], edi
    mov [arg_value], rsi

    ; Открытие файла для записи (если передан аргумент)
    cmp dword [arg_count], 2
    jne .no_file_output

    mov rdi, [rsi + 8]
    mov rsi, file_mode
    call fopen
    mov [FileName], rax
    test rax, rax
    jz .file_error

.no_file_output:
    ; Запрос ввода x
    mov rdi, msg1
    xor eax, eax
    call printf

    ; Ввод x
    mov rdi, msg2
    lea rsi, [rbp-4]
    xor eax, eax
    call scanf
    movss xmm0, [rbp-4]
    movss [rbp-16], xmm0
    ; Запрос ввода точности
    mov rdi, msg5
    xor eax, eax
    call printf

    ; Ввод точности
    mov rdi, msg2
    lea rsi, [rbp-12]
    xor eax, eax
    call scanf

    movss xmm0, [rbp-4]
    movss xmm1, [two_pi]
    call fmodf
    movss [rbp-4], xmm0
    ; Вычисление cos²(x) с использованием библиотечной функции
    movss xmm0, [rbp-4]
    call cosf
    mulss xmm0, xmm0
    movss [rbp-8], xmm0

    ; Вывод библиотечного результата
    mov rdi, msg3
    cvtss2sd xmm0, [rbp-16]
    cvtss2sd xmm1, [rbp-8]
    mov eax, 2
    call printf

    ; Вывод в файл (если он открыт)
    cmp qword [FileName], 0
    je .no_file_out1

.no_file_out1:
    ; Вычисление mycos2
    movss xmm0, [rbp-4]     ; Загрузка x
    movss xmm1, [rbp-12]    ; Загрузка точности
    call mycos2
    movss [rbp-8], xmm0

    ; Вывод результата mycos2
    mov rdi, msg4
    cvtss2sd xmm0, [rbp-16]
    cvtss2sd xmm1, [rbp-8]
    mov eax, 2
    call printf

    ; Вывод в файл (если он открыт)
    cmp qword [FileName], 0
    je .no_file_out2

    mov rdi, [FileName]
    mov rsi, msg4
    cvtss2sd xmm0, [rbp-16]
    cvtss2sd xmm1, [rbp-8]
    mov eax, 2
    call fprintf

.no_file_out2:
    ; Закрытие файла (если он открыт)
    cmp qword [FileName], 0
    je .no_file_close

    mov rdi, [FileName]
    call fclose

.no_file_close:
    leave
    xor eax, eax
    ret

.file_error:
    mov rdi, error_open_file
    call printf
    jmp .no_file_output
