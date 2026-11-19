# ZMB v0.1 — Offline prototype

## v0.1.12 — Pinch camera zoom

Removed both HUD zoom buttons. Two touches starting on the world pinch to adjust camera distance (4–16 m); single-finger drag orbits again after release. Joystick and action-button fingers are excluded from the gesture. A camera distance slider remains in Settings; desktop wheel zoom is unchanged. Native input regression passed and the exported-Web test now checks pinch gestures too.

## v0.1.11 — Character statistics and playtime

Character information shows 17 localized live fields, with session time measured from character entry using monotonic time. Local accumulated playtime and first-entry timestamp are saved separately every 10 seconds and on focus loss/exit. Account registration remains unavailable until real authentication exists. All browser-local values are untrusted and must never be used as anti-cheat evidence. Production must store immutable account creation UTC, server-issued session IDs, server-timestamped login/logout/heartbeat records, deduplicated active seconds and server-authoritative EXP/item/level transactions. Compare progression against actual recorded playtime to flag anomalies for review, not automatic bans based on hours alone.

## v0.1.10 — Refit inventory popup

Draw the visible popup artwork region without the transparent image padding. Enlarge the inventory panel, move its navigation and content down, and leave a 40-pixel horizontal inset and 68-pixel top inset. The updated regression verifies both header and inventory content remain inside the frame in all three languages.

## v0.1.9 — Popup frame containment

All popup controls are inset past the visible artwork border, with extra top/bottom clearance for transparent PNG padding, clipped content and compact equal inventory columns. Language and close controls stay inside the frame; the inventory regression checks the header and scrolling area bounds across all three languages.

## v0.1.8 — Inventory layout and language picker

Bag, Character, Storage and Skills share a wider modal with top navigation and a three-language dropdown. Bag splits equipment and the current 3D player preview from the 48-slot inventory; accessories are smaller and the loot-pet slot is included. Storage and equipment remain preview-only pending their gameplay backend. Bundled Thai and simplified Chinese UI fonts prevent missing glyphs. The existing player model, world and control routing are unchanged.

## v0.1.7 — UHD UI asset integration

Original transparent PNGs recovered from the approved UI designs are stored in `assets/uhd/` (13 files). The shared popup, item grids, market/trade menu icons and live HP/MP/EXP meters use these assets. Portrait, nameplate and level badge artwork is available for the next HUD layout pass. Existing controls, touch capture, camera, safe zone and demo gameplay are unchanged. Missing artwork retains the prior UI until its individual PNG is available.

Godot 4.6.3 / GDScript / Compatibility renderer / single-threaded Web.

Playable locally: character selection, primitive village, movement, jump, dash, run, camera rotation/zoom, monsters, target cycling/tapping, three weapon ranges, basic and three skills, HP/MP, EXP/level, loot, auto hunt, potion buttons, death/revive, bag item display, configurable HUD. Keyboard WASD, Space, Shift, F, 1–3, E, Tab; right mouse drag and wheel. Touch HUD uses mouse-emulation events.

Preview only: partial three-language labels, storage/equipment, character/skill previews, trade/shop/market/quest/social/ranking/news/map panels. Placeholder meshes and programmatic styles are not final game art. No real GM functionality or credentials are included. No network players, real accounts, persistent economy, atomic trade, or dedicated server are implemented. Server-side authorization and transactions are required before adding online features.

Deploy: configure Settings > Pages > Source > GitHub Actions. Push to main triggers export/deploy. Verify Actions logs and the actual browser game before release.
