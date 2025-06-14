-- -----------------------------------------------------------------------------
-- lang/nl.lua
-- -----------------------------------------------------------------------------

local M = {}
local CC = CruxCounterR

--- Setup translation strings
--- @return nil
function M.Setup()
	ZO_CreateStringId("CRUX_COUNTER_SETTINGS_LOCK", "Vergrendel")
	ZO_CreateStringId("CRUX_COUNTER_SETTINGS_UNLOCK", "Ontgrendel")
	ZO_CreateStringId("CRUX_COUNTER_SETTINGS_LOCK_DESC", "Schakel de vergrendeling van de tellerweergave in of uit om deze te verplaatsen.")

	ZO_CreateStringId("CRUX_COUNTER_SETTINGS_DISPLAY_HEADER", "Weergave")
	ZO_CreateStringId("CRUX_COUNTER_SETTINGS_LOCK_TO_RETICLE_WARNING", "Schakel 'Vergrendel op richtpunt' uit om deze instelling te wijzigen.")

	ZO_CreateStringId("CRUX_COUNTER_SETTINGS_MOVE_TO_CENTER", "Naar het midden verplaatsen")
	ZO_CreateStringId("CRUX_COUNTER_SETTINGS_MOVE_TO_CENTER_DESC", "Plaats de weergave in het midden van het scherm. Handig als het kwijt is.")

	ZO_CreateStringId("CRUX_COUNTER_SETTINGS_LOCK_TO_RETICLE", "Vergrendel op richtpunt")
	ZO_CreateStringId("CRUX_COUNTER_SETTINGS_LOCK_TO_RETICLE_DESC", "Plaatsing in het midden van het scherm boven het richtkruis.")

	ZO_CreateStringId("CRUX_COUNTER_SETTINGS_HIDE_OUT_OF_COMBAT", "Verberg buiten gevecht")
	ZO_CreateStringId("CRUX_COUNTER_SETTINGS_HIDE_OUT_OF_COMBAT_DESC", "Verberg alles buiten gevecht.")

	ZO_CreateStringId("CRUX_COUNTER_SETTINGS_SIZE", "Grootte")
	ZO_CreateStringId("CRUX_COUNTER_SETTINGS_SIZE_DESC", "Weergavegrootte van de teller.")

	ZO_CreateStringId("CRUX_COUNTER_SETTINGS_STYLE_HEADER", "Stijl")
	ZO_CreateStringId("CRUX_COUNTER_SETTINGS_STYLE_ROTATE", "Draaien")

	ZO_CreateStringId("CRUX_COUNTER_SETTINGS_STYLE_NUMBER", "Nummer")
	ZO_CreateStringId("CRUX_COUNTER_SETTINGS_STYLE_NUMBER_DESC", "Toon of verberg het aantal actieve Crux.")

	ZO_CreateStringId("CRUX_COUNTER_SETTINGS_STYLE_NUMBER_COLOR", "Kleur")
	ZO_CreateStringId("CRUX_COUNTER_SETTINGS_STYLE_NUMBER_COLOR_DESC", "Kleur van het weergegeven aantal actieve Crux.")
	ZO_CreateStringId("CRUX_COUNTER_SETTINGS_STYLE_NUMBER_COLOR_RESET", "Reset kleur")
	ZO_CreateStringId("CRUX_COUNTER_SETTINGS_STYLE_NUMBER_COLOR_RESET_DESC", "Reset de nummerkleur naar de standaardinstelling.")

	ZO_CreateStringId("CRUX_COUNTER_SETTINGS_STYLE_CRUX_RUNES", "Crux Runes")
	ZO_CreateStringId("CRUX_COUNTER_SETTINGS_STYLE_CRUX_RUNES_DESC", "Schakel het tonen van Crux rune texturen in of uit.")
	ZO_CreateStringId("CRUX_COUNTER_SETTINGS_STYLE_CRUX_RUNES_ROTATE_DESC", "Schakel het draaien van Crux rune texturen in of uit.")
	ZO_CreateStringId("CRUX_COUNTER_SETTINGS_STYLE_CRUX_RUNES_ROTATION_SPEED", "Snelheid")
	ZO_CreateStringId("CRUX_COUNTER_SETTINGS_STYLE_CRUX_RUNES_ROTATION_SPEED_DESC", "Draaisnelheid van de Crux rune texturen. Hoe hoger, hoe sneller.")

	ZO_CreateStringId("CRUX_COUNTER_SETTINGS_STYLE_CRUX_COLOR", "Kleur")
	ZO_CreateStringId("CRUX_COUNTER_SETTINGS_STYLE_CRUX_COLOR_DESC", "Kleur van de Crux rune texturen.")
	ZO_CreateStringId("CRUX_COUNTER_SETTINGS_STYLE_CRUX_COLOR_RESET", "Reset kleur")
	ZO_CreateStringId("CRUX_COUNTER_SETTINGS_STYLE_CRUX_COLOR_RESET_DESC", "Reset de kleur van rune texturen naar de standaardinstelling.")

	ZO_CreateStringId("CRUX_COUNTER_SETTINGS_STYLE_BACKGROUND", "Achtergrond")
	ZO_CreateStringId("CRUX_COUNTER_SETTINGS_STYLE_BACKGROUND_DESC", "Schakel het tonen van de teller achtergrondtextuur in of uit.")
	ZO_CreateStringId("CRUX_COUNTER_SETTINGS_STYLE_BACKGROUND_ROTATE", "Schakel het draaien van de teller achtergrondtextuur in of uit.")
	ZO_CreateStringId("CRUX_COUNTER_SETTINGS_STYLE_BACKGROUND_HIDE_ZERO_CRUX", "Verberg zonder Crux")
	ZO_CreateStringId("CRUX_COUNTER_SETTINGS_STYLE_BACKGROUND_HIDE_ZERO_CRUX_DESC", "Verberg de achtergrond wanneer er geen actieve Crux zijn.")

	ZO_CreateStringId("CRUX_COUNTER_SETTINGS_STYLE_BACKGROUND_COLOR", "Kleur")
	ZO_CreateStringId("CRUX_COUNTER_SETTINGS_STYLE_BACKGROUND_COLOR_DESC", "Kleur van de teller achtergrondtextuur.")
	ZO_CreateStringId("CRUX_COUNTER_SETTINGS_STYLE_BACKGROUND_COLOR_RESET", "Reset kleur")
	ZO_CreateStringId("CRUX_COUNTER_SETTINGS_STYLE_BACKGROUND_COLOR_RESET_DESC", "Reset de kleur van de teller achtergrond naar de standaardinstelling.")

	ZO_CreateStringId("CRUX_COUNTER_SETTINGS_SOUNDS_HEADER", "Geluiden")
	ZO_CreateStringId("CRUX_COUNTER_SETTINGS_SOUNDS_PLAY", "Afspelen")

	ZO_CreateStringId("CRUX_COUNTER_SETTINGS_SOUNDS_CRUX_GAINED", "Crux Verkregen")
	ZO_CreateStringId("CRUX_COUNTER_SETTINGS_SOUNDS_CRUX_GAINED_DESC", "Speel geluid af wanneer een Crux wordt verkregen.")

	ZO_CreateStringId("CRUX_COUNTER_SETTINGS_SOUNDS_MAXIMUM_CRUX", "Maximaal Crux")
	ZO_CreateStringId("CRUX_COUNTER_SETTINGS_SOUNDS_MAXIMUM_CRUX_DESC", "Speel geluid af wanneer het maximale aantal Crux is bereikt.")

	ZO_CreateStringId("CRUX_COUNTER_SETTINGS_SOUNDS_CRUX_LOST", "Crux Verloren")
	ZO_CreateStringId("CRUX_COUNTER_SETTINGS_SOUNDS_CRUX_LOST_DESC", "Speel geluid af wanneer een Crux verloren gaat.")

	ZO_CreateStringId("CRUX_COUNTER_SETTINGS_STYLE_REIMAGINED_HEADER", "Herontworpen")

	ZO_CreateStringId("CRUX_COUNTER_SETTINGS_STYLE_CRUX_DURATION", "Crux Duur")
	ZO_CreateStringId("CRUX_COUNTER_SETTINGS_STYLE_CRUX_DURATION_DESC", "Totale duur van de Crux buff (in seconden).")

	ZO_CreateStringId("CRUX_COUNTER_SETTINGS_STYLE_CRUX_WARN_THRESHOLD", "Waarschuwingsdrempel Verlopen")
	ZO_CreateStringId("CRUX_COUNTER_SETTINGS_STYLE_CRUX_WARN_THRESHOLD_DESC", "Verander de kleur van de rune bij deze drempel naar de gedefinieerde waarschuwingkleur.")

	ZO_CreateStringId("CRUX_COUNTER_SETTINGS_STYLE_NUMBER_WARN_COLOR", "Waarschuwingskleur Tekst")
	ZO_CreateStringId("CRUX_COUNTER_SETTINGS_STYLE_NUMBER_WARN_COLOR_DESC", "Kleur van het actieve Crux nummer wanneer ze bijna verlopen zijn.")

	ZO_CreateStringId("CRUX_COUNTER_SETTINGS_STYLE_NUMBER_WARN_COLOR_RESET", "Reset kleur")
	ZO_CreateStringId("CRUX_COUNTER_SETTINGS_STYLE_NUMBER_WARN_COLOR_RESET_DESC", "Reset de waarschuwingstekstkleur naar standaard.")

	ZO_CreateStringId("CRUX_COUNTER_SETTINGS_STYLE_CRUX_WARN_COLOR", "Waarschuwingskleur Rune")
	ZO_CreateStringId("CRUX_COUNTER_SETTINGS_STYLE_CRUX_WARN_COLOR_DESC", "Kleur van actieve runen wanneer ze bijna verlopen zijn.")

	ZO_CreateStringId("CRUX_COUNTER_SETTINGS_STYLE_CRUX_WARN_COLOR_RESET", "Reset kleur")
	ZO_CreateStringId("CRUX_COUNTER_SETTINGS_STYLE_CRUX_WARN_COLOR_RESET_DESC", "Reset de waarschuwingskleur van runen naar standaard.")

	ZO_CreateStringId("CRUX_COUNTER_SETTINGS_STYLE_CRUX_WARN_POLLING_INTERVAL", "Waarschuwingscontrole Interval")
	ZO_CreateStringId("CRUX_COUNTER_SETTINGS_STYLE_CRUX_WARN_POLLING_INTERVAL_DESC", "Hoe vaak controleren op resterende bufftijd van Crux (in milliseconden).")

	ZO_CreateStringId("CRUX_COUNTER_SETTINGS_STYLE_BACKGROUND_WARN_COLOR", "Waarschuwingskleur Achtergrond")
	ZO_CreateStringId("CRUX_COUNTER_SETTINGS_STYLE_BACKGROUND_WARN_COLOR_DESC", "Kleur van de achtergrondtextuur wanneer runen bijna verlopen zijn.")

	ZO_CreateStringId("CRUX_COUNTER_SETTINGS_STYLE_BACKGROUND_WARN_COLOR_RESET", "Reset kleur")
	ZO_CreateStringId("CRUX_COUNTER_SETTINGS_STYLE_BACKGROUND_WARN_COLOR_RESET_DESC", "Reset de waarschuwingskleur van de achtergrond naar standaard.")
end

CC.Translation = M