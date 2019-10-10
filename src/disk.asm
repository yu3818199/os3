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
; ���̹�����                                                           ;
;                                                                        ;
; ��Ҫ���ܣ�������Ϣ��ȡ����д���̵ȹ���                                 ;
; ��    ��: yuqiancheng                                                  ;
; ��д����: 2019/10/01                                                   ;
;                                                                        ;
;------------------------------------------------------------------------;

;------------------------------------------------------------------
; ��ȡ������Ϣ������title_diskinfo��ַ��
display_diskinfo:

    pusha

    call get_diskinfo

    ; �̷�
    ; ��ֵ��4λ
    mov dl , [cs:start_disk]
    xor bx,bx
    mov bl,dl
    shr bl,4
    mov dl, [cs:hex+bx]
    mov [cs:title_diskinfo+6],dl
    ;��ֵ��4λ
    mov dl , [cs:start_disk]
    xor bx,bx
    mov bl,dl
    shl bl,4
    shr bl,4
    mov dl, [cs:hex+bx]
    mov [cs:title_diskinfo+7],dl
  
    ;��������
    mov al,[cs:disk_info]
    ; ��ֵ��4λ;����16������ʾ
    xor bx,bx
    mov bl,al
    shr bl,4
    mov dl, [cs:hex+bx]
    mov [cs:title_diskinfo+14],dl
    ;��ֵ��4λ
    xor bx,bx
    mov bl,al
    shl bl,4
    shr bl,4
    mov dl, [cs:hex+bx]
    mov [cs:title_diskinfo+15],dl

    ; ����
    xor ax,ax
    mov ax,[cs:disk_cylinder]
    call bin2dec
    mov si,dec_char
    mov di,title_diskinfo+26
    mov cx,5
    call _memcpy

    ; DH����ͷ��
    xor ax,ax
    mov al,[cs:disk_heads]
    call bin2dec
    mov si,dec_char+3
    mov di,title_diskinfo+38
    mov cx,2
    call _memcpy

    ; CL��λ5-0�������� 
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
; ȡ������Ϣ
get_diskinfo:

  pusha
  
    ;ȡ������Ϣ
    xor ax,ax
    xor bx,bx
    xor cx,cx
    xor dx,dx

    mov ah,08h
    mov dl , [cs:start_disk]
    int 13h
    
    jc get_diskinfo_error
    
    ; BL��01H �� 360K ��02H �� 1.2M ��03H �� 720K ��04H �� 1.44M
    mov [cs:disk_info],bl

    ; CL��λ7-6���������ĸ�2λ
    xor ax,ax
    mov ah,cl
    shr ah,6
    ; CH���������ĵ�8λ
    mov al,ch
    inc ax
    mov [cs:disk_cylinder], ax
    
    ; DH����ͷ��
    xor ax,ax
    mov al,dh
    inc ax
    mov [cs:disk_heads], al

    ; CL��λ5-0�������� 
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

;��������
disk_info: db 0x0
;��ͷ��
disk_heads: db 0x0
;������
disk_cylinder: db 0x0,0x0
;������
disk_sector: db 0x0


;----------------------------------------------------------------------------
; ȡ�����������ڴ�
; ��������� cx - ��ȡ������
;            si - �ڴ�ƫ�Ƶ�ַ
;            ds - �ڴ�ε�ַ
;            bx - ��ʼLBA��
read_disk_LBA:

    pusha

    mov [cs:disk_packet_count],cx
    mov [cs:disk_packet_bufferoff],si
    mov [cs:disk_packet_bufferseg],ds
    mov [cs:disk_packet_blockNum],bx

    mov ax,cs   ;��ʼ���Ĵ���  
    mov ds,ax  
    mov es,ax  

    mov ah,0x42 ; 0x42�� 0x43д
    mov dl,[cs:start_disk]  ; disk
    mov si,disk_packet
    int 13h

    jc  read_disk_LBA_error  

    popa
    ret

read_disk_LBA_error:

  popa

ret 

;int13��д��ַ���ݽṹ��  
disk_packet:  
disk_packet_packet_size: db 10h     ;packet��С��16���ֽ�  
disk_packet_reserved:    db 0  
disk_packet_count:       dw 0       ;��ȡ������
disk_packet_bufferoff:   dw 0       ;�ڴ�ƫ�Ƶ�ַ  
disk_packet_bufferseg:   dw 0       ;�ڴ�ε�ַ  
disk_packet_blockNum:    dd 0       ;��ʼLBA��  
                         dd 0  


