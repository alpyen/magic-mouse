#include "magic-mouse/shared.as"

bool hotspotInfoDetailLevel = false;

int groupId = -1;

vec3 adjustedScale;

bool switchState = false;

string GetTypeString()
{
	return TYPE_SWITCH_HOTSPOT;
}

void Init()
{
	hotspotInfoDetailLevel = GetConfigValueBool(CONFIG_HOTSPOTINFO_DETAILLEVEL);
}

void Dispose()
{
	DeleteObjectID(groupId);
}

void SetParameters()
{
	params.AddInt(SP_CHARACTER_ID, -1);
	params.AddIntCheckbox(SP_DEFAULT_SWITCH_STATE_IS_ON, false);
	params.AddIntCheckbox(SP_SEND_MESSAGE_ON_LEVEL_RESET, false);
	params.AddString(SP_SEND_MESSAGE_ON_SWITCH_OFF_TO_ON, "");
	params.AddString(SP_SEND_MESSAGE_ON_SWITCH_ON_TO_OFF, "");
}

void Update()
{
	Object@ hotspotObject = ReadObjectFromID(hotspot.GetID());
	
	if (groupId == -1)
	{
		groupId = CreateObject("Data/Objects/magic-mouse/switch.xml", true);
	
		Object@ groupObject = ReadObjectFromID(groupId);		
		groupObject.SetTranslation(ReadObjectFromID(hotspot.GetID()).GetTranslation());
		
		array<int> groupObjects = groupObject.GetChildren();
		groupObjects.insertAt(0, groupId);
		
		// You could technically select the elements through the scenegraph and scale them,
		// but the scaling will not save correctly, as it is dependant on the group scale.
		// Disabling it completely is possible, but not worth the time and effort.
		for (int i = 0; i < int(groupObjects.size()); ++i)
		{
			Object@ object = ReadObjectFromID(groupObjects[i]);
			object.SetDeletable(false);
			object.SetCopyable(false);
			object.SetRotatable(false);
			object.SetScalable(false);
			object.SetSelectable(false);
		}
		
		adjustedScale = 10.0f * ReadObjectFromID(groupId).GetScale();
		SetSwitchState((params.GetInt(SP_DEFAULT_SWITCH_STATE_IS_ON) == 1) ? true : false, false);
	}
	
	Object@ switchObject = ReadObjectFromID(groupId);
		
	if (switchObject.GetTranslation() != hotspotObject.GetTranslation())
		switchObject.SetTranslation(hotspotObject.GetTranslation());
		
	if (switchObject.GetRotation() != hotspotObject.GetRotation())
		switchObject.SetRotation(hotspotObject.GetRotation());
		
	if (switchObject.GetScale() != hotspotObject.GetScale() * adjustedScale)
		switchObject.SetScale(hotspotObject.GetScale() * adjustedScale);
}

void DrawEditor()
{
	if (!hotspotInfoDetailLevel)
	{
		int receiverId = params.GetInt(SP_CHARACTER_ID);

		string displayText = "Switch Hotspot [" + hotspot.GetID() + "]\n\n" +
			"Receiver ID: " + ((receiverId == -1) ? "Level" : (receiverId + "")) + "\n" +
			"Message Off->On: " + params.GetString(SP_SEND_MESSAGE_ON_SWITCH_OFF_TO_ON) + "\n" +
			"Message On->Off: " + params.GetString(SP_SEND_MESSAGE_ON_SWITCH_ON_TO_OFF)
		;
		
		DebugDrawText(
			ReadObjectFromID(hotspot.GetID()).GetTranslation(),
			displayText,
			1.0f,
			true,
			_delete_on_draw
		);
	}
}

void ReceiveMessage(string message)
{
	TokenIterator ti;
	ti.Init();
	
	// A check of groupId == -1 would be necessary if the effects would be available in editor mode.
	// But they are not in the levelscript, if they were, it would crash without the check.
	
	if (!ti.FindNextToken(message)) return;
	
	if (ti.GetToken(message) == MSG_CLICK)
	{
		if (!ti.FindNextToken(message)) return;
		
		int clickedId = atoi(ti.GetToken(message));
		
		array<int>@ groupObjects = ReadObjectFromID(groupId).GetChildren();
		
		if (clickedId == groupObjects[1] || clickedId == groupObjects[2])
			SetSwitchState(!switchState, true);
	}
	else if (ti.GetToken(message) == MSG_HOVER)
	{
		if (!ti.FindNextToken(message)) return;
		
		int clickedId = atoi(ti.GetToken(message));
		
		array<int>@ groupObjects = ReadObjectFromID(groupId).GetChildren();
		
		float brightness = (clickedId == groupObjects[1] || clickedId == groupObjects[2]) ? 2.0f : 1.0f;
		
		ReadObjectFromID(groupObjects[1]).SetTint(brightness * vec3(1.0f, 0.0f, 0.0f));
		ReadObjectFromID(groupObjects[2]).SetTint(brightness * vec3(0.0f, 1.0f, 0.0f));
	}
	else if (ti.GetToken(message) == MSG_HOTSPOTINFO_DETAILLEVEL_CHANGED)
	{
		hotspotInfoDetailLevel = GetConfigValueBool(CONFIG_HOTSPOTINFO_DETAILLEVEL);
	}
}

void Reset()
{
	bool defaultStateIsOn = params.GetInt(SP_DEFAULT_SWITCH_STATE_IS_ON) == 1;
	bool messageOnLevelReset = params.GetInt(SP_SEND_MESSAGE_ON_LEVEL_RESET) == 1;

	SetSwitchState(
		defaultStateIsOn,
		messageOnLevelReset && switchState != defaultStateIsOn
	);
}

void SetSwitchState(bool state, bool sendMessage)
{
	array<int>@ groupObjects = ReadObjectFromID(groupId).GetChildren();
	
	Object@ offSwitchObject = ReadObjectFromID(groupObjects[1]);
	Object@ onSwitchObject = ReadObjectFromID(groupObjects[2]);
	
	if (state)
	{
		offSwitchObject.SetEnabled(false);
		onSwitchObject.SetEnabled(true);
		
		string message = params.GetString(SP_SEND_MESSAGE_ON_SWITCH_OFF_TO_ON);
		
		if (sendMessage && message != "")
		{
			int receiverId = params.GetInt(SP_CHARACTER_ID);
		
			if (receiverId == -1)
				level.SendMessage(message);
			else if (ObjectExists(receiverId) && ReadObjectFromID(receiverId).GetType() == _movement_object)
				ReadCharacterID(receiverId).ReceiveScriptMessage(message);
		}
	}
	else
	{
		offSwitchObject.SetEnabled(true);
		onSwitchObject.SetEnabled(false);
		
		string message = params.GetString(SP_SEND_MESSAGE_ON_SWITCH_ON_TO_OFF);
		
		if (sendMessage && message != "")
		{
			int receiverId = params.GetInt(SP_CHARACTER_ID);
			
			if (receiverId == -1)
				level.SendMessage(message);
			else if (ObjectExists(receiverId) && ReadObjectFromID(receiverId).GetType() == _movement_object)
				ReadCharacterID(receiverId).ReceiveScriptMessage(message);
		}
	}
	
	switchState = state;
}