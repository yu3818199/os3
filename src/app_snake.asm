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

    ; ������� ch=�� cl=�� cs:si=�ַ���Ӧ��ַ dl=��ʽ
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

    ; ������� ch=�� cl=�� cs:si=�ַ���Ӧ��ַ dl=��ʽ
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
; ��ͣһ��ʱ��
; �����������: ��
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

; �����ڴ������
%include "memory.asm"

; ������ֵת������
%include "dec.asm"

; ������Ļ���ƺ���
%include "screen.asm"

; ���ô��̹�����
%include "disk.asm"
 
; ���������4KB�ռ�
times 512*8-($-$$) db 0xff

