	PAGE
	SBTTL "--- WARMSTART ROUTINE ---"

	; -------------
	; ZIP WARMSTART
	; -------------

WARM2:	LDA	#0		; CLEAR ALL Z-PAGE VARIABLES
	LDX	#ZEROPG
ST0:	STA	0,X
	INX
	CPX	#ZPGTOP
	BCC	ST0

	INC	ZSP+LO		; INIT Z-STACK POINTERS
	INC	OLDZSP+LO	; TO "1"
	INC	SCRIPT		; ENABLE SCRIPTING
	INC	SCREENF		; TURN DISPLAY ON
	INC	SIDEFLG		; SET SIDE 1
	INC	ZPURE		; TO FAKE OUT GETDSK SO READS 1ST SECTOR

	; GRAB THE FIRST BLOCK OF PRELOAD

	LDA	#HIGH ZBEGIN	; MSB OF PRELOAD START ADDRESS
	STA	ZCODE		; FREEZE IT HERE
	STA	DBUFF+HI	; LSB IS ALWAYS ZERO

	JSR	GETDSK		; [DBLOCK] SET TO Z-BLOCK 0
	BCC	CHKGAM
	JMP	DSKERR		; BAD DISK READ

	; EXTRACT GAME DATA FROM Z-CODE HEADER

CHKGAM:	LDA	ZBEGIN+ZVERS	; (EZIP) IS GAME AN EZIP?
	CMP	#4	
	BEQ	YESEZ		; YES, CONTINUE

; *** ERROR #16 -- NOT AN EZIP GAME ***
	LDA	#16	
	JMP	ZERROR	

; *** ERROR #0 -- INSUFFICIENT RAM ***
NORAM:	LDX	#5
	LDY	#0
	JSR	PLOT
	LDA	#0
	JMP	ZERROR

YESEZ:	LDX	ZBEGIN+ZENDLD	; MSB OF ENDLOAD POINTER
	INX			; ADD 1 TO GET
	STX	ZPURE		; 1ST "PURE" PAGE OF Z-CODE

	TXA			; MAKE SURE FITS IN MEMORY
	CLC
	ADC	ZCODE		; SIZE OF PRELOAD + START IN MEMORY
	STA	J		; SHOULD BE A VALUE = TO OR LT MEMTOP
	JSR	MEMTOP
	CMP	J
	BEQ	ITFITS
	BCC	NORAM		; OOPS

ITFITS:	LDA	ZBEGIN+ZMODE	; ENABLE SPLIT-SCREEN,
	ORA	#%00111011	; INVERSE, CURSOR CONTROL,
	STA	ZBEGIN+ZMODE	; SOUND (EZIP)
	LDA	#EZIPID		; SET INTERPRETER ID
	STA	ZBEGIN+ZINTWD	
	LDA	#VERSID	
	STA	ZBEGIN+ZINTWD+1	
	LDA	#$18		; AND SCREEN PARAMETERS
	STA	ZBEGIN+ZSCRWD	
	LDA	#40	
	STA	ZBEGIN+ZSCRWD+1	
	LDA	ZBEGIN+ZGLOBA	; GET MSB OF GLOBAL TABLE ADDR
	CLC			; CONVERT TO
	ADC	ZCODE		; ABSOLUTE ADDRESS
	STA	GLOBAL+HI	
	LDA	ZBEGIN+ZGLOBA+1	; LSB NEEDN'T CHANGE
	STA	GLOBAL+LO	
	LDA	ZBEGIN+ZFWORD	; DO SAME FOR FWORDS TABLE
	CLC		
	ADC	ZCODE	
	STA	FWORDS+HI	
	LDA	ZBEGIN+ZFWORD+1	; NO CHANGE FOR LSB
	STA	FWORDS+LO	
	LDA	ZBEGIN+ZOBJEC	; NOT TO MENTION
	CLC			; THE OBJECT TABLE
	ADC	ZCODE	
	STA	OBJTAB+HI	
	LDA	ZBEGIN+ZOBJEC+1	; LSB SAME
	STA	OBJTAB+LO	

	; FIND SIZE AND NUMBER OF SAVES

	LDA	ZBEGIN+ZPURBT	; SIZE OF IMPURE
SIZE0:	ADC	#6		; PLUS ZSTACK &...
	STA	SAVSIZ		; HOW MANY PAGES PER SAVE

	LDX	#0
	STX	NUMSAV
SIZE1:	INC	NUMSAV		; INC NUMSAVE WITH EACH 
	CLC			; POSSIBLE SAVE
	ADC	SAVSIZ
	BCC	SIZE1
SIZE2:	INC	NUMSAV		; TOTAL SIZE IS 170K, ($298)
	CLC
	ADC	SAVSIZ		; SO DO LOOP FOR 1ST & 2ND $100
	BCC	SIZE2
SIZE3:	CMP	#$98
	BCS	SIZE4		; BEYOND TOTAL DISK SIZE
	INC	NUMSAV
	CLC
	ADC	SAVSIZ
	BCC	SIZE3

SIZE4:	LDA	NUMSAV
	CMP	#$0A		; MAX OF 9 FOR EASE OF USE
	BCC	SIZE5
	LDA	#9
	STA	NUMSAV
SIZE5:	CLC
	ADC	#'0'
	STA	POSTOP		; SET POSITION MSG

	LDY	#1		; POSITION MESSAGE
	LDX	#14
	CLC
	JSR	PLOT

	LDX	#LOW TMSG
	LDA	#HIGH TMSG
	LDY	#TMSGL
	JSR	DLINE

	JMP	ENDTST

TMSG:	DB	"(Please be patient, this takes a while)"
	DB	EOL
TMSGL	EQU	$-TMSG

ENDTST:	JSR	INITPAG	
	JSR	CLS		; GET RID OF "LOADING" MSG
	LDA	ZBEGIN+ZGO	; GET START ADDRESS OF Z-CODE
	STA	ZPCM		; MSB
	LDA	ZBEGIN+ZGO+1	; AND LSB
	STA	ZPCL		; HIGH BIT ALREADY ZEROED
	JSR	VLDZPC		;MACKE ZPC VALID

	LDA	SFLAG		; CHECK IF RESTART & WERE PRINTING
	CMP	#1
	BNE	EX2		; NO
	STA	SCRIPTF		; YES, TURN SCRIPT FLAG ON
	ORA	ZBEGIN+ZSCRIP+1	; SET GAME FLAG ALSO
	STA	ZBEGIN+ZSCRIP+1	

EX2:	JSR	CLS		; CLEAR SCREEN ...

	; ... AND FALL INTO MAIN LOOP

	END