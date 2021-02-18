;; NTT+ DEFINES
%define INTERVAL 0xF1
%define TRUE_INTERVAL (INTERVAL - 0x4)
%define JUMP_DIST (0xC000)
%define TOP_TRAP_DIST 0x11
%define BOTTOM_TRAP_DIST 0x3B
%define TRAP_VAL TRUE_INTERVAL
%define INIT_SI (0x2 + TOP_TRAP_DIST + (@main_loop_end - @main_loop) + BOTTOM_TRAP_DIST)
%define BOMB_VAL 0xA593
%define DIST_CALC (0xA2 + 0x4*0x4 -((@main_loop_end - @copy) + BOTTOM_TRAP_DIST))
%define SAFETY_GAP 0x10
%define DX_OFFSET (0x2-0x11)
%define CL_PART1 0x13
%define CL_PART2 ((@copy_end - @copy)/0x2 - CL_PART1)
%define SI_PART1 (CL_PART1*0x2)
;;
;; ZOMBIE DEFINES
%define ZOMB_WRITE_DIST 0x6C
%define ZOMB_SEG_DIFF 0x4
%define ZOMB_INT_87_AX 0x86D7
%define ZOMB_INT_87_DX 0xD7C4
%define CALL_DI_SHL_BYTE 0xFFE2
%define CALL_DI_SHL_WORD 0xF8E2
%define CALL_DI_LOOP_BYTE 0x46
%define CALL_DI_LOOP_WORD 0x8346

;;
;; GENRAL DEFINES
%define CALL_AMOUNT 0x84
%define CALL_DIST (0x4 * CALL_AMOUNT)
%define CF_JUMP_DIST 0xC600
%define ROWS_GAP 0x1
%define ZOMBIE_COUNTER 0x80

%define AX_XLATB 0x86D7
%define ARENA_SEG 0x1000

%define SHARE_LOC 0xE129
%define SHARE_LOC_1 0x8701
%define SHARE_LOC_2 0x8801

%define INT_87_AX 0xCCCC
%define INT_87_DX 0x29CC
%define INT_86_DX 0xD7E0
;;


mov [SHARE_LOC],ax
jmp @our_start

@top_decoy:
nop
xlatb
xchg ah,al
xlatb
nop
xlatb
xchg ah,al
xlatb
nop
xlatb
xchg ah,al
xlatb
xlatb
xchg ah,al
xlatb
xlatb
xchg ah,al
xlatb

@div_offset:
db 0xF
db 0x0
@ax_les_offset:
dw AX_XLATB
dw ARENA_SEG

@zombie_start:
mov di,[CALL_DI_SHL_WORD]
int 0x86
mov di,[CALL_DI_LOOP_WORD]
int 0x86

mov ax,ZOMB_INT_87_AX
xchg cx,si
std
mov dx,ZOMB_INT_87_DX
int 0x87
cld

lea ax,[si - @zombie_start + ZOMB_SEG_DIFF]

dw 0xD233 ; xor dx,dx
div word [si - @zombie_start + @div_offset]
add dx,0xFF6

add si,(@cf_copy - 0x1 - @zombie_start)

@zomb_wait:
xchg ch,[si]

cmp ch,0x1
jnz @zomb_wait

xchg ch,[si]
inc si
dw 0xEA8B ; mov bp,dx
mov cl,(@cf_copy_end - @cf_copy)/0x2-0x1
push ss
clc
rcr bp,cl
pop es
dw 0xFF33 ; xor di,di

rep movsw
movsw

lea bx,[bp + CALL_DIST + 0x1]

add byte [si - @cf_copy_end + @add_jd + 0x3],(ROWS_GAP + 0x3)
@add_jd:
lea ax,[si + 0x7000 - @cf_copy_end]
push ss
mov al,0xA2
pop ds

mov [bx],ax

push cs
xchg [bx+0x2],dx

pop es
push cs

dw 0xC38B ; mov ax,bx
pop ss

lea bp,[si - @cf_copy_end] ;dw 0xEE8B ; mov bp,si
and bp,0x7
mov dh,[si+bp]

mov cl,(@cf_loop_end - @cf_loop)/0x2
dw 0xF633 ; xor si,si
add [si + @cf_loop_end - @cf_copy + 0x1],dh
les di,[bx+si]
mov bp,0x8000+ZOMBIE_COUNTER
dec di

lea sp,[di+bx]
mov word [bx + (@cf_loop_end - @cf_copy)],(CALL_DIST)
add byte [bx + (@cf_loop_end - @cf_copy) + 0x1],dh

movsw
movsw

mov byte [bx+si],0x2
sub di,[bx+si]

call far [bx]

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
@our_start:
mov bx,ss
or bx,0x10
add bx,0x14
xchg si,ax

les ax,[si + @ax_les_offset]
mov dx,INT_86_DX
lea di,[si - 0x100]
int 0x86
add di,@end
int 0x86

add si,(@copy_end - SI_PART1)
lea di,[si + SI_PART1 - @copy_end + @zombie_loop]
mov [si + SI_PART1 - @copy_end + @add_xchg + 0x2],di
mov [si + SI_PART1 - @copy_end + @reset_xchg + 0x2],di

; push bx ; push ax
mov di,INIT_SI + @copy_end - @copy - SI_PART1
push si ; for end

lea dx,[si - @copy_end + JUMP_DIST]
mov es,bx ; mov es,ax

mov cl,CL_PART1

mov dl,((DIST_CALC - SAFETY_GAP)%(0x100)) + DX_OFFSET - 0x10
rep movsw


;; zombie section
mov cl,0x4
dw 0xEF8B ; mov bp,di
lea bx,[si - @copy_end + @zombie_start]
mov [si - @copy_end + @write_ah + 0x3],bh
mov [si - @copy_end + @write_al + 0x4],bl
dw 0xF633 ; xor si,si
add dx,[SHARE_LOC_1]
push dx ; for end
xchg bx,[SHARE_LOC_2]

@bomb_again:
mov [0xC501],al
mov [0xC701],al
mov [0xC401],al
mov [0xC101],al
mov [0xC201],al
mov [0xC301],al

@xchg:
xchg sp,[di + 0x8200 - 0xBA]
xchg dx,[di + 0x8400 - 0xBA]
xchg si,[di + 0x8600 - 0xBA]
xchg ax,[di + 0x8800 - 0xBA]

@zombie_loop:
xchg ax,ax
xlatb
xchg ah,al
xlatb
dw 0xE032 ; xor ah,al
xchg di,ax
@write_ah:
mov word [di + ZOMB_WRITE_DIST + 0x2],0xFFCC
@write_al:
mov word [di + ZOMB_WRITE_DIST],0xCCB9
@add_xchg:
add byte [0xCCCC],0x2
loop @zombie_loop

@reset_xchg:
mov byte [0xCCCC],0x90

inc bp
mov cl,0x4
dw 0xFD8B ; mov di,bp

mov sp,0x7FC ; for end

jp @bomb_again


;; zombie section end

pop bx ; for end
mov cl,CL_PART2
pop si ; for end

push es
mov di,INIT_SI
push cs
add si,SI_PART1 - @copy_end + @copy
rep movsw

pop es

add bx,(@main_loop - @copy - TOP_TRAP_DIST - 0x2)
pop ds
mov si,(INIT_SI + @reset_main_loop - @copy - 0x2)

mov [si + @main_loop_end - @reset_main_loop + 0x8 + 0x2],ds
push cs

mov cl,((@main_loop_end - @reset_main_loop)/0x2)


mov ax,INT_87_AX
pop ss

mov dx,INT_87_DX
lea sp,[bx + INIT_SI + 0x2]
int 0x87

mov ax,BOMB_VAL
lea dx,[bx-(@main_loop - @copy - TOP_TRAP_DIST - 0x2)]
lea di,[bx + 0x2 + TOP_TRAP_DIST - (@reset_main_loop_end - @reset_main_loop) - 0x2]

dw 0xEF8B ; mov bp,di
movsw
jmp bp

cwd

@copy:
@traps_loader:
movsw
movsw
mov cx,(@traps_loop_end - @traps_loop)/0x2
movsw
rep movsw

@traps_loop:
lea sp,[bx + INIT_SI - 0x3]
mov cx,0x504
dw 0xDF8B ; mov bx,di

@anti_loop:
pop di
pop bp
shl bp,cl
mov word [bp+di-0x2],ax
add sp,(-0x3)
dec ch
jnz @anti_loop
mov di,bx
rep movsw
@traps_loop_end:

@reset_main_loop_loader:
mov cl,(@main_loop_end - @reset_main_loop)/0x2 - 0x2
rep movsw

@reset_main_loop:
add di,BOTTOM_TRAP_DIST
movsw
sub di,(INIT_SI + 0x2)
dw 0xDF8B ; mov bx,di
movsw
mov cx,[si+0x4]
lds si,[si]
add dh,(JUMP_DIST/0x100)
@reset_main_loop_end:

@main_loop:
pop di
pop bp
add sp,[bx]
shl bp,cl
mov word [bp+di-0x2],ax
mov bp,[bx]
cmp [bx+si],bp
jz @main_loop
mov ds,cx
dw 0xFA8B ; mov di,dx
movsw
jmp dx
@main_loop_end:
dw TRAP_VAL
dw TRAP_VAL
dw INIT_SI
dw 0x1000
@copy_end:
db 0x1
@cf_copy:
@call_far:
db 0x66
call far [bx]
db 0x68

@cf_loader:
movsb
movsw
rep movsw
@cf_loop:
mov cl,(@cf_loop_end - @cf_loop)/0x2
add di,[si]
add sp,[bx+si]
dw 0xF633 ; xor si,si
add [bx+si],dx
movsw
movsw
sub di,[bx+si]
dec bp
db 0x78
call far [bx]
@cf_loop_end:
dw (-(@cf_loop_end - @cf_loader) - 0x2)
@cf_copy_end:

@jds:
db 0x27
db 0x4B
db 0x52
db 0x5E
db 0xC6
db 0xD3
db 0xEE
db 0x52

@bottom_decoy:
nop
xlatb
xchg ah,al
xlatb
xlatb
xchg ah,al
xlatb
xlatb
xchg ah,al
xlatb
xlatb
xchg ah,al
xlatb

@end: