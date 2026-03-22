# Pokemon Red and Blue [![Build Status][ci-badge]][ci]

<div align="center">

<img src="https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/other/official-artwork/6.png" width="120">
<img src="https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/other/official-artwork/9.png" width="120">

**Bugfixed disassembly of Pokemon Red and Blue**

*Every known bug — squashed. Every glitch — patched.*

</div>

---

This is a disassembly of Pokemon Red and Blue with **29 bug fixes** applied across the battle engine, overworld, items, scripts, and audio systems.

It builds the following ROMs:

- Pokemon Red (UE) [S][!].gb `sha1: ea9bcae617fdf159b045185467ae58b2e4a48b9a`
- Pokemon Blue (UE) [S][!].gb `sha1: d7037c83e1ae5b39bde3c30787637ba1d4c48ce2`
- BLUEMONS.GB (debug build) `sha1: 5b1456177671b79b263c614ea0e7cc9ac542e9c4`

> **Note:** `make compare` will fail because the generated ROMs no longer match the original retail cartridges byte-for-byte. That's the point.

To set up the repository, see [**INSTALL.md**](INSTALL.md).

---

## How to Play

<img src="https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/versions/generation-i/red-blue/25.png" width="56" align="right">
<img src="https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/versions/generation-i/red-blue/6.png" width="56" align="right">

1. Install the build prerequisites from [**INSTALL.md**](INSTALL.md)
2. Build the ROMs:
   ```bash
   make clean && make
   ```
3. Grab your ROM from the project root:
   - **`pokered.gbc`** — Pokemon Red
   - **`pokeblue.gbc`** — Pokemon Blue
4. **OpenEmu (macOS):** drag the `.gbc` file into the OpenEmu window — it just works
5. **Other emulators:** [BGB](https://bgb.bircd.org/), [mGBA](https://mgba.io/), [SameBoy](https://sameboy.github.io/), and [Gambatte](https://github.com/sinamas/gambatte) all work great

---

## Bug Fixes

### Battle Engine

---

#### 1. Focus Energy Divides Critical Hit Rate Instead of Multiplying

<img src="https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/versions/generation-i/red-blue/106.png" width="56" align="right">

**File:** `engine/battle/core.asm` | **Severity:** HIGH

Focus Energy is supposed to quadruple the critical hit rate, but `srl` (shift right = divide) was used instead of `sla` (shift left = multiply). The move literally does the opposite of what it should.

```diff
 .focusEnergyUsed
-    srl b                        ; divides by 2
+    sla b                        ; multiply by 2
+    jr nc, .noFocusEnergyUsed
+    ld b, $ff                    ; cap at 255
```

---

#### 2. Bide Accumulated Damage Only Zeroes High Byte

<img src="https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/versions/generation-i/red-blue/113.png" width="56" align="right">

**File:** `engine/battle/core.asm` | **Severity:** HIGH

When an enemy faints, only the high byte of Bide damage is zeroed. The low byte stays, so damage becomes `damage mod 256` instead of 0. Causes link battle desync since `RemoveFaintedPlayerMon` zeroes both bytes.

```diff
     xor a
     ld [wPlayerBideAccumulatedDamage], a
+    ld [wPlayerBideAccumulatedDamage + 1], a
```

---

#### 3. Transform Invulnerability Check Completely Broken

<img src="https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/versions/generation-i/red-blue/132.png" width="56" align="right">

**File:** `engine/battle/move_effects/transform.asm` | **Severity:** HIGH

Two bugs: (A) On enemy's turn, `a` is loaded with status then immediately overwritten by `hWhoseTurn`. (B) On player's turn, it checks the user's status instead of the target's. The Fly/Dig invulnerability check never works.

```diff
-    ld a, [wEnemyBattleStatus1]  ; immediately overwritten
-    ldh a, [hWhoseTurn]
+    ldh a, [hWhoseTurn]
     and a
-    jr nz, .hitTest
-    ld a, [wPlayerBattleStatus1] ; wrong target
+    jr nz, .loadTargetStatus
+    ld a, [wEnemyBattleStatus1]  ; correct target
+    jr .hitTest
+.loadTargetStatus
+    ld a, [wPlayerBattleStatus1] ; correct target on enemy turn
 .hitTest
     bit INVULNERABLE, a
```

---

#### 4. CooltrainerF AI Never Switches Pokemon

<img src="https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/versions/generation-i/red-blue/124.png" width="56" align="right">

**File:** `engine/battle/trainer_ai.asm` | **Severity:** MEDIUM

CooltrainerF is supposed to have a 25% chance to consider switching, but `ret nc` was commented out. She never switches.

```diff
 CooltrainerFAI:
     cp 25 percent + 1
-    ; ret nc                     ; commented out!
+    ret nc                       ; 25% switch chance restored
```

---

#### 5. Substitute Can Leave User at 0 HP

<img src="https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/versions/generation-i/red-blue/122.png" width="56" align="right">

**File:** `engine/battle/move_effects/substitute.asm` | **Severity:** MEDIUM

Only checks for negative HP, not zero. A Pokemon can survive at 0 HP — undead.

```diff
     jr c, .notEnoughHP
+    and a
+    jr nz, .highByteNonzero
+    or d
+    jr z, .notEnoughHP           ; also reject exactly 0 HP
+    xor a
+.highByteNonzero
```

---

#### 6. Swift Fix Broke HP Drain vs Substitute

<img src="https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/versions/generation-i/red-blue/133.png" width="56" align="right">

**File:** `engine/battle/core.asm` | **Severity:** MEDIUM

`CheckTargetSubstitute` overwrites register `a`, so the subsequent `cp DRAIN_HP_EFFECT` never matches. Leech Life and Dream Eater drain HP through Substitutes.

```diff
     call CheckTargetSubstitute
     jr z, .checkForDigOrFlyStatus
+    ld a, [de]                   ; re-read move effect
     cp DRAIN_HP_EFFECT
```

---

#### 7. Win SFX Plays Before Checking Player HP

<img src="https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/versions/generation-i/red-blue/39.png" width="56" align="right">

**File:** `engine/battle/core.asm` | **Severity:** MEDIUM

Victory music plays before checking if the player's Pokemon is still alive. If both faint on the same turn, you hear the victory fanfare then black out.

```diff
 .wild_win
     call EndLowHealthAlarm
-    ld a, MUSIC_DEFEATED_WILD_MON
-    call PlayBattleVictoryMusic
 .sfxplayed
+    ; check HP first, play victory music after
     ld hl, wBattleMonHP
     ld a, [hli]
     or [hl]
     ...
+    ld a, MUSIC_DEFEATED_WILD_MON
+    call PlayBattleVictoryMusic
```

---

#### 8. Screen Tearing During Faint/Trainer Animations

<img src="https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/versions/generation-i/red-blue/137.png" width="56" align="right">

**File:** `engine/battle/core.asm` | **Severity:** LOW

Both `SlideDownFaintedMonPic` and `SlideTrainerPicOffScreen` run with `hAutoBGTransferEnabled` active, causing visible screen tearing during the animation.

```diff
 SlideDownFaintedMonPic:
+    xor a
+    ldh [hAutoBGTransferEnabled], a   ; disable during animation
     ...
+    ld a, 1
+    ldh [hAutoBGTransferEnabled], a   ; re-enable after
```

---

#### 9. Jump Kick / Hi Jump Kick Recoil Always 1 HP

<img src="https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/versions/generation-i/red-blue/106.png" width="56" align="right">

**File:** `engine/battle/core.asm` | **Severity:** LOW

Crash damage should be `potential_damage / 8`, but `MoveHitTest` zeroes `wDamage` on miss before the recoil calc runs. Result: always `0 / 8 = 0`, rounded up to 1.

```diff
+; save damage before MoveHitTest zeroes it
+    ld a, [wDamage]
+    ld [wBuffer], a
+    ld a, [wDamage + 1]
+    ld [wBuffer + 1], a
     call MoveHitTest
     ...
-    ld hl, wDamage               ; always 0 after miss
+    ld hl, wBuffer               ; preserved pre-miss damage
```

---

#### 10. Self-Confusion / Substitute Hits Wrong Target

<img src="https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/versions/generation-i/red-blue/54.png" width="56" align="right">

**File:** `engine/battle/core.asm` | **Severity:** MEDIUM

`AttackSubstitute` uses `hWhoseTurn` to pick the target, but self-damage effects temporarily swap the turn. Confusion damage and Jump Kick recoil hit the opponent's Substitute instead of the user's.

```diff
-; AttackSubstitute picks target based on hWhoseTurn (wrong during turn swap)
-    ld de, wEnemySubstituteHP
-    ldh a, [hWhoseTurn]
-    and a
-    jr z, .applyDamageToSubstitute
-    ld de, wPlayerSubstituteHP
+; Callers now pass correct target explicitly in de/bc
+    ; ApplyDamageToEnemyPokemon:
+    ld de, wEnemySubstituteHP
+    ld bc, wEnemyBattleStatus2
+    jp AttackSubstitute
```

---

#### 11. Type Effectiveness Uses Magic Number

<img src="https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/versions/generation-i/red-blue/81.png" width="56" align="right">

**File:** `engine/battle/core.asm` | **Severity:** LOW

AI type effectiveness init uses `$10` instead of `EFFECTIVE` constant. Functionally identical but hurts readability.

```diff
-    ld a, $10
+    ld a, EFFECTIVE
```

---

#### 12. OAM Attribute Written to Wrong Sprite Entry

<img src="https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/versions/generation-i/red-blue/101.png" width="56" align="right">

**File:** `engine/battle/animations.asm` | **Severity:** LOW

A stray `dec hl` causes attribute 160 to be written to the *previous* OAM entry instead of the current one.

```diff
-    dec hl
-    ld a, 160
-    ld [hli], a      ; writes to previous entry
+    ld a, 160
+    ld [hl], a        ; writes to current entry
```

---

#### 13. Redundant Dead Code in Multi-Turn Move Handlers

<img src="https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/versions/generation-i/red-blue/92.png" width="56" align="right">

**File:** `engine/battle/core.asm` | **Severity:** LOW

Two `jp nz, .returnToHL` instructions that can never execute because the preceding case is already handled by `CheckNumAttacksLeft`. Removed.

```diff
     ld hl, GetPlayerAnimationType
-    jp nz, .returnToHL  ; redundant - case already handled
     jp .returnToHL
```

---

#### 14. Wild Encounters Can Trigger Stone Evolutions

<img src="https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/versions/generation-i/red-blue/133.png" width="56" align="right">

**File:** `engine/pokemon/evos_moves.asm` | **Severity:** MEDIUM

`wCurItem` is aliased to `wCurPartySpecies`, which may contain arbitrary species IDs during battle. Stone evolution entries can match incorrectly.

```diff
+    ld a, [wIsInBattle]
+    and a
+    jp nz, .nextEvoEntry1        ; skip stone evos during battle
```

---

#### 15. Max Ether/Elixir PP Check Ignores PP Up Bits

<img src="https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/versions/generation-i/red-blue/65.png" width="56" align="right">

**File:** `engine/items/item_effects.asm` | **Severity:** LOW

The PP-full comparison doesn't mask out the upper 2 bits used for PP Up count. Max Ethers may appear to fail when PP Ups have been applied.

```diff
     ld a, [hl]
+    and PP_SLOT_MASK              ; mask out PP Up bits
     cp b
```

---

### Items

---

#### 16. Transformed Pokemon Assumed to Be Ditto

<img src="https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/versions/generation-i/red-blue/132.png" width="56" align="right">

**File:** `engine/items/item_effects.asm` | **Severity:** LOW

When catching a transformed Pokemon, the game hardcodes `DITTO` as the species. Any Pokemon using Transform (via Mirror Move) would incorrectly become Ditto.

```diff
-    ld a, DITTO
+    ld a, [wEnemyMonSpecies]     ; use actual species
     ld [wEnemyMonSpecies2], a
```

---

### Overworld

---

#### 17. MissingNo. Glitch (Stale Wild Encounter Data)

<img src="https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/versions/generation-i/red-blue/104.png" width="56" align="right">

**File:** `engine/overworld/wild_mons.asm` | **Severity:** HIGH

The old man tutorial writes the player's name into `wGrassMons` (aliased with `wLinkEnemyTrainerName`). Maps with no grass encounters (like Cinnabar coast) don't clear this buffer, so the name bytes are interpreted as wild Pokemon data — producing MissingNo. and other glitch Pokemon.

```diff
-    jr z, .NoGrassData
+    jr z, .ClearGrassData        ; clear buffer when rate is 0
     ...
+.ClearGrassData
+    push hl
+    ld de, wGrassMons
+    ld bc, WILDDATA_LENGTH - 1
+.clearGrassLoop
+    xor a
+    ld [de], a
+    inc de
+    dec bc
+    ld a, b
+    or c
+    jr nz, .clearGrassLoop
+    pop hl
```

---

#### 18. Sprite Movement Bounds Check Gets Sprites Stuck

<img src="https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/versions/generation-i/red-blue/84.png" width="56" align="right">

**File:** `engine/overworld/movement.asm` | **Severity:** MEDIUM

A `cp $5` / `jr c, .impassable` check was supposed to limit how far sprites walk, but it actually gets sprites stuck after walking upward 5 steps. Meanwhile, rightward/downward movement has no limit.

```diff
     add d
-    cp $5
-    jr c, .impassable            ; sprites get stuck after 5 upward steps
     jr .checkHorizontal
```

---

#### 19. Water Collision Relies on Stale Register Value

<img src="https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/versions/generation-i/red-blue/131.png" width="56" align="right">

**File:** `home/overworld.asm` | **Severity:** LOW

Sprite collision on water jumped to tile-checking code without loading the tile into `c`. It worked by accident because `c` retained `$F0` from a prior call (never a passable tile).

```diff
     and d
-    jr nz, .checkIfNextTileIsPassable ; relies on stale c = $F0
+    jr nz, .collision                 ; direct collision handling
```

---

#### 20. Oak Speech Bike Flag Carries Over From Previous Save

<img src="https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/versions/generation-i/red-blue/25.png" width="56" align="right">

**File:** `engine/movie/oak_speech/oak_speech.asm` | **Severity:** MEDIUM

`PrepareOakSpeech` saves/restores `wStatusFlags6` to preserve debug mode, but also carries over `BIT_ALWAYS_ON_BIKE` from a previous save file.

```diff
     pop af
+    res BIT_ALWAYS_ON_BIKE, a    ; clear bike flag from old save
     ld [wStatusFlags6], a
```

---

#### 21. Oak Speech Unnecessary ROM Bank Switching

<img src="https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/versions/generation-i/red-blue/33.png" width="56" align="right">

**File:** `engine/movie/oak_speech/oak_speech.asm` | **Severity:** LOW

Two locations save `hLoadedROMBank`, call `PlaySound`, then restore the bank by writing to `rROMB` directly. Since this code runs outside the Home bank, the direct ROM bank writes are invalid. `PlaySound` handles its own bank switching internally.

```diff
-    ldh a, [hLoadedROMBank]
-    push af
     ld a, SFX_SHRINK
     call PlaySound
-    pop af
-    ldh [hLoadedROMBank], a
-    ld [rROMB], a                ; invalid outside Home bank
```

---

### Scripts & Events

---

#### 22. Bench Guys Skip Data Bytes

<img src="https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/versions/generation-i/red-blue/143.png" width="56" align="right">

**File:** `engine/events/hidden_events/bench_guys.asm` | **Severity:** MEDIUM

The bench guy lookup loop has 3-byte entries but only increments `hl` for the first 2 bytes. When the facing direction doesn't match, it loops back misaligned, reading past the table and eventually hitting VRAM garbage (`$FF`).

```diff
+    inc hl                       ; skip text pointer byte
     jr nz, .loop
```

---

#### 23. Vermilion Gym Trash Can RNG Out of Bounds

<img src="https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/versions/generation-i/red-blue/100.png" width="56" align="right">

**File:** `engine/events/hidden_events/vermilion_gym_trash.asm` | **Severity:** MEDIUM

The second trash can selection does `dec a` on the masked random number. If the mask produces 0, `dec a` wraps to `$FF` (255), causing an out-of-bounds table access.

```diff
     and b
-    dec a                        ; wraps to $FF if masked result is 0
+    and 3                        ; clamp to valid range [0, 3]
```

---

#### 24. Pewter City Youngster Sprite Off by 16 Pixels

<img src="https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/versions/generation-i/red-blue/74.png" width="56" align="right">

**File:** `scripts/PewterCity.asm` | **Severity:** LOW

The gym guide youngster's X coordinate is `$40` (64) when it should be `$50` (80), misaligning the sprite during the gym cutscene.

```diff
-    ld a, $40
+    ld a, $50
```

---

#### 25. Rocket Hideout B1F Door SFX Replays Every Visit

<img src="https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/versions/generation-i/red-blue/109.png" width="56" align="right">

**File:** `scripts/RocketHideoutB1F.asm` | **Severity:** LOW

After playing the door-opening SFX, the event flag is *checked* but never *set*. The SFX replays on every map entry.

```diff
-    CheckEventHL EVENT_ENTERED_ROCKET_HIDEOUT
+    SetEvent EVENT_ENTERED_ROCKET_HIDEOUT
```

---

### Audio & Graphics

---

#### 26. Oak Speech Plays Nidorina Cry for Nidorino Sprite

<img src="https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/versions/generation-i/red-blue/33.png" width="56" align="right">

**File:** `home/text.asm` | **Severity:** LOW

The intro loads a Nidorino sprite but the `TextCommandSounds` table maps the cry to Nidorina. A famous bug — the anime actually replicated this mistake in its first episode.

```diff
-    db TX_SOUND_CRY_NIDORINA, NIDORINA
+    db TX_SOUND_CRY_NIDORINA, NIDORINO
```

---

### Other

---

#### 27. Naming Screen Uses Wrong Bank Reference

<img src="https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/versions/generation-i/red-blue/63.png" width="56" align="right">

**File:** `engine/menus/naming_screen.asm` | **Severity:** LOW

`BANK("Home")` is used to load `ED_Tile` graphics, but the tile data lives in the naming screen's bank. It works by coincidence (both resolve to the same value), but it's incorrect.

```diff
-    lb bc, BANK("Home"), (ED_TileEnd - ED_Tile) / TILE_1BPP_SIZE
+    lb bc, BANK(ED_Tile), (ED_TileEnd - ED_Tile) / TILE_1BPP_SIZE
```

---

#### 28. Remove Pokemon Writes Invalid String Terminator

<img src="https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/versions/generation-i/red-blue/12.png" width="56" align="right">

**File:** `engine/pokemon/remove_mon.asm` | **Severity:** LOW

When removing the last Pokemon, `$FF` is written instead of `"@"` (`$50`), the proper string terminator. Leaves an unterminated string in memory.

```diff
-    ld [hl], $ff
+    ld [hl], "@"
```

---

#### 29. Slot Machine 7 Symbol Can Never Land

<img src="https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/versions/generation-i/red-blue/52.png" width="56" align="right">

**File:** `engine/slots/slot_machine.asm` | **Severity:** MEDIUM

The wheel-stop check for the 7 symbol uses `jr c` (jump if less than), but no valid tile value is less than `HIGH(SLOTS7)`. The condition is always false — 7s are unreachable.

```diff
     cp HIGH(SLOTS7)
-    jr c, .stopWheel             ; condition never true
+    jr z, .stopWheel             ; stop when 7 symbol matches
```

---

## Gameplay Mods

In addition to the 29 bug fixes above, this build includes the following gameplay modifications:

---

### Custom Starters

<img src="https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/other/official-artwork/151.png" width="100">
<img src="https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/other/official-artwork/133.png" width="100">
<img src="https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/other/official-artwork/94.png" width="100">

**File:** `constants/pokemon_constants.asm` (lines 204-206)

The three starter Pokemon in Oak's Lab have been replaced:

| Pokeball | Original | Modded |
|----------|----------|--------|
| Left (STARTER1) | Charmander | **Mew** |
| Middle (STARTER2) | Squirtle | **Eevee** |
| Right (STARTER3) | Bulbasaur | **Gengar** |

Your rival picks the starter after yours in the rotation. If you pick Mew, the rival gets Eevee. If you pick Eevee, the rival gets Gengar. If you pick Gengar, the rival gets Mew.

---

### Wild Encounter Overhaul

**Files:** All 60 files in `data/wild/maps/*.asm`

Every wild encounter table in the game has been rewritten. Rare, normally-unobtainable, and legendary Pokemon now appear as regular wild encounters throughout the game. Version-exclusive `IF DEF(_RED)` / `IF DEF(_BLUE)` conditionals have been removed so both versions have identical encounters.

#### Encounter Slot Probability

The game engine uses a weighted 10-slot system for wild encounters:

| Slot | Probability | Role in This Mod |
|------|-------------|------------------|
| 1 | ~20% | Common rare Pokemon |
| 2 | ~20% | Common rare Pokemon |
| 3 | ~15% | Common rare Pokemon |
| 4 | ~10% | Rare Pokemon |
| 5 | ~10% | Rare Pokemon |
| 6 | ~5% | Ultra-rare Pokemon |
| 7 | ~5% | Legendary Pokemon |
| 8 | ~4% | Legendary Pokemon |
| 9 | ~4% | Legendary Pokemon |
| 10 | ~1% | Legendary Pokemon |

#### Early Game (Routes 1-3, Route 22, Viridian Forest) — Levels 3-10

Top slots filled with Pokemon that are normally one-per-game or trade-only:

- **Common (slots 1-5):** Dratini, Eevee, Chansey, Scyther, Pinsir
- **Uncommon (slots 6-7):** Lapras, Kangaskhan, Tauros, Porygon
- **Legendary (slots 8-10):** Articuno, Zapdos, Moltres, Mew (varying by route)

Even Route 1's tall grass can yield a legendary bird at level 8-10.

#### Mid Game (Routes 4-12, 24, 25) — Levels 15-30

Evolved and powerful Pokemon take over the common slots:

- **Common (slots 1-5):** Dragonair, Snorlax, Tauros, Hitmonlee/Hitmonchan, Aerodactyl
- **Uncommon (slots 6-7):** Kabuto, Omanyte, Porygon (fossil Pokemon in the wild!)
- **Legendary (slots 8-10):** Mewtwo, Mew, legendary birds

Routes vary between Hitmonlee and Hitmonchan, and rotate through different legendaries in the bottom slots.

#### Late Game (Routes 13-18, 21, 23) — Levels 30-50

Fully-evolved powerhouses dominate:

- **Common (slots 1-4):** Dragonite, Alakazam, Gengar, Machamp
- **Legendary (slots 5-7):** Articuno, Zapdos, Moltres
- **Ultra-legendary (slots 8-10):** Mewtwo, Mew, high-level Dragonite

#### Caves

All caves have been converted to rare/legendary hunting grounds:

| Cave | Levels | Theme |
|------|--------|-------|
| **Mt. Moon** (3 floors) | 8-14 | Fossil Pokemon (Kabuto, Omanyte, Aerodactyl) + legendaries |
| **Rock Tunnel** (2 floors) | 16-23 | Fossil Pokemon + legendaries |
| **Diglett's Cave** | 20-30 | Fossil Pokemon + legendaries |
| **Seafoam Islands** (5 floors) | 30-48 | Fossil Pokemon with increasing legendary density per floor |
| **Victory Road** (3 floors) | 40-55 | High-level fossils and legendaries, Mewtwo at 50-55 |

Cave encounter pattern (all caves):
- Slots 1-3: Kabuto, Omanyte, Aerodactyl
- Slots 4-6: Chansey, Ditto, Porygon
- Slots 7-10: Articuno, Zapdos, Moltres, Mewtwo

#### Pokemon Tower (Floors 3-7) — Levels 20-35

Ghost-themed with legendaries mixed in:

- **Common:** Gengar, Haunter, Gastly
- **Uncommon:** Chansey, Ditto, Porygon
- **Legendary:** Articuno, Zapdos, Moltres, Mewtwo, Mew

Floors 1-2 remain empty (lobby/no encounters) as in vanilla.

#### Pokemon Mansion (4 floors) — Levels 32-46

Fire-type theme with rare spawns:

- **Common:** Arcanine, Ninetales, Rapidash
- **Uncommon:** Kabuto, Omanyte, Aerodactyl
- **Legendary:** Articuno, Zapdos, Moltres, Mewtwo, Mew

#### Power Plant — Levels 30-40

Electric-type theme with heavy Zapdos representation:

- **Common:** Electabuzz, Raichu, Magneton
- **Uncommon:** Zapdos (higher rate than other areas), Porygon
- **Legendary:** Articuno, Moltres, Mewtwo, Mew

#### Safari Zone (4 areas) — Levels 24-35

All four Safari Zone areas now have the rarest Pokemon in the game as common catches:

- **Common:** Chansey, Kangaskhan, Tauros, Scyther, Pinsir, Dratini
- **Uncommon:** Dragonair
- **Legendary:** Articuno, Zapdos, Moltres, Mewtwo, Mew (varying by area)

#### Sea Routes (Surfing) — Levels 25-45

Water encounters completely overhauled:

- **Common:** Lapras, Gyarados, Starmie
- **Uncommon:** Dragonair, Seadra, Cloyster
- **Legendary:** Articuno, Mew, Mewtwo, Dragonite

Route 21 also has water encounters with the same rare/legendary theme.

#### Cerulean Cave (Endgame) — Levels 55-70

The ultimate hunting ground. Every encounter is a powerhouse:

| Floor | Level Range | Encounters |
|-------|------------|------------|
| **1F** | 55-65 | Dragonite, Alakazam, Gengar, Machamp, all legendaries |
| **2F** | 58-68 | Same roster at higher levels |
| **B1F** | 60-70 | Highest levels in the game. Mewtwo up to level 70 |

All three floors: Dragonite, Alakazam, Gengar, Machamp in common slots; Articuno, Zapdos, Moltres, Mewtwo, Mew in legendary slots.

---

### Boosted Legendary Catch Rates

**Files:** `data/pokemon/base_stats/*.asm`

Legendary and rare Pokemon catch rates have been significantly increased so they're actually catchable when encountered in the wild. The Gen 1 catch rate scale is 0-255 (higher = easier). For reference, Pidgey is 255 and a regular Great Ball catch.

| Pokemon | Original Catch Rate | Modded Catch Rate |
|---------|-------------------|------------------|
| Articuno | 3 | **100** |
| Zapdos | 3 | **100** |
| Moltres | 3 | **100** |
| Mewtwo | 3 | **100** |
| Mew | 45 | **100** |
| Snorlax | 25 | **100** |
| Chansey | 30 | **100** |

At catch rate 100, you have a solid chance with Great Balls and Ultra Balls. Not a guaranteed catch, but no longer requires 50 Ultra Balls and a prayer.

---

### Version Differences Removed

All `IF DEF(_RED)` / `IF DEF(_BLUE)` conditionals have been stripped from wild encounter data. Both Pokemon Red and Pokemon Blue now have **identical wild encounter tables**. No more version exclusives blocking Pokedex completion.

---

## Open Bugs

There is **1 known bug** that is intentionally left unfixed. See [**KNOWN_BUGS.md**](KNOWN_BUGS.md) for details:

| Bug | Severity | Reason |
|-----|----------|--------|
| Counter desync in link battles | Medium | Too deeply coupled to battle menu cursor logic; fixing risks introducing new bugs |

---

## See also

- [**Wiki**][wiki] (includes [tutorials][tutorials])
- [**Symbols**][symbols]
- [**Tools**][tools]
- [**POKERED_RESEARCH.md**](POKERED_RESEARCH.md) — Deep technical analysis of the codebase

You can find us on [Discord (pret, #pokered)](https://discord.gg/d5dubZ3).

For other pret projects, see [pret.github.io](https://pret.github.io/).

[wiki]: https://github.com/pret/pokered/wiki
[tutorials]: https://github.com/pret/pokered/wiki/Tutorials
[symbols]: https://github.com/pret/pokered/tree/symbols
[tools]: https://github.com/pret/gb-asm-tools
[ci]: https://github.com/pret/pokered/actions
[ci-badge]: https://github.com/pret/pokered/actions/workflows/main.yml/badge.svg
