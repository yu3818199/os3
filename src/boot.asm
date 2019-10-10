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
; BOOT主控程序                                                           ;
;                                                                        ;
; 主要功能：展示主界面，实现操作系统关机、重启，扩展程序加载等功能。     ;
; 作    者: yuqiancheng                                                  ;
; 编写日期: 2019/10/01                                                   ;
;                                                                        ;
;------------------------------------------------------------------------;

[bits 16]
; 设置本段初始地址(由MBR加载至0x500位置，共4KB)
org 0x500

;------------------------------------------------------------------
;   内存说明
; 
; 起始地址	结束地址	大小	    用途
;  FFFF0     FFFFF    16B       BIOS入口地址，此地址也属于BIOS区域
;  F0000     FFFEF    64KB-16B	BIOS区域
;  C8000     EFFFF    160KB     映射硬件适配器的ROM或内存映射式I/O
;  C0000     C7FFF    32KB      显示器适配BIOS
;  B8000     BFFFF    32KB      用于文本模式显示适配器
;  B0000     B7FFF    32KB      用于黑白显示器适配器
;  A0000     AFFFF    64KB      用于彩色显示器适配器
;  9FC00     9FFFF    1KB       EBDA，扩展BIOS区域
;  07E00     9FBFF    约608KB   (加载本操作系统扩展程序)
;  07C00     07DFF    512B      MBR程序区
;  01500     07BFF    约25K     (空闲)
;  00500     014FF    4KB       本程序被MBR加载至此处
;  00400     004FF    256B      BIOS Data Area (BIOS数据区)
;  00000     003FF    1KB       Interrupt Vector Table(中断向量表)
;------------------------------------------------------------------

;------------------------------------------------------------------
;    磁盘说明
;  磁头    柱面   扇区          用途
;   0       0      1          MBR程序区
;   0       0     2-9         主控程序区(8个扇区)
;   0       0      10         数据分区表
;------------------------------------------------------------------

;------------------------------------------------------------------
;  数据分区表说明
;  (每个文件分配区占用32字节，每个扇区支持16个文件)
;  2字节开始+16字节文件名+8字节LBA开始地址+4字节读取扇区数+2字节结束
;
;------------------------------------------------------------------

; 保存启动盘标志
  mov [cs:start_disk],dl

; 设定代码数据同段
  mov ax,cs
  mov ds,ax
  mov es,ax

;------------------------------------------------------------------
; 显示主屏幕
call _display_main

;------------------------------------------------------------------
;进入主控程序
_main_jmp:
  call _main
jmp _main_jmp

jmp $

;-----------------------------------------------------------------
; 主控程序

_main:

  ; 接收输入的命令
  call command_buf
  
  ; 判断命令缓存区是否有匹配的命令
  call command_check

ret

; 引用内存管理函数
%include "memory.asm"

; 引用数值转换函数
%include "dec.asm"

; 引用屏幕控制函数
%include "screen.asm"

; 引用磁盘管理函数
%include "disk.asm"

;------------------------------------------------------------------
; 显示主屏幕内容
; 输入输出参数: 无
_display_main:

  pusha

  ;清屏
  call clear_screen

  ;显示os3
  call show_CharPictures

  ;显示标题
  mov si,title
  call show_title

  ;显示日期
  call dsp_datetime
  
  popa
  
ret

;------------------------------------------------------------------
; 关机
; 输入输出参数: 无
power_off:

  ;显示关机提示
  mov si,title_shutdown
  call show_title

  ;显示关机动画
  call power_off_display
 
  ;关机 ; 只会关闭系统，无法关闭电源。
  mov    ax,5301H
  xor    bx,bx
  xor    cx,cx
  int    15H
  mov    ax,530EH
  xor    bx,bx
  mov    cx,102H
  int    15H
  MOV AX,5307H  ; 高级电源管理功能,设置电源状态 
  MOV BX,0001H  ; 设备ID,1:所有设备 
  MOV CX,0003H  ; 状态,3:表示关机 
  INT 15H 
  jmp $

ret

;------------------------------------------------------------------
; 重启
; 输入输出参数: 无
reboot:

  ;显示重启提示
  mov si,title_restart
  call show_title

  ; 关机动画
  call power_off_display

  ; 重启
  jmp 0xffff:0x0000

ret

;-----------------------------------------------------------------
; 判断命令缓存区是否有匹配的命令
command_check:
  
  pusha

  ;--------------------------------------------------------
  ; 关机命令
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
  ; 重启命令
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
  ; 显示帮助栏
  mov si,command
  mov di,command_help
  mov cx,[cs:command_help_len]
  call _memcmp
  cmp ax,0
  jnz command_check_help
  mov si,title_help
  call show_title
  mov ax,0 ; 无需恢复主屏
  jmp command_check_ok
  command_check_help:

  ;--------------------------------------------------------
  ; 按回车恢复界面
  mov si,command
  mov di,command_enter
  mov cx,[cs:command_enter_len]
  call _memcmp
  cmp ax,0
  jnz command_check_enter
  mov ax,1 ; 恢复主屏
  jmp command_check_ok
  command_check_enter:

  ;--------------------------------------------------------
  ; 显示磁盘信息
  mov si,command
  mov di,command_diskinfo
  mov cx,[cs:command_diskinfo_len]
  call _memcmp
  cmp ax,0
  jnz command_check_diskinfo
  call display_diskinfo
  mov si,title_diskinfo
  call show_title
  mov ax,0 ; 无需恢复主屏
  jmp command_check_ok
  command_check_diskinfo:
 
  ;--------------------------------------------------------
  ; 无匹配的命令从文件中查询
  call load_file
  cmp ax,0
  jnz command_check_load_file
  mov ax,1 ; 需恢复主屏
  jmp command_check_ok
  command_check_load_file:

  ;--------------------------------------------------------
  ; 无匹配的命令
  mov si,title_invalid
  call show_title
  popa
  ret

command_check_ok:

  cmp ax,0
  jz command_check_display
  ; 恢复主屏幕
  call _display_main
  command_check_display:

  popa

ret

;------------------------------------------------------------------
; 从键盘记录命令到缓存区
command_display:

   pusha

   ; 更新屏幕命令输入区
   ; 初始定位在23行第1列
   mov bx,22*80*2 
   ;赋值显卡段地址
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

   ; 其余填充空格
   mov cx,72
   command_buf_clear:
     mov byte [ds:bx],' '
     mov byte [ds:bx+1],00001111b
     add bx,2
   loop command_buf_clear

   mov ah,2
   mov bh,0
   mov dh,22 ; 第23行
   mov cx,8  ; 光标定位在第8列
   mov dl,cl ;
   int 10h

   popa
ret

;------------------------------------------------------------------
; 从键盘记录命令到缓存区
command_buf:

   call command_display

   ; 清空命令缓存区
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

   ; 读键盘缓冲
   mov ah,0
   int 16h
   ; al中保存ascii码

   ; 保存输入值到命令缓存中
   mov bx,[cs:command_len]
   mov [cs:command+bx],al
   ; 更新命令长度
   add bx,1
   mov [cs:command_len],bx

   ; 达到50字节重新输入
   cmp bx,50
   jz command_buf

   ; 按ESC，清除缓存重新输入
   cmp al,27
   jz command_buf

   ; 按回车，命令收集完毕
   cmp al,13
   jz command_buf_end

   ; 在光标位置打印al的值 
   mov ah,9
   mov bl,00000111b
   mov bh,0
   mov cx,1
   int 10h

   ;设置光标位置
   mov ah,2
   mov bh,0
   mov dh,22 ; 第23行
   mov cx,[cs:command_len] ; 读取光标位置
   add cx,8 ; 右移8位
   mov dl,cl ;
   int 10h

  jmp command_buf_1

command_buf_end:

  call command_display

ret;
;------------------------------------------------------------------------------
; 从文件分配表中查询匹配文件并加载内存执行
; 返回值:ax 0成功 1失败
load_file:

  pusha

  mov ax,0
  mov ds,ax
  mov es,ax

  ; 文件分配表加载在0x1500
  mov di,0x1500

  ;一个扇区最多支持16个文件
  mov cx,16

 ; 循环读取文件分配表
 load_file_load:
 
  push cx
  push di

  ; 空表则跳转
  mov ax,[es:di]
  cmp ax,0xcccc
  jnz load_file_load_loop

  add di,2 ; 偏移2位指向文件名
  mov si,di
  call _strlen
  mov cx,ax

  mov si,command
  call _memcmp

  cmp ax,0
  jnz load_file_load_loop

  mov ax,0
  mov ds,ax
  add di,16 ; 偏移16位指向LBA
  mov bx,[es:di]
  add di,8 ; 偏移8位指向扇区
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
  add di,32 ; 移到下一个文件表

  loop load_file_load

  popa
  mov ax,1

ret

;------------------------------------------------------------------------------
;文件分配表
filetable:
times 32 db 0x0

;--------------------------------------------------------------------------
;启动盘

start_disk: db 0x00

;--------------------------------------------------------------------------
;标题栏

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
command_len: dw 0x0 ; 命令内容的长度

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

; 本程序分配4KB空间
times 512*8-($-$$) db 0xff

