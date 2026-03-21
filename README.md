# Pokémon Red and Blue [![Build Status][ci-badge]][ci]

This is a disassembly of Pokémon Red and Blue.

It builds the following ROMs:

- Pokemon Red (UE) [S][!].gb `sha1: ea9bcae617fdf159b045185467ae58b2e4a48b9a`
- Pokemon Blue (UE) [S][!].gb `sha1: d7037c83e1ae5b39bde3c30787637ba1d4c48ce2`
- BLUEMONS.GB (debug build) `sha1: 5b1456177671b79b263c614ea0e7cc9ac542e9c4`
- dmgapae0.e69.patch `sha1: 0fb5f743696adfe1dbb2e062111f08f9bc5a293a`
- dmgapee0.e68.patch `sha1: ed4be94dc29c64271942c87f2157bca9ca1019c7`

To set up the repository, see [**INSTALL.md**](INSTALL.md).


## Bug Fixes Applied

This fork applies fixes for all known bugs documented in the original Pokemon Red/Blue disassembly. These fixes **intentionally change ROM output** — `make compare` will fail because the generated ROM no longer matches the original retail cartridge byte-for-byte.

For the full technical research document covering the entire codebase, see [**POKERED_RESEARCH.md**](POKERED_RESEARCH.md).

### High Severity

#### 1. Focus Energy Divides Critical Hit Rate Instead of Multiplying
**File:** `engine/battle/core.asm` (line ~4514)

Focus Energy is supposed to quadruple the critical hit rate, but due to using `srl` (shift right / divide) instead of `sla` (shift left / multiply), it actually reduces the crit rate to 1/4 of normal — the exact opposite of the intended effect.

```asm
; ORIGINAL (bugged):
.focusEnergyUsed
    srl b                        ; divides by 2 instead of multiplying

; FIXED:
.focusEnergyUsed
    sla b                        ; multiply by 2 (left shift)
    jr nc, .noFocusEnergyUsed
    ld b, $ff                    ; cap at 255
```

#### 2. Bide Accumulated Damage Only Zeroes High Byte (Link Battle Desync)
**File:** `engine/battle/core.asm` (line ~757)

When an enemy Pokemon faints, only the high byte of the player's Bide accumulated damage is zeroed, leaving the low byte intact (damage becomes `damage mod 256` instead of 0). The counterpart function `RemoveFaintedPlayerMon` zeroes both bytes. In link battles, this asymmetry causes the two Game Boys to desync.

```asm
; ORIGINAL (bugged):
    xor a
    ld [wPlayerBideAccumulatedDamage], a    ; only zeroes high byte

; FIXED:
    xor a
    ld [wPlayerBideAccumulatedDamage], a
    ld [wPlayerBideAccumulatedDamage + 1], a ; also zero low byte
```

#### 3. Transform Move Invulnerability Check Completely Broken
**File:** `engine/battle/move_effects/transform.asm` (lines 5-17)

Two bugs combine to make Transform's invulnerability check (Fly/Dig) never work:
- **Bug A:** On the enemy's turn, `a` is loaded with `wEnemyBattleStatus1` but immediately overwritten by `hWhoseTurn`, so the status is lost.
- **Bug B:** On the player's turn, it checks `wPlayerBattleStatus1` (the user) instead of `wEnemyBattleStatus1` (the target).

```asm
; ORIGINAL (bugged):
    ld a, [wEnemyBattleStatus1]  ; immediately overwritten on next line
    ldh a, [hWhoseTurn]
    and a
    jr nz, .hitTest
    ...
    ld a, [wPlayerBattleStatus1] ; checks user instead of target
.hitTest
    bit INVULNERABLE, a          ; never works correctly

; FIXED:
    ldh a, [hWhoseTurn]
    and a
    jr nz, .loadTargetStatus
    ...
    ld a, [wEnemyBattleStatus1]  ; correctly check target
    jr .hitTest
.loadTargetStatus
    ld a, [wPlayerBattleStatus1] ; correctly check target on enemy turn
.hitTest
    bit INVULNERABLE, a
```

### Medium Severity

#### 4. CooltrainerF AI Switch Chance Broken
**File:** `engine/battle/trainer_ai.asm` (line 348)

CooltrainerF's AI is supposed to have a 25% chance to consider switching Pokemon, but the `ret nc` instruction is commented out, so she never considers switching.

```asm
; ORIGINAL (bugged):
CooltrainerFAI:
    cp 25 percent + 1
    ; ret nc                     ; commented out!

; FIXED:
CooltrainerFAI:
    cp 25 percent + 1
    ret nc                       ; uncommented — 25% switch chance works
```

#### 5. Substitute Can Leave User at 0 HP
**File:** `engine/battle/move_effects/substitute.asm` (line 39)

The HP subtraction check only branches on carry (negative result), but doesn't check for the result being exactly zero. A Pokemon can be left with 0 HP but still considered alive.

```asm
; ORIGINAL (bugged):
    jr c, .notEnoughHP           ; only checks for negative HP

; FIXED:
    jr c, .notEnoughHP
    and a
    jr nz, .highByteNonzero
    or d
    jr z, .notEnoughHP           ; also reject exactly 0 HP
    xor a
.highByteNonzero
```

#### 6. Swift Fix Broke HP Drain vs Substitute Check
**File:** `engine/battle/core.asm` (line ~5251-5256)

When Swift was fixed to never miss (from the Japanese version), `CheckTargetSubstitute` was added before the drain HP check. But `CheckTargetSubstitute` overwrites register `a` with 0 or 1, so the subsequent `cp DRAIN_HP_EFFECT` comparison never matches, allowing Leech Life and Dream Eater to incorrectly drain HP from Substitutes.

```asm
; ORIGINAL (bugged):
    call CheckTargetSubstitute   ; overwrites a with 0 or 1
    jr z, .checkForDigOrFlyStatus
    cp DRAIN_HP_EFFECT           ; never matches because a is 0 or 1
    jp z, .moveMissed

; FIXED:
    call CheckTargetSubstitute
    jr z, .checkForDigOrFlyStatus
    ld a, [de]                   ; re-read move effect
    cp DRAIN_HP_EFFECT
    jp z, .moveMissed
```

#### 7. Win SFX Plays Before Checking Player HP
**File:** `engine/battle/core.asm` (line ~797)

In wild battles, victory music plays before checking if the player's Pokemon has HP remaining. If both Pokemon faint on the same turn, the player hears victory music but then gets the blackout sequence.

#### 8. Wild Encounters Can Trigger Stone Evolutions
**File:** `engine/pokemon/evos_moves.asm` (line ~97)

`wCurItem` is aliased to `wCurPartySpecies`, which may contain arbitrary species IDs during wild encounters. This can cause stone evolution entries to match incorrectly. Fixed in Pokemon Yellow.

```asm
; FIXED: Skip stone evolution entries entirely during battle
.checkItemEvo
    ld a, [hli]
    ld b, a
    ld a, [wIsInBattle]
    and a
    jp nz, .nextEvoEntry1        ; no stone evos during battle
    ld a, [wCurItem]
```

#### 9. Self-Confusion / Hi Jump Kick Recoil Hits Wrong Substitute
**File:** `engine/battle/core.asm` (line ~4854)

`AttackSubstitute` is shared by both player and enemy, but self-damage effects (confusion, Jump Kick recoil) cause a temporary turn swap. This means damage is applied to the opponent's Substitute instead of the user's own.

### Low Severity

#### 10. Screen Tearing in Fainted Mon / Trainer Slide Animations
**File:** `engine/battle/core.asm` (lines ~1180, ~1234)

Both `SlideDownFaintedMonPic` and `SlideTrainerPicOffScreen` are called with `hAutoBGTransferEnabled` set to non-zero, causing visible screen tearing during the animations.

#### 11. Jump Kick / Hi Jump Kick Recoil Always 1 HP
**File:** `engine/battle/core.asm` (line ~3745)

When Jump Kick or Hi Jump Kick misses, recoil is calculated as `wDamage / 8`. But since the move missed, `wDamage` is always 0 at this point, making the recoil always `0 / 8 = 0`, rounded up to 1.

#### 12. Type Effectiveness Uses `$10` Literal Instead of `EFFECTIVE` Constant
**File:** `engine/battle/core.asm` (line ~5200)

The AI type effectiveness initialization uses the raw hex value `$10` instead of the named constant `EFFECTIVE`. While functionally equivalent, it reduces readability.

```asm
; ORIGINAL:
    ld a, $10 ; bug: should be EFFECTIVE (10)

; FIXED:
    ld a, EFFECTIVE
```

#### 13. OAM Attribute Written to Wrong Entry
**File:** `engine/battle/animations.asm` (line ~1346)

A `dec hl` before writing causes the attribute value 160 to be written to the previous OAM entry's attribute byte instead of the current one.

```asm
; ORIGINAL (bugged):
    dec hl
    ld a, 160
    ld [hli], a      ; writes to previous entry

; FIXED:
    ld a, 160
    ld [hl], a        ; writes to current entry
```

#### 14. Transformed Pokemon Assumed to Be Ditto
**File:** `engine/items/item_effects.asm` (line ~471)

If a caught Pokemon is transformed, it's assumed to be Ditto. While Ditto is the only wild Pokemon that naturally knows Transform, a wild Pokemon could theoretically use Transform via Mirror Move.

#### 15. Max Ether/Elixir PP Check Ignores PP Up Bits
**File:** `engine/items/item_effects.asm` (line ~2080)

The "is PP full?" comparison doesn't mask out the upper 2 bits used to count PP Ups, so Max Ethers/Elixirs may fail to detect that PP is already full when PP Ups have been applied.

```asm
; ORIGINAL (bugged):
    ld a, [hl]       ; includes PP Up bits in upper 2 bits
    cp b

; FIXED:
    ld a, [hl]
    and PP_SLOT_MASK  ; mask out PP Up bits
    cp b
```

#### 16. Counter Desync in Link Battles
**File:** `engine/battle/core.asm` (line ~4552)

Counter's variables are updated whenever the cursor moves in the battle menu. When a player switches out while the opponent uses Counter, the menu cursor position affects Counter's behavior, potentially causing link battle desync.

---

## See also

- [**Wiki**][wiki] (includes [tutorials][tutorials])
- [**Symbols**][symbols]
- [**Tools**][tools]

You can find us on [Discord (pret, #pokered)](https://discord.gg/d5dubZ3).

For other pret projects, see [pret.github.io](https://pret.github.io/).

[wiki]: https://github.com/pret/pokered/wiki
[tutorials]: https://github.com/pret/pokered/wiki/Tutorials
[symbols]: https://github.com/pret/pokered/tree/symbols
[tools]: https://github.com/pret/gb-asm-tools
[ci]: https://github.com/pret/pokered/actions
[ci-badge]: https://github.com/pret/pokered/actions/workflows/main.yml/badge.svg
