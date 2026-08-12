
Initialize     = $800
JoyUpdate      = $803
Random         = $806
DrawChar       = $809
DrawStr        = $80c
DrawPoint      = $80f
DrawRect       = $812
DrawBlock      = $815
DrawDither     = $818
DrawHLine      = $81b
PlaySnd        = $81e
ReadFile       = $821
WriteFile      = $824
Bye            = $827
DrawCharX      = $82a

LO          = $26
HI          = $27

* SCANLINE_TBL.S

* ScanlineTblHI = $840
* ScanlineTblLO = $900

* XPOS_TABLES.S

* XPosByte    = $a00
* XPosShift   = $b00

* FontBase    = $c00

* Core graphics interface
gr_idx      = $f9
gr_xpos     = $fa
gr_ypos     = $fb
gr_addr_lo  = $fc
gr_addr_hi  = $fd
gr_width    = $fe
gr_height   = $ff
gr_LastYPos = $eb
gr_scaling  = $ed
GR_PTMP     = $ec

GR_SCALE_X  = 1
GR_SCALE_Y  = 2
GR_SCALE_XY = 3

* TODO: move these???
ff_color    =  $08
ff_xpos     =  $06
ff_ypos     =  $07
ff_dir2     =  $ff
ff_dir1     =  $fe
ff_stack    =  $fd

* I/O reuses the gr_ interface
io_src_addr_hi  = $f9
io_src_count_hi = $fa
io_tgt_addr_hi  = $fb

* Joystick state (0,1,2) "low","center","high"
* call JoyUpdate to update the values
joy_x       = $ee
joy_y       = $ef

tmp0        = $08
tmp1        = $09

* ProDOS entry point
MLI            equ $bf00
* MLI functions
MLI_GETPREFIX  equ $2b
MLI_SETPREFIX  equ $2c
MLI_OPENFILE   equ $c8
MLI_READFILE   equ $ca
MLI_WRITEFILE  equ $cb
MLI_SETMARK    equ $ce
MLI_CLOSEFILE  equ $cc
MLI_CREATEFILE equ $c0
MLI_BYE        equ $65

* Soft switches and i/o ports
KBD         equ   $c000      ;R last key pressed + 128
KBDSTRB     equ   $c010      ;RW keyboard strobe
SPKR        equ   $c030      ;RW toggle speaker
TXTCLR      equ   $c050      ;RW display graphics
MIXCLR      equ   $c052      ;RW display full screen
MIXSET      equ   $c053      ;RW display split screen
TXTPAGE1    equ   $c054      ;RW display page 1
HIRES       equ   $c057      ;RW display hi-res graphics
BUTN0       equ   $c061      ;R switch input 0 / open-apple
BUTN1       equ   $c062      ;R switch input 1 / closed-apple
PADDL0      equ   $C064      ; Read paddle 0 soft switch
PADDL1      equ   $C065      ; Read paddle 1 soft switch
PTRIG       equ   $C070      ; Trigger (start) paddle measurement

* monitor entry points
MONITOR     equ   $FF69
HGR         equ   $F3E2
HGR_CLEAR   equ   $f3e2
HPLOT0      equ   $f457
HCOLOR      equ   $f6ec
SETHCOLOR   equ   $f6f0
MON_WAIT    equ   $fca8      ;delay for (26 + 27*Acc + 5*(Acc*Acc))/2 cycles
