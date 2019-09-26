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
;------------------------------------------------------------------


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

;------------------------------------------------------------------
; ���������ڴ�
; �������: si-�ڴ��׵�ַ��cx-���� dl-���ֵ
; �������: ��
_memset:
 pusha
 _memset_1:
  mov bx,cx
  mov [cs:si+bx-1],dl
 loop _memset_1
 popa
ret

;------------------------------------------------------------------
; �ڴ�Ƚ�
; �������: si-�ڴ��׵�ַ1��di-�ڴ��׵�ַ2��cx-�Ƚϳ���
; �������: ax 0-��ͬ 1-����ͬ
_memcmp:
  pusha

 ; �Ƚ�
 _memcmp_1:
  mov bx,cx
  mov ah,[cs:si+bx-1]
  mov al,[cs:di+bx-1]
  cmp ah,al
  jne _mem_jne
 loop _memcmp_1

 ;��ͬ
  popa
  mov ax,0
  ret

 ;��ͬ
 _mem_jne:
  popa
  mov ax,1

ret

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
; �����Ļ���趨���
; �����������: ��
clear_screen:

   pusha

   ;AH ���ܺ�= 0x06  �Ͼ���
   ;AL = �Ͼ������(���Ϊ0,��ʾȫ��)
   mov     ax, 0600h

   ;BH = �Ͼ�������
   mov     bx, 0700h

   ;(CL,CH) = �������Ͻǵ�(X,Y)λ��
   mov     cx, 0      ; ���Ͻ�: (0, 0)

   ;(DL,DH) = �������½ǵ�(X,Y)λ��
   mov     dx, 184fh	; ���½�: (80,25),

   ;INT 0x10   ���ܺ�:0x06 �Ͼ���
   int     10h

   ; ah=02 �趨���λ��
   mov ah,2

   ; bh ���λ�õ���ʾҳ
   mov bh,0

   ; �趨������ڵ�����
   mov dh,0  ; ��1��
   mov dl,0  ; ��1��

   ; �趨���λ��
   int 10h

   popa

ret

;------------------------------------------------------------------
;ȫ����ʾos/3�ַ�ͼƬ
; �����������: ��
show_CharPictures:

   pusha
   push ds

   ; si=ͼƬ������ʼ��ַ
   mov si,os3_picture
   mov bx,0

   ; dsָ���ı���ʾ���ε�ַ
   mov dx,0xb800
   mov ds,dx;

   ; cx=��������
   mov cx,[cs:os3_picture_len]

  show_CharPictures_1:

   ; bxָ����Ҫ��ʾ������ڴ��ַ
   mov bx,[cs:si]
   add bx,bx

   ; ��ֵ�Դ��ַ
   mov byte [ds:bx],0x0
   mov byte [ds:bx+1],00110000b 

   ; ָ����һ��������ַ
   add si,2 

 loop show_CharPictures_1; ѭ����ʾ����
 
   pop ds
   popa

ret
;------------------------------------------------------------------
; �ڵ�21����ʾ80�ֽ��ı�
; �������: si-��ʾ�ı���ʼ��ַ
show_title:

   pusha
   push ds

   ; dsָ���ı���ʾ���ε�ַ
   mov dx,0xb800
   
   ; ����20��
   add dx,20*80*2/16
   
   ; �ε�ַָ���21��
   mov ds,dx;

   ; ��ʾ80�ַ�
   mov cx,80

  show_title_1:

   mov bx,cx
   sub bx,1

   ; ȡ1���ַ�
   mov dl,[cs:si+bx]

   ;�޸��Դ�����
   add bx,bx
   mov byte [ds:bx],dl
   mov byte [ds:bx+1],01110000b

  loop show_title_1;

  pop ds
  popa

ret

;------------------------------------------------------------------
; ��ȡʱ��
dsp_datetime:

   pusha
   push ds

   ; ��
   mov al,9
   out 70h,al
   in al,71h
   mov ah,al
   shr ah,4
   and al,00001111b
   add ah,30h
   add al,30h
   mov [cs:message_time+2],ah
   mov [cs:message_time+3],al
   ; ��
   mov al,8
   out 70h,al
   in al,71h
   mov ah,al
   shr ah,4
   and al,00001111b
   add ah,30h
   add al,30h
   mov [cs:message_time+5],ah
   mov [cs:message_time+6],al
   ; ��
   mov al,7
   out 70h,al
   in al,71h
   mov ah,al
   shr ah,4
   and al,00001111b
   add ah,30h
   add al,30h
   mov [cs:message_time+8],ah
   mov [cs:message_time+9],al
   ; ʱ
   mov al,4
   out 70h,al
   in al,71h
   mov ah,al
   shr ah,4
   and al,00001111b
   add ah,30h
   add al,30h
   mov [cs:message_time+11],ah
   mov [cs:message_time+12],al
   ; ��
   mov al,2
   out 70h,al
   in al,71h
   mov ah,al
   shr ah,4
   and al,00001111b
   add ah,30h
   add al,30h
   mov [cs:message_time+14],ah
   mov [cs:message_time+15],al
   ; ��
   mov al,0
   out 70h,al
   in al,71h
   mov ah,al
   shr ah,4
   and al,00001111b
   add ah,30h
   add al,30h
   mov [cs:message_time+17],ah
   mov [cs:message_time+18],al

   ; ��ӡʱ�� 

   ;��ֵ�Կ��ε�ַ
   mov bx,0xb800
   mov ds,bx;
   
   ; ��ʼ��
   mov si,message_time_end-1-3

   ; ��ʾ�ַ���
   mov cx,[cs:message_time_len]
   sub cx,3

   ; ��ʼ��λ�����һ�����һ��
   mov bx,25*80*2-1

 dsp_datetime_1:

   ;��ȡһ���ַ�
   mov dl,[cs:si]

   ;�޸��Դ�����
   mov byte [ds:bx-1],dl
   mov byte [ds:bx],00000111b

   ;��������ֵ
   sub si,1
   sub bx,2

 loop dsp_datetime_1; ѭ����ʾ

   pop ds
   popa

ret;

;------------------------------------------------------------------
; �ػ����������±���ˢ���м�
; �����������: ��
power_off_display:

   pusha
   push ds

   ;��ֵ�Կ��ε�ַ
   mov ax,0xb800
   mov ds,ax;
   
   ; ѭ��12��
   mov cx,12

 power_off_1:
   push cx
   ;---------------------------------
   ; �ϱߵ��к�
   mov ax,12
   sub ax,cx  ; ax=12-cx
   ; �������׵�ַ����ax��
   mov bx,80*2
   mul bx ; ax=ax*bx
   mov bx,ax
   ; �ϱ�ȫ��ˢ��
   mov cx,80
   power_off_2:
      mov byte [ds:bx],' '
      mov byte [ds:bx+1],00000000b
      add bx,2
   loop power_off_2
   ;---------------------------------
   ; �±ߵ��к�
   pop cx
   push cx
   ; 12+cx�õ��±ߵ��к�
   mov ax,12
   add ax,cx ;ax=12+cx
   ; �������׵�ַ����ax��
   mov bx,80*2
   mul bx ; ax=ax*bx
   mov bx,ax
   ; �ϱ�ȫ��ˢ��
   mov cx,80
   power_off_3:
      mov byte [ds:bx],' '
      mov byte [ds:bx+1],00000000b
      add bx,2
   loop power_off_3
   ;---------------------------------
   ; �ȴ�
   call sleep
   pop cx
 loop power_off_1
 ;---------------------------------
 ; �м�һ��
   mov bx,12*80*2
   mov cx,80
 power_off_4:
   mov byte [ds:bx],' '
   mov byte [ds:bx+1],00000000b
   add bx,2
 loop power_off_4
   call sleep
   
   pop ds
   popa

ret
;------------------------------------------------------------------
; ��ͣһ��ʱ��
; �����������: ��
sleep:
 pusha
  mov cx,3000
 sleep_1:
  pusha
  mov cx,1000
  sleep_2:
   pusha
   popa
  loop sleep_2
  popa
 loop sleep_1
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

;------------------------------------------------------------------
; ��ʾ��̬��Ļ
; �����������: ��
display_Multicolor:

   pusha
   push ds

   ;��ֵ�Կ��ε�ַ
   mov bx,0xb800
   mov ds,bx

   mov dx,1234h
   
   ; ѭ��1���
   mov cx,10000

   ; ��ʾ����ַ�����ɫ
 Multicolor1:
   push cx
   mov cx,25*80-1
  Multicolor2:
   mov bx,cx
   add bx,bx ; �����ַ
   add dx,bx ; ģ����ʾ����
   mov byte [ds:bx],dh
   mov byte [ds:bx+1],dl
  loop Multicolor2
   pop cx
 loop Multicolor1

   pop ds
   popa

ret

;-----------------------------------------------------------------
; �ж���������Ƿ���ƥ�������
command_check:
  
  pusha

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

  ; ��ʾ�����
  mov si,command
  mov di,command_test
  mov cx,[cs:command_test_len]
  call _memcmp
  cmp ax,0
  jnz command_check_color
  call display_Multicolor
  mov ax,1 ; ��ָ�����
  jmp command_check_ok
  command_check_color:

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


;--------------------------------------------------------------------------
;������

title:
db ' Welcome to OS/3 System , Written by YuQiancheng .                              '

title_help:
db ' (support command : poweroff / reboot / test )                                  '

title_restart:
db ' Restarting this system !                                                       '

title_shutdown:
db ' Shutting down this system !                                                    '

title_invalid:
db ' Invalid command ! (support command : poweroff / reboot / test )                '

;--------------------------------------------------------------------------------
;OS/3ͼƬ��Ӧ��λ�ã���24*80��Χ�ڴ��ϵ��´����Ҷ�λ
os3_picture:
dw 88,89,90,91,92,93,94,95,96,113,114,115,116,117,118,119,120,137,138,139,147,148,149,150,151,152,153
dw 166,167,168,169,170,171,172,173,174,175,176,177,178,191,192,193,194,195,196,197,198,199,200,201,202,203,216,217,218,219,224,225,226,227,228,229,230,231,232,233,234,235
dw 244,245,246,247,248,256,257,258,259,260,270,271,272,273,281,282,283,284,296,297,298,303,304,305,306,313,314,315,316
dw 323,324,325,326,338,339,340,341,349,350,351,362,363,364,365,376,377,378,383,384,385,395,396,397
dw 402,403,404,405,419,420,421,422,429,430,431,443,444,445,455,456,457,462,463,464,475,476,477
dw 482,483,484,500,501,502,509,510,511,535,536,537,555,556,557
dw 561,562,563,581,582,583,589,590,591,592,593,614,615,616,617,633,634,635,636
dw 641,642,643,661,662,663,670,671,672,673,674,675,676,677,694,695,696,709,710,711,712,713,714
dw 721,722,723,741,742,743,752,753,754,755,756,757,758,759,760,761,762,774,775,776,788,789,790,791,792,793,794,795,796
dw 801,802,803,821,822,823,836,837,838,839,840,841,842,843,844,853,854,855,874,875,876,877
dw 881,882,883,901,902,903,921,922,923,924,925,933,934,935,955,956,957,958
dw 961,962,963,981,982,983,1003,1004,1005,1006,1013,1014,1015,1036,1037,1038
dw 1042,1043,1044,1060,1061,1062,1068,1069,1070,1084,1085,1086,1092,1093,1094,1116,1117,1118
dw 1122,1123,1124,1125,1139,1140,1141,1142,1148,1149,1150,1151,1164,1165,1166,1172,1173,1174,1182,1183,1184,1196,1197,1198
dw 1203,1204,1205,1206,1218,1219,1220,1221,1229,1230,1231,1243,1244,1245,1246,1251,1252,1253,1262,1263,1264,1265,1275,1276,1277
dw 1284,1285,1286,1287,1288,1296,1297,1298,1299,1300,1310,1311,1312,1313,1322,1323,1324,1325,1331,1332,1333,1343,1344,1345,1346,1354,1355,1356,1357
dw 1366,1367,1368,1369,1370,1371,1372,1373,1374,1375,1376,1377,1378,1391,1392,1393,1394,1395,1396,1397,1398,1399,1400,1401,1402,1403,1404,1411,1412,1413,1424,1425,1426,1427,1428,1429,1430,1431,1432,1433,1434,1435
dw 1448,1449,1450,1451,1452,1453,1454,1455,1456,1473,1474,1475,1476,1477,1478,1479,1480,1481,1490,1491,1492,1507,1508,1509,1510,1511,1512,1513
os3_picture_len: dw ($-os3_picture)/2
;------------------------------------------------------------------
;������ʱ����(Ԥ��19���ֽڿռ�)
message_time: db '20XX-XX-XX XX:XX:XX'
message_time_end:
message_time_len: dw ($-message_time)
;------------------------------------------------------------------
command: times 50 db 0x00
command_len: dw 0x0 ; �������ݵĳ���

command_poweroff: db 'poweroff',13
command_poweroff_len: dw ($-command_poweroff)

command_reboot: db 'reboot',13
command_reboot_len: dw ($-command_reboot)

command_help: db 'help',13
command_help_len: dw ($-command_help)

command_test: db 'test',13
command_test_len: dw ($-command_test)

command_enter: db 13
command_enter_len: dw ($-command_enter)

;------------------------------------------------------------------

; ���������4KB�ռ�
times 512*8-($-$$) db 0x00

