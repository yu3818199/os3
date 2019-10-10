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
; 内存管理函数                                                           ;
;                                                                        ;
; 主要功能：内存更新、复制、比较等功能                                   ;
; 作    者: yuqiancheng                                                  ;
; 编写日期: 2019/10/01                                                   ;
;                                                                        ;
;------------------------------------------------------------------------;

;------------------------------------------------------------------
; 批量更新内存
; 输入参数: si-内存首地址，cx-长度 dl-填充值
; 输出参数: 无
_memset:
 pusha
 _memset_1:
  mov bx,cx
  mov [cs:si+bx-1],dl
 loop _memset_1
 popa
ret

;------------------------------------------------------------------
; 批量复制内存
; 输入参数: si-源地址，di-目标地址 ,cx -长度
; 输出参数: 无
_memcpy:
 pusha
  mov ax,cs
  mov ds,ax
  mov es,ax
  rep movsb
 popa
ret

;------------------------------------------------------------------
; 内存比较
; 输入参数: si-内存首地址1，di-内存首地址2，cx-比较长度
; 输出参数: ax 0-相同 1-不相同
_memcmp:
  pusha

 ; 比较
 _memcmp_1:
  mov bx,cx
  mov ah,[cs:si+bx-1]
  mov al,[cs:di+bx-1]
  cmp ah,al
  jne _mem_jne
 loop _memcmp_1

 ;相同
  popa
  mov ax,0
  ret

 ;不同
 _mem_jne:
  popa
  mov ax,1

ret

;------------------------------------------------------------------
; 字符串长度
; 输入参数: cs:si-首地址
; 输出参数: ax-长度
_strlen:
 push bx
 mov bx,0
 _strlen_1:
  mov al,[cs:si+bx]
  cmp al,0
  jz _strlen_end
  inc bx
  jmp _strlen_1
 _strlen_end:
 mov ax,bx
 pop bx
ret