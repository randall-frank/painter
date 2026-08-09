         ORG   $2000
         DSK   ../bin/LOADER#062000
         TYP   $06  ; /BIN file

SRCLO    =     0
SRCHI    =     1
TGTLO    =     2
TGTHI    =     3

* // LINK - ../memory.txt

* Low order addresses
         LDA   #$00
         STA   SRCLO
         STA   TGTLO

* Read from 2800-3fff and store to 800-1fff         
         LDA   #$28
         STA   SRCHI
         LDA   #$08
         STA   TGTHI
         LDX   #$18
         JSR   MOVEMEM
* Start the game                           
         JMP   $7F00

MOVEMEM  LDY   #$00
MOVELOOP LDA   (SRCLO),Y
         STA   (TGTLO),Y
         DEY
         BNE   MOVELOOP
         INC   TGTHI
         INC   SRCHI
         DEX
         BNE   MOVEMEM
         RTS
