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
	call __MEM_INIT
	jp __MAIN_PROGRAM__
__CALL_BACK__:
	DEFW 0
ZXBASIC_USER_DATA:
	; Defines HEAP SIZE
ZXBASIC_HEAP_SIZE EQU 4768
ZXBASIC_MEM_HEAP:
	DEFS 4768
	; Defines USER DATA Length in bytes
ZXBASIC_USER_DATA_LEN EQU ZXBASIC_USER_DATA_END - ZXBASIC_USER_DATA
	.__LABEL__.ZXBASIC_USER_DATA_LEN EQU ZXBASIC_USER_DATA_LEN
	.__LABEL__.ZXBASIC_USER_DATA EQU ZXBASIC_USER_DATA
_b:
	DEFB 00, 00
_c:
	DEFB 00, 00
ZXBASIC_USER_DATA_END:
__MAIN_PROGRAM__:
	call _test3
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
_test1:
	push ix
	ld ix, 0
	add ix, sp
	ld hl, 0
	ld (_b), hl
	jp __LABEL0
__LABEL3:
	ld hl, (_b)
	push hl
	ld l, (ix+4)
	ld h, (ix+5)
	call __UBOUND
	ld (_c), hl
__LABEL4:
	ld hl, (_b)
	inc hl
	ld (_b), hl
__LABEL0:
	ld hl, 3
	ld de, (_b)
	or a
	sbc hl, de
	jp nc, __LABEL3
__LABEL2:
_test1__leave:
	ld sp, ix
	pop ix
	exx
	pop hl
	ex (sp), hl
	exx
	ret
_test3:
	push ix
	ld ix, 0
	add ix, sp
	ld hl, -8
	add hl, sp
	ld sp, hl
	ld (hl), 0
	ld bc, 7
	ld d, h
	ld e, l
	inc de
	ldir
	ld hl, _test3_a.__UBOUND__
	push hl
	ld hl, 0
	push hl
	ld hl, -8
	ld de, __LABEL5
	ld bc, 9
	call __ALLOC_LOCAL_ARRAY_WITH_BOUNDS
	push ix
	pop hl
	ld de, -8
	add hl, de
	push hl
	call _test1
_test3__leave:
	ex af, af'
	exx
	ld l, (ix-6)
	ld h, (ix-5)
	call __MEM_FREE
	ex af, af'
	exx
	ld sp, ix
	pop ix
	ret
_test3_a.__UBOUND__:
	DEFW 0005h
	DEFW 0009h
	;; --- end of user code ---
#line 1 "/zxbasic/src/arch/zx48k/library-asm/arrayalloc.asm"
#line 1 "/zxbasic/src/arch/zx48k/library-asm/calloc.asm"
; vim: ts=4:et:sw=4:
	; Copyleft (K) by Jose M. Rodriguez de la Rosa
	;  (a.k.a. Boriel)
;  http://www.boriel.com
	;
	; This ASM library is licensed under the MIT license
	; you can use it for any purpose (even for commercial
	; closed source programs).
	;
	; Please read the MIT license on the internet
#line 1 "/zxbasic/src/arch/zx48k/library-asm/alloc.asm"
; vim: ts=4:et:sw=4:
	; Copyleft (K) by Jose M. Rodriguez de la Rosa
	;  (a.k.a. Boriel)
;  http://www.boriel.com
	;
	; This ASM library is licensed under the MIT license
	; you can use it for any purpose (even for commercial
	; closed source programs).
	;
	; Please read the MIT license on the internet
	; ----- IMPLEMENTATION NOTES ------
	; The heap is implemented as a linked list of free blocks.
; Each free block contains this info:
	;
	; +----------------+ <-- HEAP START
	; | Size (2 bytes) |
	; |        0       | <-- Size = 0 => DUMMY HEADER BLOCK
	; +----------------+
	; | Next (2 bytes) |---+
	; +----------------+ <-+
	; | Size (2 bytes) |
	; +----------------+
	; | Next (2 bytes) |---+
	; +----------------+   |
	; | <free bytes...>|   | <-- If Size > 4, then this contains (size - 4) bytes
	; | (0 if Size = 4)|   |
	; +----------------+ <-+
	; | Size (2 bytes) |
	; +----------------+
	; | Next (2 bytes) |---+
	; +----------------+   |
	; | <free bytes...>|   |
	; | (0 if Size = 4)|   |
	; +----------------+   |
	;   <Allocated>        | <-- This zone is in use (Already allocated)
	; +----------------+ <-+
	; | Size (2 bytes) |
	; +----------------+
	; | Next (2 bytes) |---+
	; +----------------+   |
	; | <free bytes...>|   |
	; | (0 if Size = 4)|   |
	; +----------------+ <-+
	; | Next (2 bytes) |--> NULL => END OF LIST
	; |    0 = NULL    |
	; +----------------+
	; | <free bytes...>|
	; | (0 if Size = 4)|
	; +----------------+
	; When a block is FREED, the previous and next pointers are examined to see
	; if we can defragment the heap. If the block to be freed is just next to the
	; previous, or to the next (or both) they will be converted into a single
	; block (so defragmented).
	;   MEMORY MANAGER
	;
	; This library must be initialized calling __MEM_INIT with
	; HL = BLOCK Start & DE = Length.
	; An init directive is useful for initialization routines.
	; They will be added automatically if needed.
#line 1 "/zxbasic/src/arch/zx48k/library-asm/error.asm"
	; Simple error control routines
; vim:ts=4:et:
	ERR_NR    EQU    23610    ; Error code system variable
	; Error code definitions (as in ZX spectrum manual)
; Set error code with:
	;    ld a, ERROR_CODE
	;    ld (ERR_NR), a
	ERROR_Ok                EQU    -1
	ERROR_SubscriptWrong    EQU     2
	ERROR_OutOfMemory       EQU     3
	ERROR_OutOfScreen       EQU     4
	ERROR_NumberTooBig      EQU     5
	ERROR_InvalidArg        EQU     9
	ERROR_IntOutOfRange     EQU    10
	ERROR_NonsenseInBasic   EQU    11
	ERROR_InvalidFileName   EQU    14
	ERROR_InvalidColour     EQU    19
	ERROR_BreakIntoProgram  EQU    20
	ERROR_TapeLoadingErr    EQU    26
	; Raises error using RST #8
__ERROR:
	    ld (__ERROR_CODE), a
	    rst 8
__ERROR_CODE:
	    nop
	    ret
	; Sets the error system variable, but keeps running.
	; Usually this instruction if followed by the END intermediate instruction.
__STOP:
	    ld (ERR_NR), a
	    ret
#line 69 "/zxbasic/src/arch/zx48k/library-asm/alloc.asm"
#line 1 "/zxbasic/src/arch/zx48k/library-asm/heapinit.asm"
; vim: ts=4:et:sw=4:
	; Copyleft (K) by Jose M. Rodriguez de la Rosa
	;  (a.k.a. Boriel)
;  http://www.boriel.com
	;
	; This ASM library is licensed under the BSD license
	; you can use it for any purpose (even for commercial
	; closed source programs).
	;
	; Please read the BSD license on the internet
	; ----- IMPLEMENTATION NOTES ------
	; The heap is implemented as a linked list of free blocks.
; Each free block contains this info:
	;
	; +----------------+ <-- HEAP START
	; | Size (2 bytes) |
	; |        0       | <-- Size = 0 => DUMMY HEADER BLOCK
	; +----------------+
	; | Next (2 bytes) |---+
	; +----------------+ <-+
	; | Size (2 bytes) |
	; +----------------+
	; | Next (2 bytes) |---+
	; +----------------+   |
	; | <free bytes...>|   | <-- If Size > 4, then this contains (size - 4) bytes
	; | (0 if Size = 4)|   |
	; +----------------+ <-+
	; | Size (2 bytes) |
	; +----------------+
	; | Next (2 bytes) |---+
	; +----------------+   |
	; | <free bytes...>|   |
	; | (0 if Size = 4)|   |
	; +----------------+   |
	;   <Allocated>        | <-- This zone is in use (Already allocated)
	; +----------------+ <-+
	; | Size (2 bytes) |
	; +----------------+
	; | Next (2 bytes) |---+
	; +----------------+   |
	; | <free bytes...>|   |
	; | (0 if Size = 4)|   |
	; +----------------+ <-+
	; | Next (2 bytes) |--> NULL => END OF LIST
	; |    0 = NULL    |
	; +----------------+
	; | <free bytes...>|
	; | (0 if Size = 4)|
	; +----------------+
	; When a block is FREED, the previous and next pointers are examined to see
	; if we can defragment the heap. If the block to be breed is just next to the
	; previous, or to the next (or both) they will be converted into a single
	; block (so defragmented).
	;   MEMORY MANAGER
	;
	; This library must be initialized calling __MEM_INIT with
	; HL = BLOCK Start & DE = Length.
	; An init directive is useful for initialization routines.
	; They will be added automatically if needed.
	; ---------------------------------------------------------------------
	;  __MEM_INIT must be called to initalize this library with the
	; standard parameters
	; ---------------------------------------------------------------------
__MEM_INIT: ; Initializes the library using (RAMTOP) as start, and
	        ld hl, ZXBASIC_MEM_HEAP  ; Change this with other address of heap start
	        ld de, ZXBASIC_HEAP_SIZE ; Change this with your size
	; ---------------------------------------------------------------------
	;  __MEM_INIT2 initalizes this library
; Parameters:
;   HL : Memory address of 1st byte of the memory heap
;   DE : Length in bytes of the Memory Heap
	; ---------------------------------------------------------------------
__MEM_INIT2:
	        ; HL as TOP
	        PROC
	        dec de
	        dec de
	        dec de
	        dec de        ; DE = length - 4; HL = start
	        ; This is done, because we require 4 bytes for the empty dummy-header block
	        xor a
	        ld (hl), a
	        inc hl
        ld (hl), a ; First "free" block is a header: size=0, Pointer=&(Block) + 4
	        inc hl
	        ld b, h
	        ld c, l
	        inc bc
	        inc bc      ; BC = starts of next block
	        ld (hl), c
	        inc hl
	        ld (hl), b
	        inc hl      ; Pointer to next block
	        ld (hl), e
	        inc hl
	        ld (hl), d
	        inc hl      ; Block size (should be length - 4 at start); This block contains all the available memory
	        ld (hl), a ; NULL (0000h) ; No more blocks (a list with a single block)
	        inc hl
	        ld (hl), a
	        ld a, 201
	        ld (__MEM_INIT), a; "Pokes" with a RET so ensure this routine is not called again
	        ret
	        ENDP
#line 70 "/zxbasic/src/arch/zx48k/library-asm/alloc.asm"
	; ---------------------------------------------------------------------
	; MEM_ALLOC
	;  Allocates a block of memory in the heap.
	;
	; Parameters
	;  BC = Length of requested memory block
	;
; Returns:
	;  HL = Pointer to the allocated block in memory. Returns 0 (NULL)
	;       if the block could not be allocated (out of memory)
	; ---------------------------------------------------------------------
MEM_ALLOC:
__MEM_ALLOC: ; Returns the 1st free block found of the given length (in BC)
	        PROC
	        LOCAL __MEM_LOOP
	        LOCAL __MEM_DONE
	        LOCAL __MEM_SUBTRACT
	        LOCAL __MEM_START
	        LOCAL TEMP, TEMP0
	TEMP EQU TEMP0 + 1
	        ld hl, 0
	        ld (TEMP), hl
__MEM_START:
	        ld hl, ZXBASIC_MEM_HEAP  ; This label point to the heap start
	        inc bc
	        inc bc  ; BC = BC + 2 ; block size needs 2 extra bytes for hidden pointer
__MEM_LOOP:  ; Loads lengh at (HL, HL+). If Lenght >= BC, jump to __MEM_DONE
	        ld a, h ;  HL = NULL (No memory available?)
	        or l
#line 111 "/zxbasic/src/arch/zx48k/library-asm/alloc.asm"
	        ret z ; NULL
#line 113 "/zxbasic/src/arch/zx48k/library-asm/alloc.asm"
	        ; HL = Pointer to Free block
	        ld e, (hl)
	        inc hl
	        ld d, (hl)
	        inc hl          ; DE = Block Length
	        push hl         ; HL = *pointer to -> next block
	        ex de, hl
	        or a            ; CF = 0
	        sbc hl, bc      ; FREE >= BC (Length)  (HL = BlockLength - Length)
	        jp nc, __MEM_DONE
	        pop hl
	        ld (TEMP), hl
	        ex de, hl
	        ld e, (hl)
	        inc hl
	        ld d, (hl)
	        ex de, hl
	        jp __MEM_LOOP
__MEM_DONE:  ; A free block has been found.
	             ; Check if at least 4 bytes remains free (HL >= 4)
	        push hl
	        exx  ; exx to preserve bc
	        pop hl
	        ld bc, 4
	        or a
	        sbc hl, bc
	        exx
	        jp nc, __MEM_SUBTRACT
	        ; At this point...
	        ; less than 4 bytes remains free. So we return this block entirely
	        ; We must link the previous block with the next to this one
	        ; (DE) => Pointer to next block
	        ; (TEMP) => &(previous->next)
	        pop hl     ; Discard current block pointer
	        push de
	        ex de, hl  ; DE = Previous block pointer; (HL) = Next block pointer
	        ld a, (hl)
	        inc hl
	        ld h, (hl)
	        ld l, a    ; HL = (HL)
	        ex de, hl  ; HL = Previous block pointer; DE = Next block pointer
TEMP0:
	        ld hl, 0   ; Pre-previous block pointer
	        ld (hl), e
	        inc hl
	        ld (hl), d ; LINKED
	        pop hl ; Returning block.
	        ret
__MEM_SUBTRACT:
	        ; At this point we have to store HL value (Length - BC) into (DE - 2)
	        ex de, hl
	        dec hl
	        ld (hl), d
	        dec hl
	        ld (hl), e ; Store new block length
	        add hl, de ; New length + DE => free-block start
	        pop de     ; Remove previous HL off the stack
	        ld (hl), c ; Store length on its 1st word
	        inc hl
	        ld (hl), b
	        inc hl     ; Return hl
	        ret
	        ENDP
#line 13 "/zxbasic/src/arch/zx48k/library-asm/calloc.asm"
	; ---------------------------------------------------------------------
	; MEM_CALLOC
	;  Allocates a block of memory in the heap, and clears it filling it
	;  with 0 bytes
	;
	; Parameters
	;  BC = Length of requested memory block
	;
; Returns:
	;  HL = Pointer to the allocated block in memory. Returns 0 (NULL)
	;       if the block could not be allocated (out of memory)
	; ---------------------------------------------------------------------
__MEM_CALLOC:
	        push bc
	        call __MEM_ALLOC
	        pop bc
	        ld a, h
	        or l
	        ret z  ; No memory
	        ld (hl), 0
	        dec bc
	        ld a, b
	        or c
	        ret z  ; Already filled (1 byte-length block)
	        ld d, h
	        ld e, l
	        inc de
	        push hl
	        ldir
	        pop hl
	        ret
#line 3 "/zxbasic/src/arch/zx48k/library-asm/arrayalloc.asm"
	; ---------------------------------------------------------------------
	; __ALLOC_LOCAL_ARRAY
	;  Allocates an array element area in the heap, and clears it filling it
	;  with 0 bytes
	;
	; Parameters
	;  HL = Offset to be added to IX => HL = IX + HL
	;  BC = Length of the element area = n.elements * size(element)
	;  DE = PTR to the index table
	;
; Returns:
	;  HL = (IX + HL) + 4
	; ---------------------------------------------------------------------
__ALLOC_LOCAL_ARRAY:
	    push de
	    push ix
	    pop de
	    add hl, de  ; hl = ix + hl
	    pop de
	    ld (hl), e
	    inc hl
	    ld (hl), d
	    inc hl
	    push hl
	    call __MEM_CALLOC
	    pop de
	    ex de, hl
	    ld (hl), e
	    inc hl
	    ld (hl), d
	    ret
	; ---------------------------------------------------------------------
	; __ALLOC_INITIALIZED_LOCAL_ARRAY
	;  Allocates an array element area in the heap, and clears it filling it
	;  with 0 bytes
	;
	; Parameters
	;  HL = Offset to be added to IX => HL = IX + HL
	;  BC = Length of the element area = n.elements * size(element)
	;  DE = PTR to the index table
	;  [SP + 2] = PTR to the element area
	;
; Returns:
	;  HL = (IX + HL) + 4
	; ---------------------------------------------------------------------
__ALLOC_INITIALIZED_LOCAL_ARRAY:
	    push bc
	    call __ALLOC_LOCAL_ARRAY
	    pop bc
	    ;; Swaps [SP], [SP + 2]
	    exx
	    pop hl       ; HL <- RET address
	    ex (sp), hl  ; HL <- Data table, [SP] <- RET address
	    push hl      ; [SP] <- Data table
	    exx
	    ex (sp), hl  ; HL = Data table, (SP) = (IX + HL + 4) - start of array address lbound
	    ; HL = data table
	    ; BC = length
	    ; DE = new data area
	    ldir
	    pop hl  ; HL = addr of LBound area if used
	    ret
	; ---------------------------------------------------------------------
	; __ALLOC_LOCAL_ARRAY_WITH_BOUNDS
	;  Allocates an array element area in the heap, and clears it filling it
	;  with 0 bytes. Then sets LBOUND and UBOUND ptrs
	;
	; Parameters
	;  HL = Offset to be added to IX => HL = IX + HL
	;  BC = Length of the element area = n.elements * size(element)
	;  DE = PTR to the index table
	;  [SP + 2] PTR to the lbound element area
	;  [SP + 4] PTR to the ubound element area
	;
; Returns:
	;  HL = (IX + HL) + 8
	; ---------------------------------------------------------------------
__ALLOC_LOCAL_ARRAY_WITH_BOUNDS:
	    call __ALLOC_LOCAL_ARRAY
__ALLOC_LOCAL_ARRAY_WITH_BOUNDS2:
	    pop bc   ;; ret address
	    pop de   ;; lbound
	    inc hl
	    ld (hl), e
	    inc hl
	    ld (hl), d
	    pop de
	    inc hl
	    ld (hl), e
	    inc hl
	    ld (hl), d
	    push bc
	    ret
	; ---------------------------------------------------------------------
	; __ALLOC_INITIALIZED_LOCAL_ARRAY_WITH_BOUNDS
	;  Allocates an array element area in the heap, and clears it filling it
	;  with 0 bytes
	;
	; Parameters
	;  HL = Offset to be added to IX => HL = IX + HL
	;  BC = Length of the element area = n.elements * size(element)
	;  DE = PTR to the index table
	;  TOP of the stack = PTR to the element area
	;  [SP + 2] = PTR to the element area
	;  [SP + 4] = PTR to the lbound element area
	;  [SP + 6] = PTR to the ubound element area
	;
; Returns:
	;  HL = (IX + HL) + 8
	; ---------------------------------------------------------------------
__ALLOC_INITIALIZED_LOCAL_ARRAY_WITH_BOUNDS:
	    ;; Swaps [SP] and [SP + 2]
	    exx
	    pop hl       ;; Ret address
	    ex (sp), hl  ;; HL <- PTR to Element area, (sp) = Ret address
	    push hl      ;; [SP] = PTR to element area, [SP + 2] = Ret address
	    exx
	    call __ALLOC_INITIALIZED_LOCAL_ARRAY
	    jp __ALLOC_LOCAL_ARRAY_WITH_BOUNDS2
#line 137 "/zxbasic/src/arch/zx48k/library-asm/arrayalloc.asm"
#line 92 "ubound10.bas"
#line 1 "/zxbasic/src/arch/zx48k/library-asm/bound.asm"
	; ---------------------------------------------------------
	; Copyleft (k)2011 by Jose Rodriguez (a.k.a. Boriel)
; http://www.boriel.com
	;
; ZX BASIC Compiler http://www.zxbasic.net
	; This code is released under the BSD License
	; ---------------------------------------------------------
	; Implements both LBOUND(array, N) and UBOUND(array, N) function
; Parameters:
	; HL = PTR to array
	; [stack - 2] -> N (dimension)
	    PROC
	    LOCAL __BOUND
	    LOCAL __DIM_NOT_EXIST
	    LOCAL __CONT
__LBOUND:
	    ld a, 4
	    jr __BOUND
__UBOUND:
	    ld a, 6
__BOUND:
	    ex de, hl       ; DE <-- Array ptr
	    pop hl          ; HL <-- Ret address
    ex (sp), hl     ; CALLEE: HL <-- N, (SP) <-- Ret address
	    ex de, hl       ; DE <-- N, HL <-- ARRAY_PTR
	    push hl
	    ld c, (hl)
	    inc hl
	    ld h, (hl)
	    ld l, c         ; HL = start of dimension table (first position contains number of dimensions - 1)
	    ld c, (hl)
	    inc hl
	    ld b, (hl)
	    inc bc          ; Number of total dimensions of the array
	    pop hl          ; Recovers ARRAY PTR
	    ex af, af'      ; Saves A for later
	    ld a, d
	    or e
	    jr nz, __CONT   ; N = 0 => Return number of dimensions
	    ;; Return the number of dimensions of the array
	    ld h, b
	    ld l, c
	    ret
__CONT:
	    dec de
	    ex af, af'      ; Recovers A (contains PTR offset)
	    ex de, hl       ; HL = N (dimension asked) - 1, DE = Array PTR
	    or a
	    sbc hl, bc      ; if no Carry => the user asked for a dimension that does not exist. Return 0
	    jr nc, __DIM_NOT_EXIST
	    add hl, bc      ; restores HL = (N - 1)
	    add hl, hl      ; hl *= 2
	    ex de, hl       ; hl = ARRAY_PTR + 3, DE jsz = (N - 1) * 2
	    ld b, 0
	    ld c, a
	    add hl, bc      ; HL = &BOUND_PTR
	    ld a, (hl)
	    inc hl
	    ld h, (hl)
	    ld l, a         ; LD HL, (HL) => Origin of L/U Bound table
	    add hl, de      ; hl += OFFSET __LBOUND._xxxx
	    ld e, (hl)      ; de = (hl)
	    inc hl
	    ld d, (hl)
	    ex de, hl       ; hl = de => returns result in HL
	    ret
__DIM_NOT_EXIST:
	;   The dimension requested by the user does not exists. Return 0
	    ld hl, 0
	    ret
	    ENDP
#line 93 "ubound10.bas"
#line 1 "/zxbasic/src/arch/zx48k/library-asm/free.asm"
; vim: ts=4:et:sw=4:
	; Copyleft (K) by Jose M. Rodriguez de la Rosa
	;  (a.k.a. Boriel)
;  http://www.boriel.com
	;
	; This ASM library is licensed under the BSD license
	; you can use it for any purpose (even for commercial
	; closed source programs).
	;
	; Please read the BSD license on the internet
	; ----- IMPLEMENTATION NOTES ------
	; The heap is implemented as a linked list of free blocks.
; Each free block contains this info:
	;
	; +----------------+ <-- HEAP START
	; | Size (2 bytes) |
	; |        0       | <-- Size = 0 => DUMMY HEADER BLOCK
	; +----------------+
	; | Next (2 bytes) |---+
	; +----------------+ <-+
	; | Size (2 bytes) |
	; +----------------+
	; | Next (2 bytes) |---+
	; +----------------+   |
	; | <free bytes...>|   | <-- If Size > 4, then this contains (size - 4) bytes
	; | (0 if Size = 4)|   |
	; +----------------+ <-+
	; | Size (2 bytes) |
	; +----------------+
	; | Next (2 bytes) |---+
	; +----------------+   |
	; | <free bytes...>|   |
	; | (0 if Size = 4)|   |
	; +----------------+   |
	;   <Allocated>        | <-- This zone is in use (Already allocated)
	; +----------------+ <-+
	; | Size (2 bytes) |
	; +----------------+
	; | Next (2 bytes) |---+
	; +----------------+   |
	; | <free bytes...>|   |
	; | (0 if Size = 4)|   |
	; +----------------+ <-+
	; | Next (2 bytes) |--> NULL => END OF LIST
	; |    0 = NULL    |
	; +----------------+
	; | <free bytes...>|
	; | (0 if Size = 4)|
	; +----------------+
	; When a block is FREED, the previous and next pointers are examined to see
	; if we can defragment the heap. If the block to be breed is just next to the
	; previous, or to the next (or both) they will be converted into a single
	; block (so defragmented).
	;   MEMORY MANAGER
	;
	; This library must be initialized calling __MEM_INIT with
	; HL = BLOCK Start & DE = Length.
	; An init directive is useful for initialization routines.
	; They will be added automatically if needed.
	; ---------------------------------------------------------------------
	; MEM_FREE
	;  Frees a block of memory
	;
; Parameters:
	;  HL = Pointer to the block to be freed. If HL is NULL (0) nothing
	;  is done
	; ---------------------------------------------------------------------
MEM_FREE:
__MEM_FREE: ; Frees the block pointed by HL
	            ; HL DE BC & AF modified
	        PROC
	        LOCAL __MEM_LOOP2
	        LOCAL __MEM_LINK_PREV
	        LOCAL __MEM_JOIN_TEST
	        LOCAL __MEM_BLOCK_JOIN
	        ld a, h
	        or l
	        ret z       ; Return if NULL pointer
	        dec hl
	        dec hl
	        ld b, h
	        ld c, l    ; BC = Block pointer
	        ld hl, ZXBASIC_MEM_HEAP  ; This label point to the heap start
__MEM_LOOP2:
	        inc hl
	        inc hl     ; Next block ptr
	        ld e, (hl)
	        inc hl
	        ld d, (hl) ; Block next ptr
	        ex de, hl  ; DE = &(block->next); HL = block->next
	        ld a, h    ; HL == NULL?
	        or l
	        jp z, __MEM_LINK_PREV; if so, link with previous
	        or a       ; Clear carry flag
	        sbc hl, bc ; Carry if BC > HL => This block if before
	        add hl, bc ; Restores HL, preserving Carry flag
	        jp c, __MEM_LOOP2 ; This block is before. Keep searching PASS the block
	;------ At this point current HL is PAST BC, so we must link (DE) with BC, and HL in BC->next
__MEM_LINK_PREV:    ; Link (DE) with BC, and BC->next with HL
	        ex de, hl
	        push hl
	        dec hl
	        ld (hl), c
	        inc hl
	        ld (hl), b ; (DE) <- BC
	        ld h, b    ; HL <- BC (Free block ptr)
	        ld l, c
	        inc hl     ; Skip block length (2 bytes)
	        inc hl
	        ld (hl), e ; Block->next = DE
	        inc hl
	        ld (hl), d
	        ; --- LINKED ; HL = &(BC->next) + 2
	        call __MEM_JOIN_TEST
	        pop hl
__MEM_JOIN_TEST:   ; Checks for fragmented contiguous blocks and joins them
	                   ; hl = Ptr to current block + 2
	        ld d, (hl)
	        dec hl
	        ld e, (hl)
	        dec hl
	        ld b, (hl) ; Loads block length into BC
	        dec hl
	        ld c, (hl) ;
	        push hl    ; Saves it for later
	        add hl, bc ; Adds its length. If HL == DE now, it must be joined
	        or a
	        sbc hl, de ; If Z, then HL == DE => We must join
	        pop hl
	        ret nz
__MEM_BLOCK_JOIN:  ; Joins current block (pointed by HL) with next one (pointed by DE). HL->length already in BC
	        push hl    ; Saves it for later
	        ex de, hl
	        ld e, (hl) ; DE -> block->next->length
	        inc hl
	        ld d, (hl)
	        inc hl
	        ex de, hl  ; DE = &(block->next)
	        add hl, bc ; HL = Total Length
	        ld b, h
	        ld c, l    ; BC = Total Length
	        ex de, hl
	        ld e, (hl)
	        inc hl
	        ld d, (hl) ; DE = block->next
	        pop hl     ; Recovers Pointer to block
	        ld (hl), c
	        inc hl
	        ld (hl), b ; Length Saved
	        inc hl
	        ld (hl), e
	        inc hl
	        ld (hl), d ; Next saved
	        ret
	        ENDP
#line 94 "ubound10.bas"
__LABEL5:
	DEFB 01h
	DEFB 00h
	DEFB 03h
	DEFB 00h
	DEFB 01h
	END
