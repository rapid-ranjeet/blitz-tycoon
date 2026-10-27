# Blitz Tycoon: Unicorn Empire 🦄🎲

A high-stakes, fast-paced mobile board game built with Flutter for Android and iOS. It fuses **classic Monopoly property strategy** with **modern retention hooks**:
- **12-Minute Blitz Loops:** 28-tile compact board on an 8×8 perimeter grid.
- **Real-Time Off-Turn Insider Trading:** Live stochastic stock ticker (Ornstein-Uhlenbeck SDE) with 3% bid-ask anti-arbitrage friction.
- **CEO RPG Hero Avatars:** Active and passive skills with cooldowns (FinTech Shark, Real Estate Mogul, The Lobbyist).
- **Corporate Espionage:** Tri-Vault risk/reward decryption mini-games & hostile strikes.
- **Exponential Sudden Death:** Rent doubles every lap from Lap 10 onwards, driving matches to finish within 10–15 minutes.
- **Tactile Juice & Decoupled 120 FPS Rendering:** Non-linear trauma screen shake, quadratic Bézier flying cash particle fountains, and decoupled parabolic token hopping.
- **Authoritative Multiplayer & Anti-Cheat:** 4-player lobbies, 15-second blitz turn deadlines, and cryptographic deterministic roll PRNG (FNV-1a).
- **Offline Persistence & Recovery:** Local state snapshots saved on every turn with monotonic vector clock cloud reconciliation.
- **Meta-Progression Campus:** Tech District city builder with Garage Labs, Unicorn HQs, and AI Superclusters.

---

## 🏛️ Complete Production Architecture

```text
lib/
├── core/
│   ├── constants/
│   │   └── game_constants.dart      # Blitz tile rules, economy salaries, city palettes, league tiers
│   ├── services/
│   │   ├── feedback_service.dart    # Multi-cadence tactile haptic waveforms
│   │   └── audio_service.dart       # Low-latency audio FX pool & dynamic BGM ducking controller
│   └── theme/
│       └── app_theme.dart           # Luxury Dark & Gold aesthetic (#0A0E1A, #FFB800, #00E5FF)
├── models/
│   ├── ceo_model.dart               # CEO hero definitions, roles, cooldowns, skills
│   ├── tile_model.dart              # Tile types, 4-tier rent stages, upgrade levels, audit freeze
│   ├── player_model.dart            # Liquid cash, net worth, portfolio, bankruptcy status
│   ├── stock_model.dart             # Ornstein-Uhlenbeck jump-diffusion pricing & bid/ask spreads
│   └── game_state_model.dart        # Unified state tracking, turns, multiplier, difficulty
├── logic/
│   └── ai_engine.dart               # Multi-Attribute Utility AI (MAUT) decision engine
├── services/
│   ├── multiplayer_service.dart     # Real-time room state machine, 15s turn clocks, FNV-1a anti-cheat
│   └── persistence_service.dart     # Turn auto-saves, career match history, monotonic vector clock
├── ui/
│   ├── screens/
│   │   ├── home_empire_screen.dart  # Meta-progression campus builder, division tiers, CEO picker
│   │   ├── matchmaking_screen.dart  # Private rooms, room codes, live player slots, instant AI matches
│   │   └── game_board_screen.dart   # Interactive 8×8 board, token movement, HUD, event stream
│   └── widgets/
│       ├── board_canvas.dart        # InteractiveViewer board canvas & RepaintBoundary static caching
│       ├── board_tile_widget.dart   # Individual property card & status badges
│       ├── center_stock_ticker.dart # Live stock market widget with instant Buy/Sell actions
│       ├── heist_modal.dart         # Tri-Vault corporate espionage decryption mini-game
│       ├── trade_bottom_sheet.dart  # Slider-based property buyout & negotiation sheet
│       ├── auction_dialog.dart      # Fast 10-second public bidding auction timer with MAUT AI
│       ├── juice_overlay.dart       # Trauma screen shaker, Bézier cash particles & confetti
│       └── token_hopper_layer.dart  # 120 FPS decoupled parabolic token hopping engine
└── main.dart                        # Application bootstrap & portrait lock
```

---

## 🚀 How to Run

```bash
# 1. Fetch dependencies
flutter pub get

# 2. Run on Chrome (Web Preview)
flutter run -d chrome

# 3. Or deploy to Android / iOS
flutter run -d <device_id>
```
