.model small
.stack 100h 

.data
input1 DB "Введите строку: $"
input2 DB 0Ah, 0Dh, "Введите строку для поиска: $"
input3 DB 0Ah, 0Dh, "Введите строку для замены: $"
outputMessage DB 0Ah, 0Dh, "Строка после замены: $"
maxLength equ 200
str1MaxLength DB 0
str1Length DB '$'                  ;исходная строка
str1 DB maxLength + 2 dup('$')

str2MaxLength DB maxLength
str2Length DB '$'                  ;строка для поиска
str2 DB maxLength + 2  dup('$')

str3MaxLength DB maxLength
str3Length DB '$'                  ;строка для замены
str3 DB maxLength + 2  dup('$')

space DB ' ' 
ins dw 0
def dw 0
trans dw 0
drt dw 0

.code
start:
mov ax, @data
mov ds, ax
mov es, ax       
xor ax, ax

mov str1MaxLength, maxLength;
mov str2MaxLength, maxLength;
mov str3MaxLength, maxLength;

;Ввод строк и вывод сообщений
lea dx, input1
call showString

lea dx, str1MaxLength
call getString

lea dx, input2
call showString

lea dx, str2MaxLength
call getString

lea dx, input3
call showString

lea dx, str3MaxLength
call getString

xor cx, cx
mov cl, str1MaxLength[1]       ; помещает в cx количество символов в исходной строке
sub cl, str2MaxLength[1]
inc cl              
cld                 
lea di, str2MaxLength[2]        ; помещает в di адрес строки для поиска
lea si, str1MaxLength[2]        ; помещает в si адрес исходной строки
xor ax, ax
call transform

CHECK_STRING:       ; повторять уменьшенную длину кол во раз
mov def, 0          ; обнулить счетчик разности
call searchWord
inc si
add si, def         ;сдвинуть счетчик на количество вставленных символов
mov dx, def
add ins, dx         ;переместить индекс вхождения
add str1MaxLength[1], dl    ;увеличить длину строки
inc ins
loop CHECK_STRING

call deleteSpace
lea dx, outputMessage
call showString
lea dx, str1        ; вывести исходную строку
call showString 

END:
mov ax, 4c00h
int 21h

; **** Procedures ****

; процедура ввода строки
getString proc
    push ax
    mov ah, 0ah
    int 21h
    pop ax
    ret
getString endp

;процедура вывода строки
showString proc
    push ax
    mov ah, 09h
    int 21h
    pop ax 
    ret
showString endp

; процедура нахождения подстроки
; процедура проходит по строке,
; находит нужное, удаляет его
; и заменяет на слово для замены
searchWord proc
    push cx
    push di
    push si
    mov bx, si
    mov cl, str2Length
    repe cmpsb              
    je _EQ
    jne _NEQ
    _EQ:
    pusha
    push ins 
    xor si, si
    xor dx, dx
    mov dl, str2MaxLength[1]
    add ins, dx
    mov dx, ins
    mov si, dx
    mov bl, str1[si]
    cmp str1[si], ' '
    pop ins
    popa
    jne _NEQ                        
    call delete
    call change
    inc al
    _NEQ:
    pop si
    pop di
    pop cx
    ret
searchWord endp

; удаление подстроки из исходной строки
; путем перемещения байт из si в di
delete proc
    push bx
    push di
    push si
    mov di, bx 
    xor cx, cx
    mov cl, str1Length
    repe movsb              
    pop si
    pop di
    pop bx
    ret
delete endp

;процедура вставки слова в строку
change proc
    pusha
    push ins                            ;сохранение в стеке индекса вхождения
    lea si, str1MaxLength
    lea di, str3MaxLength
    ;len1
    mov ch, str1MaxLength[1]                    ;определение длины строк
    mov cl, str3MaxLength[1]
    xor bx, bx
    xor di, di
    Outer_Cycl:
        mov dl, str3[di]                ;помещаем в стек очередное значение из подстроки
        push dx
        mov bl, ch
        mov si, bx
        cycl:                           ;в цикле сдвигаем строку вправо до индекса вхождения
            mov dl, str1[si-1]
            mov str1[si], dl
            dec si
            cmp ins, si
            jne cycl
        pop dx
        mov str1[si], dl                ;вставляем символ
        
        inc si
        inc di
        inc ch
        inc ins
        inc def
        xor dx, dx
        mov dl, cl
        cmp di, dx 
        jne Outer_Cycl                  ;пока непройдем слово полностью
    pop ins
    dec def    
    popa
    ret
change endp

transform PROC
    pusha
    lea si, str2MaxLength
    lea di, str3MaxLength
    xor bx, bx
    xor di, di
    xor si, si
    mov ch, str2MaxLength[1]                    ;определение длины строк
    mov cl, str3MaxLength[1]
    mov bl, ch
    mov si, bx
    cycl1:
            mov dl, str2[si-1]
            mov str2[si], dl
            dec si
            cmp trans, si
            jne cycl1
    mov dl, space
    mov str2[si], dl
    add str2MaxLength[1], 1
    mov bl, cl
    mov di, bx
    cycl2:
            mov dl, str3[di-1]
            mov str3[di], dl
            dec di
            cmp trans, di
            jne cycl2
    mov dl, space
    mov str3[di], dl
    add str3MaxLength[1], 1
    lea si, str1MaxLength
    xor si, si
    xor cx, cx
    mov ch, str1MaxLength[1]
    mov bl, ch
    mov si, bx
    cycl3:
            mov dl, str1[si-1]
            mov str1[si], dl
            dec si
            cmp trans, si
            jne cycl3
    mov dl, space
    mov str1[si], dl
    add str1MaxLength[1], 1
    xor si, si
    xor cx, cx
    mov ch, str1MaxLength[1]
    mov bl, ch
    mov si, bx
    mov dl, space
    mov str1[si], dl
    add str1MaxLength[1], 1        
    popa
    ret
endp transform

deleteSpace PROC
    pusha
    lea si, str1MaxLength
    xor si, si
    xor cx, cx
    xor dx, dx
    mov ch, str1MaxLength[1]
    mov bl, ch
    mov di, bx
    xor si, si
    cycle:
        mov dl, str1[si+1]
        mov str1[si], dl
        inc si
        cmp si, di
        jne cycle
    sub str1MaxLength[1], 1
    popa
    ret    
endp deleteSpace    

end start