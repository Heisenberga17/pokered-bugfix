LoadWildData::
	ld hl, WildDataPointers
	ld a, [wCurMap]

	; get wild data for current map
	ld c, a
	ld b, 0
	add hl, bc
	add hl, bc
	ld a, [hli]
	ld h, [hl]
	ld l, a       ; hl now points to wild data for current map
	ld a, [hli]
	ld [wGrassRate], a
	and a
	jr z, .ClearGrassData ; if no grass data, clear the buffer and skip to surfing data
	push hl
	ld de, wGrassMons ; otherwise, load grass data
	ld bc, WILDDATA_LENGTH - 1
	call CopyData
	pop hl
	ld bc, WILDDATA_LENGTH - 1
	add hl, bc
	jr .GrassDataDone
; bugfix: clear wGrassMons when rate is 0, to prevent stale data from causing
; the MissingNo. glitch on Cinnabar Island and Route 21 coast tiles
.ClearGrassData
	push hl
	ld de, wGrassMons
	ld bc, WILDDATA_LENGTH - 1
.clearGrassLoop
	xor a
	ld [de], a
	inc de
	dec bc
	ld a, b
	or c
	jr nz, .clearGrassLoop
	pop hl
.GrassDataDone
	ld a, [hli]
	ld [wWaterRate], a
	and a
	ret z        ; if no water data, we're done
	ld de, wWaterMons  ; otherwise, load surfing data
	ld bc, WILDDATA_LENGTH - 1
	jp CopyData

INCLUDE "data/wild/grass_water.asm"
