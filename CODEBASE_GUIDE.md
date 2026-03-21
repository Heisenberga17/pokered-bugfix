# pokered Codebase Deep Dive

This document synthesizes findings from a thorough exploration of the entire pret/pokered disassembly.

---

## 1. Battle Engine Walkthrough

### Battle Initiation & Main Loop
- **Core file**: `engine/battle/core.asm` (~6900+ lines)
- Entry: `SlidePlayerAndEnemySilhouettesOnScreen` (lines 1-100)
- **Main loop**: `MainInBattleLoop` (lines 280-441)

### Turn Flow
```
START TURN
  -> Determine turn order (speed comparison, priority moves)
  -> Player: CheckPlayerStatusConditions -> MoveSelectionMenu -> ExecutePlayerMove
  -> Enemy:  CheckEnemyStatusConditions  -> SelectEnemyMove   -> ExecuteEnemyMove
  -> HandlePoisonBurnLeechSeed (residual damage)
  -> LOOP
```

### Damage Formula (lines 4299-4465)
```
damage = ((2 * level / 5 + 2) * power * attack / defense / 50) + MIN_NEUTRAL_DAMAGE
```
Then: type effectiveness (2x/0.5x/0x) -> critical hit (2x) -> randomization (85%-100%)

### Status Conditions (lines 3328-3477)
Checked in order: Sleep -> Freeze -> Trapped -> Flinch -> Hyperbeam Recharge -> Disabled -> Confusion -> Paralysis

### Trainer AI (`engine/battle/trainer_ai.asm`)
- Weighted move selection: initialize all moves at weight `$0A`, modify via 4 AI layers
- Per-trainer behaviors: Giovanni uses Guard Spec, Sabrina uses Hyper Potion, Lance heals at <20% HP
- `wAICount` controls difficulty (Elite Four get more AI iterations)

### Move Effects
Individual files in `engine/battle/move_effects/`: drain_hp, recoil, one_hit_ko, leech_seed, substitute, reflect_light_screen, transform, haze, etc.

---

## 2. Map Loading & Overworld System

### Map Structure
Each map = 3 components:
- **Header** (`data/maps/headers/*.asm`): tileset, dimensions, block pointer, text pointer, script pointer, connections
- **Objects** (`data/maps/objects/*.asm`): NPCs, warps, signs
- **Blocks** (`maps/*.blk`): binary tile data

### Key Macros (`macros/scripts/maps.asm`)
- `map_header` (lines 142-153): 11-byte header
- `connection` (lines 167-232): 11-byte connection entry linking adjacent outdoor maps
- `warp_event` (lines 51-56): door/staircase transitions (Y, X, dest_warp, dest_map)
- `object_event` (lines 16-39): NPCs with sprite, position, movement type, text ID
- `bg_event` (lines 67-71): signs/bookshelves (Y, X, text_id)

### Wild Encounters
- **Loading**: `engine/overworld/wild_mons.asm` - copies grass/water data to RAM on map entry
- **Triggering**: `engine/battle/wild_encounters.asm` - `TryDoWildEncounter` checks tile type, Repel, random roll vs encounter rate
- **Slot probabilities** (`data/wild/probabilities.asm`): Slots 0-1 at 19.9% each, down to Slot 9 at 1.2%

### Map Scripts (example: `scripts/PalletTown.asm`)
- State machine pattern: `wPalletTownCurScript` indexes into `PalletTown_ScriptPointers`
- Scripts check event flags, manipulate player input, trigger music, queue NPC movement

---

## 3. Build Toolchain

### Required: RGBDS 1.0.1 (`.rgbds-version`)
| Tool | Purpose |
|------|---------|
| rgbasm | Assembles .asm -> .o object files |
| rgblink | Links .o files using layout.link -> .gbc |
| rgbfix | Adds ROM header, checksums, metadata |
| rgbgfx | Converts PNG -> .2bpp/.1bpp tile data |

### Makefile (215 lines)
- Builds 3 ROMs: pokered.gbc, pokeblue.gbc, pokeblue_debug.gbc
- Variant flags: `-D _RED`, `-D _BLUE`, `-D _DEBUG`
- Graphics pipeline: `*.png -> rgbgfx -> *.2bpp -> tools/gfx (optimize) -> tools/pkmncompress -> *.pic`
- `make compare` validates SHA1 against `roms.sha1`

### layout.link (205 lines)
- ROM0: Header, RST vectors, interrupts, Home bank
- Banks $1-$2: Audio
- Banks $3-$F: Battle engine, maps, graphics
- Banks $10-$1D: Maps, tilesets, events
- Banks $20-$2C: Text (13 banks)
- WRAM: Audio RAM, sprite state, party data, save data
- SRAM 0-3: Sprite buffers, save data, PC boxes

### Custom Tools (`tools/`)
| Tool | Lines | Purpose |
|------|-------|---------|
| scan_includes.c | 122 | Recursive INCLUDE/INCBIN dependency scanner |
| gfx.c | 300 | Tile deduplication, trim whitespace, flip detection |
| pkmncompress.c | 364 | Pokemon sprite compression (RLE + Gray code) |
| make_patch.c | 528 | Virtual Console patch generation |

---

## 4. Mod Planning Guide - Entry Points

### Adding/Modifying Pokemon
| What | File | Format |
|------|------|--------|
| Base stats | `data/pokemon/base_stats/*.asm` | `db HP, ATK, DEF, SPD, SPC, type1, type2, catch_rate, exp_yield` |
| Names | `data/pokemon/names.asm` | `dname "BULBASAUR"` (10 chars max) |
| Evolutions & learnsets | `data/pokemon/evos_moves.asm` | Pointer table + evo conditions + level-up moves |
| TM/HM compatibility | embedded in base stats | `tmhm` macro bit-packing (7 bytes = 55 TM/HMs) |
| Sprites | `gfx/pokemon/front/*.png`, `gfx/pokemon/back/*.png` | Compressed via pkmncompress |
| Pokedex entries | `data/pokemon/dex_entries.asm` | Pointer table with species name, height, weight |
| Pokedex text | `data/pokemon/dex_text.asm` | Description text for each Pokemon |
| Cry data | `data/pokemon/cries.asm` | Base cry, pitch, length parameters |

**Constants to sync**: `NUM_POKEMON` (pokedex_constants.asm), `NUM_POKEMON_INDEXES` (pokemon_constants.asm)

### Editing Trainers
| What | File |
|------|------|
| Trainer parties | `data/trainers/parties.asm` |
| Trainer names | `data/trainers/names.asm` |
| Trainer AI | `engine/battle/trainer_ai.asm` (per-class AI routines, lines 320-450) |

### Modifying Items
| What | File |
|------|------|
| Item properties | `data/items/` directory |
| Item names | `data/items/names.asm` |
| Constant: `NUM_ITEMS` | `constants/item_constants.asm` (currently 95) |

### Wild Encounters
| What | File |
|------|------|
| Grass/water tables | `data/wild/grass_water.asm` |
| Encounter probabilities | `data/wild/probabilities.asm` |
| Super Rod data | `data/wild/super_rod.asm` |

### Type Chart
- **File**: `data/types/type_matchups.asm`
- Format: `db ATTACKING_TYPE, DEFENDING_TYPE, EFFECTIVENESS`
- Terminated by `db -1`

### Text/Dialogue
- Text spread across `text/*.asm` (13 ROM banks worth)
- Map-specific text in `scripts/*.asm` (TextPointers tables)
- Uses `text_far` for cross-bank text references

---

## 5. Common Build Issues & Debugging Guide

### Bank Overflow
- Each ROMX bank = $4000 (16,384) bytes max
- Error: `Section "X" is N bytes, max 16384`
- Fix: Move code/data to a less-full bank, update layout.link

### Critical Constant Dependencies
| Constant | Value | File | Dependent Tables |
|----------|-------|------|-----------------|
| NUM_MOVES | 4 | battle_constants.asm | BASE_MOVES, MON_MOVES, MON_PP structures |
| NUM_POKEMON | 151 | pokedex_constants.asm | BaseStats, MonPartyData, MonsterPalettes |
| NUM_POKEMON_INDEXES | 151 | pokemon_constants.asm | MonsterNames, EvosMovesPointerTable, CryData |
| NUM_ATTACKS | 166 | move_constants.asm | Moves table, MoveNames, animations |
| NUM_ITEMS | 95 | item_constants.asm | Item tables |
| NUM_TM_HM | 55 | item_constants.asm | tmhm macro byte count (7 bytes) |
| NUM_WILDMONS | 10 | pokemon_data_constants.asm | Encounter table size |

### Assembly Pitfalls
1. **farcall vs call**: Code in other banks MUST use `farcall`/`callfar` (macros/farcall.asm). Direct `call` only works within same bank or to home bank (ROM0)
2. **hLoadedROMBank sync**: Any direct bank switch (`ld [rROMB], a`) must also update HRAM tracker
3. **Assertion macros**: `assert_table_length` and `assert_list_length` catch count mismatches at build time
4. **tmhm bit-packing**: Adding TMs changes byte count calculation `(NUM_TM_HM + 7) / 8`, cascading through all Pokemon base stat entries
5. **Predef table ordering**: IDs = offset/3, so inserting/removing entries shifts all subsequent IDs

### Validation Built In
The codebase uses extensive compile-time assertions:
- `assert_table_length NUM_POKEMON_INDEXES` on MonsterNames
- `ASSERT NUM_TMS == const_value - TM01` on TM enumeration
- `def_grass_wildmons`/`end_grass_wildmons` validate encounter data structure

---

## Verification
To confirm everything works after any mod:
```bash
make clean && make        # Full rebuild
make compare              # SHA1 validation (will fail if you changed anything, expected)
```
Test in an emulator (BGB, mGBA, or SameBoy) to verify runtime behavior.
