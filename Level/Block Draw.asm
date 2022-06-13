; -------------------------------------------------------------------------
; Sonic CD Disassembly
; By Ralakimus 2021
; -------------------------------------------------------------------------
; Block drawing functions
; -------------------------------------------------------------------------

; -------------------------------------------------------------------------
; Draw a row of blocks
; -------------------------------------------------------------------------
; PARAMETERS:
;	d0.l - Swapped VDP write command
;	d4.w - Y position
;	d5.w - X position
;	a3.l - Camera position pointer
;	a4.l - Layout data pointer
;	a5.l - VDP control port
;	a6.l - VDP data port
; -------------------------------------------------------------------------

DrawBlockRow:
	moveq	#((320+(16*2))/16)-1,d6		; 22 blocks in a row

DrawBlockRow2:
	move.l	#$800000,d7			; VDP command row delta
	move.l	d0,d1				; Copy VDP command

.Loop:
	movem.l	d4-d5,-(sp)			; Draw a block
	bsr.w	GetBlockData
	move.l	d1,d0
	bsr.w	DrawBlock
	addq.b	#4,d1				; Set up VDP command for next block
	andi.b	#$7F,d1
	movem.l	(sp)+,d4-d5

	addi.w	#16,d5				; Move right
	dbf	d6,.Loop			; Loop until finished

	rts

; -------------------------------------------------------------------------
; Draw a static row of blocks
; -------------------------------------------------------------------------
; PARAMETERS:
;	d0.l - Swapped VDP write command
;	d4.w - Y position
;	d5.w - X position
;	a3.l - Camera position pointer
;	a4.l - Layout data pointer
;	a5.l - VDP control port
;	a6.l - VDP data port
; -------------------------------------------------------------------------

DrawBlockRowAbsX:
	move.l	#$800000,d7			; VDP command row delta
	move.l	d0,d1				; Copy VDP command

.Draw:
	movem.l	d4-d5,-(sp)			; Draw a block
	bsr.w	GetBlockDataAbsX
	move.l	d1,d0
	bsr.w	DrawBlock
	addq.b	#4,d1				; Set up VDP command for next block
	andi.b	#$7F,d1
	movem.l	(sp)+,d4-d5

	addi.w	#16,d5				; Move right
	dbf	d6,.Draw			; Loop until finished

	rts

; -------------------------------------------------------------------------
; Draw a column of blocks
; -------------------------------------------------------------------------
; PARAMETERS:
;	d0.l - Swapped VDP write command
;	d4.w - Y position
;	d5.w - X position
;	a3.l - Camera position pointer
;	a4.l - Layout data pointer
;	a5.l - VDP control port
;	a6.l - VDP data port
; -------------------------------------------------------------------------

DrawBlockCol:
	moveq	#((224+(16*2))/16)-1,d6		; 16 blocks in a column
	move.l	#$800000,d7			; VDP command row delta
	move.l	d0,d1				; Copy VDP command

.Draw:
	movem.l	d4-d5,-(sp)			; Draw a block
	bsr.w	GetBlockData
	move.l	d1,d0
	bsr.w	DrawBlock
	addi.w	#$100,d1			; Set up VDP command for next block
	andi.w	#$FFF,d1
	movem.l	(sp)+,d4-d5

	addi.w	#16,d4				; Move down
	dbf	d6,.Draw			; Loop until finished

	rts

; -------------------------------------------------------------------------
; Draw a block
; -------------------------------------------------------------------------
; PARAMETERS:
;	d0.l - Swapped VDP write command
;	d4.w - Y position
;	d5.w - X position
;	a0.l - Block metadata pointer
;	a1.l - Block data pointer
;	a5.l - VDP control port
;	a6.l - VDP data port
; -------------------------------------------------------------------------

DrawBlock:
	or.w	d2,d0				; Add base high VDP word
	swap	d0

	btst	#4,(a0)				; Is this block flipped vertically?
	bne.s	.FlipY				; If so, branch
	btst	#3,(a0)				; Is this block flipped horizontally?
	bne.s	.FlipX				; If so, branch

	move.l	d0,(a5)				; Draw a block
	move.l	(a1)+,(a6)
	add.l	d7,d0
	move.l	d0,(a5)
	move.l	(a1)+,(a6)
	rts

; -------------------------------------------------------------------------

.FlipX:
	move.l	d0,(a5)				; Draw a block (flipped horizontally)
	move.l	(a1)+,d4
	eori.l	#$8000800,d4
	swap	d4
	move.l	d4,(a6)
	add.l	d7,d0
	move.l	d0,(a5)
	move.l	(a1)+,d4
	eori.l	#$8000800,d4
	swap	d4
	move.l	d4,(a6)
	rts

; -------------------------------------------------------------------------

.FlipY:
	btst	#3,(a0)				; Is this block flipped horizontally?
	bne.s	.FlipXY				; If so, branch

	move.l	d0,(a5)				; Draw a block (flipped vertically)
	move.l	(a1)+,d5
	move.l	(a1)+,d4
	eori.l	#$10001000,d4
	move.l	d4,(a6)
	add.l	d7,d0
	move.l	d0,(a5)
	eori.l	#$10001000,d5
	move.l	d5,(a6)
	rts

; -------------------------------------------------------------------------

.FlipXY:
	move.l	d0,(a5)				; Draw a block (flipped both ways)
	move.l	(a1)+,d5
	move.l	(a1)+,d4
	eori.l	#$18001800,d4
	swap	d4
	move.l	d4,(a6)
	add.l	d7,d0
	move.l	d0,(a5)
	eori.l	#$18001800,d5
	swap	d5
	move.l	d5,(a6)
	rts

; -------------------------------------------------------------------------
; Get the addresses of a block's metadata and data at a position relative
; to a camera
; -------------------------------------------------------------------------
; PARAMETERS:
;	d4.w - Y position
;	d5.w - X position
;	a3.l - Camera position pointer
;	a4.l - Layout data pointer
; RETURNS:
;	a0.l - Block metadata pointer
;	a1.l - Block data pointer
; -------------------------------------------------------------------------

GetBlockData:
	add.w	(a3),d5				; Add camera X position

GetBlockDataAbsX:
	add.w	4(a3),d4			; Add camera Y position

GetBlockDataAbsXY:
	lea	blockBuffer,a1			; Prepare block data pointer

	move.w	d4,d3				; Get the chunk that the block we want is in
	lsr.w	#1,d3
	andi.w	#$380,d3
	lsr.w	#3,d5
	move.w	d5,d0
	lsr.w	#5,d0
	andi.w	#$7F,d0
	add.w	d3,d0
	moveq	#0,d3
	move.b	(a4,d0.w),d3
	beq.s	.End				; If it's a blank chunk, branch out of here

	subq.b	#1,d3				; Get pointer to block metadata in the chunk
	andi.w	#$7F,d3
	ror.w	#7,d3
	add.w	d4,d4
	andi.w	#$1E0,d4
	andi.w	#$1E,d5
	add.w	d4,d3
	add.w	d5,d3
	add.l	#LevelChunks,d3			; Add base chunk data pointer
	movea.l	d3,a0

	move.w	(a0),d3				; Get pointer to block data
	andi.w	#$3FF,d3
	lsl.w	#3,d3
	adda.w	d3,a1

	moveq	#1,d0				; Mark block as retrieved

.End:
	rts

; -------------------------------------------------------------------------
; Calculate the base VDP command for drawing blocks with
; (For VRAM addresses $C000-$FFFF)
; -------------------------------------------------------------------------
; PARAMETERS:
;	d4.w - Y position
;	d5.w - X position
;	a3.l - Camera position pointer
; RETURNS:
;	d0.l - Base VDP command 
; -------------------------------------------------------------------------

GetBlockVDPCmd:
	add.w	(a3),d5				; Add camera X position

GetBlockVDPCmdAbsX:
	add.w	4(a3),d4			; Add camera Y position

GetBlockVDPCmdAbsXY:
	andi.w	#$F0,d4				; Calculate VDP command
	andi.w	#$1F0,d5
	lsl.w	#4,d4
	lsr.w	#2,d5
	add.w	d5,d4
	moveq	#3,d0
	swap	d0
	move.w	d4,d0

	rts

; -------------------------------------------------------------------------
; Calculate the base VDP command for drawing blocks with
; (For VRAM addresses $8000-$BFFF)
; -------------------------------------------------------------------------
; PARAMETERS:
;	d4.w - Y position
;	d5.w - X position
;	a3.l - Camera position pointer
; RETURNS:
;	d0.l - Base VDP command 
; -------------------------------------------------------------------------

GetBlockVDPCmd2:
	add.w	4(a3),d4			; Add camera Y position
	add.w	(a3),d5				; Add camera X position

	andi.w	#$F0,d4				; Calculate VDP command
	andi.w	#$1F0,d5
	lsl.w	#4,d4
	lsr.w	#2,d5
	add.w	d5,d4
	moveq	#2,d0
	swap	d0
	move.w	d4,d0

	rts
	
; -------------------------------------------------------------------------
