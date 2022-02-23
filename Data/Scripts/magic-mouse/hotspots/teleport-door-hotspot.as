int doorId = -1;

int playerId = -1;
float timestampHotspotEntered;

array<int> incomingConnections;

string GetTypeString()
{
	return "TeleportDoorHotspot";
}

void Reset()
{
	playerId = -1;
}

void Dispose()
{
	if (hotspot.GetConnectedObjects().length() == 1)
		hotspot.Disconnect(ReadObjectFromID(hotspot.GetConnectedObjects()[0]));

	if (doorId != -1) DeleteObjectID(doorId);
}

void Update()
{
	Object@ hotspotObject = ReadObjectFromID(hotspot.GetID());
	
	if (doorId == -1)
	{
		doorId = CreateObject("Data/Objects/Buildings/Door1.xml", true);
		ReadObjectFromID(doorId).SetTranslation(ReadObjectFromID(hotspot.GetID()).GetTranslation());
		
		hotspotObject.SetRotatable(false);
		hotspotObject.SetScalable(false);		
	}
	
	Object@ doorObject = ReadObjectFromID(doorId);
	
	if (hotspotObject.GetTranslation() != doorObject.GetTranslation() + vec3(0.0f, 0.0f, -1.0f))
		doorObject.SetTranslation(hotspotObject.GetTranslation() + vec3(0.0f, 0.0f, -1.0f));
		
	if (hotspotObject.GetScale() != vec3(0.5f))
		hotspotObject.SetScale(vec3(0.5f));
	
	for (int i = hotspot.GetConnectedObjects().length() - 1; i >= 1; --i)
		hotspot.Disconnect(ReadObjectFromID(hotspot.GetConnectedObjects()[i]));
	
	if (hotspot.GetConnectedObjects().length() == 1 && playerId != -1 && ImGui_GetTime() - timestampHotspotEntered >= 0.5f)
	{	
		DebugDrawText(
			hotspotObject.GetTranslation() + vec3(0.0f, 0.5f, 0.0f),
			"Hold 'E' to enter.",
			1.0f,
			true,
			_delete_on_update
		);
		
		MovementObject@ player = ReadCharacterID(playerId);
		
		if (GetInputPressed(player.controller_id, "e"))
		{
			player.position = ReadObjectFromID(hotspot.GetConnectedObjects()[0]).GetTranslation() + vec3(0.0f, -0.55f, 0.0f);
			player.velocity = vec3(0.0f);
			
			level.SendMessage("tdh-teleported " + hotspot.GetConnectedObjects()[0]);
		}
	}
		
}

void HandleEvent(string event, MovementObject @mo)
{
	if (event == "enter" && mo.controlled)
	{
		timestampHotspotEntered = ImGui_GetTime();
		playerId = mo.GetID();
	}
	else if (event == "exit" && mo.controlled)
	{
		playerId = -1;
	}
}

bool AcceptConnectionsFrom(Object@ other)
{
	return
		other.GetType() == _hotspot_object
		&& cast<Hotspot@>(other).GetTypeString() == GetTypeString()
	;
}

bool AcceptConnectionsTo(Object@ other)
{
	return
		hotspot.GetConnectedObjects().length() == 0
		&& other.GetType() == _hotspot_object
		&& cast<Hotspot@>(other).GetTypeString() == GetTypeString()
	;
}

void ConnectedFrom(Object@ other)
{
	incomingConnections.insertLast(other.GetID());
}

bool ConnectTo(Object@ other)
{
	return true;
}

bool Disconnect(Object@ other)
{	
	return true;
}

void DisconnectedFrom(Object@ other)
{
	for (int i = 0; i < int(incomingConnections.length()); ++i)
	{
		if (incomingConnections[i] == other.GetID())
		{
			incomingConnections.removeAt(i);
			break;
		}
	}
}

void DrawEditor()
{
	string displayText = "Door Teleport Hotspot [" + hotspot.GetID() + "]";
	
	if (incomingConnections.length() > 0)
	{
		displayText += "\n\nIn:  [";
		
		for (int i = 0; i < int(incomingConnections.length()); ++i)
		{
			displayText += incomingConnections[i];
			if (i < int(incomingConnections.length()) - 1) displayText += ", ";
		}
		
		displayText += "]";
	}
	
	if (hotspot.GetConnectedObjects().length() == 1)
	{
		displayText += "\nOut: [" + hotspot.GetConnectedObjects()[0] + "]";
	
		DebugDrawLine(
			ReadObjectFromID(hotspot.GetID()).GetTranslation(),
			ReadObjectFromID(hotspot.GetConnectedObjects()[0]).GetTranslation(),
			vec3(0.0f, 1.0f, 0.0f),
			_delete_on_draw
		);
	}
	
	DebugDrawText(
		ReadObjectFromID(hotspot.GetID()).GetTranslation(),
		displayText,
		1.0f,
		true,
		_delete_on_draw
	);
}