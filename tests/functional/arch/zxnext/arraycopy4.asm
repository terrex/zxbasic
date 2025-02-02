	org 32768
.core.__START_PROGRAM:
	di
	push iy
	ld iy, 0x5C3A  ; ZX Spectrum ROM variables address
	ld hl, 0
	add hl, sp
	ld (.core.__CALL_BACK__), hl
	ei
	call .core.__MEM_INIT
	jp .core.__MAIN_PROGRAM__
.core.__CALL_BACK__:
	DEFW 0
.core.ZXBASIC_USER_DATA:
	; Defines HEAP SIZE
.core.ZXBASIC_HEAP_SIZE EQU 4768
.core.ZXBASIC_MEM_HEAP:
	DEFS 4768
	; Defines USER DATA Length in bytes
.core.ZXBASIC_USER_DATA_LEN EQU .core.ZXBASIC_USER_DATA_END - .core.ZXBASIC_USER_DATA
	.core.__LABEL__.ZXBASIC_USER_DATA_LEN EQU .core.ZXBASIC_USER_DATA_LEN
	.core.__LABEL__.ZXBASIC_USER_DATA EQU .core.ZXBASIC_USER_DATA
.core.ZXBASIC_USER_DATA_END:
.core.__MAIN_PROGRAM__:
	call _test
	ld hl, 0
	ld b, h
	ld c, l
.core.__END_PROGRAM:
	di
	ld hl, (.core.__CALL_BACK__)
	ld sp, hl
	pop iy
	ei
	ret
_test:
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
	ld hl, -4
	ld de, .LABEL.__LABEL0
	ld bc, 22
	call .core.__ALLOC_LOCAL_ARRAY
	ld hl, -8
	ld de, .LABEL.__LABEL1
	ld bc, 22
	call .core.__ALLOC_LOCAL_ARRAY
	ld l, (ix-6)
	ld h, (ix-5)
	push hl
	ld l, (ix-2)
	ld h, (ix-1)
	push hl
	ld hl, 11
	push hl
	call .core.STR_ARRAYCOPY
_test__leave:
	ex af, af'
	exx
	ld hl, 11
	push hl
	ld l, (ix-2)
	ld h, (ix-1)
	call .core.__ARRAYSTR_FREE_MEM
	ld hl, 11
	push hl
	ld l, (ix-6)
	ld h, (ix-5)
	call .core.__ARRAYSTR_FREE_MEM
	ex af, af'
	exx
	ld sp, ix
	pop ix
	ret
	;; --- end of user code ---
#line 1 "/zxbasic/src/lib/arch/zxnext/runtime/arrayalloc.asm"
#line 1 "/zxbasic/src/lib/arch/zxnext/runtime/calloc.asm"
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
#line 1 "/zxbasic/src/lib/arch/zxnext/runtime/alloc.asm"
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
#line 1 "/zxbasic/src/lib/arch/zxnext/runtime/error.asm"
	; Simple error control routines
; vim:ts=4:et:
	    push namespace core
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
	    pop namespace
#line 69 "/zxbasic/src/lib/arch/zxnext/runtime/alloc.asm"
#line 1 "/zxbasic/src/lib/arch/zxnext/runtime/heapinit.asm"
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
	    push namespace core
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
	    pop namespace
#line 70 "/zxbasic/src/lib/arch/zxnext/runtime/alloc.asm"
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
	    push namespace core
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
#line 113 "/zxbasic/src/lib/arch/zxnext/runtime/alloc.asm"
	    ret z ; NULL
#line 115 "/zxbasic/src/lib/arch/zxnext/runtime/alloc.asm"
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
	    pop namespace
#line 13 "/zxbasic/src/lib/arch/zxnext/runtime/calloc.asm"
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
	    push namespace core
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
	    pop namespace
#line 3 "/zxbasic/src/lib/arch/zxnext/runtime/arrayalloc.asm"
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
	    push namespace core
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
#line 139 "/zxbasic/src/lib/arch/zxnext/runtime/arrayalloc.asm"
	    pop namespace
#line 62 "arch/zxnext/arraycopy4.bas"
#line 1 "/zxbasic/src/lib/arch/zxnext/runtime/arraystrfree.asm"
	; This routine is in charge of freeing an array of strings from memory
	; HL = Pointer to start of array in memory
	; Top of the stack = Number of elements of the array
#line 1 "/zxbasic/src/lib/arch/zxnext/runtime/free.asm"
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
	    push namespace core
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
	    pop namespace
#line 6 "/zxbasic/src/lib/arch/zxnext/runtime/arraystrfree.asm"
	    push namespace core
__ARRAYSTR_FREE:
	    PROC
	    LOCAL __ARRAY_LOOP
	    ex de, hl
	    pop hl		; (ret address)
	    ex (sp), hl	; Callee -> HL = Number of elements
	    ex de, hl
__ARRAYSTR_FREE_FAST:	; Fastcall entry: DE = Number of elements
	    ld a, h
	    or l
	    ret z		; ret if NULL
	    ld b, d
	    ld c, e
__ARRAY_LOOP:
	    ld e, (hl)
	    inc hl
	    ld d, (hl)
	    inc hl		; DE = (HL) = String Pointer
	    push hl
	    push bc
	    ex de, hl
	    call __MEM_FREE ; Frees it from memory
	    pop bc
	    pop hl
	    dec bc
	    ld a, b
	    or c
	    jp nz, __ARRAY_LOOP
	    ret		    ; Frees it and return
	    ENDP
__ARRAYSTR_FREE_MEM: ; like the above, buf also frees the array itself
	    ex de, hl
	    pop hl		; (ret address)
	    ex (sp), hl	; Callee -> HL = Number of elements
	    ex de, hl
	    push hl		; Saves array pointer for later
	    call __ARRAYSTR_FREE_FAST
	    pop hl		; recovers array block pointer
	    jp __MEM_FREE	; Frees it and returns from __MEM_FREE
	    pop namespace
#line 63 "arch/zxnext/arraycopy4.bas"
#line 1 "/zxbasic/src/lib/arch/zxnext/runtime/strarraycpy.asm"
	; (K)opyleft - by Jose M. Rodriguez de la Rosa (a.k.a. Boriel)
	; 2009 - This is Free OpenSource BSD code
; vim: et:ts=4:sw=4
	; Copies a vector of strings from one place to another
	; reallocating strings of the destiny vector to hold source strings.
; This is used in the following code:
; DIM a$(20) : DIM b$(20): a$ = b$
#line 1 "/zxbasic/src/lib/arch/zxnext/runtime/lddede.asm"
	; Loads DE into DE
	; Modifies C register
	; There is a routine similar to this one
	; at ROM address L2AEE
	    push namespace core
__LOAD_DE_DE:
	    ex de, hl
	    ld c, (hl)
	    inc hl
	    ld h, (hl)
	    ld l, c
	    ex de, hl
	    ret
	    pop namespace
#line 11 "/zxbasic/src/lib/arch/zxnext/runtime/strarraycpy.asm"
#line 1 "/zxbasic/src/lib/arch/zxnext/runtime/strcpy.asm"
#line 1 "/zxbasic/src/lib/arch/zxnext/runtime/realloc.asm"
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
	; MEM_REALLOC
	;  Reallocates a block of memory in the heap.
	;
	; Parameters
	;  HL = Pointer to the original block
	;  BC = New Length of requested memory block
	;
; Returns:
	;  HL = Pointer to the allocated block in memory. Returns 0 (NULL)
	;       if the block could not be allocated (out of memory)
	;
; Notes:
	;  If BC = 0, the block is freed, otherwise
	;  the content of the original block is copied to the new one, and
	;  the new size is adjusted. If BC < original length, the content
	;  will be truncated. Otherwise, extra block content might contain
	;  memory garbage.
	;
	; ---------------------------------------------------------------------
	    push namespace core
__REALLOC:    ; Reallocates block pointed by HL, with new length BC
	    PROC
	    LOCAL __REALLOC_END
	    ld a, h
	    or l
	    jp z, __MEM_ALLOC    ; If HL == NULL, just do a malloc
	    ld e, (hl)
	    inc hl
	    ld d, (hl)    ; DE = First 2 bytes of HL block
	    push hl
	    exx
	    pop de
	    inc de        ; DE' <- HL + 2
	    exx            ; DE' <- HL (Saves current pointer into DE')
	    dec hl        ; HL = Block start
	    push de
	    push bc
	    call __MEM_FREE        ; Frees current block
	    pop bc
	    push bc
	    call __MEM_ALLOC    ; Gets a new block of length BC
	    pop bc
	    pop de
	    ld a, h
	    or l
	    ret z        ; Return if HL == NULL (No memory)
	    ld (hl), e
	    inc hl
	    ld (hl), d
	    inc hl        ; Recovers first 2 bytes in HL
	    dec bc
	    dec bc        ; BC = BC - 2 (Two bytes copied)
	    ld a, b
	    or c
	    jp z, __REALLOC_END        ; Ret if nothing to copy (BC == 0)
	    exx
	    push de
	    exx
	    pop de        ; DE <- DE' ; Start of remaining block
	    push hl        ; Saves current Block + 2 start
    ex de, hl    ; Exchanges them: DE is destiny block
	    ldir        ; Copies BC Bytes
	    pop hl        ; Recovers Block + 2 start
__REALLOC_END:
	    dec hl        ; Set HL
	    dec hl        ; To begin of block
	    ret
	    ENDP
	    pop namespace
#line 2 "/zxbasic/src/lib/arch/zxnext/runtime/strcpy.asm"
	; String library
	    push namespace core
__STRASSIGN: ; Performs a$ = b$ (HL = address of a$; DE = Address of b$)
	    PROC
	    LOCAL __STRREALLOC
	    LOCAL __STRCONTINUE
	    LOCAL __B_IS_NULL
	    LOCAL __NOTHING_TO_COPY
	    ld b, d
	    ld c, e
	    ld a, b
	    or c
	    jr z, __B_IS_NULL
	    ex de, hl
	    ld c, (hl)
	    inc hl
	    ld b, (hl)
	    dec hl		; BC = LEN(b$)
	    ex de, hl	; DE = &b$
__B_IS_NULL:		; Jumps here if B$ pointer is NULL
	    inc bc
	    inc bc		; BC = BC + 2  ; (LEN(b$) + 2 bytes for storing length)
	    push de
	    push hl
	    ld a, h
	    or l
	    jr z, __STRREALLOC
	    dec hl
	    ld d, (hl)
	    dec hl
	    ld e, (hl)	; DE = MEMBLOCKSIZE(a$)
	    dec de
	    dec de		; DE = DE - 2  ; (Membloksize takes 2 bytes for memblock length)
	    ld h, b
	    ld l, c		; HL = LEN(b$) + 2  => Minimum block size required
	    ex de, hl	; Now HL = BLOCKSIZE(a$), DE = LEN(b$) + 2
	    or a		; Prepare to subtract BLOCKSIZE(a$) - LEN(b$)
	    sbc hl, de  ; Carry if len(b$) > Blocklen(a$)
	    jr c, __STRREALLOC ; No need to realloc
	    ; Need to reallocate at least to len(b$) + 2
	    ex de, hl	; DE = Remaining bytes in a$ mem block.
	    ld hl, 4
	    sbc hl, de  ; if remaining bytes < 4 we can continue
	    jr nc,__STRCONTINUE ; Otherwise, we realloc, to free some bytes
__STRREALLOC:
	    pop hl
	    call __REALLOC	; Returns in HL a new pointer with BC bytes allocated
	    push hl
__STRCONTINUE:	;   Pops hl and de SWAPPED
	    pop de	;	DE = &a$
	    pop hl	; 	HL = &b$
	    ld a, d		; Return if not enough memory for new length
	    or e
	    ret z		; Return if DE == NULL (0)
__STRCPY:	; Copies string pointed by HL into string pointed by DE
	    ; Returns DE as HL (new pointer)
	    ld a, h
	    or l
	    jr z, __NOTHING_TO_COPY
	    ld c, (hl)
	    inc hl
	    ld b, (hl)
	    dec hl
	    inc bc
	    inc bc
	    push de
	    ldir
	    pop hl
	    ret
__NOTHING_TO_COPY:
	    ex de, hl
	    ld (hl), e
	    inc hl
	    ld (hl), d
	    dec hl
	    ret
	    ENDP
	    pop namespace
#line 12 "/zxbasic/src/lib/arch/zxnext/runtime/strarraycpy.asm"
	    push namespace core
STR_ARRAYCOPY:
	; Copies an array of string a$ = b$
; Parameters in the stack:
	; a$, b$, num. of elements;
	    pop hl  ; ret address
	    pop bc  ; num of elements
	    pop de  ; source array + offset to the 1st elem.
	    ex (sp), hl ; Callee -> hl = destiny array + offset to the 1st elem.
	; FASTCALL ENTRY
	; HL = a$ + offset
	; DE = b$ + offset
	; BC = Number of elements
__STR_ARRAYCOPY:
	    PROC
	    LOCAL LOOP
LOOP:
	    ld a, b
	    or c
	    ret z ; Done!
	    dec bc
	    push bc
	    push de
	    ld a,(hl)
	    inc hl
	    ld c,(hl)
	    dec hl
	    push hl
	    ld h, c
	    ld l, a
	    call __LOAD_DE_DE
	    call __STRASSIGN
	    ex de, hl
	    pop hl
	    ld (hl), e
	    inc hl
	    ld (hl), d
	    inc hl
	    pop de
	    pop bc
	    inc de
	    inc de
	    jp LOOP
	    ENDP
	    pop namespace
#line 64 "arch/zxnext/arraycopy4.bas"
.LABEL.__LABEL0:
	DEFB 00h
	DEFB 00h
	DEFB 02h
.LABEL.__LABEL1:
	DEFB 00h
	DEFB 00h
	DEFB 02h
	END
