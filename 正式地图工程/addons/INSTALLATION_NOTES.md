# Installed Godot add-ons

Installed on 2026-11-18. All three projects use MIT licenses; upstream license files are retained.

- Nodes Plus: https://github.com/Rekiex/godot-nodes-plus (commit e88df95262151ab745d41bd8a5d8b486c7802d7d)
- GlobalTweens: https://github.com/Rp-ics/Godot-Engine-GlobalTweens (commit 22d9679185a700513c44136bfc79578d4fc20a45)
- Phantom Camera: https://github.com/ramokz/phantom-camera (commit 1a722d6f2df41f9752ad567f5c6de919fa7cf7c9)

Local compatibility change: Nodes Plus State and StateMachine global class names are prefixed with NodesPlus to avoid collisions with existing local State enums. Source identifiers and script templates were updated; upstream file paths and licenses are unchanged.

Runtime integration: Target2D supplies target detection; GlobalTweens supplies visual bounce feedback. Phantom Camera and its manager are installed and enabled, but no new camera host replaces the existing opening/gameplay camera driver. This avoids two controllers writing to the same display camera.

GlobalTweens quantum_jump and squash_stretch are not used directly on character bodies. Gameplay owns exchange timing, collision-safe movement, input locks and cancellation.
