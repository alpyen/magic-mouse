void Init(string level_name) { }

void Menu()
{
	if (ImGui_BeginMenu("Magic Mouse"))
	{
	
		if (level.GetScriptParams().HasParam("[Magic Mouse] Max Energy"))
		{
			ImGui_AlignTextToFramePadding();
			ImGui_TextColored(HexColor("#FF3EC3"), "                      Magic Mouse Settings Menu");
			ImGui_Text("_____________________________________________________________________");
			ImGui_NewLine();
			ImGui_Indent();
				ImGui_Text("Personal best time for the current level:");
				ImGui_Indent();
					ImGui_AlignTextToFramePadding();
					ImGui_Text("Time: 00:05.6");
					ImGui_SameLine();
					ImGui_Button("Reset Record");
				ImGui_Unindent();
				
				ImGui_NewLine();
				ImGui_Text("Detail level of hotspot info in the editor:");
					ImGui_Indent();
					ImGui_RadioButton(" Full Details (parameter and connection)", true);
					ImGui_RadioButton(" Less Details (abbreviated)", false);
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
			ImGui_Button("Open Workshop Page");
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