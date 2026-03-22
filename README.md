# Pokemon Red and Blue [![Build Status][ci-badge]][ci]

<div align="center">

<img src="https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/other/official-artwork/151.png" width="120">
<img src="https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/other/official-artwork/144.png" width="120">
<img src="https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/other/official-artwork/150.png" width="120">

**Modded & Bugfixed Pokemon Red and Blue**

*Mew as a starter. Legendaries in every route. 29 bugs squashed.*

</div>

---

This is a modded disassembly of Pokemon Red and Blue featuring **custom starters** (Mew, Eevee, Gengar), a **complete wild encounter overhaul** with rare and legendary Pokemon on every route, **boosted catch rates** for legendaries, and **29 bug fixes** across the battle engine, overworld, items, scripts, and audio systems.

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

## Gameplay Mods

This build includes **4 gameplay modifications** that transform the Pokemon Red/Blue experience. Every change is documented below with exact file paths, before/after comparisons, and full encounter tables.

---

### Mod 1: Custom Starters — Mew, Eevee, Gengar

<img src="https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/other/official-artwork/151.png" width="100">
<img src="https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/other/official-artwork/133.png" width="100">
<img src="https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/other/official-artwork/94.png" width="100">

**File:** `constants/pokemon_constants.asm` (lines 204-206)

The three starter Pokemon in Professor Oak's Lab have been completely replaced. When you walk up to a Pokeball in Oak's Lab, you'll get one of these instead of the original Kanto starters:

| Pokeball Position | Original Starter | New Starter | Pokedex # |
|-------------------|-----------------|-------------|-----------|
| Left (STARTER1) | Charmander | **Mew** | #151 |
| Middle (STARTER2) | Squirtle | **Eevee** | #133 |
| Right (STARTER3) | Bulbasaur | **Gengar** | #94 |

**How it works:** The game uses `STARTER1`, `STARTER2`, `STARTER3` constants throughout `scripts/OaksLab.asm` to determine what's in each Pokeball and what the rival picks. By changing only the constants, the entire starter flow updates automatically — no script editing needed.

**Rival behavior:** Your rival always picks the starter *after* yours in the rotation:
- You pick **Mew** → Rival gets **Eevee**
- You pick **Eevee** → Rival gets **Gengar**
- You pick **Gengar** → Rival gets **Mew**

**Code change:**
```diff
-DEF STARTER1 EQU CHARMANDER
-DEF STARTER2 EQU SQUIRTLE
-DEF STARTER3 EQU BULBASAUR
+DEF STARTER1 EQU MEW
+DEF STARTER2 EQU EEVEE
+DEF STARTER3 EQU GENGAR
```

---

### Mod 2: Wild Encounter Overhaul — Legendaries Everywhere

**Files modified:** All 60 encounter files in `data/wild/maps/*.asm`
**Total species affected:** 150+ unique Pokemon placements across 60 maps

Every single wild encounter table in the game has been rewritten from scratch. Rare, normally-unobtainable, and legendary Pokemon now appear as regular wild encounters throughout Kanto. All `IF DEF(_RED)` / `IF DEF(_BLUE)` version-exclusive conditionals have been removed — both versions now have identical encounters.

#### How Wild Encounters Work in Gen 1

The game engine uses a weighted 10-slot system. When you step in tall grass (or surf), one of 10 slots is chosen with these probabilities:

| Slot | Probability | Our Design Intent |
|------|-------------|-------------------|
| 1 | **~20%** | Legendary Pokemon (Mewtwo, Mew, or a legendary bird) |
| 2 | **~20%** | Legendary Pokemon |
| 3 | **~15%** | Legendary Pokemon |
| 4 | **~10%** | Legendary Pokemon |
| 5 | **~10%** | Legendary Pokemon |
| 6 | **~5%** | Rare Pokemon (Dragonite, Snorlax, Aerodactyl, etc.) |
| 7 | **~5%** | Rare Pokemon |
| 8 | **~4%** | Rare Pokemon |
| 9 | **~4%** | Rare Pokemon |
| 10 | **~1%** | Rare Pokemon |

**~75% of all encounters are legendaries** (Mewtwo, Mew, Articuno, Zapdos, Moltres). The remaining ~25% are other rare Pokemon like Dragonite, Snorlax, and Aerodactyl. Commons are effectively extinct in the wild.

---

#### Early Game Routes — Levels 3-10

These are the first areas you visit. Levels are kept low so your starter can handle them, but every encounter is a Pokemon that's normally impossible to get this early.

##### Route 1 (Pallet Town → Viridian City)

| Slot | Level | Pokemon | Encounter Rate |
|------|-------|---------|----------------|
| 1 | 5 | **Articuno** | ~20% |
| 2 | 5 | **Zapdos** | ~20% |
| 3 | 5 | **Moltres** | ~15% |
| 4 | 5 | **Mew** | ~10% |
| 5 | 5 | **Mewtwo** | ~10% |
| 6 | 4 | **Dragonite** | ~5% |
| 7 | 4 | **Lapras** | ~5% |
| 8 | 3 | **Dratini** | ~4% |
| 9 | 3 | **Eevee** | ~4% |
| 10 | 3 | **Chansey** | ~1% |

##### Route 2 (Viridian City → Viridian Forest)

| Slot | Level | Pokemon | Encounter Rate |
|------|-------|---------|----------------|
| 1 | 5 | **Zapdos** | ~20% |
| 2 | 5 | **Moltres** | ~20% |
| 3 | 5 | **Articuno** | ~15% |
| 4 | 5 | **Mewtwo** | ~10% |
| 5 | 5 | **Mew** | ~10% |
| 6 | 4 | **Dragonite** | ~5% |
| 7 | 4 | **Kangaskhan** | ~5% |
| 8 | 3 | **Dratini** | ~4% |
| 9 | 3 | **Scyther** | ~4% |
| 10 | 3 | **Porygon** | ~1% |

##### Route 3 (Pewter City → Mt. Moon)

| Slot | Level | Pokemon | Encounter Rate |
|------|-------|---------|----------------|
| 1 | 7 | **Moltres** | ~20% |
| 2 | 7 | **Articuno** | ~20% |
| 3 | 7 | **Zapdos** | ~15% |
| 4 | 7 | **Mew** | ~10% |
| 5 | 7 | **Mewtwo** | ~10% |
| 6 | 6 | **Dragonite** | ~5% |
| 7 | 6 | **Lapras** | ~5% |
| 8 | 5 | **Eevee** | ~4% |
| 9 | 5 | **Tauros** | ~4% |
| 10 | 5 | **Pinsir** | ~1% |

##### Route 22 (Viridian City → Pokemon League Gate)

| Slot | Level | Pokemon | Encounter Rate |
|------|-------|---------|----------------|
| 1 | 5 | **Articuno** | ~20% |
| 2 | 5 | **Moltres** | ~20% |
| 3 | 5 | **Zapdos** | ~15% |
| 4 | 5 | **Mew** | ~10% |
| 5 | 5 | **Mewtwo** | ~10% |
| 6 | 4 | **Dragonite** | ~5% |
| 7 | 4 | **Kangaskhan** | ~5% |
| 8 | 3 | **Dratini** | ~4% |
| 9 | 3 | **Chansey** | ~4% |
| 10 | 3 | **Scyther** | ~1% |

##### Viridian Forest

| Slot | Level | Pokemon | Encounter Rate |
|------|-------|---------|----------------|
| 1 | 6 | **Mew** | ~20% |
| 2 | 6 | **Articuno** | ~20% |
| 3 | 6 | **Zapdos** | ~15% |
| 4 | 6 | **Moltres** | ~10% |
| 5 | 6 | **Mewtwo** | ~10% |
| 6 | 5 | **Dragonite** | ~5% |
| 7 | 5 | **Lapras** | ~5% |
| 8 | 4 | **Eevee** | ~4% |
| 9 | 4 | **Scyther** | ~4% |
| 10 | 4 | **Pinsir** | ~1% |

---

#### Mid Game Routes — Levels 15-30

Pokemon evolve from the early-game rarities into more powerful mid-tier species. Fossil Pokemon appear in common slots, and legendaries start showing up with Mewtwo and Mew.

**Routes 4-12, 24, 25** all follow this pattern (levels and specific species vary per route):

- **Slots 1-5 (~75%):** Mewtwo, Mew, Articuno, Zapdos, Moltres — legendaries dominate
- **Slots 6-7 (~10%):** Dragonite, Snorlax
- **Slots 8-10 (~9%):** Aerodactyl, Hitmonlee/Hitmonchan, Lapras/Kangaskhan/Tauros

Each route rotates which legendary leads slot 1 and alternates between Hitmonlee and Hitmonchan to add variety.

---

#### Late Game Routes — Levels 30-50

Fully-evolved powerhouses dominate. Every encounter is a Pokemon that would normally be endgame-only.

**Routes 13-18, 21, 23** all follow this pattern:

- **Slots 1-5 (~75%):** Mewtwo, Mew, Articuno, Zapdos, Moltres — all legendaries, all the time
- **Slots 6-7 (~10%):** Dragonite, Alakazam
- **Slots 8-10 (~9%):** Gengar, Machamp, Snorlax

Levels scale from ~33 (Route 13) up to ~45 (Route 23 near Victory Road).

---

#### Caves — Fossil Pokemon + Legendary Hunting Grounds

All caves have been converted to legendary hunting grounds. Legendaries dominate the encounter tables:

- **Slots 1-5 (~75%):** Mewtwo, Mew, Articuno, Zapdos, Moltres
- **Slots 6-7 (~10%):** Dragonite, Aerodactyl
- **Slots 8-10 (~9%):** Kabuto, Omanyte, Chansey

| Cave | Floors | Level Range | Notes |
|------|--------|-------------|-------|
| **Mt. Moon** | 1F, B1F, B2F | 8-14 | Earliest cave — fossil Pokemon at low levels |
| **Rock Tunnel** | 1F, B1F | 16-23 | Mid-game fossil and legendary hunting |
| **Diglett's Cave** | 1 floor | 20-30 | Higher levels than Rock Tunnel |
| **Seafoam Islands** | 1F, B1F-B4F | 30-48 | Levels increase deeper you go. B4F has Mewtwo at 48 |
| **Victory Road** | 1F, 2F, 3F | 40-55 | Late-game. Mewtwo at 50-55 on upper floors |

---

#### Pokemon Tower (Lavender Town) — Levels 20-35

Ghost-themed encounters with legendaries mixed in. Floors 1-2 remain empty (lobby) as in vanilla.

- **Slots 1-5 (~75%):** Mewtwo, Mew, Articuno, Zapdos, Moltres
- **Slots 6-7 (~10%):** Gengar, Haunter
- **Slots 8-10 (~9%):** Dragonite, Chansey, Porygon

Levels increase per floor: Floor 3 starts at 22, Floor 7 reaches 30.

---

#### Pokemon Mansion (Cinnabar Island) — Levels 32-42

Legendaries dominate, with fire-type rares in the bottom slots:

- **Slots 1-5 (~75%):** Mewtwo, Mew, Moltres, Articuno, Zapdos
- **Slots 6-7 (~10%):** Dragonite, Arcanine
- **Slots 8-10 (~9%):** Ninetales, Aerodactyl, Chansey

Levels increase per floor. Basement has the strongest encounters (38-42).

---

#### Power Plant — Levels 30-35

Zapdos leads the encounter table (fitting since Zapdos's static encounter is here in vanilla):

- **Slots 1-5 (~75%):** Zapdos, Mewtwo, Mew, Articuno, Moltres
- **Slots 6-7 (~10%):** Dragonite, Electabuzz
- **Slots 8-10 (~9%):** Raichu, Magneton, Chansey

---

#### Safari Zone — Levels 25-30

All four Safari Zone areas have legendaries as the most common encounters (encounter rate 30, the highest in the game):

- **Slots 1-5 (~75%):** Mewtwo, Mew, Articuno, Zapdos, Moltres (rotating leads)
- **Slots 6-7 (~10%):** Dragonite + area-specific rare (Kangaskhan, Scyther, Tauros, Pinsir)
- **Slots 8-10 (~9%):** More area-specific rares (Chansey, Scyther, etc.)

| Area | Slot 1-2 Leads |
|------|----------------|
| **Center** | Mewtwo, Mew |
| **East** | Mew, Mewtwo |
| **North** | Articuno, Mewtwo |
| **West** | Zapdos, Mew |

---

#### Sea Routes (Surfing) — Levels 25-45

Water encounters on all ocean routes have been completely overhauled:

| Slot | Level | Pokemon | Encounter Rate |
|------|-------|---------|----------------|
| 1 | 35 | **Articuno** | ~20% |
| 2 | 35 | **Mew** | ~20% |
| 3 | 35 | **Mewtwo** | ~15% |
| 4 | 33 | **Zapdos** | ~10% |
| 5 | 33 | **Moltres** | ~10% |
| 6 | 30 | **Dragonite** | ~5% |
| 7 | 30 | **Lapras** | ~5% |
| 8 | 28 | **Gyarados** | ~4% |
| 9 | 28 | **Starmie** | ~4% |
| 10 | 25 | **Dragonair** | ~1% |

Route 21 (south of Pallet Town) also has legendary-first water encounters.

---

#### Cerulean Cave (Endgame) — Levels 55-67

The ultimate hunting ground. This is the postgame dungeon and every single encounter has legendaries in the top slots. Highest encounter rate in any cave (25 on B1F).

| Floor | Slots 1-5 (~75%) | Slots 6-7 (~10%) | Slots 8-10 (~9%) |
|-------|----------------|----------------|----------------|
| **1F** (55-60) | Mewtwo, Mew, Articuno, Zapdos, Moltres | Dragonite, Alakazam | Gengar, Machamp, Snorlax |
| **2F** (58-63) | Mewtwo, Mew, Articuno, Zapdos, Moltres | Dragonite, Alakazam | Gengar, Machamp, Snorlax |
| **B1F** (60-67) | **Mewtwo (67)**, **Mew (67)**, Articuno, Zapdos, Moltres | Dragonite, Alakazam | Gengar, Machamp, Snorlax |

The basement floor has the highest-level wild Pokemon in the entire game: **Level 67 Mewtwo** with a **~20% encounter rate**.

---

### Mod 3: Boosted Legendary Catch Rates

**Files modified:** 7 files in `data/pokemon/base_stats/`

Legendary and rare Pokemon catch rates have been dramatically increased so they're actually catchable when you encounter them in the wild. Without this mod, encountering a legendary in tall grass would be pointless — you'd burn through your entire item bag trying to catch it.

The Gen 1 catch rate scale is 0-255 (higher = easier to catch). For reference:
- Pidgey/Rattata: **255** (basically guaranteed with any ball)
- Butterfree: **45** (moderate difficulty)
- Original legendaries: **3** (nearly impossible without Master Ball)

| Pokemon | Original Catch Rate | Modded Catch Rate | Difficulty |
|---------|:-------------------:|:-----------------:|------------|
| **Articuno** | 3 | **100** | Solid chance with Great/Ultra Ball |
| **Zapdos** | 3 | **100** | Solid chance with Great/Ultra Ball |
| **Moltres** | 3 | **100** | Solid chance with Great/Ultra Ball |
| **Mewtwo** | 3 | **100** | Solid chance with Great/Ultra Ball |
| **Mew** | 45 | **100** | Easier than before |
| **Snorlax** | 25 | **100** | Much easier |
| **Chansey** | 30 | **100** | Much easier |

At catch rate **100**, you have roughly a 40-50% chance per Ultra Ball throw at full HP. Weaken the Pokemon first and you'll catch it in 1-3 throws. Still feels like a real catch, but no longer requires 50 Ultra Balls and a prayer.

**Code change (example — Mewtwo):**
```diff
 ; data/pokemon/base_stats/mewtwo.asm
-    db 3 ; catch rate
+    db 100 ; catch rate
```

---

### Mod 4: Version Differences Removed

**Files modified:** All wild encounter files that previously had `IF DEF(_RED)` / `IF DEF(_BLUE)` conditionals

All version-exclusive Pokemon conditionals have been stripped from wild encounter data. Both Pokemon Red and Pokemon Blue now build with **identical wild encounter tables**. This means:

- No more version-exclusive Pokemon blocking Pokedex completion
- Both ROMs have the exact same gameplay experience
- You can complete the full 151 Pokedex in a single version

**Before (example — Cerulean Cave 1F):**
```asm
IF DEF(_RED)
    db 52, ARBOK
ENDC
IF DEF(_BLUE)
    db 52, SANDSLASH
ENDC
```

**After:**
```asm
    db 58, ARTICUNO    ; same in both versions
```

---

### Summary of All Files Modified

| Category | Files Changed | What Changed |
|----------|:------------:|--------------|
| Starters | 1 | `constants/pokemon_constants.asm` — STARTER1/2/3 constants |
| Wild Encounters | 60 | Every file in `data/wild/maps/` — complete encounter table rewrites |
| Catch Rates | 7 | `data/pokemon/base_stats/` — Articuno, Zapdos, Moltres, Mewtwo, Mew, Snorlax, Chansey |
| **Total** | **68 files** | |

---

## Bug Fixes

This build also includes **29 bug fixes** across the battle engine, overworld, items, scripts, and audio systems.

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
