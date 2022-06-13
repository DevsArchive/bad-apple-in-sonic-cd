; -------------------------------------------------------------------------
; Bad Apple in Sonic CD
; By Ralakimus 2022
; -------------------------------------------------------------------------

	rsset	freeLevelVars
baDMABuffer	rs.b	$A			; DMA buffe
baLastRing	rs.b	1			; Last ring frame
		rs.b	1
baGetData	rs.b	$200			; Get data routine

; -------------------------------------------------------------------------
; Initialization
; -------------------------------------------------------------------------

InitBadApple:
	lea	baDMABuffer,a0			; Set up DMA buffer
	move.l	#$94009300,(a0)+
	move.l	#$97009600,(a0)+
	move.w	#$9500,(a0)+
	
	lea	baGetData,a0			; Copy data get routine
	lea	GetBadAppleData,a1
	move.w	#(GetBadAppleDataEnd-GetBadAppleData)/2-1,d0
	
.Copy:
	move.w	(a1)+,(a0)+
	dbf	d0,.Copy
	
	lea	BadAppleMapBuf,a0		; Clear map buffer
	move.w	#$1000/4-1,d0
	
.ClearMap:
	clr.l	(a0)+
	dbf	d0,.ClearMap
	
	move.w	#SCMD_BADAPPLE,GACOMCMD0	; Start Bad Apple
	move.w	#0,GACOMCMD2
	
.WaitStart:
	tst.w	GACOMSTAT0			; Has it started?
	beq.s	.WaitStart			; If not, wait
	
	st	baLastRing			; Reset last ring frame ID
	rts

; -------------------------------------------------------------------------
; Update
; -------------------------------------------------------------------------

UpdateBadApple:
	tst.b	levelStarted			; Has the level started?
	beq.s	.End				; If not, branch

	moveq	#0,d0				; Get ring frame
	move.b	ringAnimFrame,d0
	cmp.b	baLastRing,d0			; Has it changed?
	beq.s	.GetData			; If not, branch
	move.b	d0,baLastRing			; Update last ring frame ID
	
	lsl.w	#6,d0				; Get ring art address
	add.l	#(Art_BadAppleRings/2)+1,d0
	
	lea	baDMABuffer,a0			; Set up DMA parameters
	movep.l	d0,3(a0)
	move.w	#$80/2,d0
	movep.w	d0,1(a0)
	
	jsr	StopZ80				; Stop the Z80
	lea	VDPCTRL,a1			; Run DMA
	move.l	(a0)+,(a1)
	move.l	(a0)+,(a1)
	move.w	(a0)+,(a1)
	move.w	#$5C80,(a1)
	move.w	#$0081,-(sp)
	move.w	(sp)+,(a1)
	jsr	StartZ80			; Start the Z80

.GetData:
	jmp	baGetData			; Get data

.End:
	rts

; -------------------------------------------------------------------------	
; Get data
; -------------------------------------------------------------------------

GetBadAppleData:
	obj	baGetData
	
	btst	#0,lvlFrameCount+3		; Are we on an odd frame?
	bne.w	.End				; If so, branch

	move.w	#1,GACOMCMD4			; Request data
	
.WaitResponse:
	move.w	GACOMSTAT4,d0			; Get response
	beq.s	.WaitResponse			; If there is no response yet, wait
	bmi.s	.Stop				; If there is no data to retrieve, branch

.GiveWordRAM:
	bset	#1,GAMEMMODE			; Give Sub CPU Word RAM access
	beq.s	.GiveWordRAM			; If it hasn't been given yet, wait
	
.WaitData:
	btst	#0,GAMEMMODE			; Do we have Word RAM access?
	beq.s	.WaitData			; If not, branch
	
	jsr	StopZ80				; Stop the Z80
	lea	VDPCTRL,a5			; VDP control port
	move.l	#$94089300,(a5)			; DMA map buffer
	move.l	#$96009500|(((BadAppleMapBuf+2)>>1)&$FF)|(((BadAppleMapBuf+2)<<7)&$FF0000),(a5)
	move.w	#$9700|(((BadAppleMapBuf+2)>>17)&$7F),(a5)
	move.w	#$4000,(a5)
	move.w	#$83,-(sp)
	move.w	(sp)+,(a5)
	move.l	#$40000003,(a5)
	move.l	BadAppleMapBuf,-4(a5)
	jsr	StartZ80			; Start the Z80

.Stop:
	move.w	#0,GACOMCMD4			; Stop request
	
.WaitSubDone:
	tst.w	GACOMSTAT4			; Wait for the Sub CPU to finish up
	bne.s	.WaitSubDone

.End:
	rts

	objend
GetBadAppleDataEnd:
	
; -------------------------------------------------------------------------
; Data
; -------------------------------------------------------------------------

Art_BadAppleRings:
	incbin	"Level/_Data/Bad Apple/Rings.bin"
	even

; -------------------------------------------------------------------------
