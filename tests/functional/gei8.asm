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
_a:
	DEFB 00
ZXBASIC_USER_DATA_END:
__MAIN_PROGRAM__:
	ld a, 5
	ld hl, (_a - 1)
	call __LEI8
	or a
	jp z, __LABEL1
	ld a, 255
	ld (16384), a
__LABEL1:
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
#line 1 "/zxbasic/src/arch/zx48k/library-asm/lei8.asm"
__LEI8: ; Signed <= comparison for 8bit int
	        ; A <= H (registers)
	    PROC
	    LOCAL checkParity
	    sub h
	    jr nz, __LTI
	    inc a
	    ret
__LTI8:  ; Test 8 bit values A < H
	    sub h
__LTI:   ; Generic signed comparison
	    jp po, checkParity
	    xor 0x80
checkParity:
	    ld a, 0     ; False
	    ret p
	    inc a       ; True
	    ret
	    ENDP
#line 25 "gei8.bas"
	END
