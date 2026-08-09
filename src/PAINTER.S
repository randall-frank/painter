
         dsk   ../bin/PAINTER#066000
         typ   $06
         
         put   COMMON.S         

FLG_NO_FILL     equ 1
FLG_COLLIDE     equ 2
FLG_NO_GREMLINS equ $80

KEY_RETURN      equ $8d
KEY_CTRL_S      equ $93
KEY_ESC         equ $9b
KEY_SPACE       equ $a0

FF_STACK_SIZE   equ $d8   


TMP0     equ   $00
TMP1     equ   $01
CROSS_X  equ   $02
CROSS_Y  equ   $03
MON_CH   equ   $24        ;cursor horizontal displacement
MON_CV   equ   $25        ;cursor vertical displacement
GR_LOW   equ   $26
GR_HIGH  equ   $27
MON_COLOR equ  $30        ;lo-res graphics color
AS_RAND_BYTE equ $9f
HGR_PAGE equ   $e6
HT2_INIT equ   $07fd

         org   $6000

* 8 bytes/highscore, 10 highscores
* 3 bytes score (two nibble digits/byte), 3 bytes Initials

HIGHSCORES
         hex   0000000000000000000000000000000000000000000000000000000000000000
         hex   0000000000000000000000000000000000000000000000000000000000000000
         hex   0000000000000000000000000000000000000000000000000000000000000000
         hex   0000000000000000000000000000000000000000000000000000000000000000
         hex   0000000000000000000000000000000000000000000000000000000000000000
         hex   0000000000000000000000000000000000000000000000000000000000000000
         hex   0000000000000000000000000000000000000000000000000000000000000000
         hex   0000000000000000000000000000000000000000000000000000000000000000

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
         sta   L6256      ;4
         lda   #$00       ;2
         sta   HS_NUMBER  ;4

* Prompt for 3 initials

:L61BC   lda   HS_NUMBER  ;4
         clc              ;2
         adc   L6256      ;4
         sta   MON_CH     ;3
:key_loop 
         bit   KBD        ;4
         bpl   :key_loop     ;2+
         lda   KBD        ;4  Enter initials

         bit   KBDSTRB    ;4
         cmp   #KEY_RETURN ;2
         beq   :L61F1     ;2+
         jsr   MON_COUT   ;6
         ldy   HS_NUMBER  ;4
         iny              ;2
         iny              ;2
         iny              ;2
         sta   (TMP0),y   ;6
         inc   HS_NUMBER  ;6
         lda   HS_NUMBER  ;4
         cmp   #$03       ;2
         bne   :L61BC     ;2+
         lda   #$00       ;2
         sta   HS_NUMBER  ;4
         jmp   :L61BC     ;3

:L61F1   rts              ;6

DISP_HISCORES
         lda   #$0a       ;2  10 highscores in two columns
         sta   HS_NUMBER  ;4
         lda   #$92       ;2
         jsr   MON_COUT   ;6
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
L6256    dfb   $00
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
DO_TITLE_DITHER
         jsr   DITHERNAME ;6
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
         jmp   DO_TITLE_DITHER ;3

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
         rts              ;6

DITHERNAME
         lda   #>TITLE_PIXELS  ;2  pixels at $7000 - Need call to $F3E2 (HGR) first
         sta   TMP1       ;3
         lda   #<TITLE_PIXELS       ;2
         sta   TMP0       ;3
         lda   #$92       ;2
         jsr   MON_COUT   ;6
         sta   KBDSTRB    ;4
         ldx   #$03       ;2
         jsr   HCOLOR     ;6
L62D4    ldy   #$00       ;2
         lda   (TMP0),y   ;5+
         pha              ;3
         iny              ;2
         lda   (TMP0),y   ;5+
         clc              ;2
         adc   #$10       ;2
         tay              ;2
         pla              ;4
         clc              ;2
         adc   #$28       ;2
         tax              ;2
         tya              ;2
         ldy   #$00       ;2
         jsr   HPLOT0     ;6  A=height, X=width low, Y=width high
         lda   TMP0       ;3
         clc              ;2
         adc   #$02       ;2
         sta   TMP0       ;3
         lda   TMP1       ;3
         adc   #$00       ;2
         sta   TMP1       ;3
         lda   KBD        ;4
         cmp   #$a0       ;2
         bne   NOISE      ;3+
         rts              ;6

NOISE    ldy   #$ff       ;2
:L6302   dey              ;2
         bne   :L6302     ;2+
         sta   SPKR       ;4
         lda   TMP1       ;3
         cmp   #$7a       ;2  pixels end at 7a4c
         bne   L62D4      ;3+
         lda   TMP0       ;3
         cmp   #$4c       ;2
         bne   L62D4      ;3+
         rts              ;6

         dfb   $30
         dfb   $7a
         dfb   $4a
         dfb   $90
         dfb   $64
         dfb   $e6
         dfb   $88
         dfb   $d0
         dfb   $2e
         dfb   $48
         dfb   $b1
         dfb   $79
         dfb   $c9
         dfb   $bc
         dfb   $f0
         dfb   $04
         dfb   $c9
         dfb   $be
         dfb   $d0
         dfb   $08
         dfb   $a9
         dfb   $00
         dfb   $85
         dfb   $87
         dfb   $68
         dfb   $4c
         dfb   $25
         dfb   $1c
         dfb   $68
         dfb   $48
         dfb   $a5
         dfb   $79
         dfb   $48
         dfb   $a5
         dfb   $7a
         dfb   $48
         dfb   $86
         dfb   $70
         dfb   $20
         dfb   $f3
         dfb   $1c
         dfb   $a5
         dfb   $87
         dfb   $20
         dfb   $4f
         dfb   $1d
         dfb   $a6
         dfb   $70
         dfb   $68
         dfb   $85
         dfb   $7a
         dfb   $68
         dfb   $85
         dfb   $79
         dfb   $68
         dfb   $45
         dfb   $87
         dfb   $d0
         dfb   $21
         dfb   $88
         dfb   $c8
         dfb   $b1
         dfb   $79
         dfb   $c9
         dfb   $a0
         dfb   $f0
         dfb   $14
         dfb   $c9
         dfb   $ac
         dfb   $f0
         dfb   $10
         dfb   $c9
         dfb   $a9
         dfb   $f0
         dfb   $0c
         dfb   $c9
         dfb   $a8
         dfb   $f0
         dfb   $08
         dfb   $c9
         dfb   $a3
         dfb   $f0
         dfb   $04
         asc   "I",8d,"Pe"
         dfb   $88
         asc   "hHP!h="
         dfb   $81
         dfb   $30
         dfb   $30
         dfb   $fa
         dfb   $4a
         dfb   $b0
         dfb   $f7
         dfb   $d0
         dfb   $93
         dfb   $38
         dfb   $60
         dfb   $c9
         dfb   $0b
         dfb   $d0
         dfb   $0d
         dfb   $b1
         dfb   $79
         dfb   $c9
         dfb   $a0
         dfb   $f0
         dfb   $05
         asc   "JI",8d,"Pd)"
         dfb   $0b
         dfb   $18
         dfb   $60
         dfb   $d1
         dfb   $79
         asc   "pXPZ*%"
         dfb   $89
         dfb   $85
         dfb   $95
         dfb   $a5
         dfb   $8a
         dfb   $46
         dfb   $95
         dfb   $6a
         dfb   $ca
         dfb   $d0
         dfb   $fa
         dfb   $60
         dfb   $a9
         dfb   $00
         dfb   $85
         dfb   $a7
         dfb   $85
         dfb   $99
         dfb   $20
         dfb   $92
         dfb   $22
         dfb   $a9
         dfb   $ff
         dfb   $85
         dfb   $97
         dfb   $b1
         dfb   $79
         dfb   $c9
         dfb   $bc
         dfb   $d0
         dfb   $05
         dfb   $c8
         dfb   $e6
         dfb   $97
         dfb   $f0
         dfb   $05
         dfb   $c9
         dfb   $be
         dfb   $d0
         dfb   $03
         dfb   $c8
         dfb   $e6
         dfb   $97
         dfb   $20
         dfb   $f3
         dfb   $1c
         dfb   $a5
         dfb   $95
         dfb   $85
         dfb   $89
         dfb   $a5
         dfb   $96
         dfb   $85
         dfb   $8a
         dfb   $c8
         dfb   $b1
         dfb   $79
         dfb   $a2
         dfb   $03
         dfb   $dd
         dfb   $e7
         dfb   $1c
         dfb   $f0
         dfb   $07
         dfb   $ca
         dfb   $10
         dfb   $f8
         dfb   $88
         dfb   $4c
         dfb   $bf
         dfb   $1c
         dfb   $20
         dfb   $d2
         dfb   $1c
         dfb   $4c
         dfb   $a8
         dfb   $1c
         dfb   $a6
         dfb   $97
         dfb   $30
         dfb   $0e
         dfb   $f0
         dfb   $08
         dfb   $a5
         dfb   $89
         dfb   $85
         dfb   $aa
         dfb   $a5
         dfb   $8a
         dfb   $85
         dfb   $89
         dfb   $a9
         dfb   $00
         dfb   $85
         dfb   $8a
         dfb   $60
         dfb   $a5
         dfb   $a7
         dfb   $85
         dfb   $a8
         dfb   $a9
         dfb   $00
         dfb   $85
         dfb   $a7
         dfb   $bd
         dfb   $eb
         dfb   $1c
         dfb   $48
         dfb   $bd
         dfb   $ef
         dfb   $1c
         dfb   $48
         dfb   $c8
         dfb   $20
         dfb   $f3
         dfb   $1c
         dfb   $60
         asc   "+-*/"
         dfb   $1e
         dfb   $1e
         dfb   $1e
         dfb   $1e
         dfb   $97
         dfb   $82
         dfb   $2b
         dfb   $54
         dfb   $20
         dfb   $b2
         dfb   $22
         dfb   $a9
         dfb   $ff
         dfb   $85
         dfb   $87
         dfb   $20
         dfb   $38
         dfb   $23
         dfb   $90
         dfb   $03
         dfb   $4c
         dfb   $ac
         dfb   $1d
         dfb   $c9
         dfb   $c0
         dfb   $b0
         dfb   $50
         dfb   $84
         dfb   $95
         dfb   $84
         dfb   $96
         dfb   $b1
         dfb   $79
         dfb   $38
         dfb   $e9
         dfb   $b0
         dfb   $18
         dfb   $65
         dfb   $95
         dfb   $85
         dfb   $95
         dfb   $90
         dfb   $04
         dfb   $e6
         dfb   $96
         dfb   $f0
         asc   '* 7#'
         dfb   $b0
         dfb   $2d
         dfb   $c9
         dfb   $c0
         dfb   $b0
         dfb   $29
         dfb   $20
         dfb   $47
         dfb   $1d
         dfb   $b0
         dfb   $1c
         dfb   $a5
         dfb   $96
         dfb   $48
         dfb   $a5
         dfb   $95
         dfb   $20
         dfb   $47
         dfb   $1d
         dfb   $b0
         dfb   $11
         dfb   $20
         dfb   $47
         dfb   $1d
         dfb   $b0
         dfb   $0c
         dfb   $65
         dfb   $95
         dfb   $85
         dfb   $95
         dfb   $68
         dfb   $65
         dfb   $96
         dfb   $85
         dfb   $96
         dfb   $90
         dfb   $c8
         dfb   $48
         dfb   $68
         dfb   $4c
         dfb   $19
         dfb   $1e
         dfb   $06
         dfb   $95
         dfb   $26
         dfb   $96
         dfb   $60
         dfb   $88
         dfb   $a5
         dfb   $96
         dfb   $f0
         dfb   $02
         dfb   $a9
         dfb   $01
         dfb   $85
         dfb   $87
         asc   '` T#'
         dfb   $b0
         dfb   $2d
         dfb   $aa
         dfb   $18
         dfb   $30
         dfb   $29
         dfb   $29
         dfb   $11
         dfb   $85
         asc   87,"%",87,"*"
         dfb   $29
         dfb   $01
         dfb   $85
         dfb   $87
         dfb   $8a
         dfb   $29
         dfb   $10
         dfb   $f0
         dfb   $0c
         dfb   $a9
         dfb   $00
         dfb   $85
         dfb   $95
         dfb   $85
         dfb   $96
         dfb   $b1
         dfb   $85
         dfb   $85
         dfb   $99
         dfb   $d0
         dfb   $0a
         dfb   $b1
         dfb   $85
         dfb   $85
         dfb   $95
         dfb   $c8
         dfb   $b1
         dfb   $85
         dfb   $85
         dfb   $96
         dfb   $88
         dfb   $88
         dfb   $88
         dfb   $60
         dfb   $a6
         dfb   $67
         dfb   $f0
         dfb   $15
         dfb   $2c
         dfb   $88
         dfb   $2a
         dfb   $f0
         dfb   $04
         dfb   $e6
         dfb   $93
         dfb   $d0
         dfb   $07
         dfb   $09
         dfb   $02
         dfb   $88
         dfb   $91
         dfb   $85
         dfb   $f0
         dfb   $05
         dfb   $a2
         dfb   $09
         dfb   $4c
         dfb   $ac
         dfb   $1e
         dfb   $a9
         dfb   $01
         dfb   $90
         dfb   $bc
         dfb   $a9
         dfb   $80
         dfb   $85
         dfb   $87
         dfb   $4c
         dfb   $a7
         dfb   $23
         dfb   $c9
         dfb   $a7
         dfb   $d0
         dfb   $14
         dfb   $84
         dfb   $96
         dfb   $84
         dfb   $87
         dfb   $c8
         dfb   $b1
         dfb   $79
         dfb   $25
         dfb   $94
         dfb   $85
         dfb   $95
         dfb   $c8
         dfb   $b1
         dfb   $79
         dfb   $c9
         dfb   $a7
         dfb   $f0
         dfb   $01
         dfb   $88
         dfb   $60
         dfb   $c9
         dfb   $aa
         dfb   $d0
         dfb   $0f
         dfb   $a9
         dfb   $20
         dfb   $85
         dfb   $a7
         dfb   $a5
         dfb   $7d
         dfb   $85
         dfb   $95
         dfb   $a5
         dfb   $7e
         dfb   $85
         dfb   $96
         dfb   $4c
         dfb   $4d
         dfb   $1d
         dfb   $c9
         dfb   $a4
         dfb   $d0
         dfb   $06
         dfb   $a9
         dfb   $c0
         dfb   $a2
         dfb   $04
         dfb   $d0
         dfb   $08
         dfb   $c9
         dfb   $c0
         dfb   $d0
         dfb   $37
         dfb   $a9
         dfb   $b8
         dfb   $a2
         dfb   $03
         dfb   $85
         dfb   $8e
         dfb   $86
         dfb   $8f
         dfb   $a9
         dfb   $00
         dfb   $85
         dfb   $95
         dfb   $85
         dfb   $96
         dfb   $20
         dfb   $37
         dfb   $23
         dfb   $b0
         dfb   $2b
         dfb   $c9
         dfb   $ba
         dfb   $90
         dfb   $02
         dfb   $e9
         dfb   $07
         dfb   $c5
         dfb   $8e
         dfb   $b0
         dfb   $21
         dfb   $a6
         dfb   $8f
         dfb   $e0
         dfb   $03
         dfb   $d0
         dfb   $01
         asc   0a0a0a0a0a0a,'&'
         dfb   $95
         dfb   $26
         dfb   $96
         dfb   $b0
         dfb   $05
         asc   "JPvpZ",a2
         dfb   $39
         dfb   $2c
         dfb   $a2
         dfb   $44
         dfb   $20
         dfb   $ac
         dfb   $1e
         dfb   $c8
         dfb   $60
         dfb   $88
         dfb   $20
         dfb   $38
         dfb   $23
         dfb   $b0
         dfb   $f3
         dfb   $4c
         dfb   $4d
         dfb   $1d
         dfb   $a5
         dfb   $a8
         dfb   $d0
         dfb   $29
         dfb   $20
         dfb   $b2
         dfb   $22
         dfb   $84
         dfb   $8b
         dfb   $84
         dfb   $8c
         dfb   $a0
         dfb   $10
         dfb   $a5
         dfb   $89
         dfb   $4a
         dfb   $90
         dfb   $0c
         dfb   $18
         asc   a2,"~5",8d
         dfb   $75
         dfb   $97
         dfb   $95
         asc   8d,"hPw",a2
         dfb   $03
         dfb   $76
         dfb   $89
         dfb   $ca
         dfb   $10
         dfb   $fb
         dfb   $88
         dfb   $d0
         dfb   $e5
         dfb   $60
         dfb   $a5
         dfb   $a8
         dfb   $f0
         dfb   $03
         dfb   $4c
         dfb   $1c
         dfb   $1e
         dfb   $20
         dfb   $b2
         dfb   $22
         dfb   $84
         dfb   $8b
         dfb   $84
         dfb   $8c
         dfb   $a0
         dfb   $10
         dfb   $06
         dfb   $89
         dfb   $26
         dfb   $8a
         dfb   $26
         dfb   $8b
         dfb   $26
         dfb   $8c
         dfb   $38
         dfb   $a5
         dfb   $8b
         dfb   $e5
         dfb   $95
         dfb   $aa
         dfb   $a5
         dfb   $8c
         dfb   $e5
         dfb   $96
         dfb   $90
         dfb   $06
         dfb   $86
         dfb   $8b
         dfb   $85
         dfb   $8c
         dfb   $e6
         dfb   $89
         dfb   $88
         dfb   $d0
         dfb   $e3
         dfb   $60
         dfb   $a5
         dfb   $96
         dfb   $49
         dfb   $ff
         dfb   $85
         dfb   $96
         dfb   $a5
         dfb   $95
         dfb   $49
         dfb   $ff
         dfb   $aa
         dfb   $a5
         dfb   $a7
         dfb   $45
         dfb   $a8
         dfb   $85
         dfb   $a7
         dfb   $8a
         dfb   $38
         dfb   $b0
         dfb   $09
         dfb   $a5
         dfb   $a8
         dfb   $05
         dfb   $a7
         dfb   $85
         dfb   $a7
         dfb   $18
         dfb   $a5
         dfb   $95
         dfb   $65
         dfb   $89
         dfb   $85
         dfb   $89
         dfb   $a5
         dfb   $96
         dfb   $65
         dfb   $8a
         dfb   $85
         dfb   $8a
         dfb   $60
         dfb   $24
         dfb   $93
         dfb   $10
         dfb   $01
         dfb   $60
         dfb   $20
         dfb   $fb
         dfb   $1e
         dfb   $98
         dfb   $48
         dfb   $a0
         dfb   $05
         dfb   $a9
         dfb   $aa
         dfb   $20
         dfb   $e5
         dfb   $24
         dfb   $88
         dfb   $d0
         dfb   $fa
         dfb   $68
         dfb   $a8
         dfb   $a9
         dfb   $87
         dfb   $20
         dfb   $e5
         dfb   $24
         dfb   $a9
         dfb   $c5
         dfb   $20
         dfb   $e5
         dfb   $24
         dfb   $a9
         dfb   $d2
         dfb   $20
         dfb   $e5
         dfb   $24
         dfb   $20
         dfb   $e5
         dfb   $24
         dfb   $c6
         dfb   $93
         dfb   $f0
         dfb   $03
         dfb   $20
         dfb   $00
         dfb   $1f
         dfb   $a9
         dfb   $80
         dfb   $85
         dfb   $93
         dfb   $20
         dfb   $49
         dfb   $1f
         dfb   $38
         dfb   $f8
         dfb   $a9
         dfb   $00
         dfb   $65
         dfb   $74
         dfb   $85
         dfb   $74
         dfb   $a5
         dfb   $75
         dfb   $69
         dfb   $00
         dfb   $85
         dfb   $75
         dfb   $d8
         dfb   $a2
         dfb   $06
         dfb   $a9
         dfb   $00
         dfb   $20
         asc   "(|JPx)",8d
         dfb   $4c
         dfb   $e5
         dfb   $24
         dfb   $ad
         dfb   $2f
         dfb   $30
         dfb   $c9
         dfb   $40
         dfb   $b0
         dfb   $37
         dfb   $98
         dfb   $48
         dfb   $ac
         dfb   $2f
         dfb   $30
         dfb   $a5
         dfb   $6d
         dfb   $99
         dfb   $2f
         dfb   $2f
         dfb   $a0
         dfb   $07
         dfb   $8a
         dfb   $d9
         dfb   $3f
         dfb   $1f
         dfb   $f0
         dfb   $05
         dfb   $88
         dfb   $10
         dfb   $f8
         dfb   $a0
         dfb   $08
         dfb   $98
         asc   0a0a0a0a
         dfb   $05
         dfb   $62
         dfb   $ac
         dfb   $2f
         dfb   $30
         dfb   $99
         dfb   $30
         dfb   $2f
         dfb   $a5
         dfb   $61
         dfb   $99
         dfb   $31
         dfb   $2f
         dfb   $a5
         dfb   $60
         dfb   $99
         dfb   $32
         dfb   $2f
         asc   "HHHH"
         dfb   $8c
         dfb   $2f
         dfb   $30
         dfb   $68
         dfb   $a8
         dfb   $60
         dfb   $09
         dfb   $19
         asc   ',9DUbr'
         dfb   $87
         dfb   $9b
         dfb   $bd
         dfb   $61
         dfb   $1f
         dfb   $f0
         dfb   $06
         dfb   $20
         dfb   $e5
         dfb   $24
         asc   "hPu",a2
         dfb   $08
         dfb   $bd
         dfb   $61
         dfb   $1f
         dfb   $20
         dfb   $e5
         dfb   $24
         dfb   $ca
         dfb   $d0
         dfb   $f7
         dfb   $4c
         dfb   $b7
         dfb   $25
         asc   "ENIL NI : NO SUCH LABEL"
         dfb   $00
         asc   ": DUPLICATE SYMBOL"
         dfb   $00
         asc   ": BAD OPCODE"
         dfb   $00
         asc   ": OVERFLOW"
         dfb   $00
         asc   ": BAD EXPRESSION"
         dfb   $00
         asc   ": BAD EQUATE"
         dfb   $00
         asc   ": ILLEGAL LABEL"
         dfb   $00
         asc   ": ILLEGAL DSECT/DEND"
         dfb   $00
         asc   ": SYMBOL TABLE FULL"
         dfb   $00
         asc   ">>> BAD CALLING PARAMETERS"
         dfb   $00
         asc   8d,"PRESS ANY KEY TO CONTINUE "
         dfb   $3b
         dfb   $a9
         dfb   $a0
         dfb   $99
         dfb   $a6
         dfb   $2e
         dfb   $88
         dfb   $10
         dfb   $fa
         dfb   $c8
         dfb   $b9
         dfb   $00
         dfb   $08
         dfb   $f0
         dfb   $15
         dfb   $99
         dfb   $c4
         dfb   $2e
         dfb   $c0
         dfb   $1d
         asc   "PsH9"
         dfb   $00
         dfb   $08
         dfb   $f0
         dfb   $08
         dfb   $a2
         dfb   $9b
         dfb   $20
         dfb   $ac
         dfb   $1e
         dfb   $4c
         dfb   $69
         dfb   $12
         dfb   $c8
         dfb   $84
         dfb   $aa
         dfb   $b9
         dfb   $00
         dfb   $08
         dfb   $f0
         dfb   $18
         dfb   $a2
         dfb   $00
         dfb   $9d
         dfb   $a6
         dfb   $2e
         dfb   $e8
         dfb   $c8
         dfb   $b9
         dfb   $00
         dfb   $08
         dfb   $f0
         dfb   $07
         dfb   $e0
         dfb   $1e
         dfb   $90
         dfb   $f2
         dfb   $4c
         dfb   $4e
         dfb   $20
         dfb   $84
         dfb   $aa
         dfb   $4c
         dfb   $ac
         dfb   $20
         dfb   $a0
         dfb   $ff
         dfb   $c8
         dfb   $b9
         dfb   $c4
         dfb   $2e
         dfb   $99
         dfb   $a6
         dfb   $2e
         dfb   $c0
         dfb   $1d
         dfb   $90
         dfb   $f5
         dfb   $b9
         dfb   $a6
         dfb   $2e
         dfb   $88
         asc   "I pxH@"
         dfb   $19
         dfb   $90
         dfb   $0e
         asc   a2,"0I0P"
         dfb   $01
         dfb   $e8
         dfb   $8a
         dfb   $99
         dfb   $a6
         dfb   $2e
         dfb   $4c
         dfb   $ac
         dfb   $20
         dfb   $a2
         dfb   $00
         dfb   $c8
         dfb   $bd
         dfb   $45
         dfb   $21
         dfb   $99
         dfb   $a6
         dfb   $2e
         dfb   $e8
         dfb   $e0
         dfb   $05
         dfb   $90
         dfb   $f4
         dfb   $a5
         dfb   $58
         dfb   $8d
         dfb   $a4
         dfb   $2e
         dfb   $8d
         dfb   $a2
         dfb   $2e
         dfb   $a5
         dfb   $59
         dfb   $8d
         dfb   $a5
         dfb   $2e
         dfb   $8d
         dfb   $a3
         dfb   $2e
         asc   "$*H9"
         dfb   $00
         dfb   $08
         dfb   $29
         dfb   $07
         dfb   $f0
         dfb   $03
         dfb   $8d
         dfb   $a2
         dfb   $2e
         dfb   $c8
         dfb   $c8
         dfb   $b9
         dfb   $00
         dfb   $08
         dfb   $29
         dfb   $03
         dfb   $f0
         dfb   $0a
         dfb   $c9
         dfb   $03
         dfb   $d0
         dfb   $03
         dfb   $4c
         dfb   $4e
         dfb   $20
         dfb   $8d
         dfb   $a3
         dfb   $2e
         dfb   $a0
         dfb   $00
         dfb   $b9
         dfb   $0f
         dfb   $33
         dfb   $85
         dfb   $76
         dfb   $f0
         dfb   $39
         dfb   $09
         dfb   $c0
         dfb   $85
         dfb   $37
         dfb   $a9
         dfb   $00
         dfb   $85
         dfb   $36
         dfb   $20
         dfb   $ea
         dfb   $03
         dfb   $a0
         dfb   $01
         dfb   $c8
         dfb   $b9
         dfb   $0f
         dfb   $33
         dfb   $f0
         dfb   $21
         dfb   $c9
         dfb   $cc
         dfb   $d0
         dfb   $08
         dfb   $20
         dfb   $1f
         dfb   $21
         dfb   $85
         dfb   $6e
         dfb   $4c
         dfb   $f2
         dfb   $20
         dfb   $c9
         dfb   $d0
         dfb   $d0
         dfb   $08
         dfb   $20
         dfb   $1f
         dfb   $21
         dfb   $85
         dfb   $6f
         dfb   $4c
         dfb   $f2
         dfb   $20
         dfb   $20
         asc   "m}H9"
         dfb   $0f
         dfb   $33
         asc   "Pw)",8d
         dfb   $20
         dfb   $ed
         dfb   $fd
         dfb   $60
         dfb   $c8
         dfb   $b9
         dfb   $0f
         dfb   $33
         dfb   $49
         dfb   $b0
         dfb   $c9
         dfb   $0a
         dfb   $b0
         dfb   $0f
         dfb   $aa
         dfb   $c8
         dfb   $b9
         dfb   $0f
         dfb   $33
         dfb   $49
         dfb   $b0
         dfb   $c9
         dfb   $0a
         dfb   $b0
         dfb   $04
         asc   '};!`LN '
         dfb   $00
         dfb   $0a
         dfb   $14
         dfb   $1e
         asc   '(2<FPZ'
         asc   ".OBJ0",a2
         dfb   $54
         dfb   $b5
         dfb   $60
         dfb   $bc
         dfb   $ba
         dfb   $32
         dfb   $94
         dfb   $60
         dfb   $9d
         dfb   $ba
         dfb   $32
         dfb   $ca
         dfb   $10
         dfb   $f3
         dfb   $a2
         dfb   $22
         dfb   $bd
         dfb   $00
         dfb   $0b
         dfb   $bc
         dfb   $0f
         dfb   $33
         dfb   $9d
         dfb   $0f
         dfb   $33
         dfb   $98
         dfb   $9d
         dfb   $00
         dfb   $0b
         dfb   $ca
         dfb   $10
         dfb   $f0
         dfb   $60
         dfb   $a0
         dfb   $00
         dfb   $84
         dfb   $74
         dfb   $84
         dfb   $75
         dfb   $8c
         dfb   $2f
         dfb   $30
         dfb   $84
         dfb   $9a
         dfb   $84
         dfb   $77
         dfb   $8c
         dfb   $09
         dfb   $2f
         dfb   $84
         dfb   $69
         dfb   $84
         dfb   $6b
         dfb   $84
         dfb   $6c
         dfb   $84
         dfb   $6f
         dfb   $88
         dfb   $84
         dfb   $73
         dfb   $84
         dfb   $6a
         dfb   $84
         dfb   $94
         dfb   $84
         dfb   $68
         dfb   $a9
         dfb   $3c
         dfb   $85
         dfb   $6e
         dfb   $a9
         dfb   $00
         dfb   $85
         dfb   $a4
         dfb   $85
         dfb   $a5
         dfb   $85
         dfb   $a6
         dfb   $20
         dfb   $31
         dfb   $20
         dfb   $ad
         dfb   $a4
         asc   '.',0a0a0a0a
         dfb   $8d
         dfb   $e3
         dfb   $2e
         dfb   $f0
         dfb   $1a
         dfb   $38
         dfb   $66
         dfb   $a4
         dfb   $a0
         dfb   $1d
         dfb   $b9
         dfb   $c4
         dfb   $2e
         dfb   $99
         dfb   $e7
         dfb   $2e
         dfb   $88
         dfb   $10
         dfb   $f7
         dfb   $ad
         dfb   $a4
         dfb   $2e
         dfb   $8d
         dfb   $05
         dfb   $2f
         dfb   $ad
         dfb   $a5
         dfb   $2e
         dfb   $8d
         dfb   $06
         dfb   $2f
         dfb   $a5
         dfb   $0c
         dfb   $85
         dfb   $ae
         dfb   $a5
         dfb   $0d
         dfb   $85
         dfb   $af
         dfb   $a9
         dfb   $00
         dfb   $a0
         dfb   $35
         dfb   $d0
         dfb   $04
         asc   "%2$3"
         dfb   $85
         dfb   $63
         dfb   $85
         dfb   $65
         dfb   $84
         dfb   $64
         dfb   $84
         dfb   $66
         dfb   $ad
         dfb   $a2
         asc   '.',0a0a0a0a
         dfb   $8d
         dfb   $e2
         dfb   $2e
         dfb   $f0
         dfb   $03
         dfb   $38
         dfb   $66
         dfb   $a5
         dfb   $60
         dfb   $a5
         dfb   $a4
         dfb   $30
         dfb   $0a
         dfb   $a5
         dfb   $0a
         dfb   $85
         dfb   $79
         dfb   $a5
         dfb   $0b
         dfb   $85
         dfb   $7a
         dfb   $d0
         dfb   $22
         dfb   $a0
         dfb   $1d
         dfb   $b9
         dfb   $e7
         dfb   $2e
         dfb   $99
         dfb   $c4
         dfb   $2e
         dfb   $88
         dfb   $10
         dfb   $f7
         dfb   $20
         dfb   $54
         dfb   $1a
         dfb   $ad
         dfb   $05
         dfb   $2f
         dfb   $8d
         dfb   $a4
         dfb   $2e
         dfb   $ad
         dfb   $06
         dfb   $2f
         dfb   $8d
         dfb   $a5
         dfb   $2e
         dfb   $a2
         dfb   $02
         asc   ' !+ '
         dfb   $86
         dfb   $2d
         dfb   $a9
         dfb   $ff
         dfb   $85
         dfb   $94
         dfb   $a9
         dfb   $00
         dfb   $85
         dfb   $9f
         dfb   $85
         dfb   $7d
         dfb   $85
         dfb   $7e
         dfb   $85
         dfb   $7f
         dfb   $85
         dfb   $80
         dfb   $85
         dfb   $6d
         dfb   $e6
         dfb   $6d
         dfb   $85
         dfb   $60
         dfb   $85
         dfb   $61
         dfb   $85
         dfb   $62
         dfb   $e6
         dfb   $60
         dfb   $85
         dfb   $a9
         dfb   $60
         dfb   $24
         dfb   $a9
         dfb   $10
         dfb   $0a
         dfb   $a9
         dfb   $00
         dfb   $85
         dfb   $60
         dfb   $85
         dfb   $61
         dfb   $85
         dfb   $62
         dfb   $85
         dfb   $a9
         dfb   $f8
         dfb   $18
         dfb   $a5
         dfb   $60
         dfb   $69
         dfb   $01
         dfb   $85
         dfb   $60
         dfb   $d8
         dfb   $90
         dfb   $21
         dfb   $f8
         dfb   $a5
         dfb   $61
         dfb   $69
         dfb   $00
         dfb   $85
         dfb   $61
         dfb   $a5
         dfb   $62
         dfb   $69
         dfb   $00
         dfb   $85
         dfb   $62
         dfb   $d8
         dfb   $a5
         dfb   $67
         dfb   $f0
         dfb   $04
         dfb   $24
         dfb   $68
         dfb   $30
         dfb   $0b
         dfb   $a9
         dfb   $ae
         dfb   $8c
         dfb   $35
         dfb   $00
         dfb   $20
         dfb   $84
         dfb   $26
         dfb   $ac
         dfb   $35
         dfb   $00
         dfb   $60
         dfb   $a5
         dfb   $a4
         dfb   $10
         dfb   $0f
         dfb   $20
         dfb   $28
         dfb   $2d
         dfb   $b0
         dfb   $12
         dfb   $a9
         dfb   $32
         dfb   $85
         dfb   $79
         dfb   $a9
         dfb   $33
         dfb   $85
         dfb   $7a
         dfb   $90
         dfb   $08
         dfb   $a5
         dfb   $79
         dfb   $c5
         dfb   $0e
         dfb   $a5
         dfb   $7a
         dfb   $e5
         dfb   $0f
         dfb   $60
         dfb   $b1
         dfb   $79
         asc   "I PyHPw1"
         dfb   $79
         asc   "I ppHPw%$"
         dfb   $10
         dfb   $01
         dfb   $60
         dfb   $a0
         dfb   $00
         dfb   $b1
         dfb   $79
         asc   "HI",8d,"Py"
         dfb   $18
         dfb   $98
         dfb   $65
         dfb   $79
         dfb   $85
         dfb   $79
         dfb   $a9
         dfb   $00
         dfb   $a8
         dfb   $65
         dfb   $7a
         dfb   $85
         dfb   $7a
         dfb   $60
         dfb   $ad
         dfb   $00
         dfb   $c0
         dfb   $30
         dfb   $02
         dfb   $18
         dfb   $60
         dfb   $8d
         dfb   $10
         dfb   $c0
         dfb   $c9
         dfb   $83
         dfb   $d0
         dfb   $04
         dfb   $c6
         dfb   $77
         dfb   $38
         dfb   $60
         dfb   $a6
         dfb   $67
         asc   "poI P"
         dfb   $0d
         dfb   $8d
         dfb   $54
         dfb   $c0
         dfb   $ad
         dfb   $e3
         dfb   $2e
         dfb   $f0
         dfb   $21
         dfb   $9d
         dfb   $88
         dfb   $c0
         dfb   $d0
         dfb   $1c
         dfb   $c9
         dfb   $8f
         dfb   $d0
         dfb   $06
         asc   '8fhL'
         dfb   $c5
         dfb   $22
         dfb   $c9
         dfb   $8e
         dfb   $d0
         dfb   $05
         dfb   $46
         dfb   $68
         dfb   $4c
         dfb   $c5
         dfb   $22
         dfb   $c9
         dfb   $9b
         dfb   $d0
         dfb   $c7
         dfb   $8d
         dfb   $55
         dfb   $c0
         dfb   $f0
         dfb   $00
         dfb   $ad
         dfb   $00
         dfb   $c0
         dfb   $10
         dfb   $fb
         dfb   $30
         dfb   $bb
         dfb   $a5
         dfb   $85
         dfb   $c5
         dfb   $65
         dfb   $a5
         dfb   $86
         dfb   $e5
         dfb   $66
         dfb   $60
         dfb   $a0
         dfb   $00
         dfb   $b1
         dfb   $aa
         dfb   $20
         dfb   $e5
         dfb   $24
         asc   "HJPw"
         dfb   $60
         dfb   $18
         dfb   $65
         dfb   $7d
         dfb   $85
         dfb   $7d
         dfb   $90
         dfb   $02
         dfb   $e6
         dfb   $7e
         dfb   $60
         dfb   $24
         dfb   $9a
         dfb   $30
         dfb   $09
         dfb   $18
         dfb   $65
         dfb   $7f
         dfb   $85
         dfb   $7f
         dfb   $90
         dfb   $02
         dfb   $e6
         dfb   $80
         dfb   $60
         dfb   $c8
         dfb   $b1
         dfb   $79
         dfb   $c9
         dfb   $b0
         dfb   $b0
         dfb   $06
         dfb   $c9
         dfb   $ae
         dfb   $f0
         dfb   $10
         dfb   $d0
         dfb   $0c
         dfb   $c9
         dfb   $db
         dfb   $b0
         dfb   $08
         dfb   $c9
         dfb   $c1
         dfb   $b0
         dfb   $06
         dfb   $c9
         dfb   $ba
         dfb   $90
         dfb   $03
         dfb   $38
         dfb   $60
         dfb   $18
         dfb   $60
         dfb   $a5
         dfb   $63
         dfb   $85
         dfb   $85
         dfb   $a5
         dfb   $64
         dfb   $85
         dfb   $86
         dfb   $a0
         dfb   $00
         dfb   $20
         dfb   $0a
         dfb   $23
         dfb   $b0
         dfb   $42
         dfb   $b1
         dfb   $85
         dfb   $10
         dfb   $08
         dfb   $d1
         dfb   $79
         dfb   $d0
         dfb   $12
         dfb   $c8
         dfb   $4c
         dfb   $63
         dfb   $23
         dfb   $09
         dfb   $80
         dfb   $d1
         dfb   $79
         dfb   $d0
         dfb   $0d
         dfb   $c8
         dfb   $20
         dfb   $38
         dfb   $23
         dfb   $90
         dfb   $08
         dfb   $b0
         dfb   $15
         dfb   $c8
         dfb   $b1
         dfb   $85
         dfb   $30
         asc   "{HHHH"
         dfb   $18
         dfb   $98
         dfb   $65
         dfb   $85
         dfb   $85
         dfb   $85
         dfb   $90
         dfb   $ce
         dfb   $e6
         dfb   $86
         dfb   $b0
         dfb   $ca
         dfb   $b1
         dfb   $85
         dfb   $30
         dfb   $0c
         dfb   $29
         dfb   $bf
         dfb   $91
         dfb   $85
         dfb   $48
         dfb   $29
         dfb   $20
         dfb   $05
         dfb   $a7
         dfb   $85
         dfb   $a7
         dfb   $68
         dfb   $18
         dfb   $c8
         dfb   $60
         dfb   $38
         dfb   $60
         dfb   $a0
         dfb   $00
         dfb   $20
         dfb   $38
         dfb   $23
         dfb   $b0
         dfb   $42
         dfb   $c9
         dfb   $c0
         dfb   $90
         dfb   $3e
         dfb   $91
         asc   'e 7#'
         dfb   $90
         dfb   $f9
         dfb   $88
         dfb   $b1
         dfb   $65
         dfb   $29
         dfb   $7f
         dfb   $91
         dfb   $65
         asc   "H%",87,"I"
         dfb   $80
         dfb   $f0
         dfb   $04
         dfb   $05
         dfb   $a7
         dfb   $09
         dfb   $40
         dfb   $91
         dfb   $65
         dfb   $c8
         dfb   $a5
         dfb   $7d
         dfb   $91
         dfb   $65
         dfb   $c8
         dfb   $a5
         dfb   $7e
         dfb   $91
         dfb   $65
         dfb   $98
         dfb   $38
         dfb   $65
         dfb   $65
         dfb   $85
         dfb   $65
         dfb   $90
         dfb   $02
         dfb   $e6
         dfb   $66
         dfb   $a5
         dfb   $65
         dfb   $c5
         dfb   $ae
         dfb   $a5
         dfb   $66
         dfb   $e5
         dfb   $af
         dfb   $90
         dfb   $06
         dfb   $a2
         dfb   $87
         dfb   $4c
         dfb   $ac
         dfb   $1e
         dfb   $38
         dfb   $60
         dfb   $2c
         dfb   $10
         dfb   $c0
         dfb   $a9
         dfb   $17
         dfb   $85
         dfb   $aa
         dfb   $a9
         dfb   $20
         dfb   $85
         dfb   $ab
         dfb   $a2
         dfb   $1a
         dfb   $20
         dfb   $13
         dfb   $23
         dfb   $20
         dfb   $0c
         dfb   $fd
         dfb   $60
         dfb   $24
         dfb   $9a
         dfb   $30
         dfb   $1e
         dfb   $a4
         dfb   $8d
         dfb   $f0
         dfb   $1a
         dfb   $a0
         dfb   $00
         dfb   $b9
         dfb   $88
         dfb   $00
         dfb   $24
         dfb   $a6
         dfb   $10
         dfb   $06
         dfb   $20
         dfb   $d6
         asc   ',L#$$'
         dfb   $a0
         dfb   $30
         dfb   $07
         dfb   $91
         dfb   $7f
         asc   "HD",8d,"Ph%"
         dfb   $93
         dfb   $d0
         dfb   $04
         dfb   $24
         dfb   $68
         dfb   $10
         dfb   $50
         dfb   $a5
         dfb   $92
         dfb   $c9
         dfb   $81
         dfb   $d0
         dfb   $07
         dfb   $a5
         dfb   $8a
         dfb   $a6
         dfb   $89
         dfb   $4c
         dfb   $41
         dfb   $24
         dfb   $a5
         dfb   $7e
         dfb   $a6
         dfb   $7d
         dfb   $20
         dfb   $81
         dfb   $24
         dfb   $8a
         dfb   $20
         dfb   $81
         dfb   $24
         dfb   $a9
         dfb   $ba
         dfb   $24
         dfb   $9f
         dfb   $10
         dfb   $0f
         dfb   $a0
         dfb   $07
         dfb   $a9
         dfb   $a0
         dfb   $20
         dfb   $e5
         dfb   $24
         dfb   $88
         dfb   $10
         dfb   $fa
         dfb   $a9
         dfb   $d3
         dfb   $4c
         dfb   $e5
         dfb   $24
         dfb   $a2
         dfb   $00
         dfb   $a0
         dfb   $00
         dfb   $20
         dfb   $e5
         dfb   $24
         dfb   $c4
         dfb   $8d
         dfb   $90
         dfb   $0b
         dfb   $a9
         dfb   $a0
         dfb   $20
         dfb   $e5
         dfb   $24
         dfb   $20
         dfb   $e5
         asc   '$Lx$'
         dfb   $b5
         dfb   $88
         dfb   $20
         dfb   $81
         dfb   $24
         asc   ") hH@"
         dfb   $03
         dfb   $90
         dfb   $e1
         asc   '`HJJJJ '
         dfb   $8a
         dfb   $24
         dfb   $68
         dfb   $29
         dfb   $0f
         dfb   $09
         dfb   $b0
         dfb   $c9
         dfb   $ba
         dfb   $90
         dfb   $02
         dfb   $69
         dfb   $06
         dfb   $4c
         dfb   $e5
         dfb   $24
         dfb   $a5
         dfb   $92
         dfb   $c9
         dfb   $82
         dfb   $d0
         dfb   $03
         dfb   $4c
         dfb   $fb
         dfb   $1e
         dfb   $20
         dfb   $b7
         dfb   $25
         dfb   $a0
         dfb   $ff
         dfb   $84
         dfb   $a1
         dfb   $c8
         dfb   $b1
         dfb   $7b
         dfb   $c9
         dfb   $a0
         dfb   $d0
         dfb   $29
         dfb   $e6
         dfb   $a1
         dfb   $a6
         dfb   $92
         dfb   $e8
         dfb   $f0
         dfb   $20
         dfb   $a6
         dfb   $a1
         dfb   $f0
         dfb   $0c
         dfb   $e0
         dfb   $02
         dfb   $f0
         dfb   $08
         dfb   $b0
         dfb   $16
         dfb   $a5
         dfb   $92
         dfb   $c9
         dfb   $10
         asc   "pi= "
         dfb   $03
         dfb   $38
         dfb   $e5
         dfb   $71
         dfb   $90
         dfb   $08
         dfb   $f0
         dfb   $06
         dfb   $aa
         dfb   $20
         dfb   $5d
         dfb   $25
         dfb   $f0
         dfb   $05
         dfb   $a9
         dfb   $a0
         dfb   $20
         dfb   $e5
         dfb   $24
         dfb   $e6
         dfb   $7b
         dfb   $d0
         dfb   $02
         dfb   $e6
         dfb   $7c
         asc   "I",8d,"PD"
         dfb   $60
         dfb   $48
         dfb   $8a
         dfb   $48
         dfb   $98
         dfb   $48
         dfb   $ba
         dfb   $bd
         dfb   $03
         dfb   $01
         dfb   $09
         dfb   $80
         dfb   $c9
         dfb   $8c
         dfb   $f0
         dfb   $30
         dfb   $c9
         dfb   $8d
         dfb   $d0
         dfb   $51
         dfb   $a6
         dfb   $71
         dfb   $d0
         dfb   $07
         dfb   $a9
         dfb   $a0
         dfb   $20
         dfb   $23
         dfb   $27
         dfb   $a9
         dfb   $8d
         dfb   $e6
         dfb   $6a
         dfb   $a6
         dfb   $6a
         dfb   $e4
         dfb   $6e
         dfb   $90
         dfb   $3e
         dfb   $a5
         dfb   $6f
         dfb   $d0
         dfb   $04
         dfb   $24
         dfb   $69
         dfb   $70
         dfb   $1d
         dfb   $a9
         dfb   $a0
         dfb   $20
         dfb   $23
         dfb   $27
         dfb   $a9
         dfb   $8d
         dfb   $20
         dfb   $23
         dfb   $27
         dfb   $e8
         dfb   $e4
         dfb   $6f
         dfb   $90
         dfb   $f1
         dfb   $b0
         dfb   $11
         dfb   $a6
         dfb   $6a
         dfb   $f0
         dfb   $2f
         dfb   $a5
         dfb   $6f
         dfb   $f0
         dfb   $04
         dfb   $ca
         dfb   $4c
         dfb   $13
         dfb   $25
         dfb   $a9
         dfb   $8c
         dfb   $20
         dfb   $23
         dfb   $27
         dfb   $a9
         dfb   $00
         dfb   $85
         dfb   $6a
         dfb   $f8
         dfb   $38
         dfb   $65
         dfb   $6b
         dfb   $85
         dfb   $6b
         dfb   $a9
         dfb   $00
         dfb   $65
         dfb   $6c
         dfb   $85
         dfb   $6c
         dfb   $d8
         dfb   $4c
         dfb   $57
         dfb   $25
         dfb   $a6
         dfb   $6a
         dfb   $d0
         dfb   $07
         dfb   $a6
         dfb   $71
         dfb   $d0
         dfb   $03
         dfb   $20
         dfb   $89
         asc   '* #',27,'h'
         dfb   $a8
         dfb   $68
         dfb   $aa
         dfb   $68
         dfb   $60
         dfb   $a9
         dfb   $a0
         dfb   $20
         dfb   $e5
         dfb   $24
         dfb   $ca
         dfb   $d0
         dfb   $f8
         dfb   $60
         dfb   $a5
         dfb   $67
         dfb   $48
         dfb   $a9
         dfb   $01
         dfb   $85
         dfb   $67
         dfb   $20
         dfb   $7e
         dfb   $1c
         dfb   $68
         dfb   $85
         dfb   $67
         dfb   $60
         dfb   $84
         dfb   $78
         dfb   $a5
         dfb   $79
         dfb   $48
         dfb   $a5
         dfb   $7a
         dfb   $48
         dfb   $20
         dfb   $9b
         dfb   $22
         dfb   $20
         dfb   $92
         dfb   $22
         dfb   $20
         dfb   $b2
         dfb   $22
         dfb   $a2
         dfb   $03
         dfb   $b1
         dfb   $79
         dfb   $d9
         dfb   $b0
         dfb   $25
         dfb   $d0
         dfb   $06
         asc   "HJPup"
         dfb   $0f
         dfb   $a0
         dfb   $00
         dfb   $a2
         dfb   $03
         dfb   $b1
         dfb   $79
         dfb   $d9
         dfb   $b3
         dfb   $25
         dfb   $d0
         dfb   $07
         asc   "HJPu"
         dfb   $38
         dfb   $b0
         dfb   $01
         dfb   $18
         dfb   $68
         dfb   $85
         dfb   $7a
         dfb   $68
         dfb   $85
         dfb   $79
         dfb   $a4
         dfb   $78
         dfb   $60
         asc   "FINELSE"
         dfb   $48
         dfb   $98
         dfb   $48
         dfb   $8a
         dfb   $48
         dfb   $a0
         dfb   $03
         dfb   $84
         dfb   $ab
         dfb   $a2
         dfb   $0a
         dfb   $86
         dfb   $aa
         dfb   $a2
         dfb   $05
         dfb   $88
         dfb   $b9
         dfb   $60
         dfb   $00
         dfb   $46
         dfb   $aa
         dfb   $08
         dfb   $90
         dfb   $04
         asc   'JJJJ)'
         dfb   $0f
         dfb   $d0
         dfb   $0a
         dfb   $24
         dfb   $ab
         dfb   $30
         dfb   $06
         dfb   $e0
         dfb   $01
         dfb   $f0
         dfb   $02
         dfb   $a9
         dfb   $10
         dfb   $49
         dfb   $b0
         dfb   $20
         dfb   $e5
         dfb   $24
         dfb   $c9
         dfb   $b0
         dfb   $66
         dfb   $ab
         dfb   $28
         dfb   $ca
         dfb   $f0
         dfb   $04
         dfb   $b0
         dfb   $d7
         dfb   $90
         dfb   $d4
         dfb   $a9
         dfb   $a0
         dfb   $20
         dfb   $e5
         dfb   $24
         dfb   $68
         dfb   $aa
         dfb   $68
         dfb   $a8
         dfb   $68
         dfb   $3f
         dfb   $37
         dfb   $f9
         dfb   $00
         dfb   $a0
         dfb   $00
         dfb   $b1
         dfb   $14
         dfb   $91
         dfb   $0e
         dfb   $a5
         dfb   $0e
         dfb   $d0
         dfb   $02
         dfb   $c6
         dfb   $0f
         dfb   $c6
         dfb   $0e
         dfb   $a4
         dfb   $15
         dfb   $a6
         dfb   $14
         dfb   $d0
         dfb   $01
         dfb   $88
         dfb   $ca
         dfb   $86
         dfb   $14
         dfb   $84
         dfb   $15
         dfb   $e4
         dfb   $12
         dfb   $d0
         dfb   $e2
         dfb   $c4
         dfb   $13
         dfb   $d0
         dfb   $de
         dfb   $20
         dfb   $80
         dfb   $1d
         dfb   $37
         dfb   $e9
         dfb   $41
         dfb   $59
         dfb   $f2
         dfb   $07
         dfb   $fb
         dfb   $00
         dfb   $60
         dfb   $00
         dfb   $20
         dfb   $34
         dfb   $16
         dfb   $4c
         dfb   $2e
         dfb   $16
         dfb   $20
         dfb   $87
         dfb   $15
         dfb   $20
         dfb   $80
         dfb   $1d
         asc   '):(;'
         dfb   $eb
         dfb   $06
         dfb   $22
         dfb   $00
         dfb   $20
         dfb   $c4
         dfb   $14
         dfb   $4c
         dfb   $48
         dfb   $16
         dfb   $20
         dfb   $80
         dfb   $1d
         dfb   $11
         dfb   $3c
         dfb   $00
         asc   ')q',27,'q*qq'
         dfb   $a7
         dfb   $b9
         dfb   $00
         dfb   $a0
         dfb   $00
         dfb   $20
         dfb   $2c
         dfb   $fe
         dfb   $20
         dfb   $80
         dfb   $1d
         dfb   $37
         dfb   $00
         dfb   $60
         dfb   $10
         dfb   $34
         dfb   $13
         dfb   $3f
         dfb   $6c
         dfb   $34
         dfb   $cc
         dfb   $00
         dfb   $20
         dfb   $34
         dfb   $16
         dfb   $20
         dfb   $80
         dfb   $1d
         dfb   $24
         dfb   $3b
         dfb   $00
         dfb   $4c
         dfb   $e2
         dfb   $15
         dfb   $14
         dfb   $fd
         dfb   $fe
         dfb   $6c
         dfb   $3b
         dfb   $38
         dfb   $00
         dfb   $20
         dfb   $c4
         dfb   $14
         dfb   $20
         dfb   $b4
         dfb   $16
         dfb   $20
         dfb   $80
         dfb   $1d
         dfb   $33
         dfb   $f8
         dfb   $08
         dfb   $11
         asc   '2)81'
         dfb   $00
         dfb   $20
         dfb   $ee
         dfb   $15
         dfb   $20
         dfb   $80
         dfb   $1d
         dfb   $28
         dfb   $39
         dfb   $a3
         dfb   $38
         dfb   $01
         dfb   $0a
         dfb   $a5
         dfb   $03
         dfb   $4d
         dfb   $d6
         dfb   $03
         asc   'J78%9'
         dfb   $11
         dfb   $3c
         dfb   $00
         asc   ')q(q'
         dfb   $00
         dfb   $20
         dfb   $c2
         dfb   $16
         dfb   $4c
         dfb   $42
         dfb   $13
         dfb   $20
         dfb   $80
         dfb   $1d
         dfb   $e8
         dfb   $11
         dfb   $3c
         dfb   $00
         dfb   $32
         dfb   $b0
         dfb   $71
         dfb   $e0
         dfb   $71
         dfb   $22
         dfb   $00
         dfb   $6c
         dfb   $08
         dfb   $00
         dfb   $14
         dfb   $cd
         dfb   $fe
         dfb   $00
         dfb   $20
         dfb   $87
         dfb   $15
         dfb   $20
         dfb   $80
         dfb   $1d
         asc   '):(;'
         dfb   $eb
         dfb   $00
         dfb   $20
         dfb   $c4
         dfb   $14
         dfb   $20
         dfb   $80
         dfb   $1d
         asc   ')8*9'
         dfb   $f8
         dfb   $28
         dfb   $b9
         dfb   $f8
         dfb   $00
         dfb   $20
         dfb   $b4
         dfb   $16
         dfb   $20
         dfb   $80
         dfb   $1d
         dfb   $01
         dfb   $ba
         dfb   $10
         dfb   $1d
         dfb   $14
         dfb   $3f
         dfb   $10
         dfb   $80
         dfb   $03
         dfb   $00
         dfb   $20
         dfb   $8e
         dfb   $fd
         dfb   $20
         dfb   $5d
         dfb   $18
         dfb   $20
         dfb   $6f
         dfb   $18
         dfb   $20
         dfb   $80
         dfb   $1d
         dfb   $27
         dfb   $b5
         dfb   $3b
         dfb   $19
         dfb   $9e
         dfb   $1b
         dfb   $00
         dfb   $20
         dfb   $e8
         dfb   $13
         dfb   $20
         dfb   $80
         dfb   $1d
         dfb   $26
         dfb   $b7
         dfb   $3b
         dfb   $00
         dfb   $20
         dfb   $e8
         dfb   $13
         dfb   $4c
         dfb   $42
         dfb   $13
         dfb   $6c
         dfb   $3b
         dfb   $00
         dfb   $20
         dfb   $c4
         dfb   $14
         dfb   $20
         dfb   $80
         dfb   $1d
         dfb   $29
         dfb   $d7
         dfb   $03
         dfb   $08
         dfb   $38
         dfb   $6c
         dfb   $07
         dfb   $01
         dfb   $2b
         dfb   $db
         dfb   $03
         dfb   $04
         dfb   $10
         dfb   $bc
         dfb   $14
         dfb   $3f
         dfb   $3b
         dfb   $eb
         dfb   $00
         dfb   $20
         dfb   $c4
         dfb   $14
         dfb   $20
         dfb   $80
         dfb   $1d
         dfb   $29
         dfb   $b8
         dfb   $3a
         dfb   $6c
         dfb   $3b
         dfb   $00
         dfb   $20
         dfb   $c4
         dfb   $14
         dfb   $20
         dfb   $80
         dfb   $1d
         dfb   $28
         dfb   $d9
         dfb   $02
         dfb   $01
         dfb   $aa
         dfb   $31
         dfb   $2a
         dfb   $32
         dfb   $f2
         dfb   $00
         dfb   $20
         dfb   $ee
         dfb   $15
         dfb   $4c
         dfb   $42
         dfb   $13
         dfb   $00
         dfb   $20
         dfb   $87
         dfb   $15
         dfb   $20
         dfb   $6a
         dfb   $17
         dfb   $20
         dfb   $81
         dfb   $13
         dfb   $20
         dfb   $80
         dfb   $1d
         dfb   $eb
         dfb   $00
         dfb   $20
         dfb   $54
         dfb   $1b
         dfb   $4c
         dfb   $59
         dfb   $17
         dfb   $20
         dfb   $80
         dfb   $1d
         dfb   $13
         dfb   $8d
         dfb   $00
         dfb   $1a
         dfb   $00
         dfb   $08
         dfb   $12
         dfb   $81
         dfb   $00
         dfb   $29
         dfb   $34
         dfb   $d7
         dfb   $03
         dfb   $24
         dfb   $28
         dfb   $db
         dfb   $02
         dfb   $20
         dfb   $4a
         dfb   $06
         dfb   $24
         dfb   $31
         dfb   $49
         dfb   $d3
         dfb   $07
         dfb   $0c
         dfb   $eb
         dfb   $00
         dfb   $ad
         dfb   $00
         dfb   $c0
         dfb   $c9
         dfb   $83
         dfb   $d0
         dfb   $da
         dfb   $4c
         dfb   $54
         dfb   $1b
         dfb   $d1
         dfb   $06
         dfb   $e9
         dfb   $21
         dfb   $d2
         dfb   $06
         dfb   $e5
         dfb   $24
         dfb   $39
         dfb   $e9
         dfb   $01
         dfb   $ce
         dfb   $00
         dfb   $20
         dfb   $87
         dfb   $15
         dfb   $4c
         dfb   $6a
         dfb   $17
         dfb   $29
         dfb   $32
         dfb   $00
         dfb   $20
         dfb   $80
         dfb   $1d
         dfb   $13
         dfb   $8d
         dfb   $00
         dfb   $89
         dfb   $d3
         dfb   $07
         dfb   $fc
         dfb   $e9
         dfb   $00
         dfb   $60
         dfb   $1a
         dfb   $00
         dfb   $08
         dfb   $4a
         dfb   $07
         dfb   $04
         dfb   $10
         dfb   $2f
         dfb   $13
         dfb   $3f
         dfb   $19
         dfb   $b9
         dfb   $1b
         dfb   $00
         dfb   $20
         dfb   $eb
         dfb   $13
         dfb   $20
         dfb   $06
         dfb   $0c
         dfb   $c9
         dfb   $d3
         dfb   $66
         dfb   $63
         dfb   $20
         dfb   $87
         dfb   $15
         dfb   $a9
         dfb   $ff
         dfb   $85
         dfb   $69
         dfb   $d0
         dfb   $00
         dfb   $20
         dfb   $6a
         dfb   $17
         dfb   $20
         dfb   $80
         dfb   $1d
         dfb   $11
         dfb   $00
         dfb   $02
         dfb   $29
         dfb   $d4
         dfb   $06
         dfb   $04
         dfb   $49
         dfb   $51
         dfb   $01
         dfb   $f8
         dfb   $4a
         dfb   $06
         dfb   $03
         dfb   $51
         dfb   $01
         dfb   $fa
         asc   '!:BQ'
         dfb   $d3
         dfb   $07
         dfb   $fb
         dfb   $19
         dfb   $00
         dfb   $02
         dfb   $11
         dfb   $6c
         dfb   $00
         asc   '$q*q'
         dfb   $00
         dfb   $20
         dfb   $d7
         dfb   $19
         dfb   $24
         dfb   $63
         dfb   $10
         dfb   $0c
         dfb   $20
         dfb   $06
         dfb   $0c
         dfb   $c9
         dfb   $83
         dfb   $d0
         dfb   $03
         dfb   $4c
         dfb   $42
         dfb   $13
         dfb   $c9
         dfb   $9c
         dfb   $20
         dfb   $80
         dfb   $1d
         dfb   $11
         dfb   $6c
         dfb   $00
         dfb   $61
         dfb   $39
         dfb   $e9
         dfb   $61
         dfb   $3a
         dfb   $00
         dfb   $90
         dfb   $b6
         dfb   $20
         dfb   $a9
         dfb   $17
         dfb   $20
         dfb   $80
         dfb   $1d
         dfb   $2a
         dfb   $1a
         dfb   $00
         dfb   $02
         dfb   $ba
         dfb   $a9
         dfb   $34
         dfb   $00
         dfb   $20
         dfb   $9b
         dfb   $19
         dfb   $20
         dfb   $80
         dfb   $1d
         dfb   $24
         dfb   $39
         dfb   $01
         dfb   $9d
         dfb   $10
         dfb   $ab
         dfb   $18
         dfb   $00
         dfb   $20
         dfb   $49
         dfb   $18
         dfb   $20
         dfb   $62
         dfb   $18
         dfb   $20
         dfb   $6f
         dfb   $18
         dfb   $4c
         dfb   $42
         dfb   $13
         dfb   $a9
         dfb   $84
         dfb   $4c
         dfb   $ed
         dfb   $fd
         dfb   $20
         dfb   $49
         dfb   $18
         dfb   $a0
         dfb   $00
         dfb   $b1
         dfb   $04
         dfb   $10
         dfb   $06
         dfb   $20
         dfb   $ed
         dfb   $fd
         dfb   $c8
         dfb   $10
         dfb   $f6
         dfb   $a9
         dfb   $a0
         dfb   $20
         dfb   $ed
         dfb   $fd
         dfb   $a0
         dfb   $00
         dfb   $b1
         dfb   $00
         dfb   $10
         dfb   $06
         dfb   $20
         dfb   $ed
         dfb   $fd
         dfb   $c8
         dfb   $10
         dfb   $f6
         dfb   $60
         dfb   $a9
         dfb   $ac
         dfb   $20
         asc   "m})D"
         dfb   $20
         dfb   $ed
         dfb   $fd
         dfb   $a5
         dfb   $59
         dfb   $09
         dfb   $b0
         dfb   $20
         asc   "m}),"
         dfb   $20
         asc   "m})S"
         dfb   $20
         dfb   $ed
         dfb   $fd
         dfb   $a5
         dfb   $58
         dfb   $09
         dfb   $b0
         dfb   $20
         dfb   $ed
         dfb   $fd
         dfb   $4c
         dfb   $8e
         dfb   $fd
         dfb   $bd
         dfb   $d0
         dfb   $18
         dfb   $85
         dfb   $04
         dfb   $e8
         dfb   $bd
         dfb   $d0
         dfb   $18
         dfb   $85
         dfb   $05
         dfb   $20
         dfb   $4e
         dfb   $18
         dfb   $4c
         dfb   $8e
         dfb   $fd
         dfb   $20
         dfb   $4e
         dfb   $18
         dfb   $4c
         dfb   $6f
         dfb   $18
         asc   "CATALOG"
         dfb   $00
         asc   "OPEN"
         dfb   $00
         asc   "WRITE"
         dfb   $00
         asc   "CLOSE"
         dfb   $00
         asc   "DELETE"
         dfb   $00
         asc   "READ"
         dfb   $00
         dfb   $b3
         dfb   $18
         dfb   $b8
         dfb   $18
         dfb   $be
         dfb   $18
         dfb   $c4
         dfb   $18
         DS \

TITLE_PIXELS         
         dfb   $2e
         dfb   $08
         dfb   $30
         dfb   $19
         dfb   $60
         dfb   $10
         dfb   $61
         dfb   $13
         dfb   $61
         dfb   $16
         dfb   $6a
         dfb   $1a
         dfb   $b4
         dfb   $1f
         dfb   $b6
         dfb   $15
         dfb   $b8
         dfb   $10
         dfb   $96
         dfb   $10
         dfb   $b7
         dfb   $11
         dfb   $b8
         dfb   $1a
         dfb   $99
         dfb   $11
         dfb   $b9
         dfb   $11
         dfb   $2c
         dfb   $03
         dfb   $6b
         dfb   $21
         dfb   $ba
         dfb   $19
         dfb   $16
         dfb   $02
         dfb   $ba
         dfb   $1a
         dfb   $ba
         dfb   $1b
         dfb   $7e
         dfb   $10
         dfb   $bb
         dfb   $10
         dfb   $61
         dfb   $15
         dfb   $00
         dfb   $01
         dfb   $38
         dfb   $10
         dfb   $20
         dfb   $18
         dfb   $64
         dfb   $18
         dfb   $22
         dfb   $16
         dfb   $4b
         dfb   $18
         dfb   $05
         dfb   $08
         dfb   $38
         dfb   $11
         dfb   $5c
         dfb   $23
         dfb   $6c
         dfb   $1b
         dfb   $61
         dfb   $14
         dfb   $80
         dfb   $1a
         dfb   $84
         dfb   $11
         dfb   $b6
         dfb   $12
         dfb   $36
         dfb   $11
         dfb   $bc
         dfb   $10
         dfb   $bc
         dfb   $1b
         dfb   $35
         dfb   $1a
         dfb   $62
         dfb   $15
         dfb   $24
         dfb   $12
         dfb   $35
         dfb   $19
         dfb   $20
         dfb   $16
         dfb   $31
         dfb   $01
         dfb   $52
         dfb   $11
         dfb   $1e
         dfb   $07
         dfb   $16
         dfb   $05
         dfb   $11
         asc   '#Z#i j"l'
         dfb   $15
         dfb   $7c
         dfb   $11
         dfb   $80
         dfb   $13
         dfb   $80
         dfb   $1d
         dfb   $49
         dfb   $10
         dfb   $5d
         dfb   $1a
         dfb   $6e
         dfb   $12
         dfb   $32
         dfb   $04
         dfb   $ba
         dfb   $11
         dfb   $2b
         dfb   $04
         dfb   $5f
         dfb   $10
         dfb   $7b
         dfb   $11
         dfb   $bd
         dfb   $1c
         dfb   $bd
         dfb   $1d
         dfb   $16
         dfb   $14
         dfb   $bd
         dfb   $1e
         dfb   $be
         dfb   $19
         dfb   $be
         dfb   $1f
         dfb   $bf
         dfb   $1a
         dfb   $4f
         dfb   $23
         dfb   $80
         dfb   $16
         dfb   $33
         dfb   $00
         dfb   $c0
         dfb   $11
         dfb   $c0
         dfb   $19
         dfb   $c0
         dfb   $1a
         dfb   $5a
         dfb   $20
         dfb   $7f
         dfb   $1e
         dfb   $94
         dfb   $1b
         dfb   $c0
         dfb   $1f
         dfb   $50
         dfb   $11
         dfb   $3c
         dfb   $1b
         asc   'E#~"2'
         dfb   $11
         dfb   $80
         dfb   $20
         dfb   $b7
         dfb   $10
         dfb   $08
         dfb   $00
         dfb   $2e
         dfb   $05
         dfb   $39
         dfb   $19
         dfb   $1e
         dfb   $02
         dfb   $20
         dfb   $08
         dfb   $2d
         dfb   $02
         dfb   $2d
         dfb   $23
         dfb   $17
         dfb   $14
         dfb   $32
         dfb   $09
         dfb   $19
         dfb   $04
         dfb   $36
         dfb   $19
         dfb   $3a
         dfb   $1b
         dfb   $4a
         dfb   $20
         dfb   $60
         dfb   $15
         dfb   $62
         dfb   $14
         dfb   $62
         dfb   $17
         dfb   $68
         dfb   $20
         dfb   $b2
         dfb   $21
         dfb   $5c
         dfb   $18
         dfb   $30
         dfb   $13
         dfb   $5d
         dfb   $23
         dfb   $5d
         dfb   $12
         dfb   $2e
         dfb   $15
         dfb   $5d
         dfb   $17
         dfb   $20
         dfb   $06
         dfb   $92
         dfb   $1f
         dfb   $37
         dfb   $1a
         dfb   $b3
         dfb   $1f
         dfb   $3a
         dfb   $1e
         dfb   $2c
         dfb   $1a
         dfb   $06
         dfb   $09
         dfb   $14
         dfb   $17
         dfb   $15
         dfb   $1a
         dfb   $2b
         dfb   $00
         dfb   $6b
         dfb   $1d
         dfb   $6d
         dfb   $10
         dfb   $97
         dfb   $12
         dfb   $a0
         dfb   $23
         dfb   $2b
         dfb   $1f
         dfb   $6d
         dfb   $1c
         dfb   $b6
         dfb   $1a
         dfb   $b7
         dfb   $12
         dfb   $12
         dfb   $1e
         dfb   $47
         dfb   $23
         dfb   $b8
         dfb   $19
         dfb   $2e
         dfb   $14
         dfb   $00
         dfb   $00
         dfb   $b9
         dfb   $1a
         dfb   $20
         dfb   $19
         dfb   $bc
         dfb   $1c
         dfb   $b9
         dfb   $1b
         dfb   $bd
         dfb   $10
         dfb   $c0
         dfb   $20
         dfb   $b2
         dfb   $1c
         dfb   $b1
         dfb   $21
         dfb   $1f
         dfb   $1a
         dfb   $b2
         dfb   $20
         dfb   $4b
         dfb   $10
         dfb   $5b
         dfb   $1e
         dfb   $b6
         dfb   $19
         dfb   $c0
         dfb   $22
         dfb   $1a
         dfb   $11
         dfb   $be
         dfb   $11
         dfb   $05
         dfb   $03
         dfb   $46
         dfb   $23
         dfb   $c1
         dfb   $1a
         dfb   $c1
         dfb   $20
         dfb   $c1
         dfb   $23
         dfb   $39
         dfb   $1e
         dfb   $3b
         dfb   $18
         dfb   $1c
         dfb   $04
         dfb   $95
         dfb   $15
         dfb   $c3
         dfb   $17
         dfb   $05
         dfb   $00
         dfb   $05
         dfb   $09
         dfb   $39
         dfb   $1d
         dfb   $39
         dfb   $22
         dfb   $c3
         dfb   $19
         dfb   $c3
         dfb   $22
         dfb   $b3
         dfb   $17
         dfb   $06
         dfb   $01
         dfb   $11
         dfb   $22
         dfb   $13
         dfb   $1e
         dfb   $04
         dfb   $01
         dfb   $2d
         dfb   $04
         dfb   $3a
         dfb   $22
         dfb   $3d
         dfb   $16
         dfb   $5b
         dfb   $21
         dfb   $7e
         dfb   $1b
         dfb   $9d
         dfb   $19
         asc   ':!;!'
         dfb   $96
         dfb   $1e
         dfb   $2f
         dfb   $15
         dfb   $1a
         dfb   $05
         dfb   $2c
         dfb   $1c
         dfb   $39
         dfb   $20
         dfb   $5f
         dfb   $15
         dfb   $6c
         dfb   $19
         dfb   $6e
         dfb   $18
         dfb   $7e
         dfb   $21
         dfb   $bf
         dfb   $11
         dfb   $3b
         dfb   $17
         dfb   $2b
         dfb   $1d
         dfb   $2c
         dfb   $07
         dfb   $96
         dfb   $12
         dfb   $c1
         dfb   $21
         dfb   $b4
         dfb   $12
         dfb   $c2
         dfb   $11
         dfb   $6c
         dfb   $12
         dfb   $6d
         dfb   $17
         dfb   $34
         dfb   $19
         dfb   $4b
         dfb   $13
         dfb   $96
         dfb   $19
         dfb   $2e
         dfb   $1d
         dfb   $3c
         dfb   $1e
         dfb   $16
         dfb   $13
         dfb   $4a
         dfb   $11
         dfb   $4b
         dfb   $1c
         dfb   $4e
         dfb   $11
         dfb   $62
         dfb   $13
         dfb   $96
         dfb   $15
         dfb   $20
         dfb   $09
         dfb   $12
         dfb   $20
         dfb   $95
         dfb   $1d
         dfb   $17
         dfb   $05
         dfb   $96
         dfb   $16
         dfb   $31
         dfb   $12
         dfb   $7f
         dfb   $18
         dfb   $9c
         dfb   $11
         dfb   $2b
         dfb   $23
         dfb   $b4
         dfb   $16
         dfb   $c0
         dfb   $10
         dfb   $11
         dfb   $21
         dfb   $4b
         dfb   $14
         dfb   $5e
         dfb   $17
         dfb   $97
         dfb   $23
         dfb   $5b
         dfb   $23
         dfb   $a5
         dfb   $23
         dfb   $7e
         dfb   $11
         dfb   $b5
         dfb   $1c
         dfb   $35
         dfb   $01
         dfb   $14
         dfb   $13
         dfb   $1e
         dfb   $06
         dfb   $3b
         dfb   $20
         dfb   $2b
         dfb   $01
         dfb   $4a
         dfb   $1d
         dfb   $b6
         dfb   $16
         dfb   $bf
         dfb   $19
         dfb   $6a
         dfb   $1b
         dfb   $c2
         dfb   $1a
         dfb   $14
         dfb   $11
         dfb   $94
         dfb   $1d
         dfb   $96
         dfb   $18
         dfb   $48
         dfb   $23
         dfb   $1c
         dfb   $1a
         dfb   $9c
         dfb   $22
         dfb   $c3
         dfb   $10
         dfb   $1e
         dfb   $03
         dfb   $b3
         dfb   $1e
         dfb   $80
         dfb   $1f
         dfb   $32
         dfb   $08
         dfb   $c3
         dfb   $23
         dfb   $c4
         dfb   $11
         dfb   $2f
         dfb   $09
         dfb   $31
         dfb   $13
         dfb   $21
         dfb   $1a
         dfb   $3b
         dfb   $1b
         dfb   $66
         dfb   $1b
         dfb   $30
         dfb   $09
         dfb   $c4
         dfb   $15
         dfb   $13
         dfb   $18
         dfb   $16
         dfb   $09
         dfb   $15
         dfb   $14
         dfb   $3c
         dfb   $1c
         dfb   $4b
         dfb   $1d
         dfb   $5f
         dfb   $16
         dfb   $a1
         dfb   $22
         dfb   $12
         dfb   $21
         dfb   $bf
         dfb   $1f
         dfb   $2c
         dfb   $1d
         dfb   $2f
         dfb   $04
         dfb   $4a
         dfb   $1a
         dfb   $80
         dfb   $11
         dfb   $c4
         dfb   $16
         dfb   $1f
         dfb   $05
         dfb   $23
         dfb   $12
         dfb   $30
         dfb   $11
         dfb   $b3
         dfb   $1d
         dfb   $3b
         dfb   $1e
         dfb   $3c
         dfb   $16
         dfb   $12
         dfb   $1f
         dfb   $32
         dfb   $12
         dfb   $16
         dfb   $11
         dfb   $39
         dfb   $1f
         dfb   $5d
         dfb   $21
         dfb   $15
         dfb   $01
         dfb   $20
         dfb   $00
         dfb   $5e
         dfb   $1c
         dfb   $6a
         dfb   $1c
         dfb   $81
         dfb   $11
         dfb   $94
         dfb   $19
         dfb   $15
         dfb   $1c
         dfb   $5d
         dfb   $11
         dfb   $1e
         dfb   $04
         dfb   $19
         dfb   $19
         dfb   $20
         dfb   $11
         dfb   $5f
         dfb   $11
         dfb   $14
         dfb   $23
         dfb   $92
         dfb   $22
         dfb   $33
         dfb   $01
         dfb   $3c
         dfb   $1a
         dfb   $5c
         dfb   $20
         dfb   $be
         dfb   $1e
         dfb   $c4
         dfb   $17
         dfb   $9e
         dfb   $23
         dfb   $7f
         dfb   $17
         dfb   $c4
         dfb   $18
         dfb   $32
         dfb   $1a
         dfb   $9f
         dfb   $1a
         dfb   $19
         dfb   $05
         dfb   $16
         dfb   $07
         dfb   $80
         dfb   $10
         dfb   $1b
         dfb   $11
         dfb   $96
         dfb   $1d
         dfb   $5b
         dfb   $20
         dfb   $a3
         dfb   $22
         dfb   $a8
         dfb   $11
         dfb   $a5
         dfb   $22
         dfb   $37
         dfb   $11
         dfb   $38
         dfb   $19
         dfb   $15
         dfb   $08
         dfb   $1b
         dfb   $1a
         dfb   $35
         dfb   $10
         dfb   $4c
         dfb   $19
         dfb   $17
         dfb   $04
         dfb   $08
         dfb   $01
         dfb   $15
         dfb   $11
         dfb   $2c
         dfb   $21
         dfb   $49
         dfb   $1b
         dfb   $39
         dfb   $10
         dfb   $22
         dfb   $1a
         dfb   $4c
         dfb   $10
         dfb   $4d
         dfb   $15
         dfb   $63
         dfb   $16
         dfb   $13
         dfb   $1d
         dfb   $3d
         dfb   $19
         dfb   $65
         dfb   $1b
         dfb   $6b
         dfb   $1e
         dfb   $0a
         dfb   $01
         dfb   $6c
         dfb   $20
         dfb   $b5
         dfb   $19
         dfb   $bf
         dfb   $1e
         dfb   $5c
         dfb   $1c
         dfb   $c1
         dfb   $22
         dfb   $1c
         dfb   $11
         dfb   $23
         dfb   $11
         dfb   $b4
         dfb   $1d
         dfb   $21
         dfb   $12
         dfb   $3a
         dfb   $14
         dfb   $4a
         dfb   $15
         dfb   $4a
         dfb   $17
         dfb   $86
         dfb   $11
         dfb   $68
         dfb   $21
         dfb   $04
         dfb   $06
         dfb   $49
         dfb   $20
         dfb   $9f
         dfb   $10
         dfb   $bb
         dfb   $1d
         dfb   $c2
         dfb   $19
         dfb   $4f
         dfb   $22
         dfb   $c3
         dfb   $18
         dfb   $1f
         dfb   $09
         dfb   $95
         dfb   $18
         dfb   $15
         dfb   $18
         dfb   $3c
         dfb   $12
         dfb   $5d
         dfb   $1c
         dfb   $64
         dfb   $19
         dfb   $65
         dfb   $19
         dfb   $6f
         dfb   $12
         dfb   $2d
         dfb   $1f
         dfb   $05
         dfb   $01
         dfb   $4e
         dfb   $14
         dfb   $15
         dfb   $03
         dfb   $4b
         dfb   $17
         dfb   $2b
         dfb   $22
         dfb   $49
         dfb   $11
         dfb   $23
         dfb   $16
         dfb   $5b
         dfb   $1f
         dfb   $20
         dfb   $15
         dfb   $5d
         dfb   $14
         dfb   $5e
         dfb   $12
         dfb   $66
         dfb   $1c
         dfb   $06
         dfb   $06
         dfb   $32
         dfb   $05
         dfb   $68
         dfb   $1c
         dfb   $82
         dfb   $19
         dfb   $95
         dfb   $22
         dfb   $20
         dfb   $03
         dfb   $1f
         dfb   $10
         dfb   $97
         dfb   $19
         dfb   $6c
         dfb   $1a
         dfb   $8a
         dfb   $10
         dfb   $5c
         dfb   $16
         dfb   $97
         dfb   $1a
         dfb   $98
         dfb   $22
         dfb   $9d
         dfb   $23
         dfb   $82
         dfb   $12
         dfb   $4c
         dfb   $1a
         dfb   $23
         dfb   $19
         dfb   $38
         dfb   $1f
         dfb   $9f
         dfb   $11
         dfb   $83
         dfb   $10
         dfb   $a4
         dfb   $11
         dfb   $4d
         dfb   $14
         dfb   $1d
         dfb   $1a
         dfb   $2f
         dfb   $18
         dfb   $4b
         dfb   $15
         dfb   $b2
         dfb   $1b
         asc   ',"k#'
         dfb   $b2
         dfb   $22
         dfb   $65
         dfb   $1a
         dfb   $2b
         dfb   $21
         dfb   $b3
         dfb   $23
         dfb   $b4
         dfb   $18
         dfb   $23
         dfb   $18
         dfb   $b4
         dfb   $20
         dfb   $5d
         dfb   $1e
         dfb   $82
         dfb   $15
         dfb   $1d
         dfb   $19
         dfb   $14
         dfb   $20
         dfb   $17
         dfb   $12
         dfb   $23
         dfb   $14
         dfb   $21
         dfb   $16
         dfb   $2f
         dfb   $1a
         dfb   $31
         dfb   $11
         dfb   $48
         dfb   $11
         dfb   $48
         dfb   $21
         dfb   $4a
         dfb   $16
         dfb   $98
         dfb   $1a
         dfb   $b4
         dfb   $22
         dfb   $b5
         dfb   $11
         dfb   $b6
         dfb   $17
         dfb   $7a
         dfb   $11
         dfb   $4c
         dfb   $13
         dfb   $b5
         dfb   $1e
         dfb   $63
         dfb   $17
         dfb   $33
         dfb   $11
         dfb   $2c
         dfb   $02
         dfb   $16
         dfb   $04
         dfb   $6a
         dfb   $1f
         dfb   $80
         dfb   $1c
         dfb   $5c
         dfb   $22
         dfb   $94
         dfb   $23
         dfb   $81
         dfb   $1e
         dfb   $2f
         dfb   $17
         dfb   $2d
         dfb   $06
         dfb   $2e
         dfb   $1b
         dfb   $23
         dfb   $10
         dfb   $2c
         dfb   $01
         dfb   $3b
         dfb   $15
         dfb   $24
         dfb   $14
         dfb   $20
         dfb   $05
         dfb   $18
         dfb   $1a
         dfb   $5d
         dfb   $18
         dfb   $20
         dfb   $10
         dfb   $5e
         dfb   $1d
         dfb   $2d
         dfb   $1b
         dfb   $7f
         dfb   $19
         dfb   $9d
         dfb   $1a
         dfb   $a5
         dfb   $11
         dfb   $4e
         dfb   $22
         dfb   $60
         dfb   $11
         dfb   $b6
         dfb   $18
         dfb   $b8
         dfb   $11
         dfb   $bb
         dfb   $19
         dfb   $bc
         dfb   $19
         dfb   $bd
         dfb   $11
         dfb   $95
         dfb   $10
         dfb   $7f
         dfb   $1f
         dfb   $83
         dfb   $12
         dfb   $93
         dfb   $23
         dfb   $33
         dfb   $08
         dfb   $34
         dfb   $08
         dfb   $18
         dfb   $11
         dfb   $3b
         dfb   $16
         dfb   $3a
         dfb   $1d
         dfb   $93
         dfb   $1b
         dfb   $a1
         dfb   $11
         dfb   $a4
         dfb   $10
         dfb   $1d
         dfb   $10
         dfb   $17
         dfb   $03
         dfb   $2e
         dfb   $1e
         dfb   $48
         dfb   $10
         dfb   $4d
         dfb   $13
         dfb   $13
         dfb   $1a
         dfb   $04
         dfb   $09
         dfb   $15
         dfb   $04
         dfb   $95
         dfb   $1a
         dfb   $81
         dfb   $13
         dfb   $b3
         dfb   $18
         dfb   $5c
         dfb   $17
         dfb   $4a
         dfb   $10
         dfb   $3b
         dfb   $22
         dfb   $1e
         dfb   $08
         dfb   $13
         dfb   $1c
         dfb   $14
         dfb   $15
         dfb   $1f
         dfb   $08
         dfb   $30
         dfb   $16
         dfb   $3a
         dfb   $1f
         dfb   $7f
         dfb   $20
         dfb   $93
         dfb   $20
         dfb   $b3
         dfb   $1a
         dfb   $b3
         dfb   $22
         dfb   $5c
         dfb   $19
         dfb   $b5
         dfb   $14
         dfb   $80
         dfb   $12
         dfb   $45
         dfb   $22
         dfb   $b7
         dfb   $19
         dfb   $bd
         dfb   $1a
         dfb   $bd
         dfb   $1f
         dfb   $bf
         dfb   $10
         dfb   $bf
         dfb   $20
         dfb   $6c
         dfb   $1e
         dfb   $c1
         dfb   $10
         dfb   $30
         dfb   $1a
         dfb   $c2
         dfb   $21
         dfb   $5f
         dfb   $14
         dfb   $5f
         dfb   $19
         dfb   $17
         dfb   $19
         dfb   $c2
         dfb   $22
         dfb   $c2
         dfb   $23
         dfb   $15
         dfb   $17
         dfb   $22
         dfb   $17
         dfb   $b7
         dfb   $1a
         dfb   $c4
         dfb   $19
         dfb   $1e
         dfb   $19
         dfb   $16
         dfb   $17
         dfb   $13
         dfb   $1b
         dfb   $6c
         dfb   $1d
         dfb   $48
         dfb   $1f
         dfb   $88
         dfb   $10
         dfb   $1b
         dfb   $05
         dfb   $b2
         dfb   $1d
         dfb   $bb
         dfb   $1c
         dfb   $48
         dfb   $20
         dfb   $bc
         dfb   $1e
         dfb   $c4
         dfb   $1a
         dfb   $c4
         dfb   $23
         dfb   $22
         dfb   $19
         dfb   $1b
         dfb   $19
         dfb   $2c
         dfb   $23
         dfb   $3d
         dfb   $13
         dfb   $2b
         dfb   $03
         dfb   $3d
         dfb   $15
         dfb   $49
         dfb   $21
         dfb   $33
         dfb   $12
         dfb   $4c
         dfb   $1c
         dfb   $4d
         dfb   $17
         dfb   $4f
         dfb   $11
         dfb   $64
         dfb   $17
         dfb   $4a
         dfb   $1f
         dfb   $39
         dfb   $1a
         dfb   $04
         dfb   $07
         dfb   $39
         dfb   $11
         dfb   $16
         dfb   $01
         dfb   $6b
         dfb   $1a
         dfb   $87
         dfb   $11
         dfb   $2e
         dfb   $19
         dfb   $94
         dfb   $18
         dfb   $6e
         dfb   $16
         dfb   $a0
         dfb   $22
         dfb   $b1
         dfb   $1f
         dfb   $05
         dfb   $07
         dfb   $b4
         dfb   $21
         dfb   $1e
         dfb   $10
         dfb   $13
         dfb   $17
         dfb   $3c
         dfb   $15
         dfb   $b5
         dfb   $15
         dfb   $97
         dfb   $22
         dfb   $b7
         dfb   $13
         dfb   $97
         dfb   $17
         dfb   $11
         dfb   $20
         dfb   $15
         dfb   $02
         dfb   $3a
         dfb   $1c
         dfb   $46
         dfb   $22
         dfb   $17
         dfb   $02
         dfb   $62
         dfb   $16
         dfb   $7e
         dfb   $1e
         dfb   $6d
         dfb   $13
         dfb   $7f
         dfb   $1d
         dfb   $81
         dfb   $18
         dfb   $6f
         dfb   $11
         dfb   $94
         dfb   $1e
         dfb   $2b
         dfb   $1c
         dfb   $5d
         dfb   $10
         dfb   $5e
         dfb   $13
         dfb   $5f
         dfb   $12
         dfb   $21
         dfb   $19
         dfb   $6a
         dfb   $1e
         dfb   $4b
         dfb   $11
         dfb   $6d
         dfb   $12
         dfb   $94
         dfb   $1a
         dfb   $99
         dfb   $19
         dfb   $9b
         dfb   $11
         dfb   $9f
         dfb   $23
         dfb   $a0
         dfb   $10
         dfb   $a4
         asc   '#H";'
         dfb   $1c
         dfb   $4c
         dfb   $18
         dfb   $16
         dfb   $03
         dfb   $4b
         dfb   $22
         dfb   $82
         dfb   $13
         dfb   $9f
         dfb   $19
         dfb   $6b
         dfb   $15
         dfb   $6e
         dfb   $14
         dfb   $82
         dfb   $11
         dfb   $1f
         dfb   $07
         dfb   $2c
         dfb   $06
         dfb   $65
         dfb   $1c
         dfb   $16
         dfb   $10
         dfb   $1d
         dfb   $05
         dfb   $39
         dfb   $1b
         dfb   $68
         dfb   $1d
         dfb   $6b
         dfb   $16
         dfb   $81
         dfb   $10
         dfb   $84
         dfb   $10
         dfb   $7d
         dfb   $20
         dfb   $94
         dfb   $17
         dfb   $14
         dfb   $1a
         dfb   $17
         dfb   $06
         dfb   $32
         dfb   $19
         dfb   $3a
         dfb   $12
         dfb   $4f
         dfb   $10
         dfb   $19
         dfb   $10
         dfb   $4e
         dfb   $12
         dfb   $49
         dfb   $23
         dfb   $2d
         dfb   $03
         dfb   $3b
         dfb   $1f
         dfb   $3d
         dfb   $14
         dfb   $6d
         dfb   $15
         dfb   $6d
         dfb   $1d
         dfb   $1c
         dfb   $10
         dfb   $6c
         dfb   $1f
         dfb   $13
         dfb   $22
         dfb   $6e
         dfb   $13
         dfb   $1f
         dfb   $19
         dfb   $7f
         asc   '#-!["L'
         dfb   $12
         dfb   $93
         dfb   $1c
         dfb   $95
         dfb   $16
         dfb   $30
         dfb   $00
         dfb   $30
         dfb   $01
         dfb   $95
         dfb   $23
         dfb   $1d
         dfb   $04
         dfb   $19
         dfb   $11
         dfb   $2a
         dfb   $1f
         dfb   $7f
         dfb   $1b
         dfb   $7f
         dfb   $22
         dfb   $15
         dfb   $07
         dfb   $85
         dfb   $11
         dfb   $86
         dfb   $10
         dfb   $b1
         dfb   $22
         dfb   $13
         dfb   $21
         dfb   $35
         dfb   $09
         dfb   $4b
         dfb   $12
         dfb   $94
         dfb   $15
         dfb   $49
         dfb   $1e
         dfb   $5b
         dfb   $1b
         dfb   $20
         dfb   $07
         dfb   $a2
         dfb   $23
         dfb   $b2
         dfb   $1e
         dfb   $39
         dfb   $23
         dfb   $11
         dfb   $1f
         dfb   $5d
         dfb   $19
         dfb   $69
         dfb   $23
         dfb   $81
         dfb   $16
         dfb   $82
         dfb   $14
         dfb   $4b
         dfb   $19
         dfb   $95
         dfb   $21
         dfb   $14
         dfb   $18
         dfb   $b5
         dfb   $10
         dfb   $18
         dfb   $04
         dfb   $6d
         dfb   $14
         dfb   $b5
         dfb   $16
         dfb   $4b
         dfb   $1b
         dfb   $80
         dfb   $22
         dfb   $15
         dfb   $13
         dfb   $6c
         dfb   $16
         dfb   $12
         dfb   $23
         dfb   $82
         dfb   $18
         dfb   $9e
         dfb   $19
         dfb   $a2
         dfb   $11
         dfb   $12
         dfb   $1d
         dfb   $15
         dfb   $1e
         dfb   $4a
         dfb   $1b
         dfb   $bb
         dfb   $1a
         dfb   $a0
         dfb   $1a
         dfb   $83
         dfb   $13
         dfb   $2e
         dfb   $18
         dfb   $b9
         dfb   $10
         dfb   $bc
         dfb   $11
         dfb   $bd
         dfb   $19
         dfb   $6d
         dfb   $19
         dfb   $5d
         dfb   $15
         dfb   $7e
         dfb   $1a
         dfb   $be
         dfb   $10
         dfb   $be
         dfb   $1d
         dfb   $be
         dfb   $20
         dfb   $c0
         dfb   $21
         dfb   $31
         dfb   $14
         dfb   $c3
         dfb   $16
         dfb   $c4
         dfb   $12
         dfb   $3a
         dfb   $23
         dfb   $5c
         dfb   $15
         dfb   $c5
         dfb   $10
         dfb   $4a
         dfb   $18
         dfb   $65
         dfb   $18
         dfb   $c5
         dfb   $11
         dfb   $bc
         dfb   $1a
         dfb   $6f
         dfb   $10
         dfb   $c4
         dfb   $10
         dfb   $81
         dfb   $15
         dfb   $5e
         dfb   $14
         dfb   $9a
         dfb   $1a
         dfb   $b3
         dfb   $16
         dfb   $c5
         dfb   $12
         dfb   $30
         dfb   $14
         dfb   $30
         dfb   $15
         dfb   $03
         dfb   $00
         dfb   $2e
         dfb   $00
         dfb   $5c
         dfb   $1e
         dfb   $95
         dfb   $19
         dfb   $14
         dfb   $21
         dfb   $16
         dfb   $08
         dfb   $01
         dfb   $01
         dfb   $82
         dfb   $10
         dfb   $17
         dfb   $11
         dfb   $4d
         dfb   $22
         dfb   $93
         dfb   $1d
         dfb   $98
         dfb   $11
         dfb   $1e
         dfb   $05
         dfb   $5d
         dfb   $20
         dfb   $a2
         dfb   $22
         dfb   $1b
         dfb   $10
         dfb   $b3
         dfb   $1b
         dfb   $9b
         dfb   $22
         dfb   $b4
         dfb   $13
         dfb   $34
         dfb   $1a
         dfb   $94
         dfb   $1f
         dfb   $2b
         dfb   $1b
         dfb   $6c
         dfb   $18
         dfb   $6d
         dfb   $11
         dfb   $a2
         dfb   $10
         dfb   $b4
         dfb   $17
         dfb   $a1
         dfb   $1a
         dfb   $ba
         dfb   $10
         dfb   $1f
         dfb   $02
         dfb   $3c
         dfb   $19
         dfb   $c4
         dfb   $14
         dfb   $c5
         dfb   $13
         dfb   $5e
         dfb   $18
         dfb   $60
         dfb   $12
         dfb   $05
         dfb   $05
         dfb   $3c
         dfb   $17
         dfb   $7d
         dfb   $23
         dfb   $bb
         dfb   $1b
         dfb   $bc
         dfb   $1d
         dfb   $2d
         dfb   $09
         dfb   $b4
         dfb   $15
         dfb   $81
         dfb   $1b
         dfb   $c5
         dfb   $15
         dfb   $64
         dfb   $16
         dfb   $17
         dfb   $10
         dfb   $4d
         dfb   $19
         dfb   $95
         dfb   $17
         dfb   $87
         dfb   $10
         dfb   $b2
         dfb   $1a
         dfb   $c5
         dfb   $16
         dfb   $35
         dfb   $11
         dfb   $1f
         dfb   $03
         dfb   $4e
         dfb   $13
         dfb   $67
         dfb   $1e
         dfb   $13
         dfb   $15
         dfb   $c5
         dfb   $17
         dfb   $c5
         dfb   $18
         dfb   $2c
         dfb   $18
         dfb   $30
         dfb   $08
         dfb   $04
         dfb   $05
         dfb   $49
         dfb   $1d
         dfb   $c5
         dfb   $19
         dfb   $4c
         dfb   $1d
         dfb   $5a
         dfb   $22
         dfb   $12
         dfb   $1a
         dfb   $18
         dfb   $05
         dfb   $21
         dfb   $15
         dfb   $3d
         dfb   $18
         dfb   $85
         dfb   $10
         dfb   $22
         dfb   $10
         dfb   $9d
         dfb   $11
         dfb   $9f
         dfb   $22
         dfb   $31
         dfb   $09
         dfb   $80
         dfb   $15
         dfb   $21
         dfb   $17
         dfb   $bb
         dfb   $11
         dfb   $4b
         dfb   $1e
         dfb   $94
         dfb   $1c
         asc   '*"8#n'
         dfb   $10
         dfb   $17
         dfb   $13
         dfb   $b4
         dfb   $1a
         dfb   $16
         dfb   $06
         dfb   $22
         dfb   $11
         dfb   $20
         dfb   $17
         dfb   $3a
         dfb   $20
         dfb   $4c
         dfb   $11
         dfb   $8a
         dfb   $11
         dfb   $96
         dfb   $1c
         dfb   $c1
         dfb   $19
         dfb   $24
         dfb   $13
         dfb   $02
         dfb   $00
         dfb   $2c
         dfb   $1e
         dfb   $22
         dfb   $12
         dfb   $2d
         dfb   $00
         dfb   $c5
         dfb   $14
         dfb   $9e
         dfb   $10
         dfb   $5d
         dfb   $1f
         dfb   $15
         dfb   $06
         dfb   $2d
         dfb   $22
         dfb   $12
         dfb   $1c
         dfb   $95
         dfb   $20
         dfb   $32
         dfb   $01
         dfb   $b1
         dfb   $23
         dfb   $b4
         dfb   $23
         dfb   $6c
         dfb   $13
         dfb   $ba
         dfb   $1c
         dfb   $2d
         dfb   $1d
         dfb   $96
         dfb   $11
         dfb   $97
         dfb   $10
         dfb   $6a
         dfb   $21
         dfb   $6b
         dfb   $1f
         dfb   $6d
         dfb   $16
         dfb   $34
         dfb   $01
         dfb   $14
         dfb   $14
         dfb   $c1
         dfb   $11
         dfb   $13
         dfb   $1f
         dfb   $16
         dfb   $00
         dfb   $2c
         dfb   $09
         dfb   $9b
         dfb   $19
         dfb   $b3
         dfb   $21
         dfb   $31
         dfb   $05
         dfb   $37
         dfb   $10
         dfb   $5c
         dfb   $1f
         dfb   $b3
         dfb   $15
         dfb   $17
         dfb   $07
         dfb   $2d
         dfb   $01
         dfb   $c3
         dfb   $15
         dfb   $c3
         dfb   $1a
         dfb   $c5
         dfb   $1a
         dfb   $7c
         dfb   $10
         dfb   $c6
         dfb   $11
         dfb   $c2
         dfb   $10
         dfb   $c6
         dfb   $13
         dfb   $14
         dfb   $1e
         dfb   $1e
         dfb   $1a
         dfb   $2a
         dfb   $23
         dfb   $50
         dfb   $10
         dfb   $5f
         dfb   $13
         dfb   $7e
         dfb   $1d
         dfb   $7f
         dfb   $1c
         dfb   $9e
         dfb   $22
         dfb   $be
         dfb   $1a
         dfb   $c3
         dfb   $11
         dfb   $c6
         dfb   $14
         dfb   $2b
         dfb   $06
         dfb   $97
         dfb   $16
         dfb   $c6
         dfb   $15
         dfb   $c6
         dfb   $16
         dfb   $21
         dfb   $14
         dfb   $16
         dfb   $19
         dfb   $c6
         dfb   $17
         dfb   $63
         dfb   $15
         dfb   $c6
         dfb   $18
         dfb   $60
         dfb   $13
         dfb   $4c
         dfb   $1e
         dfb   $31
         dfb   $04
         dfb   $c6
         dfb   $19
         dfb   $16
         dfb   $16
         dfb   $3a
         dfb   $13
         dfb   $96
         dfb   $1a
         dfb   $6f
         dfb   $14
         dfb   $9d
         dfb   $22
         dfb   $c6
         dfb   $12
         dfb   $98
         dfb   $14
         dfb   $a1
         dfb   $19
         dfb   $69
         dfb   $21
         dfb   $14
         dfb   $10
         dfb   $89
         dfb   $11
         dfb   $5e
         dfb   $19
         dfb   $12
         dfb   $22
         dfb   $20
         dfb   $04
         dfb   $99
         dfb   $23
         dfb   $b6
         dfb   $13
         dfb   $c7
         dfb   $11
         dfb   $15
         dfb   $15
         dfb   $bf
         dfb   $21
         dfb   $c4
         dfb   $13
         dfb   $2b
         dfb   $1e
         dfb   $2c
         dfb   $20
         dfb   $4d
         dfb   $12
         dfb   $5e
         dfb   $16
         dfb   $69
         dfb   $1f
         dfb   $31
         dfb   $08
         dfb   $2b
         dfb   $02
         dfb   $c7
         dfb   $12
         dfb   $14
         dfb   $1c
         dfb   $4b
         dfb   $20
         dfb   $4e
         dfb   $10
         dfb   $b5
         dfb   $1b
         dfb   $15
         dfb   $12
         dfb   $7d
         dfb   $22
         dfb   $1e
         dfb   $09
         dfb   $93
         dfb   $1e
         dfb   $b5
         dfb   $18
         dfb   $c7
         dfb   $13
         dfb   $2b
         dfb   $05
         dfb   $6c
         dfb   $14
         dfb   $c7
         dfb   $14
         dfb   $1d
         dfb   $11
         dfb   $6d
         dfb   $1b
         dfb   $16
         dfb   $12
         dfb   $6a
         dfb   $23
         dfb   $96
         dfb   $23
         dfb   $94
         dfb   $22
         dfb   $9a
         dfb   $22
         dfb   $b9
         dfb   $19
         dfb   $2d
         dfb   $08
         dfb   $6b
         dfb   $19
         dfb   $06
         dfb   $03
         dfb   $22
         dfb   $15
         dfb   $64
         dfb   $1b
         dfb   $69
         dfb   $1e
         asc   'i"~ :'
         dfb   $1a
         dfb   $30
         dfb   $12
         dfb   $80
         dfb   $1b
         dfb   $94
         dfb   $16
         dfb   $06
         asc   07,'8 9'
         dfb   $1c
         dfb   $61
         dfb   $12
         dfb   $67
         dfb   $1f
         dfb   $20
         dfb   $1a
         dfb   $2a
         dfb   $20
         dfb   $34
         dfb   $00
         dfb   $34
         dfb   $10
         dfb   $51
         dfb   $11
         dfb   $6c
         dfb   $23
         dfb   $6f
         dfb   $13
         dfb   $81
         dfb   $14
         dfb   $6b
         dfb   $22
         dfb   $4c
         dfb   $17
         dfb   $63
         dfb   $19
         dfb   $2d
         dfb   $1a
         dfb   $5d
         dfb   $1b
         dfb   $81
         dfb   $19
         dfb   $17
         dfb   $1a
         dfb   $31
         dfb   $19
         dfb   $83
         dfb   $14
         dfb   $2e
         dfb   $1c
         dfb   $5e
         dfb   $1a
         dfb   $13
         dfb   $23
         dfb   $1e
         dfb   $01
         dfb   $23
         dfb   $15
         dfb   $13
         dfb   $19
         dfb   $2e
         dfb   $17
         dfb   $32
         dfb   $00
         dfb   $3d
         dfb   $17
         dfb   $4a
         dfb   $21
         dfb   $1f
         dfb   $06
         dfb   $4d
         dfb   $23
         dfb   $2b
         dfb   $08
         dfb   $5b
         dfb   $1d
         dfb   $2f
         dfb   $00
         dfb   $1f
         dfb   $11
         dfb   $2c
         dfb   $1b
         asc   '\!j }!'
         dfb   $7f
         dfb   $10
         dfb   $81
         dfb   $1a
         dfb   $1f
         dfb   $01
         dfb   $7d
         dfb   $10
         dfb   $92
         dfb   $21
         dfb   $2d
         dfb   $17
         dfb   $21
         dfb   $10
         dfb   $3b
         dfb   $19
         dfb   $06
         dfb   $08
         dfb   $4c
         dfb   $15
         dfb   $12
         dfb   $1b
         dfb   $13
         dfb   $16
         dfb   $3c
         dfb   $14
         dfb   $3b
         dfb   $1d
         dfb   $65
         dfb   $17
         dfb   $16
         dfb   $1a
         dfb   $07
         dfb   $01
         dfb   $2e
         dfb   $1a
         dfb   $0a
         dfb   $00
         dfb   $22
         dfb   $18
         dfb   $5d
         dfb   $16
         dfb   $6b
         dfb   $1c
         dfb   $7e
         dfb   $1c
         dfb   $88
         dfb   $11
         dfb   $93
         dfb   $22
         dfb   $95
         dfb   $13
         dfb   $97
         dfb   $13
         dfb   $98
         dfb   $12
         dfb   $99
         dfb   $10
         dfb   $24
         dfb   $11
         dfb   $1f
         dfb   $00
         dfb   $4d
         dfb   $11
         dfb   $51
         dfb   $10
         dfb   $49
         dfb   $22
         dfb   $1a
         dfb   $1a
         dfb   $21
         dfb   $18
         dfb   $67
         dfb   $1d
         dfb   $2f
         dfb   $08
         dfb   $6c
         dfb   $1c
         dfb   $7f
         dfb   $16
         dfb   $1c
         dfb   $05
         dfb   $3c
         dfb   $13
         dfb   $80
         dfb   $18
         dfb   $4b
         dfb   $16
         dfb   $01
         dfb   $00
         dfb   $2c
         dfb   $08
         dfb   $2d
         dfb   $07
         dfb   $82
         dfb   $17
         dfb   $14
         dfb   $12
         dfb   $99
         dfb   $22
         dfb   $9a
         dfb   $10
         dfb   $14
         dfb   $19
         dfb   $95
         dfb   $14
         dfb   $80
         dfb   $21
         dfb   $9a
         dfb   $23
         dfb   $9b
         dfb   $10
         dfb   $9b
         dfb   $1a
         dfb   $9e
         dfb   $1a
         dfb   $a0
         dfb   $11
         dfb   $15
         dfb   $00
         dfb   $30
         dfb   $05
         dfb   $a0
         dfb   $19
         dfb   $1e
         dfb   $00
         dfb   $93
         dfb   $1f
         dfb   $06
         dfb   $05
         dfb   $33
         dfb   $1a
         dfb   $15
         dfb   $16
         dfb   $2b
         dfb   $09
         dfb   $31
         dfb   $15
         dfb   $17
         dfb   $01
         dfb   $52
         dfb   $10
         dfb   $5e
         dfb   $1b
         dfb   $66
         dfb   $1d
         dfb   $17
         dfb   $08
         dfb   $03
         dfb   $01
         dfb   $20
         dfb   $01
         dfb   $68
         dfb   $1e
         dfb   $23
         dfb   $13
         dfb   $18
         dfb   $19
         dfb   $2b
         dfb   $20
         dfb   $2b
         dfb   $1a
         dfb   $36
         dfb   $10
         dfb   $5d
         dfb   $13
         dfb   $04
         dfb   $02
         dfb   $6e
         dfb   $15
         dfb   $34
         dfb   $11
         dfb   $95
         dfb   $1b
         dfb   $14
         dfb   $16
         dfb   $15
         dfb   $10
         dfb   $04
         dfb   $00
         dfb   $38
         dfb   $21
         dfb   $05
         dfb   $04
         dfb   $3a
         dfb   $11
         dfb   $5f
         dfb   $17
         dfb   $7d
         dfb   $1f
         dfb   $2e
         dfb   $04
         dfb   $35
         dfb   $08
         dfb   $3c
         dfb   $1d
         dfb   $33
         dfb   $10
         dfb   $4e
         dfb   $23
         dfb   $93
         dfb   $1a
         dfb   $2c
         dfb   $05
         dfb   $38
         dfb   $1a
         dfb   $4a
         dfb   $19
         dfb   $5e
         dfb   $15
         dfb   $80
         dfb   $14
         dfb   $94
         dfb   $21
         dfb   $3b
         dfb   $13
         dfb   $09
         dfb   $00
         dfb   $68
         dfb   $1f
         dfb   $95
         dfb   $1f
         dfb   $5f
         dfb   $18
         dfb   $96
         dfb   $14
         dfb   $81
         dfb   $12
         dfb   $2c
         dfb   $19
         dfb   $2f
         dfb   $05
         dfb   $64
         dfb   $1a
         dfb   $66
         dfb   $19
         dfb   $19
         dfb   $1a
         dfb   $05
         dfb   $02
         dfb   $32
         dfb   $10
         dfb   $31
         dfb   $00
         dfb   $81
         dfb   $17
         dfb   $92
         dfb   $20
         dfb   $96
         dfb   $1b
         dfb   $98
         dfb   $23
         dfb   $04
         dfb   $04
         dfb   $1a
         dfb   $04
         dfb   $6b
         dfb   $20
         dfb   $9c
         dfb   $10
         dfb   $9c
         dfb   $19
         dfb   $9c
         dfb   $1a
         dfb   $04
         dfb   $03
         dfb   $15
         dfb   $19
         dfb   $2b
         dfb   $07
         dfb   $9d
         dfb   $10
         dfb   $2d
         dfb   $20
         dfb   $2d
         dfb   $19
         dfb   $39
         dfb   $21
         dfb   $34
         dfb   $09
         dfb   $4c
         dfb   $14
         dfb   $4b
         dfb   $1a
         dfb   $35
         dfb   $00
         dfb   $7e
         dfb   $23
         dfb   $07
         dfb   $00
         dfb   $2e
         dfb   $09
         dfb   $37
         dfb   $19
         dfb   $3b
         dfb   $1a
         dfb   $49
         dfb   $1a
         dfb   $49
         dfb   $1c
         dfb   $18
         dfb   $10
         dfb   $5e
         dfb   $1e
         dfb   $6c
         dfb   $17
         dfb   $7f
         dfb   $15
         dfb   $93
         dfb   $21
         dfb   $9a
         dfb   $11
         dfb   $67
         dfb   $1b
         dfb   $a1
         dfb   $23
         dfb   $4a
         dfb   $1e
         dfb   $a3
         dfb   $10
         dfb   $a3
         dfb   $11
         dfb   $5b
         dfb   $1c
         dfb   $23
         dfb   $17
         dfb   $3c
         dfb   $18
         dfb   $a3
         dfb   $23
         dfb   $4b
         dfb   $23
         dfb   $16
         dfb   $15
         dfb   $a5
         dfb   $10
         dfb   $38
         dfb   $22
         dfb   $2d
         dfb   $18
         asc   'K!G"\'
         dfb   $1a
         dfb   $80
         dfb   $17
         dfb   $81
         dfb   $1c
         dfb   $04
         dfb   $08
         dfb   $30
         dfb   $04
         dfb   $4c
         dfb   $16
         dfb   $7f
         dfb   $1a
         dfb   $80
         dfb   $1e
         dfb   $94
         dfb   $20
         dfb   $95
         dfb   $11
         dfb   $a7
         dfb   $10
         dfb   $15
         dfb   $1d
         dfb   $a7
         dfb   $11
         dfb   $a8
         dfb   $10
         dfb   $3b
         dfb   $12
         dfb   $b1
         dfb   $20
         dfb   $b2
         dfb   $1f
         dfb   $05
         dfb   $06
         dfb   $14
         dfb   $1d
         dfb   $09
         dfb   $01
         dfb   $15
         dfb   $1b
         dfb   $14
         dfb   $22
         dfb   $39
         dfb   $12
         dfb   $3a
         dfb   $18
         dfb   $3b
         dfb   $14
         dfb   $14
         dfb   $1b
         dfb   $14
         dfb   $1f
         dfb   $17
         dfb   $00
         dfb   $1c
         dfb   $19
         dfb   $4d
         dfb   $10
         dfb   $31
         dfb   $1a
         dfb   $4d
         dfb   $18
         dfb   $1a
         dfb   $10
         dfb   $6c
         dfb   $21
         dfb   $7f
         dfb   $11
         dfb   $49
         dfb   $1f
         dfb   $82
         dfb   $16
         dfb   $33
         dfb   $09
         dfb   $95
         dfb   $1e
         dfb   $6a
         dfb   $1d
         dfb   $6e
         dfb   $17
         dfb   $4b
         dfb   $1f
         dfb   $3b
         dfb   $23
         dfb   $96
         dfb   $22
         dfb   $97
         dfb   $15
         dfb   $1e
         dfb   $11
         dfb   $3a
         dfb   $19
         dfb   $4c
         dfb   $22
         dfb   $6b
         dfb   $18
         dfb   $6b
         dfb   $1b
         dfb   $36
         dfb   $1a
         dfb   $96
         dfb   $17
         dfb   $98
         dfb   $10
         dfb   $4a
         dfb   $22
         dfb   $33
         dfb   $19
         dfb   $4a
         dfb   $23
         dfb   $95
         dfb   $12
         dfb   $9c
         dfb   $23
         dfb   $a1
         dfb   $10
         dfb   $96
         dfb   $13
         dfb   $21
         dfb   $13
         dfb   $3b
         dfb   $11
         dfb   $2f
         dfb   $01
         dfb   $6c
         dfb   $11
         dfb   $2c
         dfb   $04
         dfb   $9a
         dfb   $19
         dfb   $20
         dfb   $02
         dfb   $2f
         dfb   $13
         dfb   $2f
         dfb   $12
         dfb   $2f
         dfb   $19
         dfb   $4d
         dfb   $16
         dfb   $5a
         dfb   $1f
         dfb   $5a
         dfb   $21
         dfb   $7d
         dfb   $11
         dfb   $81
         dfb   $1d
         dfb   $1b
         dfb   $04
         dfb   $2e
         dfb   $16
         dfb   $2e
         dfb   $01
         dfb   $89
         dfb   $10
         dfb   $9e
         dfb   $11
         dfb   $7a
         dfb   $10
         dfb   $a6
         dfb   $11
         dfb   $2d
         dfb   $1c
         dfb   $1f
         dfb   $04
         dfb   $6c
         dfb   $22
         dfb   $1a
         dfb   $19
         dfb   $7f
         dfb   $21
         dfb   $97
         dfb   $14
         dfb   $15
         dfb   $09
         dfb   $5e
         dfb   $10
         dfb   $99
         dfb   $1a
         dfb   $b2
         asc   '#L#c'
         dfb   $18
         dfb   $7e
         dfb   $1f
         dfb   $b3
         dfb   $19
         dfb   $98
         dfb   $13
         dfb   $2a
         dfb   $21
         dfb   $b3
         dfb   $1c
         dfb   $b3
         dfb   $20
         dfb   $b4
         dfb   $10
         dfb   $b4
         dfb   $11
         dfb   $5e
         dfb   $11
         dfb   $80
         dfb   $23
         dfb   $b4
         dfb   $1b
         dfb   $13
         dfb   $20
         dfb   $2d
         dfb   $05
         dfb   $b4
         dfb   $19
         dfb   $17
         dfb   $09
         dfb   $6c
         dfb   $10
         dfb   $02
         dfb   $01
         dfb   $b4
         dfb   $1c
         dfb   $b4
         dfb   $1e
         dfb   $b5
         dfb   $12
         dfb   $b5
         dfb   $13
         dfb   $b5
         dfb   $17
         dfb   $6b
         dfb   $17
         dfb   $2d
         dfb   $16
         dfb   $22
         dfb   $14
         dfb   $2c
         dfb   $00
         dfb   $16
         dfb   $18
         dfb   $2f
         dfb   $16
         dfb   $7b
         dfb   $10
         dfb   $a4
         dfb   $22
         dfb   $b5
         dfb   $1a
         dfb   $b5
         dfb   $1d
         dfb   $b6
         dfb   $10
         dfb   $66
         dfb   $1e
         dfb   $2d
         dfb   $1e
         dfb   $b6
         dfb   $11
         dfb   $b6
         dfb   $14
         dfb   $b7
         dfb   $14
         dfb   $66
         dfb   $1a
         dfb   $6d
         dfb   $18
         dfb   $6d
         dfb   $1a
         dfb   $6e
         dfb   $11
         dfb   $4c
         dfb   $1b
         dfb   $5d
         dfb   $22
         dfb   $06
         dfb   $00
         dfb   $06
         dfb   $02
         dfb   $5c
         dfb   $1d
         dfb   $15
         dfb   $05
         dfb   $06
         dfb   $04
         dfb   $21
         dfb   $11
         dfb   $2f
         dfb   $14
         dfb   $60
         dfb   $14
         dfb   $5d
         dfb   $1d
         dfb   $67
         dfb   $1c
         dfb   $97
         dfb   $11
         dfb   $22
         dfb   $13
         dfb   $98
         dfb   $19
         dfb   $9b
         dfb   $23
         dfb   $2c
         dfb   $1f
         dfb   $3a
         dfb   $17
         dfb   $b4
         dfb   $14
         dfb   $83
         dfb   $11
         dfb   $4a
         dfb   $1c
         dfb   $5c
         dfb   $1b
         dfb   $80
         dfb   $19
         dfb   $97
         dfb   $18
         dfb   $a6
         dfb   $10
         dfb   $5b
         dfb   $1a
         dfb   $95
         dfb   $1c
         dfb   $1e
         dfb   $a9
         dfb   $03
         dfb   $d0
         dfb   $07
         dfb   $c9
         dfb   $ff
         dfb   $f0
         dfb   $06
         dfb   $20
         dfb   $30
         dfb   $1b
         dfb   $20
         dfb   $1f
         dfb   $23
         dfb   $20
         dfb   $a4
         asc   '" ;"L'
         dfb   $80
         dfb   $12
         dfb   $e6
         dfb   $67
         dfb   $a9
         dfb   $aa
         dfb   $85
         dfb   $98
         dfb   $38
         dfb   $66
         dfb   $a0
         dfb   $a9
         dfb   $ff
         dfb   $85
         dfb   $68
         dfb   $20
         dfb   $fb
         dfb   $1e
         dfb   $20
         dfb   $ec
         asc   '! v"'
         dfb   $90
         dfb   $01
         dfb   $60
         dfb   $a0
         dfb   $ff
         dfb   $84
         dfb   $92
         dfb   $c8
         dfb   $84
         dfb   $8d
         dfb   $84
         dfb   $93
         dfb   $a5
         dfb   $79
         dfb   $85
         dfb   $7b
         dfb   $a5
         dfb   $7a
         dfb   $85
         dfb   $7c
         dfb   $b1
         dfb   $79
         dfb   $c9
         dfb   $aa
         dfb   $f0
         dfb   $68
         dfb   $c9
         dfb   $bb
         dfb   $f0
         dfb   $64
         dfb   $24
         dfb   $9f
         dfb   $30
         dfb   $04
         dfb   $50
         dfb   $09
         dfb   $06
         dfb   $9f
         dfb   $46
         dfb   $92
         dfb   $20
         dfb   $74
         dfb   $25
         dfb   $90
         dfb   $55
         dfb   $20
         dfb   $9b
         dfb   $22
         dfb   $20
         dfb   $92
         dfb   $22
         dfb   $20
         dfb   $b2
         dfb   $22
         dfb   $20
         dfb   $9f
         dfb   $1b
         dfb   $90
         dfb   $0c
         dfb   $a2
         dfb   $2c
         dfb   $20
         dfb   $ac
         dfb   $1e
         dfb   $a2
         dfb   $03
         dfb   $86
         dfb   $8d
         dfb   $4c
         dfb   $2b
         dfb   $14
         dfb   $85
         dfb   $92
         dfb   $29
         dfb   $80
         dfb   $f0
         dfb   $03
         dfb   $4c
         dfb   $2b
         dfb   $14
         dfb   $a5
         dfb   $92
         dfb   $20
         dfb   $30
         dfb   $1b
         dfb   $85
         dfb   $8d
         dfb   $a5
         dfb   $91
         dfb   $e0
         dfb   $07
         dfb   $d0
         dfb   $05
         dfb   $c9
         dfb   $9e
         dfb   $d0
         dfb   $01
         dfb   $e8
         dfb   $e0
         dfb   $03
         dfb   $d0
         dfb   $16
         dfb   $c9
         dfb   $bc
         dfb   $f0
         dfb   $10
         dfb   $c9
         dfb   $dc
         dfb   $f0
         dfb   $0c
         dfb   $c9
         dfb   $9c
         dfb   $90
         dfb   $0a
         dfb   $c9
         dfb   $9f
         dfb   $b0
         dfb   $06
         dfb   $c9
         dfb   $9d
         dfb   $f0
         dfb   $02
         dfb   $a2
         dfb   $01
         dfb   $18
         dfb   $7d
         dfb   $ae
         dfb   $32
         dfb   $85
         dfb   $88
         dfb   $a4
         dfb   $8d
         dfb   $88
         dfb   $88
         dfb   $30
         dfb   $50
         dfb   $a0
         dfb   $00
         dfb   $b1
         dfb   $79
         dfb   $c9
         dfb   $a8
         dfb   $f0
         dfb   $04
         dfb   $c9
         dfb   $a3
         dfb   $d0
         dfb   $01
         dfb   $c8
         dfb   $20
         dfb   $7e
         dfb   $1c
         dfb   $a5
         dfb   $92
         dfb   $c9
         dfb   $08
         dfb   $f0
         dfb   $27
         dfb   $a5
         dfb   $a7
         dfb   $f0
         dfb   $36
         asc   "&",8d,"J)"
         dfb   $01
         dfb   $a0
         dfb   $00
         dfb   $20
         dfb   $fd
         dfb   $25
         dfb   $4c
         dfb   $2b
         dfb   $14
         dfb   $a5
         dfb   $89
         dfb   $e9
         dfb   $02
         asc   "*%",8a,"i"
         dfb   $00
         dfb   $a8
         dfb   $8a
         dfb   $38
         dfb   $e5
         dfb   $7d
         dfb   $85
         dfb   $89
         dfb   $98
         dfb   $e5
         dfb   $7e
         dfb   $85
         dfb   $8a
         dfb   $60
         dfb   $38
         dfb   $20
         dfb   $02
         dfb   $14
         dfb   $a5
         dfb   $89
         dfb   $10
         dfb   $02
         asc   "f",8a,"%",8a,"p"
         dfb   $05
         dfb   $a2
         dfb   $39
         dfb   $20
         dfb   $ac
         dfb   $1e
         dfb   $20
         dfb   $06
         dfb   $24
         dfb   $a5
         dfb   $93
         dfb   $d0
         dfb   $04
         dfb   $24
         dfb   $68
         dfb   $10
         dfb   $03
         dfb   $20
         dfb   $97
         dfb   $24
         dfb   $20
         dfb   $c0
         dfb   $22
         dfb   $90
         dfb   $03
         dfb   $4c
         dfb   $69
         dfb   $12
         dfb   $20
         dfb   $a4
         asc   '" ;"'
         dfb   $a5
         dfb   $8d
         dfb   $20
         dfb   $1f
         dfb   $23
         dfb   $a5
         dfb   $8d
         asc   ' )#LP'
         dfb   $13
         dfb   $20
         dfb   $fb
         dfb   $1e
         dfb   $a9
         dfb   $00
         dfb   $85
         dfb   $62
         dfb   $a5
         dfb   $75
         dfb   $85
         dfb   $61
         dfb   $a5
         dfb   $74
         dfb   $85
         dfb   $60
         dfb   $05
         dfb   $75
         dfb   $f0
         dfb   $14
         dfb   $20
         dfb   $b7
         dfb   $25
         dfb   $a2
         dfb   $17
         dfb   $bd
         dfb   $86
         dfb   $14
         dfb   $f0
         dfb   $06
         dfb   $20
         dfb   $e5
         dfb   $24
         dfb   $ca
         dfb   $10
         dfb   $f5
         dfb   $20
         dfb   $fb
         dfb   $1e
         dfb   $60
         dfb   $a2
         dfb   $3b
         asc   "Pm # ELIFYLBMESSA SIHT NI SRORRE "
         dfb   $00
         asc   "SRORRE ON :YLBMESSA LUFSSECCUS ***",878d,"YRAMMUS RORRE)"
         dfb   $00
         dfb   $85
         dfb   $93
         dfb   $a2
         dfb   $0d
         dfb   $bd
         dfb   $c2
         dfb   $14
         dfb   $20
         dfb   $e5
         dfb   $24
         dfb   $ca
         dfb   $10
         dfb   $f7
         dfb   $a5
         dfb   $93
         dfb   $cd
         dfb   $2f
         dfb   $30
         dfb   $90
         dfb   $01
         dfb   $60
         dfb   $a8
         dfb   $b9
         dfb   $32
         dfb   $2f
         dfb   $85
         dfb   $60
         dfb   $b9
         dfb   $31
         dfb   $2f
         dfb   $85
         dfb   $61
         dfb   $b9
         dfb   $30
         dfb   $2f
         dfb   $aa
         dfb   $29
         dfb   $0f
         dfb   $85
         dfb   $62
         dfb   $8a
         asc   'JJJJ'
         dfb   $aa
         dfb   $bd
         dfb   $3f
         dfb   $1f
         dfb   $aa
         dfb   $e8
         dfb   $e8
         dfb   $20
         dfb   $49
         dfb   $1f
         dfb   $a9
         dfb   $cf
         dfb   $20
         dfb   $e5
         dfb   $24
         dfb   $a9
         dfb   $c6
         dfb   $20
         dfb   $e5
         dfb   $24
         dfb   $a9
         dfb   $a0
         dfb   $20
         dfb   $e5
         dfb   $24
         dfb   $b9
         dfb   $2f
         dfb   $2f
         dfb   $c9
         dfb   $01
         dfb   $d0
         dfb   $12
         dfb   $a2
         dfb   $10
         dfb   $a9
         dfb   $e7
         dfb   $85
         dfb   $aa
         dfb   $a9
         dfb   $2e
         dfb   $85
         dfb   $ab
         dfb   $20
         dfb   $13
         dfb   $23
         dfb   $a4
         dfb   $93
         dfb   $4c
         dfb   $42
         dfb   $15
         dfb   $a2
         dfb   $06
         dfb   $bd
         dfb   $7f
         dfb   $14
         dfb   $20
         dfb   $e5
         dfb   $24
         dfb   $ca
         dfb   $10
         dfb   $f7
         dfb   $b9
         dfb   $2f
         dfb   $2f
         dfb   $20
         dfb   $81
         dfb   $24
         dfb   $20
         dfb   $fb
         dfb   $1e
         asc   "HHHH"
         dfb   $84
         dfb   $93
         dfb   $20
         dfb   $c0
         dfb   $22
         dfb   $90
         dfb   $03
         dfb   $4c
         dfb   $69
         dfb   $12
         dfb   $4c
         dfb   $df
         dfb   $14
         dfb   $20
         dfb   $66
         dfb   $25
         dfb   $a5
         dfb   $67
         dfb   $d0
         dfb   $09
         dfb   $a5
         dfb   $90
         dfb   $d0
         dfb   $0b
         dfb   $a2
         dfb   $55
         dfb   $20
         dfb   $ac
         dfb   $1e
         dfb   $a5
         dfb   $92
         dfb   $a0
         dfb   $00
         dfb   $18
         dfb   $60
         dfb   $a0
         dfb   $00
         dfb   $a5
         dfb   $a2
         dfb   $10
         dfb   $06
         dfb   $09
         dfb   $01
         dfb   $29
         dfb   $7f
         dfb   $d0
         dfb   $07
         dfb   $a5
         dfb   $8a
         dfb   $20
         dfb   $4f
         dfb   $1d
         dfb   $09
         dfb   $40
         dfb   $05
         dfb   $a7
         dfb   $91
         dfb   $7f
         dfb   $c8
         dfb   $a5
         dfb   $89
         dfb   $91
         dfb   $7f
         dfb   $a5
         dfb   $8a
         dfb   $c8
         dfb   $91
         dfb   $7f
         dfb   $4c
         dfb   $66
         dfb   $15
         dfb   $4c
         dfb   $6f
         dfb   $16
         dfb   $20
         dfb   $66
         dfb   $25
         dfb   $a5
         dfb   $67
         dfb   $f0
         dfb   $f6
         dfb   $a5
         dfb   $9a
         dfb   $30
         dfb   $f2
         dfb   $a5
         dfb   $a5
         dfb   $10
         asc   "n%'P"
         dfb   $6a
         dfb   $ae
         dfb   $e3
         dfb   $2e
         dfb   $f0
         dfb   $03
         dfb   $9d
         dfb   $88
         dfb   $c0
         dfb   $20
         dfb   $e2
         dfb   $2b
         dfb   $a2
         dfb   $00
         asc   ' !+ '
         dfb   $91
         dfb   $2d
         dfb   $38
         dfb   $66
         dfb   $a6
         dfb   $a5
         dfb   $89
         dfb   $85
         dfb   $83
         dfb   $20
         dfb   $d6
         dfb   $2c
         dfb   $a5
         dfb   $8a
         dfb   $85
         dfb   $84
         dfb   $20
         dfb   $d6
         dfb   $2c
         dfb   $a9
         dfb   $00
         dfb   $85
         dfb   $7f
         dfb   $85
         dfb   $80
         dfb   $20
         dfb   $d6
         dfb   $2c
         dfb   $a9
         dfb   $01
         dfb   $20
         dfb   $d6
         dfb   $2c
         dfb   $a9
         dfb   $00
         dfb   $85
         dfb   $81
         dfb   $85
         dfb   $82
         dfb   $24
         dfb   $a3
         dfb   $10
         dfb   $06
         dfb   $20
         dfb   $d6
         dfb   $2c
         dfb   $20
         dfb   $d6
         dfb   $2c
         dfb   $a5
         dfb   $68
         dfb   $30
         dfb   $03
         dfb   $4c
         dfb   $6f
         dfb   $16
         dfb   $a2
         dfb   $1f
         dfb   $a9
         dfb   $38
         dfb   $85
         dfb   $aa
         dfb   $a9
         dfb   $30
         dfb   $85
         dfb   $ab
         dfb   $20
         dfb   $13
         dfb   $23
         dfb   $00
         dfb   $00
         dfb   $00
         dfb   $22
         dfb   $0f
         ds    7
         dfb   $22
         dfb   $0e
         dfb   $22
         dfb   $0d
         ds    240
         dfb   $92
         dfb   $01
         dfb   $11
         dfb   $08
         dfb   $64
         dfb   $00
         dfb   $89
         dfb   $3a
         dfb   $97
         dfb   $3a
         dfb   $44
         dfb   $24
         dfb   $d0
         dfb   $e7
         dfb   $28
         dfb   $34
         dfb   $29
         dfb   $00
         dfb   $25
         dfb   $08
         dfb   $6e
         dfb   $00
         dfb   $46
         dfb   $24
         dfb   $d0
         asc   '"ASMIDSTAMP"'
         dfb   $00
         dfb   $3b
         dfb   $08
         dfb   $78
         dfb   $00
         dfb   $ba
         asc   'D$;"NOMON C,I,O"'
         dfb   $00
         dfb   $58
         dfb   $08
         dfb   $82
         dfb   $00
         dfb   $ba
         asc   'D$;"BLOAD ";F$;",A$3B8"'
         dfb   $00
         dfb   $7c
         dfb   $08
         dfb   $8c
         dfb   $00
         dfb   $a2
         dfb   $33
         dfb   $3a
         dfb   $ba
         asc   '"APPLE ][ EDITOR-ASSEMBLER"'
         dfb   $00
         dfb   $a5
         dfb   $08
         dfb   $96
         dfb   $00
         dfb   $a2
         dfb   $35
         dfb   $3a
         dfb   $ba
         asc   '"CURRENT ASSEMBLER ID STAMP IS:"'
         dfb   $00
         dfb   $af
         dfb   $08
         dfb   $a0
         dfb   $00
         dfb   $a2
         dfb   $37
         dfb   $3a
         dfb   $96
         dfb   $31
         dfb   $00
         dfb   $ca
         dfb   $08
         dfb   $aa
         dfb   $00
         dfb   $81
         dfb   $49
         dfb   $d0
         dfb   $39
         dfb   $35
         dfb   $32
         dfb   $c1
         asc   '968:'
         dfb   $ba
         dfb   $e7
         dfb   $28
         dfb   $e2
         asc   '(I));:'
         dfb   $82
         dfb   $00
         dfb   $e3
         dfb   $08
         dfb   $b4
         dfb   $00
         dfb   $a2
         dfb   $37
         dfb   $3a
         dfb   $96
         dfb   $31
         dfb   $3a
         dfb   $84
         asc   '"";A$:L'

GAME_SETUP
         jsr   HGR_CLEAR  ;6
         lda   MIXCLR     ;4
         jmp   TITLEPAGE  ;3

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
         jsr   CALC_GR_SCANLINE ;6
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
         jsr   INC_GR_SCANLINE ;6
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
         jsr   CALC_GR_SCANLINE ;6
         lda   #$09       ;2
         sta   UTILITY_INDEX ;4
         sty   CROSS_INDEX ;4
         ldx   #$00       ;2
:L8177   ldy   CROSS_INDEX ;4
         jsr   ERASE_CROSS_SCANLINE ;6
         jsr   INC_GR_SCANLINE ;6
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
         sta:  $0006      ;4
         inc:  $0006      ;6
         inc:  $0006      ;6
         lda   CROSS_Y    ;3
         sta:  $0007      ;4
         inc:  $0007      ;6
         inc:  $0007      ;6
         inc:  $0007      ;6
         inc:  $0007      ;6
         lda   #$02       ;2
         sta:  $0008      ;4
         jsr   FLOODFILL  ;6  Fill starting at 6,7 using color 8
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
         jsr   CALC_GR_SCANLINE ;6
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
         jsr   AS_RANDOM  ;6
         ldy   UTILITY_INDEX ;4
         lda   AS_RAND_BYTE ;3
         and   #$03       ;2
         tax              ;2
         sta   GREMLIN_DIR,y ;5  pick a move direction
         lda   AS_RAND_BYTE ;3
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
         jsr   CALC_GR_SCANLINE ;6
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
         jsr   INC_GR_SCANLINE ;6
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
         jsr   CALC_GR_SCANLINE ;6
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
         jsr   INC_GR_SCANLINE ;6
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
         jsr   CALC_GR_SCANLINE ;6  Y in ACC
:L83B1   ldy   #$28       ;2  Draw the top white band
:L83B3   dey              ;2
         lda   #$7f       ;2
         sta   (GR_LOW),y ;6
         cpy   #$00       ;2
         bne   :L83B3     ;2+
         jsr   INC_GR_SCANLINE ;6
         inc   UTILITY_INDEX ;6
         lda   UTILITY_INDEX ;4
         cmp   #$18       ;2
         bne   :L83B1     ;2+
         lda   #$b8       ;2
         sta   UTILITY_INDEX ;4
         jsr   CALC_GR_SCANLINE ;6
:L83D1   ldy   #$28       ;2  Draw the lower white band
:L83D3   dey              ;2
         lda   #$7f       ;2
         sta   (GR_LOW),y ;6
         cpy   #$00       ;2
         bne   :L83D3     ;2+
         jsr   INC_GR_SCANLINE ;6
         inc   UTILITY_INDEX ;6
         lda   UTILITY_INDEX ;4
         cmp   #$c0       ;2
         bne   :L83D1     ;2+
         lda   #$18       ;2
         sta   UTILITY_INDEX ;4
         jsr   CALC_GR_SCANLINE ;6
:L83F1   ldy   #$00       ;2  Left bar
         lda   #$7f       ;2
         sta   (GR_LOW),y ;6
         ldy   #$27       ;2
         sta   (GR_LOW),y ;6  Right bar
         inc   UTILITY_INDEX ;6
         jsr   INC_GR_SCANLINE ;6
         lda   UTILITY_INDEX ;4
         cmp   #$b8       ;2
         bne   :L83F1     ;3+
         lda   #$00       ;2  text at the top of the screen
         sta   MON_CH     ;3
         sta   MON_CV     ;3
         jsr   MON_VTAB   ;6
         ldy   #$00       ;2
:L8413   lda   TXT_SCORE,y ;4+
         jsr   MON_COUT   ;6
         iny              ;2
         cpy   #$0a       ;2
         bne   :L8413     ;2+
         lda   #$1f       ;2
         sta   MON_CH     ;3
         ldy   #$00       ;2
:L8424   lda   TXT_FILL,y ;4+
         jsr   MON_COUT   ;6
         iny              ;2
         cpy   #$0b       ;2
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
         dfb   $5c
         dfb   $64
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
         lda   #$92       ;2
         jsr   MON_COUT   ;6
         lda   #$85       ;2
         jsr   MON_COUT   ;6
         lda   #$83       ;2
         jsr   MON_COUT   ;6
         lda   #$b1       ;2
         jsr   MON_COUT   ;6
         ldy   #$00       ;2
G_DEAD_SCORE_LOOP
         lda   CURRENT_SCORE_HI,y ;4+
         lsr   A          ;2
         lsr   A          ;2
         lsr   A          ;2
         lsr   A          ;2
         ora   #$b0       ;2
         jsr   MON_COUT   ;6
         lda   CURRENT_SCORE_HI,y ;4+
         and   #$0f       ;2
         ora   #$b0       ;2
         jsr   MON_COUT   ;6
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
         lda   #$92       ;2
         jsr   MON_COUT   ;6
         lda   #$97       ;2
         jsr   MON_COUT   ;6
         lda   #$83       ;2
         jsr   MON_COUT   ;6
         lda   #$b2       ;2
         jsr   MON_COUT   ;6
         ldy   #$00       ;2
DISP_FILL_LOOP
         lda   FILL_LOW,y ;4+ Draw fill count number
         lsr   A          ;2
         lsr   A          ;2
         lsr   A          ;2
         lsr   A          ;2
         ora   #$b0       ;2
         jsr   MON_COUT   ;6
         lda   FILL_LOW,y ;4+
         and   #$0f       ;2
         ora   #$b0       ;2
         jsr   MON_COUT   ;6
         iny              ;2
         cpy   #$02       ;2
         bne   DISP_FILL_LOOP ;2+
         rts              ;6

TXT_FILL dfb   $92
         asc   "FILL LEFT"
TXT_SCORE
         dfb   $92
         dfb   $85
         dfb   $83
         asc   "1SCORE:"
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
         asc   "FLOW"
         dfb   $00
         asc   "PARAMETER(S) OMITTED"
         dfb   $00
         asc   "UNKNOWN COMMAND"
         dfb   $00
         asc   " ERROR",878d
         dfb   $00
         asc   "ASSM,S6,D1",8d
         dfb   $00
         asc   "EDITOR,S6,D1",8d
         dfb   $00
         dfb   $a4
         dfb   $24
         dfb   $b1
         dfb   $28
         dfb   $6c
         dfb   $38
         dfb   $00
         dfb   $48
         dfb   $c9
         dfb   $e0
         dfb   $90
         dfb   $02
         dfb   $29
         dfb   $1f
         dfb   $48
         dfb   $b1
         dfb   $28
         dfb   $c9
         dfb   $df
         dfb   $f0
         dfb   $05
         dfb   $68
         dfb   $a9
         dfb   $df
         dfb   $30
         dfb   $01
         dfb   $68
         dfb   $91
         dfb   $28
         dfb   $68
         dfb   $e6
         dfb   $4e
         dfb   $d0
         dfb   $0c
         dfb   $e6
         dfb   $4f
         dfb   $48
         dfb   $a9
         dfb   $3f
         dfb   $25
         dfb   $4f
         dfb   $c9
         dfb   $01
         dfb   $68
         dfb   $90
         dfb   $d9
         dfb   $2c
         dfb   $00
         dfb   $c0
         dfb   $10
         dfb   $eb
         dfb   $91
         dfb   $28
         dfb   $ad
         dfb   $00
         dfb   $c0
         dfb   $2c
         dfb   $10
         dfb   $c0
         asc   '`%R,'
         dfb   $05
         dfb   $52
         dfb   $85
         dfb   $52
         dfb   $60
         dfb   $8d
         dfb   $5c
         dfb   $c0
         dfb   $a9
         dfb   $80
         dfb   $20
         dfb   $6d
         dfb   $10
         dfb   $20
         dfb   $31
         dfb   $10
         asc   '$R02'
         dfb   $c9
         dfb   $df
         dfb   $b0
         dfb   $2e
         dfb   $c9
         dfb   $dd
         dfb   $b0
         dfb   $08
         dfb   $c9
         dfb   $db
         dfb   $b0
         dfb   $26
         dfb   $c9
         dfb   $c0
         dfb   $d0
         dfb   $03
         dfb   $49
         dfb   $10
         dfb   $18
         dfb   $90
         dfb   $0b
         dfb   $24
         dfb   $52
         dfb   $70
         dfb   $19
         dfb   $2c
         dfb   $63
         dfb   $c0
         dfb   $10
         dfb   $14
         dfb   $09
         dfb   $20
         dfb   $c9
         dfb   $94
         dfb   $f0
         dfb   $cd
         dfb   $c9
         dfb   $97
         dfb   $d0
         dfb   $0a
         dfb   $a9
         dfb   $40
         dfb   $20
         dfb   $70
         dfb   $10
         dfb   $8d
         dfb   $5d
         dfb   $c0
         dfb   $d0
         dfb   $c7
         dfb   $60
         dfb   $a9
         dfb   $87
         dfb   $20
         dfb   $ed
         dfb   $fd
         dfb   $20
         dfb   $31
         dfb   $10
         asc   "I ptI",8d,"p"
         dfb   $02
         dfb   $85
         dfb   $53
         dfb   $a5
         dfb   $53
         dfb   $20
         dfb   $ed
         dfb   $fd
         dfb   $20
         dfb   $8e
         dfb   $fd
         dfb   $4c
         dfb   $04
         dfb   $11
         dfb   $6c
         dfb   $33
         dfb   $fd
         dfb   $20
         dfb   $31

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
         jsr   AS_RANDOM  ;6
         ldx   GENERIC_INDEX ;4
         lda   AS_RAND_BYTE ;3
         and   #$60       ;2
         clc              ;2
         adc   #$14       ;2
         sta   GREMLIN_X,x ;5
         jsr   AS_RANDOM  ;6
         ldx   GENERIC_INDEX ;4
         lda   AS_RAND_BYTE ;3
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
         cpy   #>SOUND_TABLE+$300 ;2
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
         cpy   #$0a       ;2
         bne   :L86E5     ;2+
         ldx   #$20       ;2
:L86F2   lda   #$f0       ;2
         jsr   MON_WAIT   ;6
         dex              ;2
         bne   :L86F2     ;2+
         rts              ;6

TXT_GAMEOVER
         dfb   $85
         asc   "GAME OVER"

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
         cpy   #$07       ;2
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
         dfb   $85
         asc   "READY?"
TXT_LEVEL
         asc   "LEVEL:"
TXT_BOARD
         asc   "BOARD:"
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
         jsr   CALC_GR_SCANLINE ;6
         lda   :L88F2     ;4
         sta   X_POS      ;4
         jsr   DIVIDE7    ;6
         lda   :L88EB,x   ;4+
         eor   (GR_LOW),y ;5+
         sta   (GR_LOW),y ;6
         jsr   INC_GR_SCANLINE ;6
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
         dfb   $85
         asc   "OUT OF FILLRive"
         dfb   $16
         dfb   $00
         dfb   $04
         asc   "Delete"
         dfb   $04
         dfb   $00
         dfb   $16
         dfb   $c5
         dfb   $ce
         dfb   $c4
         dfb   $00
         dfb   $38
         asc   "Edit"
         dfb   $04
         dfb   $06
         dfb   $00
         dfb   $30
         asc   "FILE"
         dfb   $00
         dfb   $36
         asc   "Find"
         dfb   $04
         dfb   $06
         dfb   $00
         dfb   $2c
         asc   "HImem="
         dfb   $16
         dfb   $00
         dfb   $18
         asc   "Insert"
         dfb   $02
         dfb   $00
         dfb   $14
         asc   "LENgth"
         dfb   $00
         dfb   $26
         asc   "LOmem="
         dfb   $16
         dfb   $00
         dfb   $1a
         asc   "LOaD"
         dfb   $0a
         dfb   $00
         dfb   $10
         asc   "List"
         dfb   $04
         dfb   $00
         dfb   $28
         dfb   $cd
         dfb   $cf
         dfb   $ce
         dfb   $00
         dfb   $0a
         dfb   $ce
         dfb   $c5
         dfb   $d7
         dfb   $00
         dfb   $1c
         dfb   $d0
         dfb   $d2
         dfb   $a3
         dfb   $16
         dfb   $ac
         dfb   $0e
         dfb   $00
         dfb   $3a
         asc   "Print"
         dfb   $04
         dfb   $00
         dfb   $2e
         asc   "Replace"
         dfb   $04
         dfb   $00
         dfb   $34
         asc   "SLot"
         dfb   $16
         dfb   $00
         dfb   $06
         asc   "SaVE"
         dfb   $04
         dfb   $12
         dfb   $00
         dfb   $12
         asc   "TRuncOFf"
         dfb   $00
         dfb   $0c
         dfb   $d4
         dfb   $d2
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
         hex   4800004800004800004f07000000004f07004800004800004800000000000000
         hex   1001001001001001001e0f000000001e0f001001001001001001000000000000
         hex   2002002002002002003c1e000000003c1e002002002002002002000000000000
         hex   400400400400400400783c00000000783c004004004004004004000000000000
         hex   0009000009000009007079000000007079000009000009000009000000000000
         hex   0012000012000012006073010000006073010012000012000012000000000000
         hex   0024000024000024004067030000004067030024000024000024000000000000
         hex   552a55552a55552a55552a55552a5555ffff0000ffff0000ffff0000ffff0000


* X = $06, Y = $07, color = $08
FLOODFILL
         ldx:  $0008      ;4
         jsr   SETHCOLOR  ;6
         lda   #$00       ;2
         sta   TMP0       ;3
         sta   TMP1       ;3
         sta:  $00fd      ;4
         lda   #$01       ;2
         sta:  $00ff      ;4
:L9014   jsr   L9166      ;6
         lda   L9320      ;4
         bne   :L9022     ;2+
         dec:  $0007      ;6
         jmp   :L9014     ;3

:L9022   lda   #$02       ;2
         sta:  $00ff      ;4
         jsr   :L904D     ;6
:L902A   lda:  $00fd      ;4
         bne   FF_POPSTACK     ;2+
         rts              ;6

FF_POPSTACK
         dec:  $00fd      ;6
         ldy:  $00fd      ;4
         lda   FF_STACK_X,y    ;4+
         sta:  $0006      ;4
         lda   FF_STACK_Y,y    ;4+
         sta:  $0007      ;4
         lda   #$02       ;2
         sta:  $00ff      ;4
         jsr   :L9050     ;6
         jmp   :L902A     ;3

:L904D   jsr   :L90F0     ;6
:L9050   lda   #$00       ;2
         sta   L9322      ;4
         lda   FRAME_STATE ;4
         beq   :L905B     ;2+
         rts              ;6

:L905B   dec:  $00ff      ;6
         bne   :L9065     ;2+
         lda   #$04       ;2
         sta:  $00ff      ;4
:L9065   jsr   L9166      ;6
         lda   L9320      ;4
         bne   :L9070     ;2+
         jmp   :L90C1     ;3

:L9070   inc:  $00ff      ;6
         inc   L9322      ;6
         lda:  $00ff      ;4
         cmp   #$05       ;2
         bne   :L9082     ;2+
         lda   #$01       ;2
         sta:  $00ff      ;4
:L9082   lda   L9322      ;4
         cmp   #$05       ;2
         bne   :L9065     ;2+
         lda   #$01       ;2
         sta:  $00fe      ;4
:L908E   jsr   L9150      ;6
         lda   L9320      ;4
         beq   FF_MOVE_POINT    ;2+
         inc:  $00fe      ;6
         lda:  $00fe      ;4
         cmp   #$05       ;2
         bne   :L90A1     ;2+
         rts              ;6

:L90A1   jmp   :L908E     ;3

FF_MOVE_POINT
         ldy:  $00fe      ;4
         lda:  $0006      ;4
         clc              ;2
         adc   FF_XDIR_TAB,y    ;4+
         sta:  $0006      ;4
         lda:  $0007      ;4
         clc              ;2
         adc   FF_YDIR_TAB,y    ;4+
         sta:  $0007      ;4
         jsr   :L90F0     ;6
         jmp   :L9050     ;3

:L90C1   jsr   :L90F0     ;6
         lda:  $0006      ;4
         sta   L9324      ;4
         lda:  $0007      ;4
         sta   L9323      ;4
         ldy:  $00ff      ;4
         lda:  $0006      ;4
         clc              ;2
         adc   FF_XDIR_ADD,y    ;4+
         sta:  $0006      ;4
         lda:  $0007      ;4
         clc              ;2
         adc   FF_YDIR_ADD,y    ;4+
         sta:  $0007      ;4
         jsr   :L90F0     ;6
         jsr   L91A8      ;6
         jmp   :L9050     ;3

:L90F0   ldy   #$00       ;2
         lda:  $00ff      ;4
         pha              ;3
         lda   #$00       ;2
         sta:  $00ff      ;4
         jsr   L9166      ;6
         pla              ;4
         sta:  $00ff      ;4
         lda   L9320      ;4
         bne   :L910A     ;2+
         jsr   :L9134     ;6
:L910A   ldy   #$00       ;2
         lda:  $0006      ;4
         asl   A          ;2
         bcc   :L9114     ;2+
         ldy   #$01       ;2
:L9114   tax              ;2
         lda:  $0007      ;4
         jsr   $f411      ;6
         jsr   $f45a      ;6
         ldy   #$00       ;2
         lda:  $0006      ;4
         asl   A          ;2
         bcc   :L9128     ;2+
         ldy   #$01       ;2
:L9128   tax              ;2
         inx              ;2
         lda:  $0007      ;4
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

L9150    lda:  $00ff      ;4
         pha              ;3
         ldy:  $00fe      ;4
         iny              ;2
         iny              ;2
         iny              ;2
         iny              ;2
         sty:  $00ff      ;4
         jsr   L9166      ;6
         pla              ;4
         sta:  $00ff      ;4
         rts              ;6

L9166    lda   #$00       ;2
         sta   CROSS_INDEX ;4
         ldy:  $00ff      ;4
         lda   FF_XDIR_ADD,y    ;4+
         clc              ;2
         adc:  $0006      ;4
         pha              ;3
         lda   FF_YDIR_ADD,y    ;4+
         clc              ;2
         adc:  $0007      ;4
         jsr   CALC_GR_SCANLINE ;6
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
         lda:  $00ff      ;4
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
         sta:  $00ff      ;4
         jsr   L9166      ;6
         lda   L9320      ;4
         sta   L932D      ;4
         lda   L932E      ;4
         sta:  $00ff      ;4
         jsr   L9166      ;6
         lda   L9320      ;4
         sta   L932E      ;4
         lda   L9329      ;4
         sta:  $00fe      ;4
         jsr   L9150      ;6
         lda   L9320      ;4
         sta   L932B      ;4
         ldy:  $00fe      ;4
         iny              ;2
         cpy   #$05       ;2
         bne   :L9204     ;2+
         ldy   #$01       ;2
:L9204   sty:  $00fe      ;4
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
         sta:  $00ff      ;4
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
         ldy:  $00fd      ;4
         sta   FF_STACK_X,y    ;5
         lda   L9323      ;4
         sta   FF_STACK_Y,y    ;5
         inc:  $00fd      ;6
:L9275   lda   L9329      ;4
         sta:  $00ff      ;4
         rts              ;6

:L927C   lda   #$00       ;2
         sta   L9321      ;4
         lda:  $0006      ;4
         sta   L9327      ;4
         lda:  $0007      ;4
         sta   L9328      ;4
         lda   L9324      ;4
         sta:  $0006      ;4
         lda   L9323      ;4
         sta:  $0007      ;4
         lda   #$01       ;2
         sta:  $00ff      ;4
:L929E   jsr   L9166      ;6
         lda   L9320      ;4
         bne   :L92AB     ;2+
         lda   #$01       ;2
         sta   L9321      ;4
:L92AB   inc:  $00ff      ;6
         lda:  $00ff      ;4
         cmp   #$05       ;2
         bne   :L929E     ;2+
         lda   #$01       ;2
         sta:  $00fe      ;4
:L92BA   jsr   L9150      ;6
         lda   L9320      ;4
         bne   :L92C7     ;2+
         lda   #$01       ;2
         sta   L9321      ;4
:L92C7   inc:  $00fe      ;6
         lda:  $00fe      ;4
         cmp   #$05       ;2
         bne   :L92BA     ;2+
         lda   L9327      ;4
         sta:  $0006      ;4
         lda   L9328      ;4
         sta:  $0007      ;4
         rts              ;6

CALC_GR_SCANLINE
         pha              ;3  Slow system to compute the scanline address
         and   #$c0       ;2
         sta   GR_LOW     ;3
         lsr   A          ;2
         lsr   A          ;2
         ora   GR_LOW     ;3
         sta   GR_LOW     ;3
         pla              ;4
         sta   GR_HIGH    ;3
         asl   A          ;2
         asl   A          ;2
         asl   A          ;2
         rol   GR_HIGH    ;5
         asl   A          ;2
         rol   GR_HIGH    ;5
         asl   A          ;2
         ror   GR_LOW     ;5
         lda   GR_HIGH    ;3
         and   #$1f       ;2
         ora   HGR_PAGE   ;3
         sta   GR_HIGH    ;3
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

