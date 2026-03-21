# Comprehensive Technical Research: pokered Disassembly

A detailed technical reference for the **pret/pokered** disassembly project -- the complete reverse-engineered source code of Pokemon Red and Pokemon Blue (Generation I) for the Game Boy.

---

## 1. Overview

### What Is pokered?

The pokered project is a complete **disassembly** of Pokemon Red and Pokemon Blue for the original Game Boy. Maintained by the [pret](https://github.com/pret) community, the project reconstructs the original Z80-like assembly source code (Sharp LR35902 / SM83 CPU) from the commercial ROM binaries, producing source files that can be reassembled into byte-identical copies of the original ROMs.

The project builds the following verified ROMs:

| ROM                          | SHA1                                       |
|------------------------------|--------------------------------------------|
| Pokemon Red (UE) [S][!].gb   | `ea9bcae617fdf159b045185467ae58b2e4a48b9a` |
| Pokemon Blue (UE) [S][!].gb  | `d7037c83e1ae5b39bde3c30787637ba1d4c48ce2` |
| BLUEMONS.GB (debug build)    | `5b1456177671b79b263c614ea0e7cc9ac542e9c4` |
| dmgapae0.e69.patch (Red VC)  | `0fb5f743696adfe1dbb2e062111f08f9bc5a293a` |
| dmgapee0.e68.patch (Blue VC) | `ed4be94dc29c64271942c87f2157bca9ca1019c7` |

### History and Significance

Pokemon Red and Blue were released in Japan in 1996 (as Red and Green), with Blue following shortly after. The international releases in 1998 were based on the Japanese Blue version's engine with Red/Green's exclusive content. The pret disassembly project has been the definitive community resource for understanding the game's internals. It serves as the foundation for ROM hacks, speedrun research, bug documentation, and academic study of early Game Boy programming.

The project uses the **RGBDS** (Rednex Game Boy Development System) assembler toolchain and is structured to clearly separate engine code, data, graphics, audio, and map scripts.

---

## 2. Build System & Toolchain

### RGBDS Assembler

The project requires **RGBDS version 1.0.1** (or compatible). RGBDS provides four core tools:

| Tool       | Purpose                                                |
|------------|--------------------------------------------------------|
| `rgbasm`   | Assembler -- converts `.asm` source files into `.o` object files |
| `rgblink`  | Linker -- combines object files into a ROM binary      |
| `rgbfix`   | ROM header fixer -- sets checksums, title, MBC type    |
| `rgbgfx`   | Graphics converter -- converts PNG images to Game Boy tile formats |

### Makefile Structure

The `Makefile` is the central build orchestrator. Key aspects:

**Assembler flags:**
```makefile
RGBASMFLAGS += -Q8 -P includes.asm
# -Q8: sets fill byte for padding
# -P includes.asm: pre-includes the global includes file
```

**Version-specific defines:**
```makefile
$(pokered_obj):        RGBASMFLAGS += -D _RED
$(pokeblue_obj):       RGBASMFLAGS += -D _BLUE
$(pokeblue_debug_obj): RGBASMFLAGS += -D _BLUE -D _DEBUG
$(pokered_vc_obj):     RGBASMFLAGS += -D _RED -D _RED_VC
$(pokeblue_vc_obj):    RGBASMFLAGS += -D _BLUE -D _BLUE_VC
```

**Linker flags:**
```makefile
RGBLINKFLAGS += -d
pokered.gbc:        RGBLINKFLAGS += -p 0x00
pokeblue_debug.gbc: RGBLINKFLAGS += -p 0xff
```

**ROM header configuration (rgbfix):**
```makefile
RGBFIXFLAGS += -jsv -n 0 -k 01 -l 0x33 -m MBC3+RAM+BATTERY -r 03
pokered.gbc:  RGBFIXFLAGS += -p 0x00 -t "POKEMON RED"
pokeblue.gbc: RGBFIXFLAGS += -p 0x00 -t "POKEMON BLUE"
```

This configures:
- **MBC3+RAM+BATTERY**: Memory Bank Controller 3 with SRAM and battery backup
- **-r 03**: 4 SRAM banks (32 KB)
- **-k 01 -l 0x33**: Nintendo licensee codes
- **-jsv**: Fix Japanese flag, set SGB flag, validate

### Build Targets

| Target         | Command            | Description                                    |
|----------------|--------------------|------------------------------------------------|
| `all`          | `make`             | Builds `pokered.gbc` and `pokeblue.gbc` and debug |
| `red`          | `make red`         | Builds only `pokered.gbc`                      |
| `blue`         | `make blue`        | Builds only `pokeblue.gbc`                     |
| `blue_debug`   | `make blue_debug`  | Builds `pokeblue_debug.gbc` (debug build)      |
| `red_vc`       | `make red_vc`      | Builds `pokered.patch` (Virtual Console patch) |
| `blue_vc`      | `make blue_vc`     | Builds `pokeblue.patch` (Virtual Console patch)|
| `compare`      | `make compare`     | Builds ROMs and verifies SHA1 checksums        |
| `clean`        | `make clean`       | Removes all generated files including graphics |
| `tidy`         | `make tidy`        | Removes generated files but keeps graphics     |
| `tools`        | `make tools`       | Builds custom tools only                       |

### Object File Structure

The ROM is assembled from these object files:
```
audio.o    - Sound engine and music/SFX data
home.o     - Bank 0 code (always-accessible routines)
main.o     - Main engine code across all banks
maps.o     - Map headers, scripts, and connections
ram.o      - RAM variable definitions
text.o     - Text strings and dialogue
gfx/pics.o     - Pokemon sprite graphics
gfx/sprites.o  - NPC and overworld sprite graphics
gfx/tilesets.o - Tileset graphics
```

### Custom Tools (tools/ directory)

| Tool             | Source             | Purpose                                        |
|------------------|--------------------|-------------------------------------------------|
| `gfx`            | `gfx.c`           | Post-processes graphics: trim whitespace, remove duplicates, interleave |
| `pkmncompress`   | `pkmncompress.c`  | Compresses 2bpp Pokemon sprites into .pic format |
| `scan_includes`  | `scan_includes.c` | Scans .asm files for INCLUDE dependencies       |
| `make_patch`     | `make_patch.c`    | Generates Virtual Console patch files from sym files |

### Graphics Pipeline

The graphics build pipeline converts PNG images through multiple steps:

```
.png --> rgbgfx --> .2bpp/.1bpp --> tools/gfx (optional) --> .2bpp/.1bpp
                                                        \--> pkmncompress --> .pic
```

Specific rules exist for special graphics:
```makefile
gfx/intro/gengar.2bpp: RGBGFXFLAGS += --columns
gfx/intro/gengar.2bpp: tools/gfx += --remove-duplicates --preserve=0x19,0x76
gfx/tilesets/%.2bpp: tools/gfx += --trim-whitespace
```

### Global Includes

The file `includes.asm` is pre-included in every assembly file via `-P includes.asm`. It pulls in:

- **Macros**: `asserts.asm`, `const.asm`, `predef.asm`, `farcall.asm`, `data.asm`, `code.asm`, `gfx.asm`, `coords.asm`, `vc.asm`
- **Script macros**: `audio.asm`, `maps.asm`, `events.asm`, `text.asm`
- **Constants**: `charmap.asm`, `hardware.inc`, `oam_constants.asm`, `ram_constants.asm`, type/battle/move/item/pokemon constants, map constants, audio constants, and more (52 constant files total)
- **VC constants** (conditional): Included only when `_RED_VC` or `_BLUE_VC` is defined

---

## 3. ROM Layout & Memory Map

### ROM Bank Structure

The ROM is 1 MB (64 banks of 16 KB each), organized via `layout.link`:

| Bank(s)     | Name/Contents                                          |
|-------------|--------------------------------------------------------|
| `ROM0`      | Interrupt vectors, Header, Home routines (always accessible) |
| `$01`       | Bank 1: Sprites, battle engine (drain HP), title, main menu, naming screen |
| `$02`       | Audio Engine 1, Music 1, Sound Effects 1               |
| `$03`       | Bank 3: Joypad, player state, inventory, wild mons, item effects, HP bar |
| `$04`       | NPC Sprites 1, Font Graphics, Battle Engine 1          |
| `$05`       | NPC Sprites 2, Battle Engine 2 (Substitute, PC)        |
| `$06`       | Maps 1-2, Play Time, Doors and Ledges                  |
| `$07`       | Maps 3-4, Pokemon Names, Hidden Events 1               |
| `$08`       | Audio Engine 2, Music 2, Sound Effects 2, Bill's PC    |
| `$09`       | Pics 1, Battle Engine 3 (Focus Energy, Print Type)     |
| `$0A`       | Pics 2, Battle Engine 4 (Leech Seed)                   |
| `$0B`       | Pics 3, Battle Engine 5 (Scale Sprites, Pay Day)       |
| `$0C`       | Pics 4, Battle Engine 6 (Mist, One Hit KO)             |
| `$0D`       | Pics 5, Slot Machines, Multiply/Divide                 |
| `$0E`       | Battle Engine 7: Move data, base stats, trainer AI, evolutions |
| `$0F`       | **Battle Core**: Main battle loop, damage calculation   |
| `$10`       | Pokedex, Trade, Intro                                  |
| `$11`       | Maps 5-6, Pokedex Rating, Hidden Events Core           |
| `$12`       | Maps 7-8, Screen Effects                               |
| `$13`       | Trainer Pics, Maps 9, Predefs                          |
| `$14`       | Maps 10, Battle Engine 8, Hidden Events 2              |
| `$15`       | Maps 11-12, Battle Engine 9 (Experience), Trainer Sight|
| `$16`       | Maps 13-14, Battle Engine 10 (Common Text)             |
| `$17`       | Maps 15-16, Starter Dex, Hidden Events 3               |
| `$18`       | Maps 17-18, Cinnabar Lab, Hidden Events 4              |
| `$19`       | Tilesets 1                                             |
| `$1A`       | Battle Engine 11, Tilesets 2                           |
| `$1B`       | Tilesets 3                                             |
| `$1C`       | Splash, Hall of Fame, Palettes, Save system            |
| `$1D`       | Maps 19-21, Itemfinder, Vending Machine, Credits       |
| `$1E`       | Battle Animations, Evolution, Elevator                 |
| `$1F`       | Audio Engine 3, Music 3, Sound Effects 3               |
| `$20-$2A`   | Text banks 1-11                                        |
| `$2B`       | Pokedex Text                                           |
| `$2C`       | Move Names                                             |

### WRAM Layout (Working RAM)

WRAM is 8 KB ($C000-$DFFF) organized into these major sections:

**Audio RAM** ($C000-$C0FF):
- Channel command pointers, flags, duty cycles
- Vibrato parameters, pitch slide data
- Note delays, loop counters, octaves, volumes
- Music/SFX tempo and instrument data

**Sprite State Data** ($C100-$C2FF):
- `wSpriteStateData1` ($C100): 16 sprites x $10 bytes each
  - Picture ID, movement status, screen position, animation frame, facing direction
- `wSpriteStateData2` ($C200): 16 sprites x $10 bytes each
  - Walk counter, displacement, grid position, movement type, delay

**OAM Buffer** ($C300-$C39F):
- `wShadowOAM`: 40 OAM sprite entries (Y, X, tile, attributes)

**Tilemap** ($C3A0-$C507):
- `wTileMap`: 20x18 visible screen tile buffer (360 bytes)

**Overworld Map** ($C508+):
- `wOverworldMap`: 1300 bytes for the current map's tile data
- Overlaps with `wTempPic` (used during Pokemon pic decompression)

**Main WRAM variables** include:
- Menu state: `wCurrentMenuItem`, `wMaxMenuItem`, `wMenuWatchedKeys`
- Battle state: `wPlayerSelectedMove`, `wEnemySelectedMove`, `wAICount`, `wDamage`
- Player state: `wPlayerMonNumber`, `wBattleMonHP`, battle status flags
- Substitute HP: `wPlayerSubstituteHP`, `wEnemySubstituteHP`
- Disobedience: `wMonIsDisobedient`
- Party/Box data sections

### HRAM Layout (High RAM)

HRAM ($FF80-$FFFE) contains frequently-accessed variables:

```asm
hSoftReset::    db   ; soft reset counter (init 16, dec on A+B+SEL+START)
hWhoseTurn::    db   ; 0 = player's turn, 1 = enemy's turn
hLoadedROMBank:: db  ; currently loaded ROM bank
hSavedROMBank::  db  ; saved ROM bank for nested bank switches

; Math registers (overlapping unions):
hMultiplicand:: ds 3  ; 24-bit multiplicand
hMultiplier::   db    ; 8-bit multiplier
hProduct::      ds 4  ; 32-bit product
hDividend::     ds 4  ; 32-bit dividend
hDivisor::      db    ; 8-bit divisor
hQuotient::     ds 4  ; 32-bit quotient
hRemainder::    db    ; 8-bit remainder

; Display registers (copied to hardware during V-blank):
hSCX::  db   ; background scroll X
hSCY::  db   ; background scroll Y
hWY::   db   ; window Y position

; Joypad state:
hJoyLast::     db  ; previous frame's joypad state
hJoyReleased:: db  ; buttons released this frame
hJoyPressed::  db  ; buttons pressed this frame
hJoyHeld::     db  ; buttons held this frame

; V-blank transfer control:
hAutoBGTransferEnabled::  db  ; enable automatic BG tilemap transfer
hVBlankCopySize::         db  ; size of VBlank copy (16-byte units)
hRedrawRowOrColumnMode::  db  ; 0=none, 1=column, 2=row

; RNG:
hRandomAdd:: db  ; incremented every V-blank
hRandomSub:: db  ; decremented every V-blank

hFrameCounter::   db  ; decremented every V-blank (used for delays)
hVBlankOccurred::  db  ; set to 0 each V-blank
hTileAnimations::  db  ; controls animated tiles (water, flowers)
```

### VRAM Layout

VRAM ($8000-$9FFF) is overlaid with multiple usage patterns:

```asm
; Generic layout:
vChars0:: ds $80 tiles   ; $8000: Tile data block 0 (128 tiles)
vChars1:: ds $80 tiles   ; $8800: Tile data block 1 (128 tiles)
vChars2:: ds $80 tiles   ; $9000: Tile data block 2 (128 tiles)
vBGMap0:: ds TILEMAP_AREA ; $9800: Background tilemap 0 (32x32)
vBGMap1:: ds TILEMAP_AREA ; $9C00: Background tilemap 1 (32x32)

; Battle/menu layout:
vSprites::  ds $80 tiles  ; $8000: Sprite tiles
vFont::     ds $80 tiles  ; $8800: Font tiles
vFrontPic:: ds PIC_SIZE tiles ; $9000: Enemy Pokemon front sprite
vBackPic::  ds PIC_SIZE tiles ; Pokemon back sprite

; Overworld layout:
vNPCSprites::  ds $80 tiles  ; $8000: NPC sprite tiles
vNPCSprites2:: ds $80 tiles  ; $8800: Additional NPC sprites
vTileset::     ds $80 tiles  ; $9000: Current tileset tiles
```

### SRAM Layout (Save RAM)

SRAM is 32 KB across 4 banks:

| Bank | Contents                                         |
|------|--------------------------------------------------|
| $00  | Sprite buffers (3 x SPRITEBUFFERSIZE), Hall of Fame |
| $01  | Save data: player name, main data, sprite data, party, current box, checksum |
| $02  | Saved Boxes 1-6, checksums                       |
| $03  | Saved Boxes 7-12, checksums                      |

Save data structure in SRAM Bank 1:
```asm
sGameData::
sPlayerName::  ds NAME_LENGTH      ; 11 bytes
sMainData::    ds wMainDataEnd - wMainDataStart
sSpriteData::  ds wSpriteDataEnd - wSpriteDataStart
sPartyData::   ds wPartyDataEnd - wPartyDataStart
sCurBoxData::  ds wBoxDataEnd - wBoxDataStart
sTileAnimations:: db
sGameDataEnd::
sMainDataCheckSum:: db              ; single-byte checksum
```

---

## 4. Battle Engine Deep Dive

The battle engine is the most complex system in the game, spanning thousands of lines across dozens of files. The core logic resides in `engine/battle/core.asm` (ROM Bank $0F, "Battle Core").

### Battle Flow

#### Initialization

The battle begins with `SlidePlayerAndEnemySilhouettesOnScreen`, which:
1. Loads the player's back pic
2. Disables LCD to load font and HUD tiles
3. Copies the work RAM tilemap to VRAM
4. Slides silhouettes onto screen using scroll register tricks
5. The enemy pic scrolls via hardware SCX, the player's head is a sprite (since they share Y coordinates)

#### Start Battle

`StartBattle` initializes battle state:
```asm
StartBattle:
    xor a
    ld [wPartyGainExpFlags], a
    ld [wPartyFoughtCurrentEnemyFlags], a
    ld [wActionResultOrTookBattleTurn], a
    inc a
    ld [wFirstMonsNotOutYet], a
```
- Finds the first alive enemy mon
- For trainer battles, calls `EnemySendOutFirstMon`
- For wild battles, goes directly to player mon selection
- Safari Zone battles use a different menu flow

#### Main Battle Loop

`MainInBattleLoop` is the heart of the battle system:

1. **Check HP**: If player mon HP is 0, handle player faint. If enemy HP is 0, handle enemy faint.
2. **Player Action Selection**:
   - Skip if player is using Rage, needs to recharge, is thrashing, or charging
   - Otherwise, display battle menu (FIGHT/ITEM/POKEMON/RUN)
   - If frozen or asleep, skip to enemy move selection
   - If trapped by Bide, Wrap, etc., player cannot freely choose
3. **Enemy Move Selection** (`SelectEnemyMove`):
   - In link battles, exchange data via serial
   - For wild Pokemon, choose randomly from available moves
   - For trainers, call `AIEnemyTrainerChooseMoves` first
4. **Turn Order Determination**:
   - Quick Attack always goes first (unless both use it)
   - Counter always goes last (unless both use it)
   - Otherwise, compare speed stats
   - Speed ties: 50/50 random (with inverted logic for internal clock in link battles)
5. **Execute Moves**: Call `ExecutePlayerMove` / `ExecuteEnemyMove`
6. **Handle Residual Damage**: `HandlePoisonBurnLeechSeed` for each side
7. **Check Multi-Turn Moves**: `CheckNumAttacksLeft`
8. **Loop back** to `MainInBattleLoop`

```asm
.enemyMovesFirst
    ld a, $1
    ldh [hWhoseTurn], a
    callfar TrainerAI
    jr c, .AIActionUsedEnemyFirst
    call ExecuteEnemyMove
    ; ... check for escape/faint ...
    call HandlePoisonBurnLeechSeed
    jp z, HandleEnemyMonFainted
    call DrawHUDsAndHPBars
    call ExecutePlayerMove
    ; ... check for escape/faint ...
    call HandlePoisonBurnLeechSeed
    jp z, HandlePlayerMonFainted
    call DrawHUDsAndHPBars
    call CheckNumAttacksLeft
    jp MainInBattleLoop
```

#### Move Execution Flow

`ExecutePlayerMove` (and its mirror `ExecuteEnemyMove`) follows this pipeline:

1. Check if the player can actually move (status conditions via `CheckPlayerStatusConditions`)
2. Load current move data (`GetCurrentMove`)
3. Check for disobedience (traded Pokemon)
4. Check if move needs charging (Fly, Dig, Solar Beam, etc.)
5. Display "used [move]" text
6. Decrement PP
7. Check move effect category:
   - **ResidualEffects1**: Skip damage calculation entirely (e.g., status moves)
   - **SpecialEffectsCont**: Execute effect but continue with damage (e.g., Wrap, Thrash)
   - **SetDamageEffects**: Skip normal damage calculation (e.g., Seismic Toss, Super Fang)
8. `CriticalHitTest` -> `HandleCounterMove` -> `GetDamageVarsForPlayerAttack` -> `CalculateDamage`
9. `AdjustDamageForMoveType` (STAB and type effectiveness)
10. `RandomizeDamage` (random factor 217-255 / 255)
11. `MoveHitTest` (accuracy check)
12. Play animation, apply damage
13. Execute remaining effects (side effects like burn chance, stat drops)
14. Handle multi-hit moves, print hit count

### Damage Formula Implementation

The damage formula in `CalculateDamage`:

```
Damage = ((((2 * Level / 5 + 2) * Power * Attack / Defense) / 50) + 2)
```

Implementation in assembly:
```asm
CalculateDamage:
; input: b=attack, c=defense, d=base power, e=level

    ; EXPLODE_EFFECT halves defense
    cp EXPLODE_EFFECT
    jr nz, .ok
    srl c
    jr nz, .ok
    inc c       ; minimum defense of 1

    ; Multiply level by 2
    ld a, e
    add a       ; level * 2

    ; Divide by 5
    ld a, 5
    call Divide

    ; Add 2
    inc [hl]
    inc [hl]

    ; Multiply by base power
    ld [hl], d
    call Multiply

    ; Multiply by attack stat
    ld [hl], b
    call Multiply

    ; Divide by defense stat
    ld [hl], c
    call Divide

    ; Divide by 50
    ld [hl], 50
    call Divide

    ; Cap at 997 (MAX_NEUTRAL_DAMAGE - MIN_NEUTRAL_DAMAGE)
    ; Add MIN_NEUTRAL_DAMAGE (2)
```

The damage is capped at 999 before type effectiveness, STAB, and critical hit adjustments. After all adjustments, the final damage is applied.

**Stat scaling**: If either the offensive or defensive stat has a high byte (>255), both are divided by 4 to fit in a single byte. This allows stats up to 1023 to be handled, but higher values will wrap around. Additionally, the defensive stat can become 0 after scaling, leading to a **division by zero freeze**.

### Critical Hit Calculation

The critical hit system in `CriticalHitTest`:

```asm
CriticalHitTest:
    ; Get base speed of attacking Pokemon
    ld a, [wMonHBaseSpeed]
    ld b, a
    srl b              ; b = base_speed / 2

    ; Focus Energy check (BUGGED - see bugs section)
    bit GETTING_PUMPED, a
    jr nz, .focusEnergyUsed
    sla b              ; normal: multiply by 2
    jr .noFocusEnergyUsed
.focusEnergyUsed
    sla b              ; focus energy: same multiply by 2 (should be sla twice more)

    ; High critical hit move check
    ; If move is in HighCriticalMoves table: b *= 8
    ; If not: b /= 2

    ; Generate random number and compare
    call BattleRandom
    rlc a
    rlc a
    rlc a              ; rotate left 3 times (effectively random / 32)
    cp b               ; compare with critical rate
    ret nc             ; no critical if random >= rate
    ld a, $1
    ld [wCriticalHitOrOHKO], a
```

**Critical hit rates** (approximate, based on base speed):

| Scenario               | Formula                   | Example (base speed 100) |
|------------------------|---------------------------|--------------------------|
| Normal move            | base_speed / 2 / 256      | ~19.5%                   |
| High crit move         | base_speed / 2 * 8 / 256  | ~156% (capped)           |
| With Focus Energy (bug)| base_speed / 2 / 4 / 256  | ~4.9% (WORSE!)           |

High critical hit moves: Karate Chop, Razor Leaf, Crabhammer, Slash.

When a critical hit occurs:
- Level is doubled in the damage formula
- Attack and defense stats revert to unmodified base values (ignoring stat stages, burns, badge boosts)

### Type Effectiveness System

Type effectiveness is stored in `data/types/type_matchups.asm` as a flat table of triplets:

```asm
TypeEffects:
    ;  attacker,     defender,     multiplier
    db WATER,        FIRE,         SUPER_EFFECTIVE      ; 20 (x2.0)
    db FIRE,         GRASS,        SUPER_EFFECTIVE
    db GROUND,       FLYING,       NO_EFFECT            ; 0  (x0.0)
    db WATER,        WATER,        NOT_VERY_EFFECTIVE   ; 5  (x0.5)
    db NORMAL,       GHOST,        NO_EFFECT
    db GHOST,        PSYCHIC_TYPE, NO_EFFECT            ; Gen I bug: should be SE
    ; ... 85 total entries ...
    db -1 ; end
```

Multiplier values: `SUPER_EFFECTIVE = 20`, `NOT_VERY_EFFECTIVE = 5`, `NO_EFFECT = 0`, `EFFECTIVE = 10` (neutral, the default).

The `AdjustDamageForMoveType` function processes STAB and type matchups:

1. **STAB** (Same Type Attack Bonus): If the move's type matches either of the attacker's types, damage is multiplied by 1.5 (floor division):
```asm
.sameTypeAttackBonus
    ld hl, wDamage + 1
    ld a, [hld]
    ld h, [hl]
    ld l, a        ; hl = damage
    ld b, h
    ld c, l        ; bc = damage
    srl b
    rr c           ; bc = floor(damage / 2)
    add hl, bc     ; hl = floor(damage * 1.5)
```

2. **Type effectiveness**: For each entry in TypeEffects, if the move type matches the attacking type AND a defender type matches the defending type, multiply damage by the effectiveness value and divide by 10.

3. **Dual-type handling**: Each type of the defender is checked independently, allowing for 4x effectiveness (or resistance) when both types are weak (or resistant).

### Status Conditions

**Sleep** (SLP, bits 0-2 of status byte):
- Counter stored in bits 0-2 (1-7 turns)
- Decremented each turn; wakes up when counter reaches 0
- Cannot attack while asleep

**Poison** (PSN, bit 3):
- Deals 1/16 max HP per turn via `HandlePoisonBurnLeechSeed`
- Toxic (badly poisoned) increments a counter each turn, multiplying the base 1/16 damage

**Burn** (BRN, bit 4):
- Deals 1/16 max HP per turn
- Halves the burned Pokemon's Attack stat

**Freeze** (FRZ, bit 5):
- Completely prevents action
- Can only be thawed by a Fire-type move with burn side effect hitting the frozen Pokemon
- **Notable**: There is no random thaw chance in Gen I

**Paralysis** (PAR, bit 6):
- Quarters the Pokemon's Speed stat
- 25% chance each turn of being "fully paralyzed" (cannot move)

### AI System

The trainer AI is implemented in `engine/battle/trainer_ai.asm`. It has two components:

#### Move Choice Modifications

`AIEnemyTrainerChooseMoves` initializes a 4-element array (one per move slot) with value 10. Each trainer class has a list of modification functions to apply. After modifications, moves with the lowest values are selected.

**Modification Function 1** (`AIMoveChoiceModification1`):
Discourages status moves if the player's Pokemon already has a status condition. Adds 5 to the score of pure status moves.

**Modification Function 2** (`AIMoveChoiceModification2`):
Slightly encourages stat-modifying moves by decrementing their score by 1. Only active when `wAILayer2Encouragement == 1`.

**Modification Function 3** (`AIMoveChoiceModification3`):
Encourages super-effective moves (decrement score) and discourages not-very-effective moves (increment score). Compares `wTypeEffectiveness` with `$10` (neutral).

**Modification Function 4**: Does nothing (unused).

#### Trainer-Specific AI

Each trainer class has a dedicated AI function that can use items or switch Pokemon:

```asm
TrainerAI:
    ld a, [wTrainerClass]
    dec a
    ; ... look up AI pointer table ...
    call Random
    jp hl        ; execute with random value in a
```

Examples:
- **Brock**: Uses Full Heal if active Pokemon has a status condition
- **Misty**: 25% chance to use X Defend
- **Lt. Surge**: 25% chance to use X Speed
- **Erika**: 50% chance to use Super Potion if HP < 1/10 max
- **Sabrina**: 25% chance to use Hyper Potion if HP < 1/10 max
- **Lance**: 50% chance to use Hyper Potion if HP < 1/5 max
- **Agatha**: 8% chance to switch; 50% chance to use Super Potion if HP < 1/4 max
- **CooltrainerF**: Has a bug (see bugs section)

### Move Effects System

Move effects are dispatched through `_JumpMoveEffect`:

```asm
_JumpMoveEffect:
    ldh a, [hWhoseTurn]
    and a
    ld a, [wPlayerMoveEffect]
    jr z, .next
    ld a, [wEnemyMoveEffect]
.next
    dec a              ; subtract 1 (no effect for 00)
    add a              ; x2 for 16-bit pointers
    ld hl, MoveEffectPointerTable
    ld b, 0
    ld c, a
    add hl, bc
    ld a, [hli]
    ld h, [hl]
    ld l, a
    jp hl              ; jump to effect handler
```

Effects are categorized into several arrays that determine when they execute:

- **ResidualEffects1**: Execute instead of damage (Sleep, Poison, stat moves, etc.)
- **SetDamageEffects**: Have custom damage calculation (Seismic Toss, Super Fang, etc.)
- **SpecialEffectsCont**: Execute before damage but continue (Wrap, Thrash, etc.)
- **AlwaysHappenSideEffects**: Execute after damage always (Explode, Hyper Beam recharge)
- **SpecialEffects**: Execute after target faint check
- **ResidualEffects2**: Execute after damage and miss check

### All Documented Bugs

#### Bug 1: Focus Energy Divides Instead of Multiplies Critical Hit Rate

**File**: `engine/battle/core.asm`, line ~4507
**Severity**: HIGH

Focus Energy is supposed to quadruple the critical hit rate. Instead, due to a logic error, it results in the same multiplication as the non-Focus Energy path (both do `sla b` once), but the key issue is the structural flow: the Focus Energy path skips the normal `sla b` that non-Focus Energy users get, then both converge at `.noFocusEnergyUsed`. The effect is that Focus Energy does NOT provide the intended boost and in practice reduces the crit rate because the initial `srl b` (halving) still applies.

```asm
    bit GETTING_PUMPED, a
    jr nz, .focusEnergyUsed
    sla b                    ; normal path: double
    jr nc, .noFocusEnergyUsed
    ld b, $ff
    jr .noFocusEnergyUsed
.focusEnergyUsed
    sla b                    ; focus energy path: also just double (should be quadruple)
    jr nc, .noFocusEnergyUsed
    ld b, $ff
.noFocusEnergyUsed
```

The comment in the source explains: "bug: using focus energy causes a shift to the right instead of left, resulting in 1/4 the usual crit chance." The intent was presumably to shift left twice more (multiply by 4), not just once.

**Fixed in**: Pokemon Stadium (the game corrects this when playing linked Gen I cartridges).

---

#### Bug 2: Bide Accumulated Damage Only Zeroes High Byte (Link Battle Desync)

**File**: `engine/battle/core.asm`, line ~747
**Severity**: HIGH (Link battles)

When an enemy Pokemon faints, `FaintEnemyPokemon` should zero the player's Bide accumulated damage. However, it only writes to the first byte:

```asm
; Bug. This only zeroes the high byte of the player's accumulated damage,
; setting the accumulated damage to itself mod 256 instead of 0 as was probably
; intended. That alone is problematic, but this mistake has another more severe
; effect. This function's counterpart for when the player mon faints,
; RemoveFaintedPlayerMon, zeroes both the high byte and the low byte. In a link
; battle, the other player's Game Boy will call that function in response to
; the enemy mon (the player mon from the other side's perspective) fainting,
; and the states of the two Game Boys will go out of sync unless the damage
; was congruent to 0 modulo 256.
    xor a
    ld [wPlayerBideAccumulatedDamage], a
    ld [wPlayerBideAccumulatedDamage + 1], a
```

Note: The source has been patched to zero both bytes, but the original ROM only zeroed one.

**Fixed in**: Later games.

---

#### Bug 3: Screen Tearing in Faint and Trainer Slide Animations

**File**: `engine/battle/core.asm`, lines ~1182 and ~1236
**Severity**: LOW (cosmetic)

Both `SlideDownFaintedMonPic` and `SlideTrainerPicOffScreen` are called when `[hAutoBGTransferEnabled]` is non-zero, causing visible screen tearing as the LCD is being updated while tiles are being modified:

```asm
; bug: when this is called, [hAutoBGTransferEnabled] is non-zero,
; so there is screen tearing
SlideDownFaintedMonPic:
```

```asm
; bug: when this is called, [hAutoBGTransferEnabled] is non-zero,
; so there is screen tearing
SlideTrainerPicOffScreen:
```

---

#### Bug 4: Jump Kick / Hi Jump Kick Recoil Always 1 HP

**File**: `engine/battle/core.asm`, line ~3746
**Severity**: MEDIUM

When Jump Kick or Hi Jump Kick misses, the recoil damage should be based on the damage that would have been dealt. However, since `wDamage` is always 0 at this point (the move missed, so no damage was calculated), the recoil is always 1:

```asm
    ; if you get here, the mon used jump kick or hi jump kick and missed
    ld hl, wDamage ; since the move missed, wDamage will always contain 0
                   ; at this point. Thus, recoil damage will always be
                   ; equal to 1 even if it was intended to be potential
                   ; damage/8.
    ld a, [hli]
    ld b, [hl]
    srl a
    rr b
    srl a
    rr b
    srl a
    rr b           ; divide by 8
    ; ... result is always 0, so ...
    or b
    jr nz, .applyRecoil
    inc a           ; minimum 1 damage
    ld [hl], a
```

---

#### Bug 5: CooltrainerF AI Missing Effect

**File**: `engine/battle/trainer_ai.asm`, line ~346
**Severity**: MEDIUM

The CooltrainerF AI function has a `cp 25 percent + 1` / `ret nc` at the start, intended to give a 25% chance to consider switching. However, the comment notes this doesn't work as intended:

```asm
CooltrainerFAI:
    ; The intended 25% chance to consider switching will not apply.
    ; Uncomment the line below to fix this.
    cp 25 percent + 1
    ret nc
    ld a, 10
    call AICheckIfHPBelowFraction
    jp c, AIUseHyperPotion
    ld a, 5
    call AICheckIfHPBelowFraction
    ret nc
    jp AISwitchIfEnoughMons
```

The issue is that the `ret nc` prevents the switching logic from ever being reached because the potion check and fraction check always take precedence within the 25% window.

---

#### Bug 6: Counter Desync in Link Battles

**File**: `engine/battle/core.asm`, line ~4550
**Severity**: HIGH (Link battles)

Counter checks the opponent's last **selected** move (not last **used** move), and these variables are updated whenever the cursor points to a new move in the battle menu:

```asm
HandleCounterMove:
; The variables checked by Counter are updated whenever the cursor
; points to a new move in the battle selection menu.
; This is irrelevant for the opponent's side outside of link battles,
; since the move selection is controlled by the AI.
; However, in the scenario where the player switches out and the
; opponent uses Counter, the outcome may be affected by the player's
; actions in the move selection menu prior to switching the Pokemon.
; This might also lead to desync glitches in link battles.
```

---

#### Bug 7: Self-Confusion and Substitute Damage Applied to Wrong Side

**File**: `engine/battle/core.asm`, line ~4852
**Severity**: MEDIUM

The `AttackSubstitute` function is shared by both player and enemy. Self-confusion damage and Jump Kick recoil cause a temporary turn swap before being applied. If the user has a Substitute up, the damage hits the opponent's Substitute instead:

```asm
AttackSubstitute:
; Self-confusion damage as well as Hi-Jump Kick and Jump Kick recoil
; cause a momentary turn swap before being applied.
; If the user has a Substitute up and would take damage because of that,
; damage will be applied to the other player's Substitute.
```

---

#### Bug 8: Type Effectiveness $10 Literal in AI

**File**: `engine/battle/trainer_ai.asm`, line ~212
**Severity**: LOW

The AI type effectiveness check uses a hard-coded `$10` literal instead of the `EFFECTIVE` constant:

```asm
    ld a, [wTypeEffectiveness]
    cp $10                     ; should be EFFECTIVE
    jr z, .nextMove
```

This works correctly but is poor coding practice.

---

#### Bug 9: Wild Pokemon Stone Evolution

**File**: `engine/pokemon/evos_moves.asm`, line ~12
**Severity**: LOW

The evolution-after-battle code has a bug that can allow item-based (stone) evolutions to trigger:

```asm
; this is only called after battle
; it is supposed to do level up evolutions, though there is a bug
; that allows item evolutions to occur
EvolutionAfterBattle:
```

---

#### Bug 10: Win SFX Plays Before Checking Player Mon HP

**File**: `engine/battle/core.asm`, line ~798
**Severity**: LOW (cosmetic)

When a wild Pokemon faints, the victory music plays before checking if the player's Pokemon also fainted:

```asm
.wild_win
    call EndLowHealthAlarm
    ld a, MUSIC_DEFEATED_WILD_MON
    call PlayBattleVictoryMusic
.sfxplayed
; bug: win sfx is played for wild battles before checking for player
; mon HP. This can lead to odd scenarios where both player and enemy
; faint, as the win sfx plays yet the player never won the battle
```

---

#### Bug 11: Psywave Damage Asymmetry

**File**: `engine/battle/core.asm`, lines ~4661 and ~4780
**Severity**: LOW

Psywave's random damage range differs between player and enemy:
- Player: random in range [1, level * 1.5)
- Enemy: random in range [0, level * 1.5) -- can do 0 damage

```asm
; player version:
.loop
    call BattleRandom
    and a
    jr z, .loop      ; reroll if 0 (ensures minimum 1)
    cp b
    jr nc, .loop

; enemy version:
.loop
    call BattleRandom
    cp b
    jr nc, .loop     ; no check for 0
```

---

#### Bug 12: MissingNo. / Old Man Glitch

**File**: `engine/battle/core.asm`, line ~2026
**Severity**: HIGH (gameplay)

The Old Man tutorial copies the player's name to `wLinkEnemyTrainerName`, which overlaps with `wGrassRate`/`wGrassMons`. This data is supposed to be overwritten when entering a new map, but Cinnabar Island and Route 21 don't reload wild encounter data (they have no grass). This allows the player's name characters to be interpreted as Pokemon species IDs in wild encounters, causing MissingNo. and other glitched Pokemon to appear:

```asm
    ; Temporarily save the player name in wLinkEnemyTrainerName.
    ; Since wLinkEnemyTrainerName == wGrassRate, this affects wild encounters.
    ; The wGrassRate byte and following wGrassMons buffer are supposed
    ; to get overwritten when entering a map with wild Pokemon,
    ; but an oversight prevents this in Cinnabar and Route 21,
    ; so the infamous MissingNo. glitch can show up.
    ld hl, wPlayerName
    ld de, wLinkEnemyTrainerName
    ld bc, NAME_LENGTH
    call CopyData
```

---

#### Bug 13: Mirror Move Missing Check for Multi-Turn Moves

**File**: `engine/battle/core.asm`, line ~363
**Severity**: LOW (Link battles)

When checking if the player is using a multi-turn move during link battle switching, there's a check for Metronome but not Mirror Move:

```asm
    ld a, [hl]
    cp METRONOME ; a MIRROR MOVE check is missing, might lead to
                 ; a desync in link battles when combined with
                 ; multi-turn moves
    jr nz, .specialMoveNotUsed
```

---

#### Bug 14: Division by Zero in Stat Scaling

**File**: `engine/battle/core.asm`, line ~4119
**Severity**: MEDIUM

When scaling stats for the damage formula, the defensive stat can become 0 after division by 4, causing a freeze:

```asm
    srl b
    rr c
    srl b
    rr c
; defensive stat can actually end up as 0, leading to a division
; by 0 freeze during damage calculation
```

---

#### Bug 15: Reflect/Light Screen Overflow

**File**: `engine/battle/core.asm`, line ~4085
**Severity**: LOW

Reflect and Light Screen double the defensive stat without capping at MAX_STAT_VALUE:

```asm
; reflect and light screen boosts do not cap the stat at MAX_STAT_VALUE,
; so weird things will happen during stats scaling
; if a Pokemon with 512 or more Defense has used Reflect, or if a
; Pokemon with 512 or more Special has used Light Screen
```

---

## 5. Pokemon Data Structures

### Base Stats Structure

Each Pokemon's base stats are stored in `data/pokemon/base_stats/` with this format (defined in `constants/pokemon_data_constants.asm`):

```asm
; BASE_DATA_SIZE = 28 bytes per Pokemon
DEF BASE_DEX_NO      rb     ; Pokedex number
DEF BASE_HP          rb     ; Base HP
DEF BASE_ATK         rb     ; Base Attack
DEF BASE_DEF         rb     ; Base Defense
DEF BASE_SPD         rb     ; Base Speed
DEF BASE_SPC         rb     ; Base Special
DEF BASE_TYPE_1      rb     ; Type 1
DEF BASE_TYPE_2      rb     ; Type 2
DEF BASE_CATCH_RATE  rb     ; Catch rate (0-255)
DEF BASE_EXP         rb     ; Base experience yield
DEF BASE_PIC_SIZE    rb     ; Sprite dimensions (from .pic file)
DEF BASE_FRONTPIC    rw     ; Pointer to front sprite
DEF BASE_BACKPIC     rw     ; Pointer to back sprite
DEF BASE_MOVES       rb 4   ; Level 1 learnset (4 moves)
DEF BASE_GROWTH_RATE rb     ; Growth rate (0-5)
DEF BASE_TMHM        rb 7   ; TM/HM learnset bitmask (55 bits)
                     rb 1   ; Padding byte
```

Example (Bulbasaur):
```asm
    db DEX_BULBASAUR        ; pokedex id
    db  45,  49,  49,  45,  65
    ;   hp  atk  def  spd  spc
    db GRASS, POISON        ; type
    db 45                   ; catch rate
    db 64                   ; base exp
    INCBIN "gfx/pokemon/front/bulbasaur.pic", 0, 1  ; sprite dimensions
    dw BulbasaurPicFront, BulbasaurPicBack
    db TACKLE, GROWL, NO_MOVE, NO_MOVE  ; level 1 learnset
    db GROWTH_MEDIUM_SLOW   ; growth rate
    tmhm SWORDS_DANCE, TOXIC, BODY_SLAM, TAKE_DOWN, DOUBLE_EDGE, \
         RAGE, MEGA_DRAIN, SOLARBEAM, MIMIC, DOUBLE_TEAM, \
         REFLECT, BIDE, REST, SUBSTITUTE, CUT
    db 0                    ; padding
```

### Move Data Structure

Each move is 6 bytes (MOVE_LENGTH), stored in `data/moves/moves.asm`:

```asm
MACRO move
    db \1   ; animation (interchangeable with move id)
    db \2   ; effect
    db \3   ; power (0 for non-damaging moves)
    db \4   ; type
    db \5 percent ; accuracy (0-100, stored as 0-255)
    db \6   ; pp (max 40)
ENDM
```

Example entries:
```asm
    move POUND,       NO_ADDITIONAL_EFFECT,  40, NORMAL,   100, 35
    move FIRE_PUNCH,  BURN_SIDE_EFFECT1,     75, FIRE,     100, 15
    move GUILLOTINE,  OHKO_EFFECT,            1, NORMAL,    30,  5
    move SWORDS_DANCE,ATTACK_UP2_EFFECT,      0, NORMAL,   100, 30
    move BODY_SLAM,   PARALYZE_SIDE_EFFECT2, 85, NORMAL,   100, 15
```

### Party Pokemon Structure

Each Pokemon in the party uses `PARTYMON_STRUCT_LENGTH` ($2C = 44) bytes:

```asm
MON_SPECIES    ; 1 byte: species index
MON_HP         ; 2 bytes: current HP (big endian)
MON_BOX_LEVEL  ; 1 byte: level (used in box, may differ from calculated)
MON_STATUS     ; 1 byte: status condition
MON_TYPE1      ; 1 byte: type 1
MON_TYPE2      ; 1 byte: type 2
MON_CATCH_RATE ; 1 byte: catch rate
MON_MOVES      ; 4 bytes: move IDs
MON_OTID       ; 2 bytes: Original Trainer ID
MON_EXP        ; 3 bytes: experience points (big endian)
MON_HP_EXP     ; 2 bytes: HP stat experience
MON_ATK_EXP   ; 2 bytes: Attack stat experience
MON_DEF_EXP   ; 2 bytes: Defense stat experience
MON_SPD_EXP   ; 2 bytes: Speed stat experience
MON_SPC_EXP   ; 2 bytes: Special stat experience
MON_DVS        ; 2 bytes: Determinant Values (IVs)
MON_PP         ; 4 bytes: PP for each move (6 bits PP + 2 bits PP Up count)
; --- BOXMON_STRUCT_LENGTH ends here ($21 = 33 bytes) ---
MON_LEVEL      ; 1 byte: calculated level
MON_MAXHP      ; 2 bytes: maximum HP
MON_ATK        ; 2 bytes: Attack stat
MON_DEF        ; 2 bytes: Defense stat
MON_SPD        ; 2 bytes: Speed stat
MON_SPC        ; 2 bytes: Special stat
; PARTYMON_STRUCT_LENGTH = $2C (44 bytes)
```

### DV (Determinant Value) System

DVs are stored as 2 bytes (16 bits), encoding 4 values:

```
Byte 1: [AAAA DDDD]  Attack DV (0-15), Defense DV (0-15)
Byte 2: [SSSS PPPP]  Speed DV (0-15), Special DV (0-15)
```

HP DV is derived: bit 0 of each other DV combined = `[Atk0 Def0 Spd0 Spc0]`

DVs also determine:
- **Gender** (not in Gen I, but the data is there for Gen II transfer)
- **Shininess** (also for Gen II)

### Stat Calculation

Stats are calculated using the formula:

```
HP = ((Base + DV) * 2 + ceil(sqrt(StatExp)) / 4) * Level / 100 + Level + 10
Other = ((Base + DV) * 2 + ceil(sqrt(StatExp)) / 4) * Level / 100 + 5
```

The `CalcStat` function performs this calculation using the Game Boy's 8-bit math hardware with multiplication and division helper routines.

### Evolution and Learnset Data

Evolution and learnset data are combined in `data/pokemon/evos_moves.asm`, accessed via `EvosMovesPointerTable`. Each Pokemon has:

1. **Evolution entries** (variable length, terminated by 0):
   - `EVOLVE_LEVEL`: level, target species
   - `EVOLVE_ITEM`: item, minimum level, target species
   - `EVOLVE_TRADE`: minimum level, target species

2. **Level-up moves** (variable length, terminated by 0):
   - level, move pairs

### Growth Rates

Six growth rate curves exist:
```asm
GROWTH_MEDIUM_FAST  ; 0: n^3
GROWTH_SLIGHTLY_FAST; 1: 3/4 * n^3 + 10*n^2 - 30
GROWTH_SLIGHTLY_SLOW; 2: 3/4 * n^3 + 10*n^2 - 30 (same formula, different Pokemon)
GROWTH_MEDIUM_SLOW  ; 3: 6/5 * n^3 - 15*n^2 + 100*n - 140
GROWTH_FAST         ; 4: 4/5 * n^3
GROWTH_SLOW         ; 5: 5/4 * n^3
```

---

## 6. Map & Overworld System

### Map Data Format

Each map consists of several components spread across multiple files:

**Map Header** (`data/maps/headers/<MapName>.asm`):
```asm
map_header PalletTown, PALLET_TOWN, OVERWORLD, NORTH | SOUTH
connection north, Route1, ROUTE_1, 0
connection south, Route21, ROUTE_21, 0
end_map_header
```

The `map_header` macro encodes:
- Map name and constant
- Tileset to use
- Connection flags (which directions have map connections)

**Map Connections**: Define how maps join together (north/south/east/west).

**Map Objects** (`data/maps/objects/<MapName>.asm`):
```asm
PalletTown_Object:
    db $b ; border block

    def_warp_events
    warp_event  5,  5, REDS_HOUSE_1F, 1
    warp_event 13,  5, BLUES_HOUSE, 1
    warp_event 12, 11, OAKS_LAB, 2

    def_bg_events
    bg_event 13, 13, TEXT_PALLETTOWN_OAKSLAB_SIGN
    bg_event  7,  9, TEXT_PALLETTOWN_SIGN

    def_object_events
    object_event  8,  5, SPRITE_OAK, STAY, NONE, TEXT_PALLETTOWN_OAK
    object_event  3,  8, SPRITE_GIRL, WALK, ANY_DIR, TEXT_PALLETTOWN_GIRL
    object_event 11, 14, SPRITE_FISHER, WALK, ANY_DIR, TEXT_PALLETTOWN_FISHER

    def_warps_to PALLET_TOWN
```

**Map Block Data** (`.blk` files): Binary files containing the 2x2 metatile indices that make up the map layout.

### Tileset System

Tilesets define the visual tiles used by maps. Each tileset includes:
- Tile graphics (stored as .2bpp files in `gfx/tilesets/`)
- Block definitions (which 4 tiles make up each 2x2 metatile)
- Collision data (which blocks are walkable)

Tilesets are loaded via `engine/overworld/tilesets.asm`.

### NPC/Object Event System

NPCs are managed through the sprite state data structures:

**SpriteStateData1** (per sprite, 16 bytes):
- Picture ID, movement status, screen position
- Animation frame counter, facing direction
- Collision direction

**SpriteStateData2** (per sprite, 16 bytes):
- Walk animation counter, displacement
- Grid position (in 2x2 tile steps)
- Movement byte (type of movement: stay, random walk, etc.)
- Delay until next movement

Movement types include:
- `STAY`: NPC stands still (may turn to face player when spoken to)
- `WALK`: NPC walks randomly in allowed directions
- Scripted movements via NPC movement scripts

### Script Engine

Map scripts are implemented in `scripts/<MapName>.asm`. Each map has:

1. **Main script function**: Called each frame, checks events and triggers
2. **Script pointer table**: Array of script functions indexed by a per-map script counter
3. **Text pointers**: Dialogue triggered by talking to NPCs or examining objects

Example (Pallet Town):
```asm
PalletTown_Script:
    CheckEvent EVENT_GOT_POKEBALLS_FROM_OAK
    jr z, .next
    SetEvent EVENT_PALLET_AFTER_GETTING_POKEBALLS
.next
    call EnableAutoTextBoxDrawing
    ld hl, PalletTown_ScriptPointers
    ld a, [wPalletTownCurScript]
    jp CallFunctionInTable
```

Scripts use event flags (bits in RAM) to track game progress:
- `CheckEvent`: Test if an event flag is set
- `SetEvent`: Set an event flag
- `ResetEvent`: Clear an event flag

### Warp/Connection System

**Warps**: Defined in object files as `warp_event X, Y, DEST_MAP, WARP_ID`. When the player steps on a warp tile, they are transported to the specified destination.

**Connections**: Maps that are adjacent in the overworld use `connection` macros to define seamless scrolling between maps. The connection system handles:
- Map data loading when crossing boundaries
- Proper coordinate translation
- Tileset compatibility

### Wild Encounter Tables

Wild encounter data is in `data/wild/maps/`, with each map having grass and water encounter tables:
```
NUM_WILDMONS = 10 per encounter type
WILDDATA_LENGTH = 1 + NUM_WILDMONS * 2
```
Each entry is a (level, species) pair.

---

## 7. Graphics System

### Tile and Sprite Formats

The Game Boy uses two graphics formats:

**1bpp** (1 bit per pixel): 8 bytes per 8x8 tile. Each pixel is either on or off. Used for simple graphics like the font.

**2bpp** (2 bits per pixel): 16 bytes per 8x8 tile. Each pixel has 4 possible shades (white, light gray, dark gray, black). Used for most game graphics.

The `rgbgfx` tool converts PNG images:
```makefile
%.2bpp: %.png
    $(RGBGFX) --colors dmg $(RGBGFXFLAGS) -o $@ $<

%.1bpp: %.png
    $(RGBGFX) --colors dmg $(RGBGFXFLAGS) --depth 1 -o $@ $<
```

### Pokemon Pic Compression

Pokemon front and back sprites use a custom compression format. The `pkmncompress` tool converts uncompressed 2bpp data to `.pic` format:

```makefile
%.pic: %.2bpp
    tools/pkmncompress $< $@
```

The compression is specifically designed for the RLE-like patterns found in Pokemon sprites. Sprite dimensions are encoded in the first byte of the `.pic` file.

Sprites are loaded through multiple buffers in SRAM:
- `sSpriteBuffer0`, `sSpriteBuffer1`, `sSpriteBuffer2`

### OAM (Sprite) Management

The Game Boy supports 40 hardware sprites (OAM entries). The game uses a shadow OAM buffer (`wShadowOAM`) in WRAM that is copied to hardware OAM during V-blank via DMA:

```asm
wShadowOAM::
; 40 entries, each 4 bytes: Y, X, Tile, Attributes
FOR n, OAM_COUNT
wShadowOAMSprite{02d:n}:: sprite_oam_struct wShadowOAMSprite{02d:n}
ENDR
```

DMA transfer is initiated by writing to rDMA ($FF46), which copies 160 bytes from the source address.

### Background/Window Layers

The Game Boy has two background layers:
- **BG** (Background): 256x256 pixel scrollable plane, rendered via `vBGMap0`
- **Window**: Overlay layer, positioned via WX/WY registers, rendered via `vBGMap1`

The game uses the window layer for HUD elements (HP bars, battle text boxes). The window Y position (`hWY`) is set to $90 during battle intro to hide it, then brought into view.

### Animation System

Battle animations are handled in `engine/battle/animations.asm` (bank $1E). The system uses:

- Animation IDs corresponding to move numbers
- Sub-animation definitions in `data/battle_anims/subanimations.asm`
- Frame block definitions in `data/battle_anims/frame_blocks.asm`
- Animation types controlling effects:
  - `ANIMATIONTYPE_BLINK_ENEMY_MON_SPRITE`: Simple damage animation
  - `ANIMATIONTYPE_SHAKE_SCREEN_HORIZONTALLY_LIGHT`: Move with additional effect
  - Various screen shake and flash animations

---

## 8. Audio Engine

### Sound Engine Structure

The audio engine is replicated across three ROM banks ($02, $08, $1F) to ensure music can play regardless of which bank is currently loaded:

```
Bank $02: Audio Engine 1, Music 1, Sound Effects 1
Bank $08: Audio Engine 2, Music 2, Sound Effects 2
Bank $1F: Audio Engine 3, Music 3, Sound Effects 3
```

Key audio engine files:
- `audio/engine_1.asm`, `engine_2.asm`, `engine_3.asm`: Core sound driver (identical code in each bank)
- `audio/low_health_alarm.asm`: Special handler for the low HP beeping
- `audio/notes.asm`: Note frequency definitions
- `audio/wave_samples.asm`: Custom waveform data for Channel 3

### Music Format

Music is defined using macros from `macros/scripts/audio.asm`:
- Channel command pointers for up to 4 channels
- Notes with pitch, duration, and octave
- Tempo, volume, duty cycle commands
- Loop and call constructs for repetition

### Channel Management

The Game Boy has 4 sound channels:
1. **Channel 1**: Square wave with sweep
2. **Channel 2**: Square wave
3. **Channel 3**: Custom waveform
4. **Channel 4**: Noise

The engine multiplexes these between music and sound effects:
- Music uses channels 1-4
- SFX can temporarily override channels
- `wMuteAudioAndPauseMusic` controls muting
- `wChannelSoundIDs` tracks what's playing on each channel

### Audio RAM Variables

```asm
wSoundID::        db          ; current sound to play
wChannelCommandPointers::  ds NUM_CHANNELS * 2  ; pointers into music data
wChannelSoundIDs::         ds NUM_CHANNELS       ; what's playing per channel
wChannelFlags1::           ds NUM_CHANNELS       ; playback flags
wChannelDutyCycles::       ds NUM_CHANNELS       ; square wave duty
wChannelVibratoDelayCounters:: ds NUM_CHANNELS   ; vibrato timing
wChannelVibratoExtents::   ds NUM_CHANNELS       ; vibrato depth
wChannelOctaves::          ds NUM_CHANNELS       ; current octave
wChannelVolumes::          ds NUM_CHANNELS       ; volume + fade
wMusicTempo:: dw                                 ; music playback speed
wSfxTempo::   dw                                 ; SFX playback speed
```

---

## 9. Save System

### Save Data Format

The save system uses SRAM banks 1-3 with MBC3's battery backup:

**Bank 1** (main save):
- Player name (11 bytes)
- Main game data (wMainDataStart to wMainDataEnd)
- Sprite data (wSpriteDataStart to wSpriteDataEnd)
- Party data (wPartyDataStart to wPartyDataEnd)
- Current box data (wBoxDataStart to wBoxDataEnd)
- Tile animation state (1 byte)
- Single-byte checksum

**Bank 2**: Boxes 1-6 + checksum
**Bank 3**: Boxes 7-12 + checksum

### Checksum Calculation

The save system uses `CalcCheckSum`, which computes a simple 8-bit sum of all bytes in the save region:

```asm
LoadMainData:
    ld hl, sGameData
    ld bc, sGameDataEnd - sGameData
    call CalcCheckSum
    ld c, a
    ld a, [sMainDataCheckSum]
    cp c
    jp z, .checkSumMatched
    ; If mismatch, try once more before declaring corruption
    ; ...
```

The checksum is recalculated and verified on each load. If it fails twice, a "File data is destroyed!" message is shown.

### Hall of Fame Data

Hall of Fame records are stored in SRAM Bank 0:
```asm
sHallOfFame:: ds HOF_TEAM * HOF_TEAM_CAPACITY
; HOF_TEAM = PARTY_LENGTH * HOF_MON = 6 * $10 = 96 bytes per entry
; HOF_TEAM_CAPACITY = 50 entries maximum
```

Each Hall of Fame entry records the species, level, and nickname of each party member at the time of becoming Champion.

---

## 10. Known Bugs (Comprehensive List)

### Critical / High Severity

| # | Bug | File | Lines | Description | Fixed Later? |
|---|-----|------|-------|-------------|--------------|
| 1 | Focus Energy divides crit rate | `engine/battle/core.asm` | ~4507 | Focus Energy should multiply crit rate by 4, but only applies the same x2 as without it, effectively making it worse | Pokemon Stadium |
| 2 | Bide link battle desync | `engine/battle/core.asm` | ~747 | Only zeroes high byte of accumulated damage, causing link battle desync | Gen II |
| 3 | Counter link desync | `engine/battle/core.asm` | ~4550 | Counter checks cursor-highlighted move, not used move; desync risk in link | Gen II |
| 4 | MissingNo. (Old Man glitch) | `engine/battle/core.asm` | ~2026 | Player name stored in wild encounter buffer, not overwritten on Cinnabar/Route 21 | Gen II |
| 5 | Division by zero freeze | `engine/battle/core.asm` | ~4119 | Defensive stat can become 0 after scaling, freezing the game | Gen II |

### Medium Severity

| # | Bug | File | Lines | Description | Fixed Later? |
|---|-----|------|-------|-------------|--------------|
| 6 | Jump Kick recoil always 1 | `engine/battle/core.asm` | ~3746 | wDamage is 0 when move misses, so recoil is always 1 HP | Gen II |
| 7 | Self-confusion hits wrong substitute | `engine/battle/core.asm` | ~4852 | Turn swap during self-damage targets opponent's substitute | Gen II |
| 8 | CooltrainerF AI broken | `engine/battle/trainer_ai.asm` | ~346 | 25% switch chance never properly activates | N/A |
| 9 | Ghost/Psychic immunity | `data/types/type_matchups.asm` | ~78 | Ghost is immune to Psychic (should be super effective per lore) | Gen II |
| 10 | Reflect/Light Screen overflow | `engine/battle/core.asm` | ~4085 | Doubling defense doesn't cap at 999, causing overflow | Gen II |

### Low Severity / Cosmetic

| # | Bug | File | Lines | Description | Fixed Later? |
|---|-----|------|-------|-------------|--------------|
| 11 | Screen tearing (faint anim) | `engine/battle/core.asm` | ~1182 | hAutoBGTransferEnabled is nonzero during slide animation | Gen II |
| 12 | Screen tearing (trainer slide) | `engine/battle/core.asm` | ~1236 | Same issue for trainer pic sliding off screen | Gen II |
| 13 | Wild win SFX before HP check | `engine/battle/core.asm` | ~798 | Victory music plays before verifying player mon is alive | Gen II |
| 14 | Psywave asymmetry | `engine/battle/core.asm` | ~4661 | Player does 1-149% damage, enemy does 0-149% | Gen II |
| 15 | Type effectiveness $10 literal | `engine/battle/trainer_ai.asm` | ~212 | Hard-coded $10 instead of EFFECTIVE constant | N/A |
| 16 | Wild stone evolution | `engine/pokemon/evos_moves.asm` | ~12 | Item evolutions can trigger after battle | Gen II |
| 17 | Mirror Move missing check | `engine/battle/core.asm` | ~363 | Missing MIRROR_MOVE check for multi-turn move desync | Gen II |
| 18 | Badge stat boost stacking | `engine/battle/effects.asm` | ~499 | Badge boosts reapplied on every stat-up/down move | Gen II |
| 19 | Toxic + Leech Seed interaction | `engine/battle/core.asm` | ~547 | Toxic counter applies to Leech Seed damage too | Gen II |

---

## 11. GitHub Issues Analysis

Based on the pret/pokered repository's issue tracker, several ongoing discussions focus on code quality and naming conventions:

### Issue #551: IVs vs DVs Naming
The game internally uses "DVs" (Determinant Values), the official Japanese term. The community debates whether to use the more widely-known "IVs" (Individual Values) from later games. The current codebase uses DVs (`MON_DVS`, `wBattleMonDVs`) to match the original developer terminology.

### Issue #302: Redundant Comments
Discussion about comments that merely restate what the assembly code already says (e.g., `ld a, 5 ; load 5 into a`). The consensus is that comments should explain *why*, not *what*. Many such comments have been cleaned up, but some remain.

### Issue #495: Hard-coded Constants
Numerous magic numbers exist throughout the codebase. Examples include:
- `$10` used for type effectiveness neutral value instead of `EFFECTIVE`
- `$d` for maximum stat modifier instead of a named constant
- Various hex values for struct offsets
Replacing these with named constants is an ongoing effort.

### Issue #479: Unnamed Bitmasks
Battle status bytes use bit positions that should be named constants rather than raw numbers. The project has made significant progress on this with constants like `STORING_ENERGY`, `THRASHING_ABOUT`, `CHARGING_UP`, `USING_TRAPPING_MOVE`, `FLINCHED`, etc.

### Issues #524, #521, #498, #420, #315: Various Renaming Tasks
These issues track ongoing efforts to give meaningful names to:
- Unnamed WRAM variables
- Unlabeled functions and code sections
- Ambiguous constant names
- Inconsistent naming conventions across the codebase

The project maintains a high standard for naming, requiring that labels accurately describe their purpose and follow established conventions.

---

## 12. Modding Entry Points

### How to Add New Pokemon

1. **Define the species constant** in `constants/pokemon_constants.asm`
2. **Create base stats** in `data/pokemon/base_stats/<name>.asm`:
   ```asm
   db DEX_NEWMON
   db 80, 80, 80, 80, 80  ; hp, atk, def, spd, spc
   db TYPE1, TYPE2
   db 45                   ; catch rate
   db 100                  ; base exp
   INCBIN "gfx/pokemon/front/<name>.pic", 0, 1
   dw <Name>PicFront, <Name>PicBack
   db MOVE1, MOVE2, NO_MOVE, NO_MOVE
   db GROWTH_MEDIUM_FAST
   tmhm MOVE1, MOVE2, ...
   db 0
   ```
3. **Add the include** to `data/pokemon/base_stats.asm`
4. **Create front and back sprites** as PNG files in `gfx/pokemon/front/` and `gfx/pokemon/back/`
5. **Add a Pokedex entry** in the Pokedex text bank
6. **Add evolution and learnset data** in `data/pokemon/evos_moves.asm`
7. **Add the name** in `data/pokemon/names.asm`
8. **Add a cry** in `data/pokemon/cries.asm`
9. **Update the Pokedex constant** in `constants/pokedex_constants.asm`

**Important**: The original ROM has exactly 151 Pokemon with species IDs $01-$BE (non-contiguous, with gaps used by MissingNo.). Adding new Pokemon requires careful management of the species ID space.

### How to Modify Moves

Edit `data/moves/moves.asm`:
```asm
; To change Tackle's power from 35 to 50:
move TACKLE, NO_ADDITIONAL_EFFECT, 50, NORMAL, 95, 35

; To add a new move:
move NEW_MOVE, BURN_SIDE_EFFECT1, 90, FIRE, 100, 15
```

To add entirely new effects:
1. Define the effect constant in `constants/move_effect_constants.asm`
2. Add the effect handler in `engine/battle/effects.asm` or a new file
3. Add the entry to `MoveEffectPointerTable` in `data/moves/effects_pointers.asm`
4. Categorize it into the appropriate effect array (ResidualEffects1, etc.)

### How to Add New Maps

1. **Create the block data** (`maps/<MapName>.blk`)
2. **Create the header** (`data/maps/headers/<MapName>.asm`):
   ```asm
   map_header NewMap, NEW_MAP, OVERWORLD, NORTH
   connection north, ExistingMap, EXISTING_MAP, 0
   end_map_header
   ```
3. **Create the object data** (`data/maps/objects/<MapName>.asm`):
   ```asm
   NewMap_Object:
       db $b
       def_warp_events
       warp_event 5, 5, DEST_MAP, 1
       def_bg_events
       def_object_events
       object_event 8, 5, SPRITE_LASS, WALK, ANY_DIR, TEXT_NEWMAP_NPC
       def_warps_to NEW_MAP
   ```
4. **Create the script** (`scripts/<MapName>.asm`)
5. **Create the text** (`text/<MapName>.asm`)
6. **Add the map constant** in `constants/map_constants.asm`
7. **Add the bank reference** in `data/maps/map_header_banks.asm`
8. **Add the header pointer** in the map header pointer table
9. **Include the files** in the appropriate sections of `maps.asm`

### How to Change Trainer Teams

Trainer party data is in `data/trainers/parties.asm`. Each trainer has their Pokemon listed by level and species. For trainers with custom movesets (special trainers), moves are also specified.

### How to Modify the Battle Engine

Key files for battle engine modification:

| Purpose | File |
|---------|------|
| Main battle loop | `engine/battle/core.asm` |
| Move effects | `engine/battle/effects.asm` + individual files in `engine/battle/move_effects/` |
| Damage formula | `engine/battle/core.asm` (`CalculateDamage`) |
| Type chart | `data/types/type_matchups.asm` |
| Critical hit logic | `engine/battle/core.asm` (`CriticalHitTest`) |
| Trainer AI | `engine/battle/trainer_ai.asm` |
| AI data | `data/trainers/ai_pointers.asm`, `data/trainers/move_choices.asm` |
| Experience | `engine/battle/experience.asm` |
| Wild encounters | `engine/battle/wild_encounters.asm` |
| Move data | `data/moves/moves.asm` |
| Animations | `engine/battle/animations.asm` |

### Key Files for Common Mods

| Mod Goal | Files to Edit |
|----------|---------------|
| Change starter Pokemon | `scripts/OaksLab.asm`, `engine/events/give_pokemon.asm` |
| Modify wild encounters | `data/wild/maps/*.asm` |
| Change item prices | `data/items/prices.asm` |
| Edit NPC dialogue | `text/<MapName>.asm` |
| Modify type chart | `data/types/type_matchups.asm` |
| Change evolution methods | `data/pokemon/evos_moves.asm` |
| Edit trainer Pokemon | `data/trainers/parties.asm` |
| Modify items | `constants/item_constants.asm`, `engine/items/item_effects.asm` |
| Change music | `audio/music/` directory |
| Edit tilesets | `gfx/tilesets/` directory |
| Modify palettes (SGB/GBC) | `engine/gfx/palettes.asm` |
| Change text speed | `engine/menus/main_menu.asm` (options) |
| Edit save system | `engine/menus/save.asm` |

### ROM Bank Space Considerations

When adding content, be aware of bank boundaries:
- Each bank is 16 KB ($4000 bytes)
- ROM0 (bank 0) is always accessible but limited
- Check the `.map` file after building to see remaining space in each bank
- Text banks ($20-$2A) typically have the most free space
- The `layout.link` file defines section-to-bank assignments

### Build Verification

After making changes, always verify the build:
```bash
make clean && make
```

If you want to verify your changes produce a different ROM (not matching the original):
```bash
make compare  # This should FAIL if you've made intentional changes
```

---

## Appendix A: File Tree Overview

```
pokered/
+-- Makefile            Build system
+-- layout.link         ROM bank layout
+-- includes.asm        Global includes (pre-included in every file)
+-- main.asm            Main ROM section includes
+-- home.asm            Bank 0 (home) includes
+-- audio.asm           Audio section includes
+-- maps.asm            Map section includes
+-- ram.asm             RAM section includes
+-- text.asm            Text section includes
+-- constants/          All constant definitions (52 files)
+-- macros/             Assembly macros
+-- engine/
|   +-- battle/         Battle engine code
|   |   +-- core.asm    Main battle loop (~5300 lines)
|   |   +-- effects.asm Move effect handlers
|   |   +-- trainer_ai.asm  AI system
|   |   +-- move_effects/   Individual move effect files
|   |   +-- animations.asm  Battle animation engine
|   +-- overworld/      Overworld engine
|   +-- pokemon/        Pokemon-related logic
|   +-- menus/          Menu systems
|   +-- items/          Item logic
|   +-- events/         Event handlers
|   +-- gfx/            Graphics routines
|   +-- movie/          Cutscene code (intro, credits, etc.)
|   +-- link/           Link cable support
|   +-- math/           Math routines (BCD, multiply, divide, random)
|   +-- slots/          Slot machine minigame
+-- data/
|   +-- pokemon/        Pokemon data (base stats, names, cries, evos)
|   +-- moves/          Move data and animations
|   +-- types/          Type matchup chart
|   +-- trainers/       Trainer data (parties, AI, names)
|   +-- maps/           Map headers, objects, connections
|   +-- items/          Item data (names, prices)
|   +-- battle/         Battle data tables
|   +-- wild/           Wild encounter tables
+-- gfx/                Graphics assets (PNG sources and binary outputs)
+-- audio/              Audio engine and music/SFX data
+-- scripts/            Map scripts
+-- text/               Text and dialogue
+-- maps/               Map block data (.blk files)
+-- ram/                RAM definitions (WRAM, HRAM, VRAM, SRAM)
+-- tools/              Custom build tools
+-- vc/                 Virtual Console patch data
```

## Appendix B: Battle Status Flags Reference

### wPlayerBattleStatus1 / wEnemyBattleStatus1

| Bit | Name | Description |
|-----|------|-------------|
| 0 | STORING_ENERGY | Using Bide |
| 1 | THRASHING_ABOUT | Using Thrash/Petal Dance |
| 2 | ATTACKING_MULTIPLE_TIMES | Multi-hit move in progress |
| 3 | FLINCHED | Flinched this turn |
| 4 | CHARGING_UP | Charging for 2-turn move |
| 5 | USING_TRAPPING_MOVE | Using Wrap/Bind/etc. |
| 6 | INVULNERABLE | Using Fly/Dig (untargetable) |
| 7 | CONFUSED | Confused status |

### wPlayerBattleStatus2 / wEnemyBattleStatus2

| Bit | Name | Description |
|-----|------|-------------|
| 0 | USING_X_ACCURACY | X Accuracy active |
| 1 | PROTECTED_BY_MIST | Mist active (blocks stat drops) |
| 2 | GETTING_PUMPED | Focus Energy active |
| 3 | HAS_SUBSTITUTE_UP | Substitute is active |
| 4 | NEEDS_TO_RECHARGE | Must recharge (Hyper Beam) |
| 5 | USING_RAGE | Rage is active |
| 6 | SEEDED | Leech Seed planted |
| 7 | (unused) | |

### wPlayerBattleStatus3 / wEnemyBattleStatus3

| Bit | Name | Description |
|-----|------|-------------|
| 0 | BADLY_POISONED | Toxic (badly poisoned) |
| 1 | HAS_LIGHT_SCREEN_UP | Light Screen active |
| 2 | HAS_REFLECT_UP | Reflect active |
| 3 | TRANSFORMED | Has used Transform |

---

*This document was generated by analyzing the pokered source code at commit time. All file references, line numbers, and code snippets are based on the actual disassembly source files.*
