
;; Anti Callfar K12 - Best So Far
;; plus traps (jumps if about to be run over)
;; uses dx instead of cx as nextjumpPlace (so that it doesn't have to end with 4)
;; does anti on traps

%define interval 0xf1
%define jumpDist 0x4000
%define upper_trap_dist 0x12
%define bottom_trap_dist 0x34

%define trueJumpDist jumpDist-@anti_loop-@anti_traps_loader
%define initialSi 0x2+upper_trap_dist + (@anti_loop_end-@anti_loop) + bottom_trap_dist
%define trueInterval interval-0x4
%define TRAP trueInterval ;; make sure it isn't a common opcode or part of callfar location

mov bx,TRAP
xchg ax,bx ;; ax = TRAP, bx = loc

push ss
pop es ;; es = StackSeg
lea si,[bx+@anti_traps_loader]
mov di,initialSi
mov cl,(@anti_loop_end-@anti_traps_loader)/2
rep movsw ;; copy code to StackSeg

stosw
stosw ;; bomb 2 traps in StackSeg

mov byte [bp+di],initialSi ;; for lds si,[si]  
mov word [bp+di+0x2],cs    ;; (after all the copying)

mov ax,ss ;; ax = StackSeg
push cs
push ds
pop es ;; es = Arena 
pop ss ;; ss = Arena

;; prepare sp,dx and cl
lea sp,[bx+jumpDist]
lea dx,[bx+jumpDist] ;; dx = jmpLoc
mov cl, 0x64 ;; illegal opcode

;; prepare bx and si
lea bx,[si-(@anti_loop_end-@anti_loop)-upper_trap_dist-0x2]
mov si, initialSi+(@anti_traps_end-@anti_traps_loader)

;; jmp to jmpLoc
mov bp,dx
add bp,(@anti_traps_end-@anti_traps_loader)
mov di,bp
mov ds,ax
movsw
jmp bp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

@anti_traps_loader:
movsw
movsw
mov cl,(@anti_traps_end-@anti_traps_start)/2
movsw
rep movsw
@anti_traps_start:
lea sp,[bx+initialSi-0x3]
mov bx,di
mov cx,0x0564
@loop:
pop di
pop bp
shl bp,cl
mov [bp+di-0x2],cx
sub sp,0x3
dec ch
jnz @loop
mov di,bx
movsw
@anti_traps_end:

@reset_loader:
movsw
mov cl,(@anti_loop_end-@reset_start)/2
movsw
movsw
rep movsw
@reset_start:

add di,bottom_trap_dist
movsw ;; bomb bottom trap
sub di,initialSi+0x2
mov bx,di ;; prepare bx
movsw ;; bomb top trap
lds si,[si] ;; ds = Arena, si = initialSi
add dh,jumpDist/0x100
mov cl,0x64
@reset_end:

@anti_loop:
pop di ;; di = ip
pop bp ;; bp = seg
shl bp,cl ;; bp = 0x10*seg
mov [bp+di-0x2],cx ;; bomb 0x10*seg+ip-2
add sp,[bx] 
mov di,[bx] ;; [bx] = bottom trap
cmp di,[bx+si] ;; [bx+si] = upper trap
jz @anti_loop
mov di,dx ;; dx = nextjumpPlace
mov ds,ax ;; ax = StackSeg
movsw
jmp dx
@anti_loop_end:

