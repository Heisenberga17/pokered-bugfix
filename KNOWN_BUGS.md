# Known Bugs - Pokemon Red/Blue Disassembly

> Bugs that are **documented but intentionally left unfixed** due to complexity, risk of introducing new issues, or being deeply embedded in the game's architecture.

---

## Counter Desync in Link Battles

<img src="https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/versions/generation-i/red-blue/68.png" width="56" align="left">

**File:** `engine/battle/core.asm` (~line 4552)
**Severity:** Medium | **System:** Battle Engine | **Status:** OPEN

Counter's `wPlayerMoveListIndex` and related variables are updated whenever the cursor moves in the battle menu, not just when a move is selected. When a player switches Pokemon while the opponent uses Counter, the menu cursor position at the time of selection affects Counter's behavior. In link battles, the two Game Boys may have different cursor states, causing desync.

**Why not fixed:** Counter's implementation is tightly coupled to the battle menu cursor update logic. Fixing it requires restructuring how `wPlayerMoveListIndex` is updated — currently it updates on every cursor movement for responsiveness, but Counter reads this value expecting it to reflect the chosen move. Decoupling these two systems without breaking the battle menu's feel or introducing new edge cases is high-risk.

```asm
; The problematic area in HandleCounterMove:
; Counter reads wPlayerMoveListIndex which may not reflect the actual chosen move
; if the player navigated the menu before switching
```

---

## CollisionCheckOnWater Accidental Correctness

<img src="https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/versions/generation-i/red-blue/131.png" width="56" align="left">

**File:** `home/overworld.asm` (~line 1888)
**Severity:** Informational | **System:** Overworld | **Status:** PARTIALLY FIXED

The water collision check function had a bug where sprite collisions jumped to tile-passability checking code instead of directly to collision handling. This worked by accident because register `c` retained `$F0` from a prior function call, and `$F0` is never a passable tile.

**What was fixed:** The jump target was corrected from `.checkIfNextTileIsPassable` to `.collision`, making the logic explicit rather than relying on stale register values.

**What remains:** The function's overall structure still has some redundancy from the original implementation, but it now behaves correctly without depending on register side effects.
