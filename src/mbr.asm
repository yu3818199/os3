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
; MBR主引导程序                                                          ;
;                                                                        ;
; 主要功能：从引导磁盘中读取主控程序写入内存中，并跳转到主控程序区。     ;
; 作    者: yuqiancheng                                                  ;
; 编写日期: 2019/10/01                                                   ;
;                                                                        ;
;------------------------------------------------------------------------;

[bits 16]
org 0x7c00 ; 设置本段初始地址(BIOS加载)

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
;  07C00     07DFF    512B      本程序MBR被BIOS加载到此处
;  01500     07BFF    约25K     (空闲)
;  00500     014FF    4KB       (加载本操作系统主控程序)
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
; 磁盘中读取主控程序写入内存

  ; es:bx 写入的内存地址
  mov ax,0
  mov es,ax
  mov bx,0x500  ;  本操作系统主控程序分配内存区

  ; ah:2表示读 al:读取扇区数
  mov ah,0x02
  mov al,9    ; 读取8个扇区填充在0x500至0x16FF内存区

  ; ch:柱面 cl:扇区号
  mov cx,0x0002  ; 从2扇区开始读,第1扇区为本段代码区域

  ; 磁头号
  mov dh,0

  ; 读取启动磁盘号
  ; dl:驱动器号, 软驱 A:0 B:1 硬盘 80h (由BIOS赋值)
  ; mov dl,80h

  int 13h       ; 调用中断13

  ; 成功ah=0,al=读入扇区数
  ; 失败ah=错误码
  cmp ah,0
  jnz error
  
  ; 跳转到主控内存区开始执行
  jmp 0x00:0x500

;------------------------------------------------------------------
; 磁盘读取出错
error:

jmp $

;------------------------------------------------------------------
 times 510-($-$$) db 0
 db 0x55,0xaa
;------------------------------------------------------------------

