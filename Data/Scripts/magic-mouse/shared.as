const string MOD_ID = "magic-mouse";

// SaveFile
const string SF_PERSONAL_BEST = "[Magic Mouse] Personal Best";

// Level ScriptParams
const string SP_MAX_ENERGY = "[Magic Mouse] Max Energy";
const int SPL_DEF_ENERGY = 100;
const int SPL_MAX_ENERGY = 10000;

// Hotspot ScriptParams
const string SP_CHARACTER_ID = "Character ID (-1 for Level Message)";
const string SP_DEFAULT_SWITCH_STATE_IS_ON = "Default Switch State is On (Not Off)";
const string SP_EXECUTE_AS_CODE_INSTEAD_OF_MESSAGE = "Execute as Code instead of Message";
const string SP_SEND_MESSAGE_ON_LEVEL_RESET = "Send Message on Level Reset";
const string SP_SEND_MESSAGE_ON_SWITCH_OFF_TO_ON = "Send Message on switch Off to On";
const string SP_SEND_MESSAGE_ON_SWITCH_ON_TO_OFF = "Send Message on switch On to Off";

// Level and Hotspot Messages
const string MSG_PB_WAS_RESET = "MagicMouse-PbWasReset";
const string MSG_HOTSPOTINFO_DETAILLEVEL_CHANGED = "MagicMouse-DetailLevelChanged";
const string MSG_TELEPORTED = "MagicMouse-Teleported";
const string MSG_HOVER = "MagicMouse-Hover";
const string MSG_CLICK = "MagicMouse-Click";

// Config Keys
const string CONFIG_HOTSPOTINFO_DETAILLEVEL = "MagicMouse-HotspotInfoDetailLevel";

// Hotspot TypeStrings
const string TYPE_SWITCH_HOTSPOT = "MagicMouse-SwitchHotspot";
const string TYPE_DOOR_TELEPORT_HOTSPOT = "MagicMouse-DoorTeleportHotspot";

string GetTimeString(float totalTime)
{
	int time = int(totalTime * 1000.0f);

	int minutes = time / (60 * 1000);
	time %= (60 * 1000);
	
	int seconds = time / 1000;
	time %= 1000;
	
	int milliseconds = int(time / 100);
	
	return
		(minutes < 10 ? "0" : "") + minutes + ":" +
		(seconds < 10 ? "0" : "") + seconds + "." + 
		milliseconds;
}

void SavePbTime(float time)
{
	float truncatedTime = float(int(time * 10)) / 10;

	SavedLevel@ levelData = save_file.GetSavedLevel(GetCurrLevelRelPath());
	
	levelData.SetValue(SF_PERSONAL_BEST, formatFloat(truncatedTime, "", 0, 1));
	save_file.WriteInPlace();
}

float LoadPbTime()
{
	SavedLevel@ levelData = save_file.GetSavedLevel(GetCurrLevelRelPath());
	string pbTime = levelData.GetValue(SF_PERSONAL_BEST);
	
	return atof(pbTime);
}

float Limit(float value, float minValue, float maxValue)
{
	return min(max(value, minValue), maxValue);
}

void TimeLog(string message)
{
	Log(fatal, ImGui_GetTime() + " - " + message);
}