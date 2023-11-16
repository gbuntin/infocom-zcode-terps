	PAGE
	SBTTL "--- GAME I/O: APPLE II ---"

	; --------------
	; INTERNAL ERROR
	; --------------

	; ENTRY: ERROR CODE IN [A]
	; EXIT: HA!

ERRM:	DB	"Internal error "
ENUMB:	DB	"00."
ERRML	EQU	$-ERRM

ZERROR:	CLD
	LDY	#1		; CONVERT ERROR BYTE IN [A]
ZERR0:	LDX	#0		; TO ASCII AT "ENUMB"
ZERR1:	CMP	#10
	BCC	ZERR2
	SBC	#10
	INX
	BNE	ZERR1
ZERR2:	ORA	#'0'
	STA	ENUMB,Y
	TXA
	DEY
	BPL	ZERR0

	LDX	#LOW ERRM
	LDA	#HIGH ERRM
	LDY	#ERRML
	JSR	DLINE		; PRINT ERROR MESSAGE

	; FALL THROUGH ...

	; ----
	; QUIT
	; ----

ZQUIT:	JSR	ZCRLF		; FLUSH BUFFER

	LDX	#LOW ENDM
	LDA	#HIGH ENDM
	LDY	#ENDML
	JSR	DLINE		; "END OF STORY"

FREEZE:	JMP	FREEZE		; AND STOP

ENDM:	DB	"End of story."
	DB	EOL
ENDML	EQU	$-ENDM

	; -------
	; RESTART
	; -------

ZSTART:	LDX #0
	STX WTOP		;RESET FULL SCREEN FOR CLEAR
	LDA	ZBEGIN+ZSCRIP+1	; PRINTING?
	AND	#%00000001
	BEQ	STEX		; NO
	DEX			; = $FF
	STX	PSTAT		; MARK SO WILL CONTINUE TO PRINT 

STEX:	JMP WARM		;AND DO WARMSTART

	; --------------------
	; PRINT VERSION NUMBER
	; --------------------

VERS:	DB	"Apple II Version G"
	DB	EOL
VERSL	EQU	$-VERS

VERNUM:	JSR	ZCRLF		; FLUSH BUFFER

	LDX	#LOW VERS
	LDA	#HIGH VERS
	LDY	#VERSL
	JMP	DLINE		; PRINT ID AND RETURN

	; --------------------------
	; RETURN TOP RAM PAGE IN [A]
	; --------------------------

MEMTOP:	LDA	$FBB3		; CHECK MACHING IDENTIFICATION
	CMP	#II
	BNE	MEM2
	JMP	TOP48		; IT'S A II, USE 48K TOP
MEM2:	CMP	#IIPLUS
	BEQ	MEM0		; GO CHECK IF II+ OR III
	CMP	#IIC
	BEQ	MEM3
	JMP	TOP48		; IF NOT A STANDARD, GIVE IT 48K ONLY
MEM3:	LDA	$FBC0
	BNE	MEM4
	JMP	TOP128		; IT'S A IIC, USE 128K TOP
MEM4:	CMP	#IIE
	BEQ	MEM1		; GO CHECK AMT OF MEMORY IIE HAS
	JMP	TOP48		; NOT STANDARD, USE 48K TOP

MEM0:	LDA	$FB1E
	CMP	#III
	BNE	MEM5
	JMP	TOP48		; IT'S A III, USE 48K TOP

	; OK, IT'S A II+, CHECK IF 48 OR 64 K OF MEMORY AVAILABLE

MEM5:	LDA	#0
	STA	TSTVAL
	LDA	BNK1RW		; SET TO R/W BANK 1 RAM
	LDA	BNK1RW
MEMLP1:	LDY	#0
	LDA	TSTVAL
MEMLP2:	STA	$D000,Y		; WRITE A PG OF TSTVAL TO 
	INY		 	; $D000 RAM
	BNE	MEMLP2

MEMLP3:	LDA	$D000,Y
	CMP	TSTVAL
	BNE	NO64		; NO COMPARE, THE MEMORY ISN'T THERE
	INY
	BNE	MEMLP3		; CHECK WHOLE PAGE

	INC	TSTVAL
	BNE	MEMLP1		; CHECK WITH 0 -> FF

	LDA	ROMRAM		; RESET TO ROM
	LDA	ROMRAM

TOP64:	LDA	#0
	LDY	#$FF
	RTS			; SEND BACK VALUE FOR 64K

NO64:	LDA	ROMRAM		; RESET TO ROM
	LDA	ROMRAM
	JMP	TOP48		; GO SET TO 48K ROP

	; IT'S A IIE, CHECK IF 64 OR 128 K OF AVAILABLE MEMORY

MEM1:	LDA	#0		; START @ 0
	STA	TSTVAL
	LDA	BNK1RW		; SETY TO BANK 1 RAM
	LDA	BNK1RW

MEMLP4:	LDY	#0
	LDA	TSTVAL
MEMLP5:	STA	$D000,Y		; WRITE [TSTVAL] TO 
	INY			; HIGH MAIN MEMORY
	BNE	MEMLP5

	INC	TSTVAL
	LDA	TSTVAL
	STA	ALTZPS		; SET TO AUX MEMORY

MEMLP6:	STA	$D000,Y		; WRITE NEXT VALUE
	INY			; TO AUX MEM
	BNE	MEMLP6

	STA	ALTZPC		; SET TO MAIN MEM
	DEC	TSTVAL		; RESET TO [TSTVAL] WRITTEN TO MAIN

MEMLP7:	LDA	$D000,Y		; CHECK IF WHAT WRITTEN
	CMP	TSTVAL		; 1ST TO MAIN MEM D000 PG
	BNE	NO128		; IS STILL THERE
	INY
	BNE	MEMLP7

	INC 	TSTVAL
	STA	ALTZPS		; & SET TO AUX MEM

MEMLP8:	LDA	$D000,Y		; & SEE IF WHAT WROTE
	CMP	TSTVAL		; TO AUX MEM IS STILL THERE
	BNE	NO128
	INY
	BNE	MEMLP8

	STA	ALTZPC		; RESET TO MAIN MEM
	LDA	TSTVAL		; LAST THING WAS INC'D
	BNE	MEMLP4		; GO TRY W/ NEXT SET OF VALUES, DO 0,1 -> FF,0

	LDA	ROMRAM		; RESET TO ROM
	LDA	ROMRAM

TOP128:	; MOVE RTN TO READ FROM 48K AUX MEM 
	; TO HIGH MEM SO IT CAN BE USED

	LDA	BNK1RW		; SET BANK 1 TO RECEIVE
	LDA	BNK1RW
	LDY	#B48LNG
MOVRTN:	LDA	B48,Y
	STA	$D000,Y
	DEY
	BPL	MOVRTN
	LDA	ROMRAM		; RESET ROM
	LDA	ROMRAM
	JMP	TOPEX		; SKIP OVER THE RTN MOVED

B48:	STA	RAMRDS		; SET READ 48K AUX
	LDA	$FF00,Y		; PICK UP CHAR (FAKE ADDR)
	STA	RAMRDC		; SET BACK TO MAIN 48K RAM
	RTS
B48LNG	EQU	$-B48

TOPEX:	LDA	#1		; $1FA IS TOP USABLE BUFFER NUMBER
	LDY	#$FB
	RTS

NO128:	STA	ALTZPC		; RESET TO MAIN MEMORY
	LDA	ROMRAM		; RESET TO ROM
	LDA	ROMRAM
	JMP	TOP64		; GO SET TO 64K

TOP48:	LDA	#0
	LDY	#$C0
	RTS


	; --------------------------------
	; RETURN RANDOM BYTES IN [A] & [X]
	; --------------------------------

RANDOM:	INC RNUM1
	DEC RNUM2
	LDA RNUM1		;GENERATED BY MONITOR GETBYT
	ADC RAND1
	TAX
	LDA RNUM2
	SBC RAND2
	STA RAND1
	STX RAND2
	RTS

	; -------------------
	; Z-PRINT A CHARACTER
	; -------------------

	; ENTRY: ASCII CHAR IN [A]

COUT:	CMP	#$0D		; IF ASCII EOL,
	BEQ	ZCRLF		; DO IT!
	CMP	#SPACE		; IGNORE ALL OTHER
	BCC	CEX		; CONTROLS

	LDX	LENGTH		; GET LINE POINTER
	STA	LBUFF,X		; ADD CHAR TO BUFFER
	CPX	XSIZE		; END OF LINE?
	BCS	FLUSH		; YES, FLUSH THE LINE
	INC	LENGTH		; ELSE UPDATE POINTER

CEX:	RTS

	; -------------------
	; FLUSH OUTPUT BUFFER
	; -------------------

	; ENTRY: LENGTH OF BUFFER IN [X]

FLUSH:	LDA	#SPACE

FL0:	CMP	LBUFF,X		; FIND LAST SPACE CHAR
	BEQ	FL1		; IN THE LINE
	DEX
	BNE	FL0		; IF NONE FOUND,
	LDX	XSIZE		; FLUSH ENTIRE LINE

FL1:	STX	OLDLEN		; SAVE OLD LINE POS HERE
	STX	LENGTH		; MAKE IT THE NEW LINE LENGTH

	JSR	ZCRLF		; PRINT LINE UP TO LAST SPACE

	; START NEW LINE WITH REMAINDER OF OLD

	LDX	OLDLEN		; GET OLD LINE POS
	LDY	#0		; START NEW LINE AT BEGINNING
FL2:	INX
	CPX	XSIZE		; CONTINUE IF
	BCC	FL3		; INSIDE OR
	BEQ	FL3		; AT END OF LINE
	STY	LENGTH		; ELSE SET NEW LINE LENGTH
	RTS

FL3:	LDA	LBUFF,X		; GET CHAR FROM OLD LINE
	STA	LBUFF,Y		; MOVE TO START OF NEW LINE
	INY			; UPDATE LENGTH OF NEW LINE
	BNE	FL2		; (ALWAYS)

	; ---------------
	; CARRIAGE RETURN
	; ---------------

ZCRLF:	LDA	SPLITF		; AT SPLIT SCREEN
	BNE	ZCRLF0		; YES

	INC	LINCNT		; NEW LINE GOING OUT
ZCRLF0:	LDX	LENGTH		; INSTALL EOL
	LDA	#$8D		; (MUST! BE $8D FOR PRINTER Le 5/8/85)
	STA	LBUFF,X		; AT END OF CURRENT LINE
	INC	LENGTH		; UPDATE LINE LENGTH
	LDX	LINCNT		; IS IT TIME TO
	INX			; (A LINE FOR "MORE")
	CPX	WBOTM		; PRINT "MORE" YET?
	BCC	CR1		; NO, CONTINUE

	; SCREEN FULL; PRINT "MORE"

	JSR	ZUSL		; UPDATE STATUS LINE

	LDX	WTOP
	INX
	STX	LINCNT		; RESET LINE COUNTER

	BIT	ANYKEY		; CLEAR STROBE SO GET CLEAN READING

	LDA	#HIGH MORE
	LDX	#LOW MORE
	LDY	#MOREL
	JSR	DLINE

WAIT:	BIT KBD
	BPL WAIT
	BIT ANYKEY		;CLEAR STROBE SO THIS KEY WILL BE DISCOUNTED

	LDA	#0
	STA	CH
	STA	EH
	JSR	CLEOL		;CLEAR TO EOL

	LDX	LENGTH
	BEQ	LINEX		; SKIP IF EMPTY

CR1:

LINOUT:	LDY	LENGTH		; IF BUFFER EMPTY,
	BEQ	LINEX		; DON'T PRINT ANYTHING
	STY	PRLEN		; SAVE LENGTH HERE FOR "PPRINT"

	LDX	#0		; SEND CONTENTS OF [LBUFF]
LOUT:	LDA	LBUFF,X		; TO SCREEN
	JSR	CHAR
	INX
	DEY
	BNE	LOUT

	JSR	PPRINT		; PRINT [LBUFF] IF ENABLED
	LDA	#0		; RESET LINE LENGTH
	STA	LENGTH		; TO ZERO

LINEX:	RTS			; AND RETURN

MORE:	DB	"[MORE]"
MOREL	EQU	$-MORE

	; ----------------------
	; UPDATE THE STATUS LINE
	; ----------------------

ZUSL:	JSR LINOUT		;CLEAR LAST LINE TO SCREEN

	LDA EH			;SAVE CURRENT CURSOR POSITION
	PHA
	LDA CH
	PHA
	LDA CV
	PHA

	LDA	LENGTH		; SAVE ALL
	PHA			; STRING-PRINTING
	LDA	MPCH		; VARIABLES
	PHA
	LDA	MPCM
	PHA
	LDA	MPCL
	PHA
	LDA	TSET
	PHA
	LDA	PSET
	PHA
	LDA	ZWORD+HI
	PHA
	LDA	ZWORD+LO
	PHA
	LDA	ZFLAG
	PHA
	LDA	DIGITS
	PHA
	LDA	WTOP
	PHA

	LDX	XSIZE
USL0:	LDA	LBUFF,X		; MOVE CONTENTS OF [LBUFF]
	STA	BUFSAV,X	; TO [BUFSAV]
	LDA	#SPACE		; CLEAR
	STA	LBUFF,X		; [LBUFF] WITH SPACES
	DEX
	BPL	USL0

	LDA	#0
	STA	LENGTH		; RESET LINE LENGTH
	STA	SCRIPT		; DISABLE SCRIPTING
	STA	WTOP		; SET WINDOW TO INCLUDE STATUS LINE

	STA CH			;HOME THE CURSOR
	STA EH
	STA CV
	JSR BASCAL

	LDA #$3F			;AND SET INVERSE VIDEO
	STA INVFLG

	; PRINT ROOM DESCRIPTION

	LDA	#16		; GLOBAL VAR #16 (ROOM ID)
	JSR	GETVRG		; GET IT INTO [VALUE]
	LDA	VALUE+LO
	JSR	PRNTDC		; PRINT SHORT ROOM DESCRIPTION

	LDA COL80			;GET 80 COL FLAG
	BEQ USL3		;NOT 80 COL
	LDA #60			;THIS IS WHERE TO PRINT SCORE/TIME
	BNE USL4		;(ALWAYS)
USL3:	LDA #23			;OLD MIDDLE OF SCREEN
USL4:	STA LENGTH

	LDA	#SPACE		; TRUNCATE LONG DESCS
	JSR	COUT		; WITH A SPACE

	LDA	#17		; GLOBAL VAR #17 (SCORE/HOURS)
	JSR	GETVRG		; GET IT INTO [VALUE]

	LDA	TIMEFL		; GET MODE FLAG
	BNE	DOTIME		; USE TIME MODE IF NON-ZERO

	; PRINT "SCORE"

	LDA	#'S'
	JSR	COUT
	LDA	#'c'
	JSR	COUT
	LDA	#'o'
	JSR	COUT
	LDA	#'r'
	JSR	COUT
	LDA	#'e'
	JSR	COUT
	LDA	#':'
	JSR	COUT
	LDA	#SPACE
	JSR	COUT

	LDA	VALUE+LO	; MOVE SCORE VALUE
	STA	QUOT+LO		; INTO [QUOT]
	LDA	VALUE+HI	; FOR PRINTING
	STA	QUOT+HI
	JSR	NUMBER		; PRINT SCORE VALUE IN DECIMAL

	LDA	#'/'		; PRINT A SLASH
	BNE	MOVMIN		; BRANCH ALWAYS

	; PRINT "TIME"

DOTIME:	LDA	#'T'
	JSR	COUT
	LDA	#'i'
	JSR	COUT
	LDA	#'m'
	JSR	COUT
	LDA	#'e'
	JSR	COUT
	LDA	#':'
	JSR	COUT
	LDA	#SPACE
	JSR	COUT

	LDA	VALUE+LO	; 00 IS REALLY 24
	BNE	DT0
	LDA	#24
DT0:	CMP	#13		; IS HOURS > 12,
	BCC	DT1
	SBC	#12		; CONVERT TO 1-12
DT1:	STA	QUOT+LO		; MOVE FOR PRINTING
	LDA	#0
	STA	QUOT+HI		; CLEAR MSB
	JSR	NUMBER

	LDA	#':'		; COLON

MOVMIN:	JSR	COUT		; PRINT SLASH OR COLON

	LDA	#18		; GLOBAL VAR #18 (MOVES/MINUTES)
	JSR	GETVRG		; GET IT INTO [VALUE]
	LDA	VALUE+LO	; MOVE TO [QUOT]
	STA	QUOT+LO		; FOR EVENTUAL PRINTING
	LDA	VALUE+HI
	STA	QUOT+HI

	LDA	TIMEFL		; WHICH MODE?
	BNE	DOMINS		; TIME IF NZ

	; PRINT NUMBER OF MOVES

	JSR	NUMBER		; SHOW # MOVES
	JMP	STATEX		; ALL DONE

	; PRINT MINUTES

DOMINS:	LDA	VALUE+LO	; CHECK MINUTES
	CMP	#10		; IF MORE THAN TEN
	BCS	DOM0		; CONTINUE

	LDA	#'0'		; ELSE PRINT A
	JSR	COUT		; PADDING "0" FIRST

DOM0:	JSR	NUMBER		; SHOW MINUTES

	LDA	#SPACE
	JSR	COUT		; SEPARATE THINGS

	LDA	#17		; CHECK "HOURS" AGAIN
	JSR	GETVRG
	LDA	VALUE+LO
	CMP	#12		; PAST NOON?
	BCS	DOPM		; YES, PRINT "PM"

	LDA	#'a'		; ELSE PRINT "AM"
	BNE	DOXM		; BRANCH ALWAYS

DOPM:	LDA	#'p'

DOXM:	JSR	COUT
	LDA	#'m'
	JSR	COUT

	; STATUS LINE READY

STATEX:	LDX	#0
STX0:	LDA	LBUFF,X		; GET A CHAR FROM [LBUFF]
	JSR	CHAR		; SEND TO SCREEN
	INX			; LOOP TILL
	CPX	LENGTH		; ALL CHARS SENT
	BCC	STX0

STX1:	CPX	WWIDTH		; REAL END OF LINE
	BCS	STX2
	LDA	#$A0		; FILL REST OF LINE WITH BLANKS
	JSR	MCOUT
	INX
	BNE	STX1		; MAX 80 SO IT'S A JUMP

STX2:	LDA #$0FF		;AND CLEAR OFF INVERSE
	STA INVFLG

	LDX	XSIZE		; RESTORE OLD [LBUFF]
STX3:	LDA	BUFSAV,X
	STA	LBUFF,X
	DEX
	BPL	STX3

	PLA			; RESTORE ALL
	STA	WTOP		; SAVED VARIABLES
	PLA
	STA	DIGITS
	PLA
	STA	ZFLAG
	PLA
	STA	ZWORD+LO
	PLA
	STA	ZWORD+HI
	PLA
	STA	PSET
	PLA
	STA	TSET
	PLA
	STA	MPCL
	PLA
	STA	MPCM
	PLA
	STA	MPCH
	PLA
	STA	LENGTH

	PLA			;RESTORE CURSOR POSITION
	STA CV
	PLA 
	STA CH
	PLA
	STA EH			;** IIe'S CH
	JSR BASCAL

	LDX	#$FF
	STX	SCRIPT		; RE-ENABLE SCRIPTING
	INX			; = 0
	STX	MPCFLG		; INVALIDATE [MPC]
	RTS


STRYM	DB	"The story is loading ..."
STRYML	EQU	$-STRYM

	END
