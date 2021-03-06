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
; 屏幕控制函数                                                           ;
;                                                                        ;
; 主要功能：清屏，打印字符等功能                                         ;
; 作    者: yuqiancheng                                                  ;
; 编写日期: 2019/10/01                                                   ;
;                                                                        ;
;------------------------------------------------------------------------;


;------------------------------------------------------------------
; 清空屏幕并设定光标
; 输入输出参数: 无
clear_screen:

   pusha

   ;AH 功能号= 0x06  上卷窗口
   ;AL = 上卷的行数(如果为0,表示全部)
   mov     ax, 0600h

   ;BH = 上卷行属性
   mov     bx, 0700h

   ;(CL,CH) = 窗口左上角的(X,Y)位置
   mov     cx, 0      ; 左上角: (0, 0)

   ;(DL,DH) = 窗口右下角的(X,Y)位置
   mov     dx, 184fh	; 右下角: (80,25),

   ;INT 0x10   功能号:0x06 上卷窗口
   int     10h

   ; ah=02 设定光标位置
   mov ah,2

   ; bh 光标位置的显示页
   mov bh,0

   ; 设定光标所在的行列
   mov dh,0  ; 第1行
   mov dl,0  ; 第1列

   ; 设定光标位置
   int 10h

   popa

ret

;------------------------------------------------------------------
; 在指定的位置打印字符
; 输入参数 ch=行 cl=列 dh=字符 dl=样式
;
_putchar:

   pusha
   push dx
   ;赋值显卡段地址
   mov ax,0xb800
   mov ds,ax
   ;计算偏移位 (ch*80+cl)*2
   xor ax,ax
   mov al,ch
   mov bx,80
   mul bx     ; ch*80
   mov ch,0
   add ax,cx  ; ch*80+cl
   add ax,ax  ; (ch*80+cl)*2
   mov bx,ax
   pop dx
   mov byte [ds:bx],dh
   mov byte [ds:bx+1],dl

   popa
ret

;------------------------------------------------------------------
; 在指定的位置打印字符串
; 输入参数 ch=行 cl=列 cs:si=字符对应地址 dl=样式
;
_putstring:

   pusha
   push dx
   ;赋值显卡段地址
   mov ax,0xb800
   mov ds,ax
   ;计算偏移位 (ch*80+cl)*2
   xor ax,ax
   mov al,ch
   mov bx,80
   mul bx     ; ch*80
   mov ch,0
   add ax,cx  ; ch*80+cl
   add ax,ax  ; (ch*80+cl)*2
   mov bx,ax
   pop dx
  _putstring_1:
   mov dh,[cs:si]
   cmp dh,0
   jz _putstring_2
   mov byte [ds:bx],dh
   mov byte [ds:bx+1],dl
   inc si
   add bx,2
   jmp _putstring_1
  _putstring_2:

   popa
ret

;------------------------------------------------------------------
;全屏显示os/3字符图片
; 输入输出参数: 无
show_CharPictures:

   pusha
   push ds

   ; si=图片参数起始地址
   mov si,os3_picture
   mov bx,0

   ; ds指向文本显示区段地址
   mov dx,0xb800
   mov ds,dx;

   ; cx=参数长度
   mov cx,[cs:os3_picture_len]

  show_CharPictures_1:

   ; bx指向需要显示方块的内存地址
   mov bx,[cs:si]
   add bx,bx

   ; 赋值显存地址
   mov byte [ds:bx],0x0
   mov byte [ds:bx+1],00110000b 

   ; 指向下一个参数地址
   add si,2 

 loop show_CharPictures_1; 循环显示所有
 
   pop ds
   popa

ret

;------------------------------------------------------------------
; 在第21行显示80字节文本
; 输入参数: si-显示文本起始地址
show_title:

   pusha
   push ds

   ; ds指向文本显示区段地址
   mov dx,0xb800
   
   ; 下移20行
   add dx,20*80*2/16
   
   ; 段地址指向第21行
   mov ds,dx;

   ; 显示80字符
   mov cx,80

  show_title_1:

   mov bx,cx
   sub bx,1

   ; 取1个字符
   mov dl,[cs:si+bx]

   ;修改显存内容
   add bx,bx
   mov byte [ds:bx],dl
   mov byte [ds:bx+1],01110000b

  loop show_title_1;

  pop ds
  popa

ret


;------------------------------------------------------------------
; 获取时间
dsp_datetime:

   pusha
   push ds

   ; 年
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
   ; 月
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
   ; 日
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
   ; 时
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
   ; 分
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
   ; 秒
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

   ; 打印时间 

   ;赋值显卡段地址
   mov bx,0xb800
   mov ds,bx;
   
   ; 初始化
   mov si,message_time_end-1

   ; 显示字符数
   mov cx,[cs:message_time_len]

   ; 初始定位在最后一行最后一列
   mov bx,25*80*2-1

 dsp_datetime_1:

   ;读取一个字符
   mov dl,[cs:si]

   ;修改显存内容
   mov byte [ds:bx-1],dl
   mov byte [ds:bx],00000111b

   ;从右向左赋值
   sub si,1
   sub bx,2

 loop dsp_datetime_1; 循环显示

   pop ds
   popa

ret;

;------------------------------------------------------------------
; 关机动画，上下边逐渐刷到中间
; 输入输出参数: 无
power_off_display:

   pusha
   push ds

   ;赋值显卡段地址
   mov ax,0xb800
   mov ds,ax;
   
   ; 循环12次
   mov cx,12

 power_off_1:
   push cx
   ;---------------------------------
   ; 上边的行号
   mov ax,12
   sub ax,cx  ; ax=12-cx
   ; 计算行首地址放在ax中
   mov bx,80*2
   mul bx ; ax=ax*bx
   mov bx,ax
   ; 上边全行刷新
   mov cx,80
   power_off_2:
      mov byte [ds:bx],' '
      mov byte [ds:bx+1],00000000b
      add bx,2
   loop power_off_2
   ;---------------------------------
   ; 下边的行号
   pop cx
   push cx
   ; 12+cx得到下边的行号
   mov ax,12
   add ax,cx ;ax=12+cx
   ; 计算行首地址放在ax中
   mov bx,80*2
   mul bx ; ax=ax*bx
   mov bx,ax
   ; 上边全行刷新
   mov cx,80
   power_off_3:
      mov byte [ds:bx],' '
      mov byte [ds:bx+1],00000000b
      add bx,2
   loop power_off_3
   ;---------------------------------
   ; 等待
   call power_off_diskplay_sleep
   pop cx
 loop power_off_1
 ;---------------------------------
 ; 中间一行
   mov bx,12*80*2
   mov cx,80
 power_off_4:
   mov byte [ds:bx],' '
   mov byte [ds:bx+1],00000000b
   add bx,2
 loop power_off_4
   call power_off_diskplay_sleep
   
   pop ds
   popa

ret

;------------------------------------------------------------------
; 暂停一段时间
; 输入输出参数: 无
power_off_diskplay_sleep:
 pusha
  mov cx,3000
 power_off_diskplay_sleep_1:
  pusha
  mov cx,1000
  power_off_diskplay_sleep_2:
   pusha
   popa
  loop power_off_diskplay_sleep_2
  popa
 loop power_off_diskplay_sleep_1
 popa
ret


;--------------------------------------------------------------------------------
;OS/3图片对应的位置，在24*80范围内从上到下从左到右定位
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
;年月日时分秒(预留19个字节空间)
message_time: db '20XX-XX-XX XX:XX:XX'
message_time_end:
message_time_len: dw ($-message_time)


