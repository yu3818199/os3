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
; 磁盘管理函数                                                           ;
;                                                                        ;
; 主要功能：磁盘信息读取，读写磁盘等功能                                 ;
; 作    者: yuqiancheng                                                  ;
; 编写日期: 2019/10/01                                                   ;
;                                                                        ;
;------------------------------------------------------------------------;

;------------------------------------------------------------------
; 读取磁盘信息保存在title_diskinfo地址中
display_diskinfo:

    pusha

    call get_diskinfo

    ; 盘符
    ; 赋值高4位
    mov dl , [cs:start_disk]
    xor bx,bx
    mov bl,dl
    shr bl,4
    mov dl, [cs:hex+bx]
    mov [cs:title_diskinfo+6],dl
    ;赋值低4位
    mov dl , [cs:start_disk]
    xor bx,bx
    mov bl,dl
    shl bl,4
    shr bl,4
    mov dl, [cs:hex+bx]
    mov [cs:title_diskinfo+7],dl
  
    ;磁盘类型
    mov al,[cs:disk_info]
    ; 赋值高4位;保持16进制显示
    xor bx,bx
    mov bl,al
    shr bl,4
    mov dl, [cs:hex+bx]
    mov [cs:title_diskinfo+14],dl
    ;赋值低4位
    xor bx,bx
    mov bl,al
    shl bl,4
    shr bl,4
    mov dl, [cs:hex+bx]
    mov [cs:title_diskinfo+15],dl

    ; 柱面
    xor ax,ax
    mov ax,[cs:disk_cylinder]
    call bin2dec
    mov si,dec_char
    mov di,title_diskinfo+26
    mov cx,5
    call _memcpy

    ; DH＝磁头数
    xor ax,ax
    mov al,[cs:disk_heads]
    call bin2dec
    mov si,dec_char+3
    mov di,title_diskinfo+38
    mov cx,2
    call _memcpy

    ; CL的位5-0＝扇区数 
    xor ax,ax
    mov al,[cs:disk_sector]
    call bin2dec
    mov si,dec_char+2
    mov di,title_diskinfo+48
    mov cx,3
    call _memcpy

    popa

ret

;------------------------------------------------------------------
hex: db '0123456789ABCDEF'

title_diskinfo:
;  '01234567890123456789012345678901234567890123456789012345678901234567890123456789'
db ' DISK:** TYPE:** CYLINDER:***** HEADS:** SECTOR:***                             '

;----------------------------------------------------------------------------
; 取磁盘信息
get_diskinfo:

  pusha
  
    ;取磁盘信息
    xor ax,ax
    xor bx,bx
    xor cx,cx
    xor dx,dx

    mov ah,08h
    mov dl , [cs:start_disk]
    int 13h
    
    jc get_diskinfo_error
    
    ; BL＝01H — 360K ＝02H — 1.2M ＝03H — 720K ＝04H — 1.44M
    mov [cs:disk_info],bl

    ; CL的位7-6＝柱面数的高2位
    xor ax,ax
    mov ah,cl
    shr ah,6
    ; CH＝柱面数的低8位
    mov al,ch
    inc ax
    mov [cs:disk_cylinder], ax
    
    ; DH＝磁头数
    xor ax,ax
    mov al,dh
    inc ax
    mov [cs:disk_heads], al

    ; CL的位5-0＝扇区数 
    xor ax,ax
    mov al,cl
    shl al,2
    shr al,2
    mov [cs:disk_sector], al

  popa

  ret

get_diskinfo_error:

  mov ax,0x0
  mov [cs:disk_heads],al
  mov [cs:disk_cylinder],ax
  mov [cs:disk_sector],al

  popa

ret

;磁盘类型
disk_info: db 0x0
;磁头数
disk_heads: db 0x0
;柱面数
disk_cylinder: db 0x0,0x0
;扇区数
disk_sector: db 0x0


;----------------------------------------------------------------------------
; 取磁盘扇区到内存
; 输入参数： cx - 读取扇区数
;            si - 内存偏移地址
;            ds - 内存段地址
;            bx - 起始LBA块
read_disk_LBA:

    pusha

    mov [cs:disk_packet_count],cx
    mov [cs:disk_packet_bufferoff],si
    mov [cs:disk_packet_bufferseg],ds
    mov [cs:disk_packet_blockNum],bx

    mov ax,cs   ;初始化寄存器  
    mov ds,ax  
    mov es,ax  

    mov ah,0x42 ; 0x42读 0x43写
    mov dl,[cs:start_disk]  ; disk
    mov si,disk_packet
    int 13h

    jc  read_disk_LBA_error  

    popa
    ret

read_disk_LBA_error:

  popa

ret 

;int13读写地址数据结构体  
disk_packet:  
disk_packet_packet_size: db 10h     ;packet大小，16个字节  
disk_packet_reserved:    db 0  
disk_packet_count:       dw 0       ;读取扇区数
disk_packet_bufferoff:   dw 0       ;内存偏移地址  
disk_packet_bufferseg:   dw 0       ;内存段地址  
disk_packet_blockNum:    dd 0       ;起始LBA块  
                         dd 0  


