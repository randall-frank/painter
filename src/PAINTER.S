
         dsk   ../bin/PAINTER#066000
         typ   $06
         
         put   COMMON.S         

FLG_NO_FILL     equ   $01
FLG_COLLIDE     equ   $02
FLG_NO_GREMLINS equ   $80

KEY_RETURN      equ   $8d
KEY_CTRL_S      equ   $93
KEY_CTRL_B      equ   $82
KEY_ESC         equ   $9b
KEY_SPACE       equ   $a0
KEY_BANG        equ   $a1

FF_STACK_SIZE   equ   $d8   

TMP0            equ   $00
TMP1            equ   $01
CROSS_X         equ   $02
CROSS_Y         equ   $03
MON_CH          equ   $24        ;cursor horizontal displacement
MON_CV          equ   $25        ;cursor vertical displacement
GR_LOW          equ   $26
GR_HIGH         equ   $27
MON_COLOR       equ   $30        ;lo-res graphics color
HGR_PAGE        equ   $e6


         org   $6000

* 8 bytes/highscore, 10 highscores
* 3 bytes score (two nibble digits/byte), 3 bytes Initials

HIGHSCORES
         asc   "PAINTER1"          ; unused
         asc   $00, $00, $00, "AAAXX"
         asc   $00, $00, $00, "AAAXX"
         asc   $00, $00, $00, "AAAXX"
         asc   $00, $00, $00, "AAAXX"
         asc   $00, $00, $00, "AAAXX"
         asc   $00, $00, $00, "AAAXX"
         asc   $00, $00, $00, "AAAXX"
         asc   $00, $00, $00, "AAAXX"
         asc   $00, $00, $00, "AAAXX"
         asc   $00, $00, $00, "AAAXX"
         ds    \

GAME_SETUP
         jsr   Initialize
         jsr   HGR_CLEAR  
         lda   MIXCLR     
         jsr   LoadHiscores  
         jmp   TITLEPAGE  

LoadHiscores
         lda    #$00
         sta    io_src_addr_hi ; seek
         lda    #$01      ; one page
         sta    io_src_count_hi
         lda    #>HIGHSCORES
         sta    io_tgt_addr_hi
         jmp    ReadFile

SaveHiscores
         lda    #$00
         sta    io_tgt_addr_hi ; seek
         lda    #$01      ; one page
         sta    io_src_count_hi
         lda    #>HIGHSCORES
         sta    io_src_addr_hi
         jmp    WriteFile

DRAW_COPY
         lda   #23
         sta   MON_CV  
         jsr   MON_VTAB 
         lda   #1
         sta   MON_CH
         ldy   #0
:loop    lda   TXT_COPY,Y
         beq   :done
         jsr   MON_COUT
         iny
         jmp   :loop
:done    ldy   #0
:loop2   lda   version,Y
         jsr   MON_COUT
         iny
         cpy   #5
         bne   :loop2
         lda   #')'
         jsr   MON_COUT
         rts

TXT_COPY
         asc   "Copyright ", $13, " 1984 Randy Frank (v", $00

         put   VERSION.S

MON_COUTX
         sta   gr_idx
         lda   #GR_SCALE_X
         sta   gr_scaling
         jmp   :DrawCharX

MON_COUTXY
         sta   gr_idx
         lda   #GR_SCALE_XY
         sta   gr_scaling
:DrawCharX         
         lda   MON_CH     ; HPOS
         inc   MON_CH     ; bump HPOS by 2
         inc   MON_CH  
         sta   gr_xpos
         tya              ; protect x and y
         pha
         txa
         pha
         jsr   DrawCharX
         pla
         tax
         pla
         tay
         rts        

MON_COUT
         sta   gr_idx     ; The char to render
         lda   MON_CH     ; HPOS
         inc   MON_CH     ; bump HPOS
         sta   gr_xpos
         tya              ; protect x and y
         pha
         txa
         pha
         jsr   DrawChar
         pla
         tax
         pla
         tay
         rts

MON_VTAB
         lda   MON_CV     ; VTAB*8 -> pixel Y
         asl
         asl
         asl
         sta   gr_ypos
         rts   

CHECK_HS lda   #>HIGHSCORES ;2
         sta   TMP1       ;3
         lda   #$01       ;2
         sta   WHICH_SCORE ;4
COMPARE  jsr   COMPARE_SCORE ;6
         beq   NEXT_SCORE ;2+
         jmp   NEW_HIGHSCORE ;3

NEXT_SCORE
         inc   WHICH_SCORE ;6
         lda   WHICH_SCORE ;4
         cmp   #$0b       ;2
         bne   COMPARE    ;2+
         jmp   DISP_HISCORES ;3

COMPARE_SCORE
         lda   WHICH_SCORE ;4  Comp current vs 'which'.  return ACC=1 if current is higher 
         asl   A          ;2
         asl   A          ;2
         asl   A          ;2
         sta   TMP0       ;3
         ldy   #$00       ;2
:L6128   lda   (TMP0),y   ;5+
         cmp   CURRENT_SCORE_HI,y ;4+
         bcc   LARGER     ;2+ BLT   ACC<MEM  WHICH_SCORE<CURRENT_SCORE
         bne   SMALLER    ;2+
         iny              ;2
         cpy   #$03       ;2
         bne   :L6128     ;2+
SMALLER  lda   #$00       ;2
         rts              ;6

LARGER   lda   #$01       ;2
         rts              ;6

INSERT_POINT
         dfb   $00
WHICH_SCORE
         dfb   $00

INSERT_HISCORE
         lda   INSERT_POINT ;4
         asl   A          ;2
         asl   A          ;2
         asl   A          ;2
         sta   TMP0       ;3
         lda   #>HIGHSCORES ;2
         sta   CROSS_Y    ;3
         ldy   INSERT_POINT ;4
         iny              ;2
         tya              ;2
         asl   A          ;2
         asl   A          ;2
         asl   A          ;2
         sta   CROSS_X    ;3
         ldy   #$00       ;2
:L6156   lda   (TMP0),y   ;5+
         sta   (CROSS_X),y ;6
         iny              ;2
         cpy   #$06       ;2
         bne   :L6156     ;2+
         rts              ;6

NEW_HIGHSCORE
         lda   #$0a       ;2
         sta   INSERT_POINT ;4
STILL_MOVING
         jsr   INSERT_HISCORE ;6
         ldy   INSERT_POINT ;4
         cpy   WHICH_SCORE ;4
         beq   :L6176     ;2+
         dec   INSERT_POINT ;6
         jmp   STILL_MOVING ;3

:L6176   lda   WHICH_SCORE ;4
         asl   A          ;2
         asl   A          ;2
         asl   A          ;2
         sta   TMP0       ;3
         ldy   #$00       ;2
:L6180   lda   CURRENT_SCORE_HI,y ;4+
         sta   (TMP0),y   ;6
         iny              ;2
         cpy   #$03       ;2
         bne   :L6180     ;2+
         lda   #$a0       ;2  insert three spaces
         sta   (TMP0),y   ;6
         iny              ;2
         sta   (TMP0),y   ;6
         iny              ;2
         sta   (TMP0),y   ;6
         lda   TMP0       ;3
         pha              ;3
         lda   TMP1       ;3
         pha              ;3
         jsr   DISP_HISCORES ;6
         pla              ;4
         sta   TMP1       ;3
         pla              ;4
         sta   TMP0       ;3
         ldy   WHICH_SCORE ;4
         lda   HS_VTAB,y  ;4+
         sta   MON_CV     ;3
         jsr   MON_VTAB   ;6
         lda   HS_HTAB,y  ;4+
         clc              ;2
         adc   #$07       ;2
         sta   INITIALS_HPOS     
         lda   #$00       ;2
         sta   HS_NUMBER  ;4

* Prompt for 3 initials 
                          ; TODO: prompt for initials (include "RET" to end

INITIALS
         lda   HS_NUMBER  ;4
         clc              ;2
         adc   INITIALS_HPOS    
         sta   MON_CH     ;3
:key_loop 
         bit   KBD        ;4
         bpl   :key_loop  ;2+
         lda   KBD        ;4  Enter initials

         bit   KBDSTRB    ;4
         cmp   #KEY_RETURN ;2
         beq   :done       ;2+
         pha
         jsr   MON_COUT   ;6
         ldy   HS_NUMBER  ;4
         iny              ;2
         iny              ;2
         iny              ;2
         pla
         sta   (TMP0),y   ;6
         inc   HS_NUMBER  ;6
         lda   HS_NUMBER  ;4
         cmp   #$03       ;2
         bne   INITIALS   ;2+
         lda   #$00       ;2
         sta   HS_NUMBER  ;4
         jmp   INITIALS   ;3

:done    jsr   SaveHiscores
         rts              ;6

DISP_HISCORES
         lda   #$0a       ;2  10 highscores in two columns
         sta   HS_NUMBER  ;4
         sta   KBDSTRB    ;4
:L61FF   lda   HS_NUMBER  ;4
         jsr   DISP_1_HISCORE ;6
         dec   HS_NUMBER  ;6
         bne   :L61FF     ;3+
         rts              ;6

DISP_1_HISCORE
         tay              ;2
         lda   HS_VTAB,y  ;4+
         sta   MON_CV     ;3
         jsr   MON_VTAB   ;6
         lda   HS_HTAB,y  ;4+
         sta   MON_CH     ;3
         lda   #>HIGHSCORES ;2  Highscore table is at $6000
         sta   TMP1       ;3
         tya              ;2
         asl   A          ;2  Entry is 3 bytes score followed by 3 bytes initials
         asl   A          ;2
         asl   A          ;2
         sta   TMP0       ;3
         ldy   #$00       ;2
:L6225   lda   (TMP0),y   ;5+ Score is 3 bytes, for 6 nybble digits...
         pha              ;3
         lsr   A          ;2
         lsr   A          ;2
         lsr   A          ;2
         lsr   A          ;2
         ora   #$b0       ;2  High nybble
         jsr   MON_COUT   ;6
         pla              ;4
         and   #$0f       ;2  Low nybble
         ora   #$b0       ;2
         jsr   MON_COUT   ;6
         iny              ;2
         cpy   #$03       ;2
         bne   :L6225     ;2+
         lda   #$a0       ;2  Space
         jsr   MON_COUT   ;6
         lda   (TMP0),y   ;5+ Initials
         jsr   MON_COUT   ;6
         iny              ;2
         lda   (TMP0),y   ;5+
         jsr   MON_COUT   ;6
         iny              ;2
         lda   (TMP0),y   ;5+
         jsr   MON_COUT   ;6
         rts              ;6

HS_NUMBER
         dfb   $00
INITIALS_HPOS    dfb   $00
HS_VTAB  dfb   $00
         dfb   $0d        ;VTAB values for each high score
         dfb   $0f
         dfb   $11
         dfb   $13
         dfb   $15
         dfb   $0d
         dfb   $0f
         dfb   $11
         dfb   $13
         dfb   $15
HS_HTAB  dfb   $00
         ds    5,$06
         ds    5,$18

TITLEPAGE
         jsr   COPY_HGR2  ;6
         jsr   DISP_HISCORES ;6
DO_TITLE
                          ; jsr   DITHERNAME ;6   TODO
         ldy   #$ff       ;2  Wait awhile for 'start'  before redisplaying title
L6278    ldx   #$ff       ;2
CHECK_SPACE
         lda   KBD        ;4
         cmp   #KEY_SPACE ;2
         beq   BEGINGAME  ;2+
         lda   #$05       ;2
         jsr   MON_WAIT   ;6
         dex              ;2
         bne   CHECK_SPACE ;2+
         dey              ;2
         bne   L6278      ;2+
         jmp   TITLEPAGE  ;3

BEGINGAME
         jsr   PLAYAGAME  ;6
         jsr   COPY_HGR2  ;6  Game Over!
         jsr   CHECK_HS   ;6
         jmp   DO_TITLE   ;3

COPY_HGR2
         lda   #$40       ;2
         sta   TMP1       ;3
         lda   #$20       ;2
         sta   CROSS_Y    ;3
         lda   #$00       ;2
         sta   TMP0       ;3
         sta   CROSS_X    ;3
:L62A9   ldy   #$00       ;2
:L62AB   iny              ;2
         lda   (TMP0),y   ;5+
         sta   (CROSS_X),y ;6
         cpy   #$00       ;2
         bne   :L62AB     ;2+
         inc   TMP1       ;5
         inc   CROSS_Y    ;5
         lda   CROSS_Y    ;3
         cmp   #$40       ;2
         bne   :L62A9     ;2+
         jsr   DRAW_COPY
         rts              ;6

KEYCHECK 
         lda   KBD        ;4
         cmp   #KEY_CTRL_S ;2
         bne   :L7F3D     ;2+
         lda   INLINE_CLICK+1 ;4
         eor   #$30       ;2
         sta   INLINE_CLICK+1 ;4
         lda   KBDSTRB    ;4
:L7F3D   rts              ;6

         DS \
    
READ_JOYSTICK
         ldx   #$00       ;2
         stx   JOY_X      ;4
         stx   JOY_Y      ;4
         lda   PTRIG      ;4
:L800B   lda   PADDL0     ;4
         bpl   :L801F     ;2+
         stx   JOY_X      ;4
:L8013   lda   PADDL1     ;4
         bpl   :L8021     ;2+
         stx   JOY_Y      ;4
:L801B   inx              ;2
         bne   :L800B     ;2+
         rts              ;6

:L801F   bpl   :L8013     ;3

:L8021   bpl   :L801B     ;3

JOY_X    dfb   $00
JOY_Y    dfb   $00

UPDATE_FRAME
         jsr   READ_JOYSTICK ;6
         jsr   ERASE_CROSS ;6
         jsr   DRAW_ALL_GREMLINS ;6
         jsr   L819A      ;6
         ldy   #$04       ;2
:L8033   lda   GREMLIN_LIVE,y ;4+ Check collision with gremlins
         beq   :L8062     ;2+
         lda   GREMLIN_X,y ;4+
         clc              ;2
         adc   #$05       ;2
         cmp   CROSS_X    ;3
         bcc   :L8062     ;2+
         sec              ;2
         sbc   #$0a       ;2
         cmp   CROSS_X    ;3
         bcs   :L8062     ;2+
         lda   GREMLIN_Y,y ;4+
         clc              ;2
         adc   #$05       ;2
         cmp   CROSS_Y    ;3
         bcc   :L8062     ;2+
         sec              ;2
         sbc   #$0a       ;2
         cmp   CROSS_Y    ;3
         bcs   :L8062     ;2+
         lda   #FLG_COLLIDE ;2
         ora   FRAME_STATE ;4
         sta   FRAME_STATE ;4
:L8062   dey              ;2
         bne   :L8033     ;2+
         ldy   #$04       ;2
:L8067   lda   GREMLIN_LIVE,y ;4+
         bne   MOVE_CROSS ;2+
         dey              ;2
         bne   :L8067     ;2+
         lda   #FLG_NO_GREMLINS ;2
         ora   FRAME_STATE ;4
         sta   FRAME_STATE ;4
MOVE_CROSS
         lda   JOY_Y      ;4
         cmp   #$14       ;2
         bcs   :L8086     ;2+
         lda   #$00       ;2
         sta   JOY_Y      ;4
         jmp   :L8097     ;3

:L8086   cmp   #$50       ;2
         bcs   :L8092     ;2+
         lda   #$01       ;2
         sta   JOY_Y      ;4
         jmp   :L8097     ;3

:L8092   lda   #$02       ;2
         sta   JOY_Y      ;4
:L8097   lda   JOY_X      ;4
         cmp   #$14       ;2
         bcs   :L80A6     ;2+
         lda   #$00       ;2
         sta   JOY_X      ;4
         jmp   :L80B7     ;3

:L80A6   cmp   #$50       ;2
         bcs   :L80B2     ;2+
         lda   #$01       ;2
         sta   JOY_X      ;4
         jmp   :L80B7     ;3

:L80B2   lda   #$02       ;2
         sta   JOY_X      ;4
:L80B7   ldy   #$00       ;2
:L80B9   ldx   JOY_X      ;4
         beq   :L80C7     ;2+
         iny              ;2
         iny              ;2
         iny              ;2
         dec   JOY_X      ;6
         jmp   :L80B9     ;3

:L80C7   tya              ;2
         clc              ;2
         adc   JOY_Y      ;4
         tax              ;2
         lda   DELTA_X,x  ;4+
         clc              ;2
         adc   CROSS_X    ;3
         sta   CROSS_X    ;3
         lda   DELTA_Y,x  ;4+
         clc              ;2
         adc   CROSS_Y    ;3
         sta   CROSS_Y    ;3
         lda   CROSS_X    ;3
         cmp   #$00       ;2
         bne   :L80E7     ;2+
         lda   #$01       ;2
         sta   CROSS_X    ;3
:L80E7   cmp   #$86       ;2
         bne   :L80EF     ;2+
         lda   #$85       ;2
         sta   CROSS_X    ;3
:L80EF   lda   CROSS_Y    ;3
         cmp   #$13       ;2
         bne   :L80F9     ;2+
         lda   #$14       ;2
         sta   CROSS_Y    ;3
:L80F9   cmp   #$b5       ;2
         bne   :L8101     ;3+
         lda   #$b4       ;2
         sta   CROSS_Y    ;3
:L8101   jsr   MOVE_GREMLINS ;6
         jsr   DRAW_CROSS ;6
         rts              ;6

DELTA_X  dfb   $ff
         dfb   $ff
         dfb   $ff
         dfb   $00
         dfb   $00
         dfb   $00
         dfb   $01
         dfb   $01
         dfb   $01
DELTA_Y  dfb   $ff
         dfb   $00
         dfb   $01
         dfb   $ff
         dfb   $00
         dfb   $01
         dfb   $ff
         dfb   $00
         dfb   $01

DRAW_CROSS
         lda   CROSS_X    ;3
         sta   X_POS      ;4
         jsr   DIVIDE7    ;6
         lda   CROSS_Y    ;3
         jsr   GrScanline ;6
         txa              ;2
         asl   A          ;2
         asl   A          ;2
         asl   A          ;2
         asl   A          ;2
         asl   A          ;2
         sta   CROSS_FETCH+1 ;4
         sty   CROSS_INDEX ;4
         ldx   #$00       ;2
         lda   #$09       ;2
         sta   UTILITY_INDEX ;4
:L813A   ldy   CROSS_INDEX ;4
         jsr   CROSS_SCANLINE ;6
         jsr   GrNextScanline ;6
         dec   UTILITY_INDEX ;6
         bne   :L813A     ;2+
         rts              ;6

CROSS_SCANLINE
         lda   #$03       ;2
         sta   LINE_COUNT ;4
L814E    lda   (GR_LOW),y ;5+
         sta   CROSS_IMAGES+$e0,x ;5
CROSS_FETCH
         ora   CROSS_IMAGES,x ;4+
         sta   (GR_LOW),y ;6
         iny              ;2
         inx              ;2
         dec   LINE_COUNT ;6
         bne   L814E      ;2+
         rts              ;6

ERASE_CROSS
         lda   CROSS_X    ;3
         sta   X_POS      ;4
         jsr   DIVIDE7    ;6
         lda   CROSS_Y    ;3
         jsr   GrScanline ;6
         lda   #$09       ;2
         sta   UTILITY_INDEX ;4
         sty   CROSS_INDEX ;4
         ldx   #$00       ;2
:L8177   ldy   CROSS_INDEX ;4
         jsr   ERASE_CROSS_SCANLINE ;6
         jsr   GrNextScanline ;6
         dec   UTILITY_INDEX ;6
         bne   :L8177     ;2+
         rts              ;6

ERASE_CROSS_SCANLINE
         lda   #$03       ;2
         sta   LINE_COUNT ;4
:L818B   lda   CROSS_IMAGES+$e0,x ;4+
         sta   (GR_LOW),y ;6
         inx              ;2
         iny              ;2
         dec   LINE_COUNT ;6
         bne   :L818B     ;2+
         rts              ;6

UTILITY_INDEX
         dfb   $00
LINE_COUNT
         dfb   $00

L819A    lda   BUTN1      ;4
         asl   A          ;2
         bcc   L81F4      ;2+
         lda   CROSS_X    ;3
         sta   ff_xpos    ;4
         inc   ff_xpos    ;6
         inc   ff_xpos    ;6
         lda   CROSS_Y    ;3
         sta   ff_ypos    ;4
         inc   ff_ypos    ;6
         inc   ff_ypos    ;6
         inc   ff_ypos    ;6
         inc   ff_ypos    ;6

         ldx   FILL_COLOR_INDEX
         inx
         cpx   #4
         bne   :color_ok
         ldx   #0
:color_ok
         stx   FILL_COLOR_INDEX
         lda   FILL_COLOR_TABLE,x

         sta   ff_color   ;4
         jsr   FLOODFILL  ;6  
         lda   TMP0       ;3
         cmp   FILL_LOW   ;4
         bcc   :L81D4     ;2+
         bne   OUT_OF_FILL ;2+
         lda   TMP1       ;3
         cmp   FILL_HIGH  ;4
         bcs   OUT_OF_FILL ;2+
:L81D4   lda   FILL_HIGH  ;4
         sed              ;2
         sec              ;2
         sbc   TMP1       ;4
         sta   FILL_HIGH  ;4
         lda   FILL_LOW   ;4
         sbc   TMP0       ;4
         sta   FILL_LOW   ;4
         cld              ;2
         jsr   DISP_FILL_COUNT ;6
         rts              ;6

FILL_COLOR_INDEX
         dfb   0
FILL_COLOR_TABLE
         dfb   1,2,5,6

OUT_OF_FILL
         lda   #FLG_NO_FILL ;2
         ora   FRAME_STATE ;4
         sta   FRAME_STATE ;4
         rts              ;6

L81F4    lda   BUTN0      ;4
         asl   A          ;2
         bcs   PLOT_POINT ;2+
         rts              ;6

PLOT_POINT
         ldy   CROSS_Y    ;3
         iny              ;2
         iny              ;2
         iny              ;2
         iny              ;2
         tya              ;2
         jsr   GrScanline ;6
         ldy   CROSS_X    ;3
         iny              ;2
         iny              ;2
         sty   X_POS      ;4
         jsr   DIVIDE7    ;6
         lda   DOT_MASK0,x ;4+
         ora   (GR_LOW),y ;5+
         sta   (GR_LOW),y ;6
         iny              ;2
         lda   DOT_MASK1,x ;4+
         ora   (GR_LOW),y ;5+
         sta   (GR_LOW),y ;6
         rts              ;6

DOT_MASK0
         dfb   $07
         dfb   $0e
         dfb   $1c
         asc   '8p`@'
DOT_MASK1
         ds    5
         dfb   $01
         dfb   $03
GREMLIN_LIVE
         ds    5
GREMLIN_TICKS
         ds    5
GREMLIN_DIR
         ds    5
GREMLIN_X
         ds    5
GREMLIN_Y
         ds    5
G_TMP_X  dfb   $00
G_TMP_Y  dfb   $00
XDIR_TABLE
         dfb   $00
         dfb   $ff
         dfb   $00
         dfb   $01
YDIR_TABLE
         dfb   $ff
         dfb   $00
         dfb   $01
         dfb   $00

DRAW_ALL_GREMLINS
         lda   #$04       ;2
         sta   UTILITY_INDEX ;4
:L8255   ldy   UTILITY_INDEX ;4
         lda   GREMLIN_LIVE,y ;4+
         beq   :L8260     ;2+
         jsr   DRAW_GREMLIN ;6
:L8260   dec   UTILITY_INDEX ;6
         bne   :L8255     ;2+
         rts              ;6

MOVE_GREMLINS
         lda   #$04       ;2
         sta   UTILITY_INDEX ;4
NEXT_G_MOVE
         ldy   UTILITY_INDEX ;4
         lda   GREMLIN_LIVE,y ;4+
         beq   SKIP_REDRAW ;2+
         lda   GREMLIN_TICKS,y ;4+
         beq   NEW_G_MOVE_DIR ;2+
         ldx   UTILITY_INDEX ;4
         dec   GREMLIN_TICKS,x ;7+
         lda   GREMLIN_DIR,y ;4+
         tax              ;2
         jmp   DO_G_MOVE  ;3

NEW_G_MOVE_DIR
         jsr   Random 
         ldy   UTILITY_INDEX ;4
         pha
         and   #$03       ;2
         tax              ;2
         sta   GREMLIN_DIR,y ;5  pick a move direction
         pla
         and   #$0f       ;2
         sta   GREMLIN_TICKS,y ;5  schedule next move
DO_G_MOVE
         ldy   UTILITY_INDEX ;4
         lda   GREMLIN_X,y ;4+
         sta   G_TMP_X    ;4
         lda   GREMLIN_Y,y ;4+
         sta   G_TMP_Y    ;4
         lda   XDIR_TABLE,x ;4+
         clc              ;2
         adc   GREMLIN_X,y ;4+
         sta   GREMLIN_X,y ;5
         lda   YDIR_TABLE,x ;4+
         clc              ;2
         adc   GREMLIN_Y,y ;4+
         sta   GREMLIN_Y,y ;5
         jsr   GREMLIN_MASK_CHECK ;6
         lda   MASK_CHECK_FLAG ;4
         asl   A          ;2
         bcc   :L82D6     ;2+
         ldy   UTILITY_INDEX ;4
         lda   #$00       ;2
         sta   GREMLIN_LIVE,y ;5
         lda   #$50       ;2
         jsr   GREMLIN_DEAD ;6
         jmp   SKIP_REDRAW ;3

:L82D6   lsr   A          ;2
         cmp   #$01       ;2
         bne   :L82EA     ;2+
         ldy   UTILITY_INDEX ;4
         lda   G_TMP_X    ;4
         sta   GREMLIN_X,y ;5
         lda   G_TMP_Y    ;4
         sta   GREMLIN_Y,y ;5
:L82EA   jsr   DRAW_GREMLIN ;6
SKIP_REDRAW
         dec   UTILITY_INDEX ;6
         beq   G_MOVE_DONE ;2+
         jmp   NEXT_G_MOVE ;3

G_MOVE_DONE
         rts              ;6

DRAW_GREMLIN
         ldy   UTILITY_INDEX ;4
         lda   GREMLIN_Y,y ;4+
         jsr   GrScanline ;6
         lda   GREMLIN_X,y ;4+
         sta   X_POS      ;4
         jsr   DIVIDE7    ;6
         txa              ;2  32 byte/image (9 scanlines, 3 bytes/line)
         asl   A          ;2
         asl   A          ;2
         asl   A          ;2
         asl   A          ;2
         asl   A          ;2
         sta   SCANLINE_LOOP+1 ;4
         sty   CROSS_INDEX ;4
         ldx   #$00       ;2
         lda   #$0a       ;2  9 lines
         sta   LINE_COUNT ;4
:L831B   jsr   SCANLINE   ;6
         jsr   GrNextScanline ;6
         dec   LINE_COUNT ;6
         bne   :L831B     ;2+
         rts              ;6

SCANLINE ldy   CROSS_INDEX ;4
         lda   #$03       ;2
         sta   BYTE_COUNT_SCANLINE ;4
SCANLINE_LOOP
         lda   GREMLIN_IMAGES,x ;4+ Modified lower address
         eor   (GR_LOW),y ;5+
         sta   (GR_LOW),y ;6
         inx              ;2
         iny              ;2
         dec   BYTE_COUNT_SCANLINE ;6
         bne   SCANLINE_LOOP ;2+
         rts              ;6

GREMLIN_MASK_CHECK
         ldy   UTILITY_INDEX ;4
         lda   GREMLIN_Y,y ;4+
         jsr   GrScanline ;6
         lda   GREMLIN_X,y ;4+
         sta   X_POS      ;4
         jsr   DIVIDE7    ;6
         txa              ;2
         asl   A          ;2
         asl   A          ;2
         asl   A          ;2
         asl   A          ;2
         asl   A          ;2
         sta   NEXT_MASK_BYTE+1 ;4
         sty   CROSS_INDEX ;4
         lda   #$80       ;2
         sta   MASK_CHECK_FLAG ;4
         ldx   #$00       ;2
         lda   #$0a       ;2
         sta   LINE_COUNT ;4
MASK_LOOP
         jsr   MASK_SCANLINE ;6
         jsr   GrNextScanline ;6
         dec   LINE_COUNT ;6
         bne   MASK_LOOP  ;2+
         rts              ;6

MASK_SCANLINE
         ldy   CROSS_INDEX ;4
         lda   #$03       ;2
         sta   BYTE_COUNT_SCANLINE ;4
NEXT_MASK_BYTE
         lda   GREMLIN_MASKS,x ;4+
         and   (GR_LOW),y ;5+
         beq   :L838B     ;2+
         lda   #$01       ;2
         ora   MASK_CHECK_FLAG ;4
         sta   MASK_CHECK_FLAG ;4
:L838B   lda   (GR_LOW),y ;5+
         and   #$7f       ;2
         bne   :L8399     ;2+
         lda   MASK_CHECK_FLAG ;4
         and   #$7f       ;2
         sta   MASK_CHECK_FLAG ;4
:L8399   inx              ;2
         iny              ;2
         dec   BYTE_COUNT_SCANLINE ;6
         bne   NEXT_MASK_BYTE ;2+
         rts              ;6

MASK_CHECK_FLAG
         dfb   $00
BYTE_COUNT_SCANLINE
         dfb   $00

DRAW_BACKGROUND
         jsr   HGR_CLEAR  ;6
         lda   MIXCLR     ;4
         lda   #$10       ;2
         sta   UTILITY_INDEX ;4
         jsr   GrScanline ;6  Y in ACC
:L83B1   ldy   #$28       ;2  Draw the top white band
:L83B3   dey              ;2
         lda   #$7f       ;2
         sta   (GR_LOW),y ;6
         cpy   #$00       ;2
         bne   :L83B3     ;2+
         jsr   GrNextScanline ;6
         inc   UTILITY_INDEX ;6
         lda   UTILITY_INDEX ;4
         cmp   #$18       ;2
         bne   :L83B1     ;2+
         lda   #$b8       ;2
         sta   UTILITY_INDEX ;4
         jsr   GrScanline ;6
:L83D1   ldy   #$28       ;2  Draw the lower white band
:L83D3   dey              ;2
         lda   #$7f       ;2
         sta   (GR_LOW),y ;6
         cpy   #$00       ;2
         bne   :L83D3     ;2+
         jsr   GrNextScanline ;6
         inc   UTILITY_INDEX ;6
         lda   UTILITY_INDEX ;4
         cmp   #$c0       ;2
         bne   :L83D1     ;2+
         lda   #$18       ;2
         sta   UTILITY_INDEX ;4
         jsr   GrScanline ;6
:L83F1   ldy   #$00       ;2  Left bar
         lda   #$7f       ;2
         sta   (GR_LOW),y ;6
         ldy   #$27       ;2
         sta   (GR_LOW),y ;6  Right bar
         inc   UTILITY_INDEX ;6
         jsr   GrNextScanline ;6
         lda   UTILITY_INDEX ;4
         cmp   #$b8       ;2
         bne   :L83F1     ;3+
         lda   #$00       ;2  text at the top of the screen
         sta   MON_CH     ;3
         sta   MON_CV     ;3
         jsr   MON_VTAB   ;6
         ldy   #$00       ;2
:L8413   lda   TXT_SCORE,y ;4+
         jsr   MON_COUTXY ;6
         iny              ;2
         cpy   #$06       ;2
         bne   :L8413     ;2+
         lda   #$1f       ;2
         sta   MON_CH     ;3
         ldy   #$00       ;2
:L8424   lda   TXT_FILL,y ;4+
         jsr   MON_COUT   ;6
         iny              ;2
         cpy   #$09       ;2
         bne   :L8424     ;2+
         lda   #$00       ;2
         jsr   GREMLIN_DEAD ;6
         jsr   DISP_FILL_COUNT ;6
         ldy   NUMBER_LIVES ;4  Draw lives???
:L843A   beq   :L8453     ;2+
         sty   CROSS_X_POSITIONS ;4
         lda   CROSS_X_POSITIONS,y ;4+
         sta   CROSS_X    ;3  XPOS
         lda   CROSS_Y_POSITIONS,y ;4+
         sta   CROSS_Y    ;3  YPOS
         jsr   DRAW_CROSS ;6
         ldy   CROSS_X_POSITIONS ;4
         dey              ;2
         jmp   :L843A     ;3

:L8453   nop              ;2
         rts              ;6

CROSS_X_POSITIONS
         dfb   $00
         dfb   $5a
         dfb   $62
CROSS_Y_POSITIONS
         dfb   $00
         dfb   $03
         dfb   $03

GREMLIN_DEAD
         clc              ;2  increment score
         sed              ;2
         adc   CURRENT_SCORE_LOW ;5
         sta   CURRENT_SCORE_LOW ;4
         lda   CURRENT_SCORE_MID ;4
         adc   #$00       ;3
         sta   CURRENT_SCORE_MID ;4
         lda   CURRENT_SCORE_HI ;4
         adc   #$00       ;3
         sta   CURRENT_SCORE_HI ;4
         cld              ;2
         lda   #$0c       ;2
         sta   MON_CH     ;3
         lda   #$00       ;2
         sta   MON_CV     ;3
         jsr   MON_VTAB   ;6
         ldy   #$00       ;2
G_DEAD_SCORE_LOOP
         lda   CURRENT_SCORE_HI,y ;4+
         lsr   A          ;2
         lsr   A          ;2
         lsr   A          ;2
         lsr   A          ;2
         ora   #$b0       ;2
         jsr   MON_COUTXY ;6
         lda   CURRENT_SCORE_HI,y ;4+
         and   #$0f       ;2
         ora   #$b0       ;2
         jsr   MON_COUTXY ;6
         iny              ;2
         cpy   #$03       ;2
         bne   G_DEAD_SCORE_LOOP ;2+
         rts              ;6

DISP_FILL_COUNT
         lda   #$1f       ;2
         sta   MON_CH     ;3
         lda   #$01       ;2
         sta   MON_CV     ;3
         jsr   MON_VTAB   ;6
         ldy   #$00       ;2
DISP_FILL_LOOP
         lda   FILL_LOW,y ;4+ Draw fill count number
         lsr   A          ;2
         lsr   A          ;2
         lsr   A          ;2
         lsr   A          ;2
         ora   #$b0       ;2
         jsr   MON_COUTX  ;6
         lda   FILL_LOW,y ;4+
         and   #$0f       ;2
         ora   #$b0       ;2
         jsr   MON_COUTX  ;6
         iny              ;2
         cpy   #$02       ;2
         bne   DISP_FILL_LOOP ;2+
         rts              ;6

TXT_FILL
         asc   "Paint Lvl"
TXT_SCORE
         asc   "Score:"
CURRENT_SCORE_HI
         dfb   $00
CURRENT_SCORE_MID
         dfb   $00
CURRENT_SCORE_LOW
         dfb   $00
FILL_LOW dfb   $00
FILL_HIGH
         dfb   $00
NUMBER_LIVES
         dfb   $02
BOARD_NUMBER
         dfb   $00
LEVEL_NUMBER
         dfb   $00
FRAME_STATE
         dfb   $00        ;FLG_^
        
PLAYAGAME
         lda   #$02       ;2
         sta   NUMBER_LIVES ;4
         lda   #$00       ;2
         sta   CURRENT_SCORE_HI ;4
         sta   CURRENT_SCORE_HI+1 ;4
         sta   CURRENT_SCORE_HI+2 ;4
         lda   #$01       ;2
         sta   LEVEL_NUMBER ;4
         sta   BOARD_NUMBER ;4
NEXT_LIFE
         lda   LEVEL_NUMBER ;4
         sec              ;2
         sbc   #$01       ;2
         asl   A          ;2
         asl   A          ;2
         asl   A          ;2
         tay              ;2
         ldx   #$00       ;2
:L8624   lda   LEVEL_LIVE_GREMLIN_TABLE,y ;4+
         sta   GREMLIN_LIVE,x ;5
         iny              ;2
         inx              ;2
         cpx   #$05       ;2
         bne   :L8624     ;2+
         lda   LEVEL_LIVE_GREMLIN_TABLE,y ;4+
         sta   FILL_LOW   ;4
         iny              ;2
         lda   LEVEL_LIVE_GREMLIN_TABLE,y ;4+
         sta   FILL_HIGH  ;4
         iny              ;2
         lda   LEVEL_LIVE_GREMLIN_TABLE,y ;4+
         sta   SOUND_LENGTH ;4
         ldx   #$04       ;2
         stx   GENERIC_INDEX ;4
PLACE_GREMLIN
         ldx   GENERIC_INDEX ;4
         lda   GREMLIN_LIVE,x ;4+
         beq   :L8671     ;2+
         jsr   Random
         ldx   GENERIC_INDEX ;4
         and   #$60       ;2
         clc              ;2
         adc   #$14       ;2
         sta   GREMLIN_X,x ;5
         jsr   Random
         ldx   GENERIC_INDEX ;4
         and   #$70       ;2
         clc              ;2
         adc   #$32       ;2
         sta   GREMLIN_Y,x ;5
:L8671   dex              ;2
         stx   GENERIC_INDEX ;4
         cpx   #$00       ;2
         bne   PLACE_GREMLIN ;2+
         jsr   DRAW_BOARD ;6
         jsr   DISP_NEXTBOARD_TEXT ;6
         jsr   DRAW_BOARD ;6
         lda   #$00       ;2
         sta   FRAME_STATE ;4
FRAME_LOOP
         jsr   UPDATE_FRAME ;6
PAUSE_LOOP
         jsr   KEYCHECK   ;6
         cmp   #KEY_ESC   ;2
         beq   PAUSE_LOOP ;2+
         cmp   #KEY_BANG
         bne   :not_mon
         jsr   MONITOR
:not_mon cmp   #KEY_CTRL_B
         bne   :not_bye
         jmp   Bye
:not_bye 
         ldx   SOUND_LENGTH ;4  Number of loops for sound
NEXT_SOUND_COUNT
         ldy   SOUND_LOW  ;4  Get the delay for the current sound index
SOUND_FETCH
         lda   SOUND_TABLE,y ;4+ Starts at $8a00 and runs to $8cff
         tay              ;2
SHORT_DELAY
         dey              ;2
         bne   SHORT_DELAY ;2+ Tonal delay
INLINE_CLICK
         lda   SPKR       ;4
         dex              ;2
         bne   NEXT_SOUND_COUNT ;2+
         inc   SOUND_LOW  ;6
         bne   PING_DONE  ;2+
         ldy   SOUND_FETCH+2 ;4  Bump sound fetch hi byte
         iny              ;2
         cpy   #>SOUND_TABLE_END ;2
         bne   :L86B3     ;2+
         ldy   #>SOUND_TABLE ;2
:L86B3   sty   SOUND_FETCH+2 ;4
PING_DONE
         nop              ;2
         lda   FRAME_STATE ;4
         and   #FLG_NO_GREMLINS ;2
         cmp   #FLG_NO_GREMLINS ;2
         bne   STILL_PLAYING ;2+
         jmp   NEXT_BOARD ;3

STILL_PLAYING
         lda   FRAME_STATE ;4
         beq   FRAME_LOOP ;2+
         jsr   EXPLODE    ;6  We died
         dec   NUMBER_LIVES ;6
         lda   NUMBER_LIVES ;4
         cmp   #$ff       ;2
         beq   DISP_GAMEOVER ;2+
         jmp   NEXT_LIFE  ;3

DISP_GAMEOVER
         lda   #$0c       ;2
         sta   MON_CV     ;3
         jsr   MON_VTAB   ;6
         lda   #$0b       ;2
         sta   MON_CH     ;3
         ldy   #$00       ;2
:L86E5   lda   TXT_GAMEOVER,y ;4+
         jsr   MON_COUT   ;6
         iny              ;2
         cpy   #$09       ;2
         bne   :L86E5     ;2+
         ldx   #$20       ;2
:L86F2   lda   #$f0       ;2
         jsr   MON_WAIT   ;6
         dex              ;2
         bne   :L86F2     ;2+
         rts              ;6

TXT_GAMEOVER
         asc   "Game Over"

NEXT_BOARD
         jsr   L87A1      ;6
         ldy   BOARD_NUMBER ;4
         cpy   #$03       ;2  3 boards/level
         bne   :L8717     ;2+
         ldy   #$01       ;2
         sty   BOARD_NUMBER ;4
         jmp   NEXT_LEVEL ;3

:L8717   inc   BOARD_NUMBER ;6
         jmp   NEXT_LIFE  ;3

NEXT_LEVEL
         ldy   LEVEL_NUMBER ;4
         iny              ;2
         cpy   #$0a       ;2
         bne   :L8727     ;2+
         ldy   #$09       ;2  9 is the max level number
:L8727   sty   LEVEL_NUMBER ;4
         jmp   NEXT_LIFE  ;3

DRAW_BOARD
         jsr   DRAW_BACKGROUND ;6
         lda   #$20       ;2
         sta   CROSS_X    ;3
         sta   CROSS_Y    ;3
         jsr   MOVE_GREMLINS ;6
         jsr   DRAW_CROSS ;6
         rts              ;6

DISP_NEXTBOARD_TEXT
         lda   #$08       ;2
         sta   MON_CV     ;3
         jsr   MON_VTAB   ;6
         lda   #$0f       ;2
         sta   MON_CH     ;3
         ldy   #$00       ;2
:L874A   nop              ;2
         lda   TXT_READY,y ;4+ 'Ready?' text
         jsr   MON_COUT   ;6
         iny              ;2
         cpy   #$06       ;2
         bne   :L874A     ;2+
         lda   #$0a       ;2
         sta   MON_CV     ;3
         jsr   MON_VTAB   ;6
         lda   #$0f       ;2
         sta   MON_CH     ;3
         ldy   #$00       ;2
:L8763   lda   TXT_LEVEL,y ;4+ 'Level:'
         jsr   MON_COUT   ;6
         iny              ;2
         cpy   #$06       ;2
         bne   :L8763     ;2+
         lda   LEVEL_NUMBER ;4  Display the level number
         ora   #$b0       ;2
         jsr   MON_COUT   ;6
         lda   #$0c       ;2
         sta   MON_CV     ;3
         jsr   MON_VTAB   ;6
         lda   #$0f       ;2
         sta   MON_CH     ;3
         ldy   #$00       ;2
:L8783   lda   TXT_BOARD,y ;4+ 'Board:'
         jsr   MON_COUT   ;6
         iny              ;2
         cpy   #$06       ;2
         bne   :L8783     ;2+
         lda   BOARD_NUMBER ;4
         ora   #$b0       ;2
         jsr   MON_COUT   ;6
         ldx   #$20       ;2  Delay a bit...
:L8798   lda   #$f0       ;2
         jsr   MON_WAIT   ;6
         dex              ;2
         bne   :L8798     ;2+
         rts              ;6

L87A1    lda   FILL_HIGH  ;4
         and   #$e0       ;2
         sta   FILL_HIGH  ;4
         jsr   DISP_FILL_COUNT ;6
:L87AC   lda   FILL_LOW   ;4
         bne   :L87B7     ;2+
         lda   FILL_HIGH  ;4
         bne   :L87B7     ;2+
         rts              ;6

:L87B7   sed              ;2
         lda   FILL_HIGH  ;4
         sec              ;2
         sbc   #$20       ;3
         sta   FILL_HIGH  ;4
         lda   FILL_LOW   ;4
         sbc   #$00       ;3
         sta   FILL_LOW   ;4
         cld              ;2
         jsr   DISP_FILL_COUNT ;6
         lda   #$02       ;2
         jsr   GREMLIN_DEAD ;6
         lda   SPKR       ;4
         jmp   :L87AC     ;3

TXT_READY
         asc   "Ready?"
TXT_LEVEL
         asc   "Level:"
TXT_BOARD
         asc   "Board:"

LEVEL_LIVE_GREMLIN_TABLE
         hex   0001010000260020 ;8 bytes/level, 10 levels
         hex   0001010100260020 ;0 = unused
         hex   0001010101260020 ;1-4 = gremlin flags
         hex   0001010101200016 ;5-6 = fill lo,hi max for level
         hex   0001010101200010 ;7 = pace of sounds (lower=faster)
         hex   0001010101200010
         hex   0001010101180010
         hex   0001010101180008
         hex   0001010101150002

SOUND_LENGTH
         dfb   $00
GENERIC_INDEX
         dfb   $00
SOUND_LOW
         dfb   $00

EXPLODE  inc   CROSS_X    ;5
         inc   CROSS_X    ;5
         inc   CROSS_X    ;5
         inc   CROSS_Y    ;5
         inc   CROSS_Y    ;5
         inc   CROSS_Y    ;5
         inc   CROSS_Y    ;5
         inc   CROSS_Y    ;5
         lda   #$14       ;2
         sta   GENERIC_INDEX ;4
:L884B   nop              ;2
         lda   #$00       ;2
         sta   :L88F4     ;4
         lda   #$08       ;2
         sta   :L88F5     ;4
         jsr   :L889C     ;6
         jsr   :L888D     ;6
         lda   #$08       ;2
         sta   :L88F4     ;4
         lda   #$10       ;2
         sta   :L88F5     ;4
         jsr   :L889C     ;6
         jsr   :L888D     ;6
         lda   #$10       ;2
         sta   :L88F4     ;4
         lda   #$20       ;2
         sta   :L88F5     ;4
         jsr   :L889C     ;6
         jsr   :L888D     ;6
         dec   GENERIC_INDEX ;6
         bne   :L884B     ;2+
         lda   FRAME_STATE ;4
         cmp   #$01       ;2
         bne   :L888B     ;2+
         jsr   DISP_NO_FILL ;6
:L888B   nop              ;2
         rts              ;6

:L888D   ldx   #$20       ;2
:L888F   ldy   PTRIG      ;4
:L8892   dey              ;2
         bne   :L8892     ;2+
         lda   SPKR       ;4
         dex              ;2
         bne   :L888F     ;2+
         rts              ;6

:L889C   ldy   :L88F4     ;4
:L889F   lda   :L88F6,y   ;4+
         clc              ;2
         adc   CROSS_X    ;3
         clc              ;2
         cmp   #$89       ;2
         bcs   :L88BE     ;2+
         sta   :L88F2     ;4
         lda   :L8916,y   ;4+
         clc              ;2
         adc   CROSS_Y    ;3
         clc              ;2
         cmp   #$bb       ;2
         bcs   :L88BE     ;2+
         sta   :L88F3     ;4
         jsr   :L88CA     ;6
:L88BE   inc   :L88F4     ;6
         ldy   :L88F4     ;4
         cpy   :L88F5     ;4
         bne   :L889F     ;2+
         rts              ;6

:L88CA   lda   :L88F3     ;4
         jsr   GrScanline ;6
         lda   :L88F2     ;4
         sta   X_POS      ;4
         jsr   DIVIDE7    ;6
         lda   :L88EB,x   ;4+
         eor   (GR_LOW),y ;5+
         sta   (GR_LOW),y ;6
         jsr   GrNextScanline ;6
         lda   :L88EB,x   ;4+
         eor   (GR_LOW),y ;5+
         sta   (GR_LOW),y ;6
         rts              ;6

:L88EB   dfb   $01
         dfb   $02
         dfb   $04
         dfb   $08
         dfb   $10
         dfb   $20
         dfb   $40
:L88F2   dfb   $00
:L88F3   dfb   $00
:L88F4   dfb   $00
:L88F5   dfb   $00
:L88F6   dfb   $00
         dfb   $fc
         dfb   $fb
         dfb   $fc
         dfb   $00
         dfb   $04
         dfb   $05
         dfb   $04
         dfb   $00
         dfb   $f8
         dfb   $f6
         dfb   $f8
         dfb   $00
         dfb   $08
         dfb   $0a
         dfb   $08
         dfb   $00
         asc   "ztmlmtz"
         dfb   $00
         dfb   $06
         dfb   $0c
         dfb   $13
         dfb   $14
         dfb   $13
         dfb   $0c
         dfb   $06
:L8916   dfb   $fb
         dfb   $fc
         dfb   $00
         dfb   $04
         dfb   $05
         dfb   $04
         dfb   $00
         dfb   $fc
         dfb   $f6
         dfb   $f8
         dfb   $00
         dfb   $08
         dfb   $0a
         dfb   $08
         dfb   $00
         asc   "xlmtz"
         dfb   $00
         dfb   $06
         dfb   $0c
         dfb   $13
         dfb   $14
         dfb   $13
         dfb   $0c
         dfb   $06
         dfb   $00
         dfb   $fa
         dfb   $f4
         dfb   $ed

DISP_NO_FILL
         lda   #$0f       ;2
         sta   MON_CV     ;3
         jsr   MON_VTAB   ;6
         lda   #$09       ;2
         sta   MON_CH     ;3
         ldy   #$00       ;2
:L8943   lda   TXT_OUTOFFILL,y ;4+
         jsr   MON_COUT   ;6
         iny              ;2
         cpy   #$0c       ;2
         bne   :L8943     ;2+
         ldx   #$20       ;2
:L8950   lda   #$f0       ;2
         jsr   MON_WAIT   ;6
         dex              ;2
         bne   :L8950     ;2+
         rts              ;6

TXT_OUTOFFILL
         asc   "Out of Paint"

         ds    \
SOUND_TABLE
         hex   6464646464016464
         hex   6464640164646464
         hex   64014b4b4b4b4b4b
         hex   4b3c3c3c3c3c3c3c
         hex   3c3c3c3c3c3c3c64
         hex   6464646401646464
         hex   6464016464646464
         hex   014b4b4b4b4b4b4b
         hex   3c3c3c3c3c3c3c3c
         hex   3c3c3c3c3c3c4b4b
         hex   4b4b4b014b4b4b4b
         hex   4b01505050505001
         hex   5050505050015a5a
         hex   5a5a5a015a5a5a5a
         hex   5a01646464646464
         hex   6464646464640164
         hex   6464646401646464
         hex   6464016464646464
         hex   0150505050505050
         hex   4141414141414141
         hex   4141414141416464
         hex   6464640164646464
         hex   6401646464646401
         hex   5050505050505041
         hex   4141414141412f2f
         hex   2f2f2f2f2f2a2a2a
         hex   2a2a2a2a2f2f2f2f
         hex   2f2f2f3333333333
         hex   3333373737373737
         hex   3741414141414141
         hex   4b4b4b4b4b4b4b4b
         hex   4b4b4b4b4b4b4b4b
         hex   6464646464016464
         hex   6464640164646464
         hex   64014b4b4b4b4b4b
         hex   4b3c3c3c3c3c3c3c
         hex   3c3c3c3c3c3c3c64
         hex   6464646401646464
         hex   6464016464646464
         hex   014b4b4b4b4b4b4b
         hex   3c3c3c3c3c3c3c3c
         hex   3c3c3c3c3c3c4b4b
         hex   4b4b4b014b4b4b4b
         hex   4b01505050505001
         hex   5050505050015a5a
         hex   5a5a5a015a5a5a5a
         hex   5a01646464646464
         hex   6464646464640164
         hex   6464646401646464
         hex   6464016464646464
         hex   0150505050505050
         hex   4141414141414141
         hex   4141414141416464
         hex   6464640164646464
         hex   6401646464646401
         hex   5050505050505041
         hex   4141414141412f2f
         hex   2f2f2f2f2f2a2a2a
         hex   2a2a2a2a2f2f2f2f
         hex   2f2f2f3333333333
         hex   3333373737373737
         hex   3741414141414141
         hex   4b4b4b4b4b4b4b4b
         hex   4b4b4b4b4b4b4b4b
         hex   6464646464016464
         hex   6464640164646464
         hex   64014b4b4b4b4b4b
         hex   4b3c3c3c3c3c3c3c
         hex   3c3c3c3c3c3c3c64
         hex   6464646401646464
         hex   6464016464646464
         hex   014b4b4b4b4b4b4b
         hex   3c3c3c3c3c3c3c3c
         hex   3c3c3c3c3c3c4b4b
         hex   4b4b4b014b4b4b4b
         hex   4b01505050505001
         hex   5050505050015a5a
         hex   5a5a5a015a5a5a5a
         hex   5a01646464646464
         hex   6464646464640164
         hex   6464646401646464
         hex   6464016464646464
         hex   0150505050505050
         hex   4141414141414141
         hex   4141414141416464
         hex   6464640164646464
         hex   6401646464646401
         hex   5050505050505041
         hex   4141414141412f2f
         hex   2f2f2f2f2f2a2a2a
         hex   2a2a2a2a2f2f2f2f
         hex   2f2f2f3333333333
         hex   3333373737373737
         hex   3741414141414141
         hex   4b4b4b4b4b4b4b4b
         hex   4b4b4b4b4b4b4b4b
SOUND_TABLE_END
         DS    \
GREMLIN_MASKS
         hex   4601002800007c00
         hex   007f03007f03007f
         hex   03007f03007c0000
         hex   4400004703000408
         hex   0c03005000007801
         hex   007e07007e07007e
         hex   07007e0700780100
         hex   0801000e07000040
         hex   1806002001007003
         hex   007c0f007c0f007c
         hex   0f007c0f00700300
         hex   1002001c0e008a80
         hex   300c004002006007
         hex   00781f00781f0078
         hex   1f00781f00600700
         hex   200400381c008080
         hex   601800000500400f
         hex   00703f00703f0070
         hex   3f00703f00400f00
         hex   4008007038000020
         hex   403100000a00001f
         hex   00607f00607f0060
         hex   7f00607f00001f00
         hex   0011006071007000
         hex   006300001400003e
         hex   00407f01407f0140
         hex   7f01407f01003e00
         hex   0022004063010210
         hex   0000000000000000
         hex   0000080400040800
         hex   6211005212005e1e
         hex   0072130062110004
         DS    \
GREMLIN_IMAGES
         hex   4601002800005400001102005502007d02005502005400004400004502000408
         hex   0c03005000002801002204002a05007a05002a05002801000801000a05000040
         hex   180600200100500200440800540a00740b00540a00500200100200140a008a80
         hex   300c004002002005000811002815006817002815002005002004002814008080
         hex   601800000500400a00102200502a00502f00502a00400a004008005028000020
         hex   403100000a00001500204400205500205f002055000015000011002051007000
         hex   006300001400002a00400801402a01403e01402a01002a000022004022010210
         hex   000000000000000000000804000408006211005212005e1e0072130062110004
         DS    \
CROSS_IMAGES
         hex   0000004c01004c01004f07000000004f07004c01004c01000000000000000000
         hex   0000001803001803001e0f000000001e0f001803001803000000000000000000
         hex   0000003006003006003c1e000000003c1e003006003006000000000000000000
         hex   000000600c00600c00783c00000000783c00600c00600c000000000000000000
         hex   0000004019004019007079000000007079004019004019000000000000000000
         hex   0000000033000033006073010000006073010033000033000000000000000000
         hex   0000000066000066004067030000004067030066000066000066000000000000
         hex   552a55552a55552a55552a55552a5555ffff0000ffff0000ffff0000ffff0000


* X = $06, Y = $07, color = $08
FLOODFILL
         ldx   ff_color      ;4
         jsr   SETHCOLOR  ;6
         lda   #$00       ;2
         sta   TMP0       ;3
         sta   TMP1       ;3
         sta   ff_stack      ;4
         lda   #$01       ;2
         sta   ff_dir2      ;4
:L9014   jsr   L9166      ;6
         lda   L9320      ;4
         bne   :L9022     ;2+
         dec   ff_ypos      ;6
         jmp   :L9014     ;3

:L9022   lda   #$02       ;2
         sta   ff_dir2      ;4
         jsr   :L904D     ;6
:L902A   lda   ff_stack      ;4
         bne   FF_POPSTACK     ;2+
         rts              ;6

FF_POPSTACK
         dec   ff_stack      ;6
         ldy   ff_stack      ;4
         lda   FF_STACK_X,y    ;4+
         sta   ff_xpos      ;4
         lda   FF_STACK_Y,y    ;4+
         sta   ff_ypos      ;4
         lda   #$02       ;2
         sta   ff_dir2      ;4
         jsr   :L9050     ;6
         jmp   :L902A     ;3

:L904D   jsr   :L90F0     ;6
:L9050   lda   #$00       ;2
         sta   L9322      ;4
         lda   FRAME_STATE ;4
         beq   :L905B     ;2+
         rts              ;6

:L905B   dec   ff_dir2      ;6
         bne   :L9065     ;2+
         lda   #$04       ;2
         sta   ff_dir2      ;4
:L9065   jsr   L9166      ;6
         lda   L9320      ;4
         bne   :L9070     ;2+
         jmp   :L90C1     ;3

:L9070   inc   ff_dir2      ;6
         inc   L9322      ;6
         lda   ff_dir2      ;4
         cmp   #$05       ;2
         bne   :L9082     ;2+
         lda   #$01       ;2
         sta   ff_dir2      ;4
:L9082   lda   L9322      ;4
         cmp   #$05       ;2
         bne   :L9065     ;2+
         lda   #$01       ;2
         sta   ff_dir1      ;4
:L908E   jsr   L9150      ;6
         lda   L9320      ;4
         beq   FF_MOVE_POINT    ;2+
         inc   ff_dir1      ;6
         lda   ff_dir1      ;4
         cmp   #$05       ;2
         bne   :L90A1     ;2+
         rts              ;6

:L90A1   jmp   :L908E     ;3

FF_MOVE_POINT
         ldy   ff_dir1      ;4
         lda   ff_xpos      ;4
         clc              ;2
         adc   FF_XDIR_TAB,y    ;4+
         sta   ff_xpos      ;4
         lda   ff_ypos      ;4
         clc              ;2
         adc   FF_YDIR_TAB,y    ;4+
         sta   ff_ypos      ;4
         jsr   :L90F0     ;6
         jmp   :L9050     ;3

:L90C1   jsr   :L90F0     ;6
         lda   ff_xpos      ;4
         sta   L9324      ;4
         lda   ff_ypos      ;4
         sta   L9323      ;4
         ldy   ff_dir2      ;4
         lda   ff_xpos      ;4
         clc              ;2
         adc   FF_XDIR_ADD,y    ;4+
         sta   ff_xpos      ;4
         lda   ff_ypos      ;4
         clc              ;2
         adc   FF_YDIR_ADD,y    ;4+
         sta   ff_ypos      ;4
         jsr   :L90F0     ;6
         jsr   L91A8      ;6
         jmp   :L9050     ;3

:L90F0   ldy   #$00       ;2
         lda   ff_dir2      ;4
         pha              ;3
         lda   #$00       ;2
         sta   ff_dir2      ;4
         jsr   L9166      ;6
         pla              ;4
         sta   ff_dir2      ;4
         lda   L9320      ;4
         bne   :L910A     ;2+
         jsr   :L9134     ;6
:L910A   ldy   #$00       ;2
         lda   ff_xpos      ;4
         asl   A          ;2
         bcc   :L9114     ;2+
         ldy   #$01       ;2
:L9114   tax              ;2
         lda   ff_ypos      ;4
         jsr   $f411      ;6
         jsr   $f45a      ;6
         ldy   #$00       ;2
         lda   ff_xpos      ;4
         asl   A          ;2
         bcc   :L9128     ;2+
         ldy   #$01       ;2
:L9128   tax              ;2
         inx              ;2
         lda   ff_ypos      ;4
         jsr   $f411      ;6
         jsr   $f45a      ;6
         rts              ;6

:L9134   lda   TMP1       ;3
         sed              ;2
         clc              ;2
         adc   #$01       ;3
         sta   TMP1       ;3
         lda   TMP0       ;3
         adc   #$00       ;3
         sta   TMP0       ;3
         ldy   SPKR       ;4
         cld              ;2
         cmp   #$40       ;2
         bcc   :L914F     ;2+
         lda   #$01       ;2
         sta   FRAME_STATE ;4
:L914F   rts              ;6

L9150    lda   ff_dir2      ;4
         pha              ;3
         ldy   ff_dir1      ;4
         iny              ;2
         iny              ;2
         iny              ;2
         iny              ;2
         sty   ff_dir2      ;4
         jsr   L9166      ;6
         pla              ;4
         sta   ff_dir2      ;4
         rts              ;6

L9166    lda   #$00       ;2
         sta   CROSS_INDEX ;4
         ldy   ff_dir2      ;4
         lda   FF_XDIR_ADD,y    ;4+
         clc              ;2
         adc   ff_xpos      ;4
         pha              ;3
         lda   FF_YDIR_ADD,y    ;4+
         clc              ;2
         adc   ff_ypos      ;4
         jsr   GrScanline ;6
         pla              ;4
         sta   X_POS      ;4
         jsr   DIVIDE7    ;6
         lda   L9300,x    ;4+
         and   (GR_LOW),y ;5+
         sta   CROSS_INDEX ;4
         lda   L9307,x    ;4+
         iny              ;2
         and   (GR_LOW),y ;5+
         ora   CROSS_INDEX ;4
         sta   L9320      ;4
         rts              ;6

DIVIDE7  ldy   X_POS      ;4
         lda   DIV7_BIT_TABLE,y ;4+
         tax              ;2
         lda   DIV7_BYTE_TABLE,y ;4+
         tay              ;2
         rts              ;6

L91A8    jsr   L9166      ;6
         lda   L9320      ;4
         sta   L932A      ;4
         lda   ff_dir2      ;4
         sta   L9329      ;4
         tay              ;2
         dey              ;2
         bne   :L91BD     ;2+
         ldy   #$04       ;2
:L91BD   sty   L932D      ;4
         ldy   L9329      ;4
         iny              ;2
         cpy   #$05       ;2
         bne   :L91CA     ;2+
         ldy   #$01       ;2
:L91CA   sty   L932E      ;4
         lda   L932D      ;4
         sta   ff_dir2      ;4
         jsr   L9166      ;6
         lda   L9320      ;4
         sta   L932D      ;4
         lda   L932E      ;4
         sta   ff_dir2      ;4
         jsr   L9166      ;6
         lda   L9320      ;4
         sta   L932E      ;4
         lda   L9329      ;4
         sta   ff_dir1      ;4
         jsr   L9150      ;6
         lda   L9320      ;4
         sta   L932B      ;4
         ldy   ff_dir1      ;4
         iny              ;2
         cpy   #$05       ;2
         bne   :L9204     ;2+
         ldy   #$01       ;2
:L9204   sty   ff_dir1      ;4
         jsr   L9150      ;6
         lda   L9320      ;4
         sta   L932C      ;4
         lda   L932E      ;4
         beq   :L9222     ;2+
         lda   L932B      ;4
         beq   :L9222     ;2+
         lda   L932A      ;4
         bne   :L9222     ;2+
         jmp   :L925B     ;3

:L9222   lda   L932D      ;4
         bne   :L9246     ;2+
         lda   L932C      ;4
         beq   :L922F     ;2+
         jmp   :L925B     ;3

:L922F   lda   L932A      ;4
         beq   :L9237     ;2+
         jmp   :L925B     ;3

:L9237   lda   L932B      ;4
         beq   :L923F     ;2+
         jmp   :L925B     ;3

:L923F   lda   L9329      ;4
         sta   ff_dir2      ;4
         rts              ;6

:L9246   lda   L932E      ;4
         beq   :L924E     ;2+
         jmp   :L925B     ;3

:L924E   lda   L932A      ;4
         bne   :L923F     ;2+
         lda   L932C      ;4
         beq   :L923F     ;2+
         jmp   :L925B     ;3

:L925B   jsr   :L927C     ;6
         lda   L9321      ;4
         beq   :L9275     ;2+
         lda   L9324      ;4
         ldy   ff_stack      ;4
         sta   FF_STACK_X,y    ;5
         lda   L9323      ;4
         sta   FF_STACK_Y,y    ;5
         inc   ff_stack      ;6
:L9275   lda   L9329      ;4
         sta   ff_dir2      ;4
         rts              ;6

:L927C   lda   #$00       ;2
         sta   L9321      ;4
         lda   ff_xpos      ;4
         sta   L9327      ;4
         lda   ff_ypos      ;4
         sta   L9328      ;4
         lda   L9324      ;4
         sta   ff_xpos      ;4
         lda   L9323      ;4
         sta   ff_ypos      ;4
         lda   #$01       ;2
         sta   ff_dir2      ;4
:L929E   jsr   L9166      ;6
         lda   L9320      ;4
         bne   :L92AB     ;2+
         lda   #$01       ;2
         sta   L9321      ;4
:L92AB   inc   ff_dir2      ;6
         lda   ff_dir2      ;4
         cmp   #$05       ;2
         bne   :L929E     ;2+
         lda   #$01       ;2
         sta   ff_dir1      ;4
:L92BA   jsr   L9150      ;6
         lda   L9320      ;4
         bne   :L92C7     ;2+
         lda   #$01       ;2
         sta   L9321      ;4
:L92C7   inc   ff_dir1      ;6
         lda   ff_dir1      ;4
         cmp   #$05       ;2
         bne   :L92BA     ;2+
         lda   L9327      ;4
         sta   ff_xpos      ;4
         lda   L9328      ;4
         sta   ff_ypos      ;4
         rts              ;6

L9300    dfb   $03
         dfb   $06
         dfb   $0c
         dfb   $18
         dfb   $30
         dfb   $60
         dfb   $40
L9307    ds    6
         dfb   $01
FF_XDIR_ADD    
         dfb   $00
         dfb   $00
         dfb   $ff
         dfb   $00
FF_XDIR_TAB
         dfb   $01
         dfb   $01
         dfb   $ff
         dfb   $ff
         dfb   $01
FF_YDIR_ADD
         dfb   $00
         dfb   $ff
         dfb   $00
         dfb   $01
FF_YDIR_TAB
         dfb   $00
         dfb   $ff
         dfb   $ff
         dfb   $01
         dfb   $01
L9320    dfb   $00
L9321    dfb   $00
L9322    dfb   $00
L9323    dfb   $00
L9324    dfb   $00
CROSS_INDEX
         dfb   $00
X_POS    dfb   $00
L9327    dfb   $00
L9328    dfb   $00
L9329    dfb   $00
L932A    dfb   $00
L932B    dfb   $00
L932C    dfb   $00
L932D    dfb   $00
L932E    dfb   $00
         dfb   $20

DIV7_BIT_TABLE
         hex   0002040601030500
         hex   0204060103050002
         hex   0406010305000204
         hex   0601030500020406
         hex   0103050002040601
         hex   0305000204060103
         hex   0500020406010305
         hex   0002040601030500
         hex   0204060103050002
         hex   0406010305000204
         hex   0601030500020406
         hex   0103050002040601
         hex   0305000204060103
         hex   0500020406010305
         hex   0002040601030500
         hex   0204060103050002
         hex   0406010305000204
         hex   06010305

DIV7_BYTE_TABLE
         hex   0000000001010102
         hex   0202020303030404
         hex   0404050505060606
         hex   0607070708080808
         hex   0909090a0a0a0a0b
         hex   0b0b0c0c0c0c0d0d
         hex   0d0e0e0e0e0f0f0f
         hex   1010101011111112
         hex   1212121313131414
         hex   1414151515161616
         hex   1617171718181818
         hex   1919191a1a1a1a1b
         hex   1b1b1c1c1c1c1d1d
         hex   1d1e1e1e1e1f1f1f
         hex   2020202021212122
         hex   2222222323232424
         hex   2424252525262626
         hex   26272727
         dfb   $ff
         dfb   $ff
         dfb   $00
         dfb   $00
         dfb   $ff
         dfb   $ff
         dfb   $00
         dfb   $00

FF_STACK_X
         ds    FF_STACK_SIZE    
        
FF_STACK_Y
         ds    FF_STACK_SIZE 

