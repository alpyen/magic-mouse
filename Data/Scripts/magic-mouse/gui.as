namespace GUI
{
	const vec2 GUI_SIZE(750.0f, 120.0f);
	
	FontSetup fontText("Underdog-Regular", 50.0f, vec4(1.0f), false);
	
	IMGUI@ gui = CreateIMGUI();

	IMContainer@ container;
	IMImage@ background;
	IMText@ label;
	IMText@ energyText;
	IMImage@ energyRemainingBar;
	IMImage@ energyMaxBar;

	void Init()
	{
		gui.clear();
		gui.setup();
		
		ResizeToFullscreen();
		Build();
	}

	void SetEnergy(float remainingEnergy, float totalEnergy)
	{
		energyText.setText(int(remainingEnergy) + " / " + int(totalEnergy));
		gui.update();
		container.moveElement("energyText", vec2(container.getSizeX() - energyText.getSizeX() - 15.0f, 15.0f));
		
		// Just so we don't get a divide by zero error.
		if (totalEnergy == 0) totalEnergy = 1;
		
		energyRemainingBar.setSizeX((int(remainingEnergy) / totalEnergy) * (GUI_SIZE.x + 2.0f * -15.0f));
		
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
		@container = IMContainer();
		container.setSize(GUI_SIZE);
		gui.getMain().addFloatingElement(container, "container", vec2((gui.getMain().getSizeX() - GUI_SIZE.x) / 2.0f, gui.getMain().getSizeY() * 0.9f), 1);
		
		@background = IMImage("Textures/UI/whiteblock.tga");
		background.setColor(vec4(vec3(0.0f), 0.2f));
		background.setSize(container.getSize());
		container.addFloatingElement(background, "background", vec2(0.0f), 2);
		
		@label = IMText("Energy:", fontText);
		container.addFloatingElement(label, "label", vec2(15.0f), 2);
		
		@energyText = IMText("100 / 100", fontText);
		container.addFloatingElement(energyText, "energyText", vec2(0.0f), 2);
		gui.update();
		container.moveElement("energyText", vec2(container.getSizeX() - energyText.getSizeX() - 15.0f, 15.0f));
		
		@energyMaxBar = IMImage("Textures/UI/whiteblock.tga");
		energyMaxBar.setColor(vec4(0.0f, 0.621f, 0.0f, 0.4f));
		energyMaxBar.setSize(GUI_SIZE + vec2(2.0f * -15.0f, 3.0f * -15.0f - fontText.size));
		container.addFloatingElement(energyMaxBar, "energyMaxBar", vec2(15.0f, 15.0f + fontText.size + 15.0f), 2);
		
		@energyRemainingBar = IMImage("Textures/UI/whiteblock.tga");
		energyRemainingBar.setColor(vec4(0.0f, 1.0f, 0.0f, 0.6f));
		energyRemainingBar.setSize(GUI_SIZE + vec2(2.0f * -15.0f, 3.0f * -15.0f - fontText.size));
		container.addFloatingElement(energyRemainingBar, "energyRemainingBar", vec2(15.0f, 15.0f + fontText.size + 15.0f), 3);
		
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
			"container",
			vec2(
				(gui.getMain().getSizeX() - GUI_SIZE.x) / 2.0f,
				gui.getMain().getSizeY() * 0.9f
			)
		);
			
		gui.update();
	}
}