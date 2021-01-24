	org 32768
__START_PROGRAM:
	di
	push ix
	push iy
	exx
	push hl
	exx
	ld hl, 0
	add hl, sp
	ld (__CALL_BACK__), hl
	ei
	jp __MAIN_PROGRAM__
__CALL_BACK__:
	DEFW 0
ZXBASIC_USER_DATA:
	; Defines USER DATA Length in bytes
ZXBASIC_USER_DATA_LEN EQU ZXBASIC_USER_DATA_END - ZXBASIC_USER_DATA
	.__LABEL__.ZXBASIC_USER_DATA_LEN EQU ZXBASIC_USER_DATA_LEN
	.__LABEL__.ZXBASIC_USER_DATA EQU ZXBASIC_USER_DATA
ZXBASIC_USER_DATA_END:
__MAIN_PROGRAM__:
#line 3 "use_zxnext_asm.bas"
		LDIX
		LDWS
		LDIRX
		LDDX
		LDDRX
		LDPIRX
		OUTINB
		MUL D,E
		ADD HL,A
		ADD DE,A
		ADD BC,A
		ADD HL,0201h
		ADD DE,0201h
		ADD BC,0201h
		SWAPNIB
		MIRROR
		PUSH 4321h
		NEXTREG 37h,38h
		NEXTREG 33h,A
		PIXELDN
		PIXELAD
		SETAE
		TEST 77h
		BSLA DE,B
		BSRA DE,B
		BSRL DE,B
		BSRF DE,B
		BRLC DE,B
		JP (C)
#line 33 "use_zxnext_asm.bas"
	ld hl, 0
	ld b, h
	ld c, l
__END_PROGRAM:
	di
	ld hl, (__CALL_BACK__)
	ld sp, hl
	exx
	pop hl
	exx
	pop iy
	pop ix
	ei
	ret
	;; --- end of user code ---
	END
