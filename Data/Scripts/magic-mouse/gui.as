#include "magic-mouse/shared.as"

namespace GUI
{
	const vec2 ENERGY_CONTAINER_SIZE(750.0f, 120.0f);
	const vec2 TIMER_CONTAINER_SIZE(300.0f, 75.0f);
	const vec2 PBTIMER_CONTAINER_SIZE(150.0f, 30.0f);
	const vec2 ENDOFLEVEL_CONTAINER_SIZE(1200.0f, 450.0f);
	
	FontSetup fontText("Underdog-Regular", 50, vec4(1.0f), false);
	FontSetup fontTimer("Lato-Regular", int(TIMER_CONTAINER_SIZE.y - 25), vec4(1.0f), true);
	FontSetup fontPbTimer("Lato-Regular", int(TIMER_CONTAINER_SIZE.y - 50), vec4(1.0), false);
	FontSetup fontCongratulations("Underdog-Regular", 100, vec4(1.0f, 0.2f, 4.0f, 1.0f), true);
	FontSetup fontRestartOrAdvance("Underdog-Regular", 55, vec4(1.0f, 0.9f, 0.0f, 1.0f), false);
	FontSetup fontEndOfLevel("Underdog-Regular", 65, vec4(1.0f), true);
	
	IMGUI@ gui = CreateIMGUI();

	IMContainer@ energyContainer;
	IMImage@ energyBackground;
	IMText@ energyLabel;
	IMText@ energyText;
	IMImage@ energyRemainingBar;
	IMImage@ energyMaxBar;

	IMContainer@ timerContainer;
	IMImage@ timerBackground;
	IMImage@ timerImage;
	IMText@ timerText;

	IMContainer@ pbTimerContainer;
	IMImage@ pbTimerBackground;
	IMText@ pbTimerText;

	IMContainer@ endOfLevelContainer;
	IMImage@ endOfLevelBackground;
	IMText@ congratulationsText;
	IMText@ advanceToNextLevelText;
	IMText@ hotkeysText;

	void Init()
	{
		gui.clear();
		gui.setup();
		
		ResizeToFullscreen();
		Build();
	}

	void SetPbTime(float pbTime)
	{
		pbTimerText.setText("PB: " + GetTimeString(pbTime));
		gui.update();
	}

	void SetTimer(float timestampLevelStart)
	{
		float passedTime = min(ImGui_GetTime() - timestampLevelStart, 99 * 60 + 59 + 0.999f);
		
		timerText.setText(GetTimeString(passedTime));
		gui.update();
	}

	void SetEnergy(float remainingEnergy, float totalEnergy)
	{
		energyText.setText(int(remainingEnergy) + " / " + int(totalEnergy));
		gui.update();
		energyContainer.moveElement("energyText", vec2(energyContainer.getSizeX() - energyText.getSizeX() - 15.0f, 15.0f));
		
		// Just so we don't get a divide by zero error.
		if (totalEnergy == 0) totalEnergy = 1;
		
		energyRemainingBar.setSizeX((int(remainingEnergy) / totalEnergy) * (ENERGY_CONTAINER_SIZE.x + 2.0f * -15.0f));
		
		vec4 energyBarColor(0.0f, 0.0f, 0.0f, 0.6f);
		
		remainingEnergy /= totalEnergy;
		totalEnergy /= totalEnergy;
		
		if (remainingEnergy >= 0.5f)
		{
			energyBarColor.x = 1.0f - ((remainingEnergy - 0.5f) / (totalEnergy - 0.5f));
			energyBarColor.y = 1.0f;
		}
		else
		{
			energyBarColor.x = 1.0f;
			energyBarColor.y = 1.0f - ((totalEnergy - remainingEnergy - 0.5f) / (totalEnergy - 0.5f));
		}
		
		energyRemainingBar.setColor(energyBarColor);
	}

	void SetEndOfLevelWindowVisibility(bool show)
	{
		endOfLevelBackground.setVisible(show);
		congratulationsText.setVisible(show);
		advanceToNextLevelText.setVisible(show);
		hotkeysText.setVisible(show);
	}

	void Build()
	{
		// ===== Energy Bar ===== //
		@energyContainer = IMContainer();
		energyContainer.setSize(ENERGY_CONTAINER_SIZE);
		gui.getMain().addFloatingElement(energyContainer, "energyContainer", vec2((gui.getMain().getSizeX() - ENERGY_CONTAINER_SIZE.x) / 2.0f, gui.getMain().getSizeY() * 0.9f), 1);
		
		@energyBackground = IMImage("Textures/UI/whiteblock.tga");
		energyBackground.setColor(vec4(vec3(0.0f), 0.2f));
		energyBackground.setSize(energyContainer.getSize());
		energyContainer.addFloatingElement(energyBackground, "energyBackground", vec2(0.0f), 2);
		
		@energyLabel = IMText("Energy:", fontText);
		energyContainer.addFloatingElement(energyLabel, "energyLabel", vec2(15.0f), 2);
		
		@energyText = IMText("100 / 100", fontText);
		energyContainer.addFloatingElement(energyText, "energyText", vec2(0.0f), 2);
		
		@energyMaxBar = IMImage("Textures/UI/whiteblock.tga");
		energyMaxBar.setColor(vec4(0.0f, 0.621f, 0.0f, 0.4f));
		energyMaxBar.setSize(ENERGY_CONTAINER_SIZE + vec2(2.0f * -15.0f, 3.0f * -15.0f - fontText.size));
		energyContainer.addFloatingElement(energyMaxBar, "energyMaxBar", vec2(15.0f, 15.0f + fontText.size + 15.0f), 2);
		
		@energyRemainingBar = IMImage("Textures/UI/whiteblock.tga");
		energyRemainingBar.setColor(vec4(0.0f, 1.0f, 0.0f, 0.6f));
		energyRemainingBar.setSize(ENERGY_CONTAINER_SIZE + vec2(2.0f * -15.0f, 3.0f * -15.0f - fontText.size));
		energyContainer.addFloatingElement(energyRemainingBar, "energyRemainingBar", vec2(15.0f, 15.0f + fontText.size + 15.0f), 3);
		gui.update();
		
		energyContainer.moveElement("energyText", vec2(ENERGY_CONTAINER_SIZE.x - energyText.getSizeX() - 15.0f, 15.0f));
		
		// ===== Timer ===== //
		
		@timerContainer = IMContainer();
		timerContainer.setSize(TIMER_CONTAINER_SIZE);
		gui.getMain().addFloatingElement(timerContainer, "timerContainer", vec2((gui.getMain().getSize().x - TIMER_CONTAINER_SIZE.x) / 2.0f, gui.getMain().getSizeY() * 0.015f), 1);
		
		@timerBackground = IMImage("Textures/UI/whiteblock.tga");
		timerBackground.setColor(vec4(vec3(0.0f), 0.2f));
		timerBackground.setSize(timerContainer.getSize());
		timerContainer.addFloatingElement(timerBackground, "timerBackground", vec2(0.0f), 2);
		
		@timerImage = IMImage("Textures/magic-mouse/timer.png");
		timerImage.setSize(vec2(timerImage.getSizeX() / timerImage.getSizeY(), 1.0f) * (timerContainer.getSizeY() - 2.0f * 15.0f));
		timerContainer.addFloatingElement(timerImage, "timerImage", vec2(0.0f), 2);
		
		@timerText = IMText("00:00.0", fontTimer);
		timerContainer.addFloatingElement(timerText, "timerText", vec2(0.0f), 2);
		gui.update();
		
		timerContainer.moveElement("timerImage", vec2((TIMER_CONTAINER_SIZE.x - timerImage.getSizeX() - 30.0f - timerText.getSizeX()) / 2.0f, (TIMER_CONTAINER_SIZE.y - timerImage.getSizeY()) / 2.0f));
		timerContainer.moveElement("timerText", vec2((TIMER_CONTAINER_SIZE.x - timerImage.getSizeX() - 30.0f - timerText.getSizeX()) / 2.0f + timerImage.getSizeX() + 30.0f, (TIMER_CONTAINER_SIZE.y - timerText.getSizeY()) / 2.0f + 3.0f));
		
		// ===== PB Timer ===== //
		
		@pbTimerContainer = IMContainer();
		pbTimerContainer.setSize(PBTIMER_CONTAINER_SIZE);
		gui.getMain().addFloatingElement(pbTimerContainer, "pbTimerContainer", vec2((gui.getMain().getSize().x - PBTIMER_CONTAINER_SIZE.x) / 2.0f, gui.getMain().getSizeY() * 0.015f + timerContainer.getSizeY() + 1.0f), 1);
		
		@pbTimerBackground = IMImage("Textures/UI/whiteblock.tga");
		pbTimerBackground.setColor(vec4(vec3(0.0f), 0.2f));
		pbTimerBackground.setSize(pbTimerContainer.getSize());
		pbTimerContainer.addFloatingElement(pbTimerBackground, "pbTimerBackground", vec2(0.0f), 2);
		
		@pbTimerText = IMText("PB: 00:00.0", fontPbTimer);
		pbTimerContainer.addFloatingElement(pbTimerText, "pbTimerText", vec2(0.0f), 2);
		gui.update();
		
		pbTimerContainer.moveElement("pbTimerText", vec2((PBTIMER_CONTAINER_SIZE.x - pbTimerText.getSizeX()) / 2.0f, (PBTIMER_CONTAINER_SIZE.y - pbTimerText.getSizeY()) / 2.0f + 3.0f));
		
		// ===== Congratulations ===== //
		
		@endOfLevelContainer = IMContainer();
		endOfLevelContainer.setSize(ENDOFLEVEL_CONTAINER_SIZE);
		gui.getMain().addFloatingElement(endOfLevelContainer, "endOfLevelContainer", (gui.getMain().getSize() - endOfLevelContainer.getSize()) / 2.0f, 1);
		
		@endOfLevelBackground = IMImage("Textures/UI/whiteblock.tga");
		endOfLevelBackground.setColor(vec4(vec3(0.0f), 0.4f));
		endOfLevelBackground.setSize(endOfLevelContainer.getSize());
		endOfLevelContainer.addFloatingElement(endOfLevelBackground, "endOfLevelBackground", vec2(0.0f), 2);
		
		@congratulationsText = IMText("Congratulations!", fontCongratulations);
		endOfLevelContainer.addFloatingElement(congratulationsText, "congratulationsText", vec2(0.0f), 3);
		
		@advanceToNextLevelText = IMText("Advance or restart the level?", fontRestartOrAdvance);
		endOfLevelContainer.addFloatingElement(advanceToNextLevelText, "advanceToNextLevelText", vec2(0.0f), 3);
		
		@hotkeysText = IMText("[E] = Advance    [H] = Restart", fontEndOfLevel);
		endOfLevelContainer.addFloatingElement(hotkeysText, "hotkeysText", vec2(0.0f), 3);
		gui.update();
		
		endOfLevelContainer.moveElement("congratulationsText", vec2((ENDOFLEVEL_CONTAINER_SIZE.x - congratulationsText.getSizeX()) / 2.0f, 30.0f));
		endOfLevelContainer.moveElement("advanceToNextLevelText", (ENDOFLEVEL_CONTAINER_SIZE - advanceToNextLevelText.getSize()) / 2.0f);
		endOfLevelContainer.moveElement("hotkeysText", vec2((ENDOFLEVEL_CONTAINER_SIZE.x - hotkeysText.getSizeX()) / 2.0f, ENDOFLEVEL_CONTAINER_SIZE.y - hotkeysText.getSizeY() - 30.0f));
		
		SetEndOfLevelWindowVisibility(false);
		
		gui.update();
	}

	void Render()
	{
		if (gui !is null) gui.render();
	}

	void ResizeToFullscreen(bool bFromWindowResize = false)
	{
		if (bFromWindowResize)
		{
			gui.getMain().setSize(vec2(0.0f));
			gui.getMain().setDisplacement(vec2(0.0f));
			
			gui.doScreenResize();
		}
		
		float fDisplayRatio = 16.0f / 9.0f;
		float fXResolution, fYResolution;
		float fGUIWidth, fGUIHeight;
		
		if (screenMetrics.getScreenWidth() < screenMetrics.getScreenHeight() * fDisplayRatio)
		{
			fXResolution = screenMetrics.getScreenWidth() / screenMetrics.GUItoScreenXScale;
			fYResolution = fXResolution / fDisplayRatio;
			
			fGUIWidth = fXResolution;
			fGUIHeight = screenMetrics.getScreenHeight() / screenMetrics.GUItoScreenXScale;
			
			gui.getMain().setDisplacementY((fYResolution - fGUIHeight) / 2.0f);
			gui.getMain().setSize(vec2(fGUIWidth, fGUIHeight));
		}
		else
		{
			fYResolution = screenMetrics.getScreenHeight() / screenMetrics.GUItoScreenYScale;
			fXResolution = fYResolution * fDisplayRatio;
			
			fGUIWidth = screenMetrics.getScreenWidth() / screenMetrics.GUItoScreenYScale;
			fGUIHeight = fYResolution;
			
			gui.getMain().setDisplacementX((fXResolution - fGUIWidth) / 2.0f);
			gui.getMain().setSize(vec2(fGUIWidth, fGUIHeight));
		}
			
		gui.update();
	}
	
	void Resize()
	{
		GUI::ResizeToFullscreen(true);
		
		gui.getMain().moveElement(
			"energyContainer",
			vec2(
				(gui.getMain().getSizeX() - ENERGY_CONTAINER_SIZE.x) / 2.0f,
				gui.getMain().getSizeY() * 0.9f
			)
		);
		
		gui.getMain().moveElement(
			"timerContainer",
			vec2(
				(gui.getMain().getSize().x - TIMER_CONTAINER_SIZE.x) / 2.0f,
				gui.getMain().getSizeY() * 0.015f
			)
		);
		
		gui.getMain().moveElement(
			"pbTimerContainer",
			vec2(
				(gui.getMain().getSize().x - PBTIMER_CONTAINER_SIZE.x) / 2.0f,
				gui.getMain().getSizeY() * 0.015f + timerContainer.getSizeY() + 1.0f
			)
		);
		
		gui.getMain().moveElement(
			"endOfLevelContainer",
			(gui.getMain().getSize() - endOfLevelContainer.getSize()) / 2.0f
		);
			
		gui.update();
	}
}