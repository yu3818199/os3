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
get_diskinfo:

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
    
    ;ȡ������Ϣ
    xor ax,ax
    xor bx,bx
    xor cx,cx
    xor dx,dx

    mov ah,08h
    mov dl , [cs:start_disk]
    int 13h

    jc get_diskinfo_error

    pusha
    ;BL��01H �� 360K 
    ;��02H �� 1.2M 
    ;��03H �� 720K 
    ;��04H �� 1.44M 
    mov al,bl
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
    popa

    pusha
    xor ax,ax
    ; CL��λ7-6���������ĸ�2λ
    mov ah,cl
    shr ah,6
    ; CH���������ĵ�8λ
    mov al,ch
    inc ax
    call bin2dec
    mov si,dec_char
    mov di,title_diskinfo+26
    mov cx,5
    call _memcpy
    popa

    pusha
    ; DH����ͷ��
    xor ax,ax
    mov al,dh
    inc ax
    call bin2dec
    mov si,dec_char+3
    mov di,title_diskinfo+38
    mov cx,2
    call _memcpy
    popa

    pusha
    ; CL��λ5-0�������� 
    xor ax,ax
    mov al,cl
    shl al,2
    shr al,2
    call bin2dec
    mov si,dec_char+2
    mov di,title_diskinfo+48
    mov cx,3
    call _memcpy
    popa

ret

get_diskinfo_error:

    mov bl,'E'
    mov [cs:title_diskinfo+11],bl
    mov bl,'R'
    mov [cs:title_diskinfo+12],bl
    mov [cs:title_diskinfo+13],bl
    mov bl,':'
    mov [cs:title_diskinfo+14],bl
    
    ; ��ֵ��4λ
    xor bx,bx
    mov bl,ah
    shr bl,4
    mov dl, [cs:hex+bx]
    mov [cs:title_diskinfo+15],dl
    ;��ֵ��4λ
    xor bx,bx
    mov bl,ah
    shl bl,12
    shr bl,12
    mov dl, [cs:hex+bx]
    mov [cs:title_diskinfo+16],dl

ret

;------------------------------------------------------------------
hex: db '0123456789ABCDEF'

title_diskinfo:
;  '01234567890123456789012345678901234567890123456789012345678901234567890123456789'
db ' DISK:** TYPE:** CYLINDER:***** HEADS:** SECTOR:***                             '




