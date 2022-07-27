#include "magic-mouse/shared.as"

// False = Full Details, True = Less Details (because non-existant keys return false)
bool hotspotInfoDetailLevel = false;

void Init(string level_name)
{
	if (!ConfigHasKey(CONFIG_HOTSPOTINFO_DETAILLEVEL))
	{
		SetConfigValueBool(CONFIG_HOTSPOTINFO_DETAILLEVEL, false);
		SaveConfig();
	}
	else
	{
		hotspotInfoDetailLevel = GetConfigValueBool(CONFIG_HOTSPOTINFO_DETAILLEVEL);
	}
}

void Menu()
{
	if (ImGui_BeginMenu("Magic Mouse Mod"))
	{
	
		if (level.GetScriptParams().HasParam(SP_MAX_ENERGY))
		{
			ImGui_AlignTextToFramePadding();
			ImGui_SetWindowFontScale(1.5f);
			ImGui_TextColored(HexColor("#FF3EC3"), "           Magic Mouse Settings Menu");
			ImGui_SetWindowFontScale(1.0f);
			ImGui_Text("_____________________________________________________________________");
			ImGui_NewLine();
			ImGui_Indent();
				ImGui_Text("Personal best time for the current level:");
				ImGui_Indent();
					ImGui_AlignTextToFramePadding();
					ImGui_Text("Time: " + GetTimeString(LoadPbTime()));
					ImGui_SameLine();
					if (ImGui_Button("Reset Record")) ResetPb();
				ImGui_Unindent();
				
				ImGui_NewLine();
				ImGui_Text("Detail level of hotspot info in the editor:");
					ImGui_Indent();
					if (ImGui_RadioButton(" Full Details (parameter and connection)", !hotspotInfoDetailLevel))
						ChangeHotspotInfoDetailLevel(false);
					if (ImGui_RadioButton(" No Details (no editor tooltips)", hotspotInfoDetailLevel))
						ChangeHotspotInfoDetailLevel(true);
				ImGui_Unindent();
				
			ImGui_Unindent();
			
			ImGui_NewLine();
			ImGui_Text("_____________________________________________________________________");
			ImGui_NewLine();
			ImGui_Text("               ");
			ImGui_SameLine();
			ImGui_TextColored(HexColor("#FF3EC3"), "Magic Mouse");
			ImGui_SameLine();
			ImGui_Text("mod by");
			ImGui_SameLine();
			ImGui_TextColored(HexColor("#F1C40F"), "alpines (_Ins4ne_)");	
			
			ImGui_Text("\n" +
				"Please consider leaving a like/favorite/comment on the workshop page!\n"
				"              I read all comments! Thank you very much!"
			);
			ImGui_NewLine();
			
			ImGui_Text("                        ");
			ImGui_SameLine();
			if (ImGui_Button("Open Workshop Page")) OpenWorkshopPage();
			ImGui_NewLine();
		}
		else
		{
			ImGui_Text(
				"This is not a Magic Mouse level.\n" + 
				"The levelscript is not set."
			);
		}
		
		ImGui_EndMenu();
	}	
}

void OpenWorkshopPage()
{
	array<ModID>@ mods = GetActiveModSids();
	int index = 0;

	for (int i = 0; i < int(mods.length()); ++i)
	{	
		if (ModGetID(mods[i]) == MOD_ID)
		{
			index = i;
			break;
		}
	}

	OpenModWorkshopPage(mods[index]);
}

void ResetPb()
{
	SavePbTime(0.0f);

	level.SendMessage(MSG_PB_WAS_RESET);
}

void ChangeHotspotInfoDetailLevel(bool detailLevel)
{
	hotspotInfoDetailLevel = detailLevel;
	
	SetConfigValueBool(CONFIG_HOTSPOTINFO_DETAILLEVEL, detailLevel);
	SaveConfig();
	
	level.SendMessage(MSG_HOTSPOTINFO_DETAILLEVEL_CHANGED);
}