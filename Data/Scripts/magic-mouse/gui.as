namespace GUI
{
	const vec2 ENERGY_CONTAINER_SIZE(750.0f, 120.0f);
	const vec2 TIMER_CONTAINER_SIZE(300.0f, 75.0f);
	const vec2 PBTIMER_CONTAINER_SIZE(150.0f, 30.0f);
	
	FontSetup fontText("Underdog-Regular", 50, vec4(1.0f), false);
	FontSetup fontTimer("Lato-Regular", int(TIMER_CONTAINER_SIZE.y - 25), vec4(1.0f), false);
	FontSetup fontPbTimer("Lato-Regular", int(TIMER_CONTAINER_SIZE.y - 50), vec4(1.0), false);
	
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


	void Init()
	{
		gui.clear();
		gui.setup();
		
		ResizeToFullscreen();
		Build();
	}

	void SetTimer(float timestampLevelStart)
	{
		Log(fatal, "Elapsed Time: " + (ImGui_GetTime() - timestampLevelStart));
		
		int passedTime = min(
			int((ImGui_GetTime() - timestampLevelStart) * 1000.0f),
			99 * 60 * 1000 + 59 * 1000 + 999
		); // Cap to 99:99.999
		
		int minutes = passedTime / (60 * 1000);
		passedTime %= (60 * 1000);
		
		int seconds = passedTime / 1000;
		passedTime %= 1000;
		
		int milliseconds = int(passedTime / 100);
		
		timerText.setText(
			(minutes < 10 ? "0" : "") + minutes + ":" + 
			(seconds < 10 ? "0" : "") + seconds + "." + 
			milliseconds
		);
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
		gui.update();
		energyContainer.moveElement("energyText", vec2(ENERGY_CONTAINER_SIZE.x - energyText.getSizeX() - 15.0f, 15.0f));
		
		@energyMaxBar = IMImage("Textures/UI/whiteblock.tga");
		energyMaxBar.setColor(vec4(0.0f, 0.621f, 0.0f, 0.4f));
		energyMaxBar.setSize(ENERGY_CONTAINER_SIZE + vec2(2.0f * -15.0f, 3.0f * -15.0f - fontText.size));
		energyContainer.addFloatingElement(energyMaxBar, "energyMaxBar", vec2(15.0f, 15.0f + fontText.size + 15.0f), 2);
		
		@energyRemainingBar = IMImage("Textures/UI/whiteblock.tga");
		energyRemainingBar.setColor(vec4(0.0f, 1.0f, 0.0f, 0.6f));
		energyRemainingBar.setSize(ENERGY_CONTAINER_SIZE + vec2(2.0f * -15.0f, 3.0f * -15.0f - fontText.size));
		energyContainer.addFloatingElement(energyRemainingBar, "energyRemainingBar", vec2(15.0f, 15.0f + fontText.size + 15.0f), 3);
		
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
			
		gui.update();
	}
}