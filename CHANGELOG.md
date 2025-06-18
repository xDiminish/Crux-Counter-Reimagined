Crux Counter (reIMAGINED) – Change Log

All notable changes to this project will be documented in this file.


[v1.0.4.03 - 2025-06-17]

🛠 Functionality Changes

	- No longer listens for EFFECT_RESULT_FADED events for ALL effects, and not specifically targets only the Crux effect. 
	- Cleaned up some redundant code.

🐞 Bug Fixes
	
	- Fixed issue where if the effect was within the warn state, and the player was in a menu when the Crux buff wore off it would not trigger a UI reset cause the expiry warn state colors to persist when the effect ended.

[v1.0.4.02 - 2025-06-16]

✨ New Features

	- Flash Animation System
		- Introduced flash animations for runes, background, and aura numbers using smooth interpolation and sine wave-based timing.
		- Supports two alternating colors per element (start color and end color).
		- Configurable flash speed (cycle duration) using sine-based interpolation.
		- Flashing can be globally enabled/disabled via settings.
		- Flash activation threshold is user-configurable and respects warning timing.
	
	- Settings Panel Additions
		- Flash enable/disable toggle option
		- Flash threshold slider (e.g., flash starts N seconds before buff expiration).
		- Flash speed slider (steps of 0.5 seconds, min value of 0.5 seconds, max value of 5 seconds).
		- Per-element color pickers for Flash Start Color and Flash End Color (runes, background, aura number).
		- Reset buttons for flash colors.
		- All settings are dynamically disabled if irrelevant (e.g. element is hidden).
	
	- Slash Command Improvements
		- Added /ccr debug [1–3] to adjust debug verbosity.
		- Added /ccr help to display available debug commands.
		- Added safe fallback help text for invalid or missing arguments.

🛠 Functionality Changes

	- Visibility Handling Refactor
		- Replaced use of SetAlpha(0/1) with SetHidden(true/false) for rune visibility.
		- Improved UI behavior and eliminated visual overlap and ghosting.
	
	- Improved Warn/Flash Timing Accuracy
		- Refined elapsed time comparisons with added epsilon buffer to avoid floating point precision issues.
		- Flash and warn states are now evaluated more precisely.
	
	- Centralized Warn State Logic
		- Unified timing, warn state, and color transitions into Utils.CheckWarnState().
		- Color transitions fall back safely if user data is missing or malformed.
		- Base, warn, and flash color states are prioritized based on current time.

🌍 Localization and Text Improvements

	- All new settings use CC.Language:GetString() for localization readiness.
	- Added string IDs for:
		- Flash toggle title and tooltip
		- Flash speed label
		- Flash threshold description
		- Element-specific flash color descriptions

🐞 Bug Fixes
	
	- Fixed color handling crash when invalid color tables were passed.
	- Corrected slider defaults and steps for flash speed to respect whole or 0.5 increments.
	- Ensured settings sliders and color pickers reset to correct fallback values.
	- Improved debug trace output to better reflect current flash/warn state and timing.

[Older versions]

Older versions are documented in the original addon repository found at https://github.com/inimicus/CruxCounter.