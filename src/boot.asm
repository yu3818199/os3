;------------------------------------------------------------------------;
;                                                                        ;
;      ###########           ##########              ###   #########     ;
;    ###############      ###############           ###  #############   ;
;  #######     #######   #######    ####           ###  ######   ######  ;
; #######       #######  ###########              ###            ######  ;
; #######       #######   ###############       ####         #########   ;
; #######       #######     ###############    ####          ##########  ;
; #######       #######           #########   ####                ###### ;
;  #######     #######  #######     #######  ###       ######     ###### ;
;    ###############     #################  ###         ###############  ;
;       #########           ###########    ###            ###########    ;
;                                                                        ;
; BOOT���س���                                                           ;
;                                                                        ;
; ��Ҫ���ܣ�չʾ�����棬ʵ�ֲ���ϵͳ�ػ�����������չ������صȹ��ܡ�     ;
; ��    ��: yuqiancheng                                                  ;
; ��д����: 2019/10/01                                                   ;
;                                                                        ;
;------------------------------------------------------------------------;

[bits 16]
; ���ñ��γ�ʼ��ַ(��MBR������0x500λ�ã���4KB)
org 0x500

;------------------------------------------------------------------
;   �ڴ�˵��
; 
; ��ʼ��ַ	������ַ	��С	    ��;
;  FFFF0     FFFFF    16B       BIOS��ڵ�ַ���˵�ַҲ����BIOS����
;  F0000     FFFEF    64KB-16B	BIOS����
;  C8000     EFFFF    160KB     ӳ��Ӳ����������ROM���ڴ�ӳ��ʽI/O
;  C0000     C7FFF    32KB      ��ʾ������BIOS
;  B8000     BFFFF    32KB      �����ı�ģʽ��ʾ������
;  B0000     B7FFF    32KB      ���ںڰ���ʾ��������
;  A0000     AFFFF    64KB      ���ڲ�ɫ��ʾ��������
;  9FC00     9FFFF    1KB       EBDA����չBIOS����
;  07E00     9FBFF    Լ608KB   (���ر�����ϵͳ��չ����)
;  07C00     07DFF    512B      MBR������
;  01500     07BFF    Լ25K     (����)
;  00500     014FF    4KB       ������MBR�������˴�
;  00400     004FF    256B      BIOS Data Area (BIOS������)
;  00000     003FF    1KB       Interrupt Vector Table(�ж�������)
;------------------------------------------------------------------

;------------------------------------------------------------------
;    ����˵��
;  ��ͷ    ����   ����          ��;
;   0       0      1          MBR������
;   0       0     2-9         ���س�����(8������)
;   0       0      10         ���ݷ�����
;------------------------------------------------------------------

;------------------------------------------------------------------
;  ���ݷ�����˵��
;  (ÿ���ļ�������ռ��32�ֽڣ�ÿ������֧��16���ļ�)
;  2�ֽڿ�ʼ+16�ֽ��ļ���+8�ֽ�LBA��ʼ��ַ+4�ֽڶ�ȡ������+2�ֽڽ���
;
;------------------------------------------------------------------

; ���������̱�־
  mov [cs:start_disk],dl

; �趨��������ͬ��
  mov ax,cs
  mov ds,ax
  mov es,ax

;------------------------------------------------------------------
; ��ʾ����Ļ
call _display_main

;------------------------------------------------------------------
;�������س���
_main_jmp:
  call _main
jmp _main_jmp

jmp $

;-----------------------------------------------------------------
; ���س���

_main:

  ; �������������
  call command_buf
  
  ; �ж���������Ƿ���ƥ�������
  call command_check

ret

; �����ڴ������
%include "memory.asm"

; ������ֵת������
%include "dec.asm"

; ������Ļ���ƺ���
%include "screen.asm"

; ���ô��̹�����
%include "disk.asm"

;------------------------------------------------------------------
; ��ʾ����Ļ����
; �����������: ��
_display_main:

  pusha

  ;����
  call clear_screen

  ;��ʾos3
  call show_CharPictures

  ;��ʾ����
  mov si,title
  call show_title

  ;��ʾ����
  call dsp_datetime
  
  popa
  
ret

;------------------------------------------------------------------
; �ػ�
; �����������: ��
power_off:

  ;��ʾ�ػ���ʾ
  mov si,title_shutdown
  call show_title

  ;��ʾ�ػ�����
  call power_off_display
 
  ;�ػ� ; ֻ��ر�ϵͳ���޷��رյ�Դ��
  mov    ax,5301H
  xor    bx,bx
  xor    cx,cx
  int    15H
  mov    ax,530EH
  xor    bx,bx
  mov    cx,102H
  int    15H
  MOV AX,5307H  ; �߼���Դ������,���õ�Դ״̬ 
  MOV BX,0001H  ; �豸ID,1:�����豸 
  MOV CX,0003H  ; ״̬,3:��ʾ�ػ� 
  INT 15H 
  jmp $

ret

;------------------------------------------------------------------
; ����
; �����������: ��
reboot:

  ;��ʾ������ʾ
  mov si,title_restart
  call show_title

  ; �ػ�����
  call power_off_display

  ; ����
  jmp 0xffff:0x0000

ret

;-----------------------------------------------------------------
; �ж���������Ƿ���ƥ�������
command_check:
  
  pusha

  ;--------------------------------------------------------
  ; �ػ�����
  mov si,command
  mov di,command_poweroff
  mov cx,[cs:command_poweroff_len]
  call _memcmp
  cmp ax,0
  jnz command_check_poweroff
  call power_off
  jmp $
  command_check_poweroff:

  ;--------------------------------------------------------
  ; ��������
  mov si,command
  mov di,command_reboot
  mov cx,[cs:command_reboot_len]
  call _memcmp
  cmp ax,0
  jnz command_check_reboot
  call reboot
  jmp $
  command_check_reboot:

  ;--------------------------------------------------------
  ; ��ʾ������
  mov si,command
  mov di,command_help
  mov cx,[cs:command_help_len]
  call _memcmp
  cmp ax,0
  jnz command_check_help
  mov si,title_help
  call show_title
  mov ax,0 ; ����ָ�����
  jmp command_check_ok
  command_check_help:

  ;--------------------------------------------------------
  ; ���س��ָ�����
  mov si,command
  mov di,command_enter
  mov cx,[cs:command_enter_len]
  call _memcmp
  cmp ax,0
  jnz command_check_enter
  mov ax,1 ; �ָ�����
  jmp command_check_ok
  command_check_enter:

  ;--------------------------------------------------------
  ; ��ʾ������Ϣ
  mov si,command
  mov di,command_diskinfo
  mov cx,[cs:command_diskinfo_len]
  call _memcmp
  cmp ax,0
  jnz command_check_diskinfo
  call display_diskinfo
  mov si,title_diskinfo
  call show_title
  mov ax,0 ; ����ָ�����
  jmp command_check_ok
  command_check_diskinfo:
 
  ;--------------------------------------------------------
  ; ��ƥ���������ļ��в�ѯ
  call load_file
  cmp ax,0
  jnz command_check_load_file
  mov ax,1 ; ��ָ�����
  jmp command_check_ok
  command_check_load_file:

  ;--------------------------------------------------------
  ; ��ƥ�������
  mov si,title_invalid
  call show_title
  popa
  ret

command_check_ok:

  cmp ax,0
  jz command_check_display
  ; �ָ�����Ļ
  call _display_main
  command_check_display:

  popa

ret

;------------------------------------------------------------------
; �Ӽ��̼�¼���������
command_display:

   pusha

   ; ������Ļ����������
   ; ��ʼ��λ��23�е�1��
   mov bx,22*80*2 
   ;��ֵ�Կ��ε�ַ
   mov ax,0xb800
   mov ds,ax;
   mov byte [ds:bx],'C'
   mov byte [ds:bx+1],00001111b
   add bx,2
   mov byte [ds:bx],'O'
   mov byte [ds:bx+1],00001111b
   add bx,2
   mov byte [ds:bx],'M'
   mov byte [ds:bx+1],00001111b
   add bx,2
   mov byte [ds:bx],'M'
   mov byte [ds:bx+1],00001111b
   add bx,2 
   mov byte [ds:bx],'A'
   mov byte [ds:bx+1],00001111b
   add bx,2
   mov byte [ds:bx],'N'
   mov byte [ds:bx+1],00001111b
   add bx,2
   mov byte [ds:bx],'D'
   mov byte [ds:bx+1],00001111b
   add bx,2
   mov byte [ds:bx],':'
   mov byte [ds:bx+1],00001111b
   add bx,2

   ; �������ո�
   mov cx,72
   command_buf_clear:
     mov byte [ds:bx],' '
     mov byte [ds:bx+1],00001111b
     add bx,2
   loop command_buf_clear

   mov ah,2
   mov bh,0
   mov dh,22 ; ��23��
   mov cx,8  ; ��궨λ�ڵ�8��
   mov dl,cl ;
   int 10h

   popa
ret

;------------------------------------------------------------------
; �Ӽ��̼�¼���������
command_buf:

   call command_display

   ; ����������
   mov si,command
   mov cx,50
   mov dx,0
   call _memset
   mov dx,0
   mov [cs:command_len],dx

  command_buf_1:

   pusha
   call dsp_datetime
   popa

   ; �����̻���
   mov ah,0
   int 16h
   ; al�б���ascii��

   ; ��������ֵ���������
   mov bx,[cs:command_len]
   mov [cs:command+bx],al
   ; ���������
   add bx,1
   mov [cs:command_len],bx

   ; �ﵽ50�ֽ���������
   cmp bx,50
   jz command_buf

   ; ��ESC�����������������
   cmp al,27
   jz command_buf

   ; ���س��������ռ����
   cmp al,13
   jz command_buf_end

   ; �ڹ��λ�ô�ӡal��ֵ 
   mov ah,9
   mov bl,00000111b
   mov bh,0
   mov cx,1
   int 10h

   ;���ù��λ��
   mov ah,2
   mov bh,0
   mov dh,22 ; ��23��
   mov cx,[cs:command_len] ; ��ȡ���λ��
   add cx,8 ; ����8λ
   mov dl,cl ;
   int 10h

  jmp command_buf_1

command_buf_end:

  call command_display

ret;
;------------------------------------------------------------------------------
; ���ļ�������в�ѯƥ���ļ��������ڴ�ִ��
; ����ֵ:ax 0�ɹ� 1ʧ��
load_file:

  pusha

  mov ax,0
  mov ds,ax
  mov es,ax

  ; �ļ�����������0x1500
  mov di,0x1500

  ;һ���������֧��16���ļ�
  mov cx,16

 ; ѭ����ȡ�ļ������
 load_file_load:
 
  push cx
  push di

  ; �ձ�����ת
  mov ax,[es:di]
  cmp ax,0xcccc
  jnz load_file_load_loop

  add di,2 ; ƫ��2λָ���ļ���
  mov si,di
  call _strlen
  mov cx,ax

  mov si,command
  call _memcmp

  cmp ax,0
  jnz load_file_load_loop

  mov ax,0
  mov ds,ax
  add di,16 ; ƫ��16λָ��LBA
  mov bx,[es:di]
  add di,8 ; ƫ��8λָ������
  mov cx,[es:di]
  mov si,0x7e00
  
  call read_disk_LBA
  
  pop di
  pop cx

  call 0x7e00
  
  
  popa
  mov ax,0
  ret

load_file_load_loop:

  pop di
  pop cx
  add di,32 ; �Ƶ���һ���ļ���

  loop load_file_load

  popa
  mov ax,1

ret

;------------------------------------------------------------------------------
;�ļ������
filetable:
times 32 db 0x0

;--------------------------------------------------------------------------
;������

start_disk: db 0x00

;--------------------------------------------------------------------------
;������

title:
db ' Welcome to OS/3 System , Written by YuQiancheng .                              '

title_help:
db ' (support command : poweroff / reboot / diskinfo / [filename] )                 '

title_restart:
db ' Restarting this system !                                                       '

title_shutdown:
db ' Shutting down this system !                                                    '

title_invalid:
db ' Invalid command ! (support command: poweroff / reboot / diskinfo / [filename] )'

;------------------------------------------------------------------
command: times 50 db 0x00
command_len: dw 0x0 ; �������ݵĳ���

command_poweroff: db 'poweroff',13
command_poweroff_len: dw ($-command_poweroff)

command_reboot: db 'reboot',13
command_reboot_len: dw ($-command_reboot)

command_help: db 'help',13
command_help_len: dw ($-command_help)

command_enter: db 13
command_enter_len: dw ($-command_enter)

command_diskinfo: db 'diskinfo',13
command_diskinfo_len: dw ($-command_diskinfo)

;------------------------------------------------------------------

; ���������4KB�ռ�
times 512*8-($-$$) db 0xff

