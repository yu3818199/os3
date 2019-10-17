org 0x7e00


call clear_screen

mov cx,13
snake_1:
push cx

mov ax,13
sub ax,cx
mov bx,2
mul bx

  mov cx,55
  snake_2:
    push cx
    
    mov dx,55
    sub dx,cx

    ; 输入参数 ch=行 cl=列 cs:si=字符对应地址 dl=样式
    mov ch,al
    mov cl,dl
    mov si,_str1
    mov dl,00001111b
    call _putstring
    
    call snake_diskplay_sleep

    mov si,_str2
    call _putstring

    pop cx
  loop snake_2

  inc al

  mov cx,55
  snake_3:
    push cx
    
    mov dx,cx
    sub dx,1

    ; 输入参数 ch=行 cl=列 cs:si=字符对应地址 dl=样式
    mov ch,al
    mov cl,dl
    mov si,_str1
    mov dl,00001111b
    call _putstring
    
    call snake_diskplay_sleep

    mov si,_str2
    call _putstring

    pop cx
  loop snake_3


pop cx
loop snake_1


ret


;------------------------------------------------------------------
; 暂停一段时间
; 输入输出参数: 无
snake_diskplay_sleep:
 pusha
  mov cx,2000
 snake_diskplay_sleep_1:
  pusha
  mov cx,3000
  snake_diskplay_sleep_2:
   nop
  loop snake_diskplay_sleep_2
  popa
 loop snake_diskplay_sleep_1
 popa
ret


_str1: db 'ABCDEFGHIJKLMNOPQRSTUVWXYZ',0
_str2: db '                          ',0

; 引用内存管理函数
%include "memory.asm"

; 引用数值转换函数
%include "dec.asm"

; 引用屏幕控制函数
%include "screen.asm"

; 引用磁盘管理函数
%include "disk.asm"
 
; 本程序分配4KB空间
times 512*8-($-$$) db 0xff

