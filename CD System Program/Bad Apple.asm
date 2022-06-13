; -------------------------------------------------------------------------
; Bad Apple in Sonic CD
; By Ralakimus 2022
; -------------------------------------------------------------------------

; -------------------------------------------------------------------------
; Run Bad Apple stream
; -------------------------------------------------------------------------

BADAPPLE_BUF1	EQU	$10000			; Buffer 1
BADAPPLE_BUF2	EQU	$20000			; Buffer 2

; -------------------------------------------------------------------------

SPCmd_BadApple:
	bclr	#3,GAIRQMASK.w			; Disable timer interrupt
	move.l	#0,curPCMDriver.w		; Reset current PCM driver
	lea	CDReadVars(pc),a6		; CD read parameters
	
	move.w	#CDCSTOP,d0			; Stop CDC
	jsr	_CDBIOS.w
	move.w	#MSCSTOP,d0			; Stop CDDA
	jsr	_CDBIOS.w
	
	lea	BADAPPLE_BUF1,a0		; Clear buffers
	move.l	#$20000/4-1,d0
	
.ClearBuffers:
	clr.l	(a0)+
	dbf	d0,.ClearBuffers
	
	move.w	#0,GACOMSTAT2.w			; Reset frame count
	move.w	#0,GACOMSTAT4.w			; Reset response
	
	moveq	#16-1,d0			; Clear wave RAM
	moveq	#$FFFFFF80,d1
	
.ClearPCMWave:
	lea	PCMWAVE,a0
	move.b	d1,PCMCTRL
	moveq	#20-1,d2
	dbf	d2,*
	move.w	#$1000-1,d2

.ClearPCMWaveLoop:
	move.b	#0,(a0)+
	addq.w	#1,a0
	dbf	d2,.ClearPCMWaveLoop
	addq.w	#1,d1
	dbf	d0,.ClearPCMWave
	
	move.b	#$40,PCMCTRL			; Disable sound and control PCM1
	moveq	#10-1,d0
	dbf	d0,*
	move.b	#$FF,PCMONOFF			; Mute all channels
	moveq	#10-1,d0
	dbf	d0,*
	
	move.b	#$FF,PCMENV			; Set up PCM1
	moveq	#10-1,d0
	dbf	d0,*
	move.b	#$FF,PCMPAN
	moveq	#10-1,d0
	dbf	d0,*
	if REGION=EUROPE
		move.b	#$AB,PCMFDL
		moveq	#10-1,d0
		dbf	d0,*
		move.b	#$06,PCMFDH
		moveq	#10-1,d0
		dbf	d0,*
	else
		move.b	#$0E,PCMFDL
		moveq	#10-1,d0
		dbf	d0,*
		move.b	#$08,PCMFDH
		moveq	#10-1,d0
		dbf	d0,*
	endif
	move.b	#$00,PCMLSL
	moveq	#10-1,d0
	dbf	d0,*
	move.b	#$00,PCMLSH
	moveq	#10-1,d0
	dbf	d0,*
	move.b	#$00,PCMST
	moveq	#10-1,d0
	dbf	d0,*
	
	move.b	#$FE,PCMONOFF			; Enable PCM1
	moveq	#10-1,d0
	dbf	d0,*
	
	moveq	#FFUNC_FINDFILE,d0		; Get FMV file location
	lea	File_BadApple,a0
	jsr	FileFunc.w
	bcs.w	.Stop
	move.l	fileSector(a0),(a6)
	move.l	fileLength(a0),d0
	lsr.l	#8,d0
	lsr.l	#3,d0
	move.w	d0,SectorsLeft
	
	clr.b	ReadMode			; Reset CD read mode
	clr.b	BufferID			; Reset buffer ID
	move.b	#$88,PCMBank			; Set PCM bank
	
	move.w	#1,GACOMSTAT0.w			; Mark as running

; -------------------------------------------------------------------------

.Loop:
	tst.b	ReadMode			; Are we reading data?
	bne.w	.CheckReadMode			; If so, branch
	tst.w	GACOMCMD2.w			; Should we stop?
	bne.w	.Stop				; If so, branch

	tst.w	GACOMSTAT2.w			; Should we read more data?
	bne.w	.CheckMain			; If not, branch
	move.w	#30,GACOMSTAT2.w		; Set number of frames left to be read

	move.l	#$A800/$800,4(a6)		; Set up CD read parameters
	move.l	#BADAPPLE_BUF1,8(a6)
	move.l	#BADAPPLE_BUF2,CopyPointer
	move.l	#BADAPPLE_BUF2+$2800,PCMCopyPtr
	bchg	#0,BufferID
	beq.s	.SetHeaderBuf
	move.l	#BADAPPLE_BUF2,8(a6)
	move.l	#BADAPPLE_BUF1,CopyPointer
	move.l	#BADAPPLE_BUF1+$2800,PCMCopyPtr
	
.SetHeaderBuf:
	move.l	#HeaderBuf,$C(a6)
	
	move.w	SectorsLeft,d0			; Get sectors remaining
	sub.w	4+2(a6),d0
	move.w	d0,SectorsLeft
	bmi.w	SPCmd_BadApple			; If there are none, restart
	
	move.b	#8,PCMBanksLeft			; Set up PCM stream

	move.w	#CDCSTOP,d0			; Stop CDC
	jsr	_CDBIOS.w
	movea.l	a6,a0				; Begin operation
	move.w	#ROMREADN,d0
	jsr	_CDBIOS.w
	
	move.b	#1,ReadMode			; Mark as waiting for data to be ready
	bra.s	.CheckPrepare

.CheckReadMode:
	cmpi.b	#2,ReadMode			; Are we waiting for a frame of data to be ready?
	beq.s	.CheckFrame			; If so, branch
	cmpi.b	#3,ReadMode			; Are we waiting for the data to be transfered?
	beq.s	.CheckTransfer			; If so, branch

.CheckPrepare:
	movea.l	a6,a0				; Is the data prepared?
	move.w	#CDCSTAT,d0
	jsr	_CDBIOS.w
	bcs.s	.CheckMain			; If not, branch
	
	move.b	#2,ReadMode			; Mark as waiting for frame of data
	
.CheckFrame:
	movea.l	a6,a0				; Is a frame of data ready?
	move.w	#CDCREAD,d0
	jsr	_CDBIOS.w
	bcs.s	.CheckMain			; If not, branch
	
	move.b	#3,ReadMode			; Mark as waiting for transfer
	
.CheckTransfer:
	movea.l	8(a6),a0			; Transfer the data
	lea	$C(a6),a1
	move.w	#CDCTRN,d0
	jsr	_CDBIOS.w
	bcs.s	.CheckMain			; If it's not done, branch

	move.w	#CDCACK,d0			; Finish
	jsr	_CDBIOS.w
	
	move.b	#1,ReadMode			; Mark as waiting for data to be ready
	addi.l	#$800,8(a6)			; Next sector
	addq.l	#1,(a6)
	move.l	#HeaderBuf,$C(a6)
	subq.l	#1,4(a6)
	bne.s	.CheckMain			; If we are not done, keep reading
	clr.b	ReadMode			; Mark as not reading

.CheckMain:
	tst.w	GACOMCMD4.w			; Is the Main CPU requesting data?
	beq.w	.Loop				; If not, branch
	tst.w	GACOMSTAT2.w			; Do we have any frames left?
	beq.w	.NoFrames			; If not, branch

	move.w	#1,GACOMSTAT4.w			; Request Word RAM access
	
.WaitWordRAM:
	btst	#1,GAMEMMODE.w			; Wait for Word RAM access
	beq.s	.WaitWordRAM
	
	subq.w	#1,GACOMSTAT2.w			; Decrement frame count
	
	movea.l	CopyPointer,a0			; Copy frame data
	lea	WORDRAM2M+$100,a1
	moveq	#$1C/2-1,d1
	
.RowCopy:
	movea.l	a1,a2
	moveq	#$28/2-1,d0
	
.TileCopy:
	tst.b	(a0)+
	bne.s	.WriteRing
	
	clr.l	(a2)+
	clr.l	$80-4(a2)
	
	bra.s	.NextTile
	
.WriteRing:
	move.l	#$A2E4A2E6,(a2)+
	move.l	#$A2E5A2E7,$80-4(a2)

.NextTile:
	dbf	d0,.TileCopy
	lea	$100(a1),a1
	dbf	d1,.RowCopy
	
	move.l	a0,CopyPointer
	
	tst.b	PCMBanksLeft			; Are there any banks left to stream to?
	beq.s	.NoPCMStream			; If not, branch
	
	move.b	PCMBank,PCMCTRL			; Set PCM bank
	moveq	#20-1,d0
	dbf	d0,*

	move.b	PCMADDR1H,d1			; Should we be streaming yet?
	moveq	#20-1,d0
	dbf	d0,*
	move.b	PCMBank,d0
	lsl.b	#4,d0
	eor.b	d1,d0
	andi.b	#$80,d0
	beq.s	.NoPCMStream			; If not, branch
	
.StartPCMCopy:
	movea.l	PCMCopyPtr,a0			; Copy PCM sample data
	lea	PCMWAVE,a1
	move.w	#$1000-1,d0
	
.CopyPCM:
	move.b	(a0)+,(a1)+
	addq.w	#1,a1
	dbf	d0,.CopyPCM
	move.l	a0,PCMCopyPtr

	addq.b	#1,PCMBank			; Next bank
	andi.b	#$8F,PCMBank
	subq.b	#1,PCMBanksLeft

.NoPCMStream:
	bra.s	.GiveWordRAM

.NoFrames:
	move.w	#-1,GACOMSTAT4.w		; We have no frames left
	
.GiveWordRAM:
	bset	#0,GAMEMMODE.w			; Give Main CPU Word RAM access
	beq.s	.GiveWordRAM			; If it hasn't been given, wait
	
.WaitMainDone:
	tst.w	GACOMCMD4.w			; Is the Main CPU done?
	bne.s	.WaitMainDone			; If not, wait
	move.w	#0,GACOMSTAT4.w			; We are done here
	bra.w	.Loop				; Loop

; -------------------------------------------------------------------------

.Stop:
	move.w	#CDCSTOP,d0			; Stop CDC
	jsr	_CDBIOS.w
	
	move.b	#$40,PCMCTRL			; Disable sound
	moveq	#10-1,d0
	dbf	d0,*
	move.b	#$FF,PCMONOFF			; Mute all channels
	moveq	#10-1,d0
	dbf	d0,*
	
	move.l	#SPIRQ2,_USERCALL2+2.w		; Restore IRQ2
	andi.b	#$FA,GAMEMMODE.w		; Set to 2M mode
	move.b	#3,GACDCDEVICE.w		; Set CDC device to "Sub CPU"
	move.w	#0,GACOMSTAT0.w			; Mark as stopped
	rts

; -------------------------------------------------------------------------

CDReadVars:
	dc.l	0				; Start sector
	dc.l	0				; Number of sectors
	dc.l	0				; Read buffer
	dc.l	0				; Header buffer

HeaderBuf:					; Header buffer
	dc.l	0
SectorsLeft:					; Number of sectors left
	dc.w	0
ReadMode:					; CD read mode
	dc.b	0
BufferID:					; Buffer ID
	dc.b	0
CopyPointer:					; Copy pointer
	dc.l	0
PCMCopyPtr:					; PCM copy pointer
	dc.l	0
PCMBanksLeft:					; PCM banks left
	dc.b	0
PCMBank:					; PCM bank control
	dc.b	0

; -------------------------------------------------------------------------
