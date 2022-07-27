#include "magic-mouse/gui.as"
#include "magic-mouse/shared.as"

array<int> bridges;
bool postInit = false;

const int PLAYER_ID = 1;
const int START_ID = 2;
const int FINISH_ID = 3;

const float MINIMUM_CAMERA_DISTANCE = 10.0f;
const float DEFAULT_CAMERA_DISTANCE = 100.0f;
const float MAXIMUM_CAMERA_DISTANCE = 200.0f;
const float CAMERA_INCREMENT_PER_MILLISECOND = 100.0f;
float cameraDistance = DEFAULT_CAMERA_DISTANCE;
float timestampLastUpdate = 0.0f;

bool stickCameraToLocation = false;
vec3 savedCameraLocation;

float timestampDragStarted;
bool dragging = false;
vec3 startRay;
vec3 endRay;

float maxEnergy = SPL_DEF_ENERGY;
float remainingEnergy = maxEnergy;

float timestampLevelStart;
float timestampLevelFinished;
bool levelFinished;
int advanceOrRestart = 0;

float pbTime;

bool hotspotInfoDetailLevel = false;

// Reset player to this Z-Axis value.
float zAxisStickValue;

// Only really needed for debugging purposes.
void PostScriptReload()
{
	Init("");
}

void Init(string level_name)
{
	pbTime = LoadPbTime();

	GUI::Init();
	GUI::SetPbTime(pbTime);
	GUI::SetEnergy(remainingEnergy, maxEnergy);
	
	hotspotInfoDetailLevel = GetConfigValueBool(CONFIG_HOTSPOTINFO_DETAILLEVEL);
}

void Update(int is_paused)
{
	if (!postInit)
	{
		postInit = true;
		
		timestampLevelStart = ImGui_GetTime();
		levelFinished = false;
		
		zAxisStickValue = ReadObjectFromID(PLAYER_ID).GetTranslation().z;
	}
	
	ProtectBlocks();	
	HandleScriptParams();
	
	if (!levelFinished)
		GUI::SetTimer(timestampLevelStart);
	else
		GUI::SetTimer(ImGui_GetTime() - (timestampLevelFinished - timestampLevelStart));
	
	MovementObject@ player = ReadCharacterID(PLAYER_ID);
	player.position.z = zAxisStickValue;
	
	// Stick characters to one digit behind decimal point.
	// This is not a perfect solution, as it will make characters
	// stick too it if they move too fast, but it should do the trick
	// without having to manage zAxisStickValues for every character
	// or setting the scripts manually.
	for (int i = 0; i < GetNumCharacters(); ++i)
	{
		MovementObject@ character = ReadCharacter(i);
		if (character.controlled) continue;
		
		vec3 fixedPosition = character.position;
		fixedPosition.z = float(int(fixedPosition.z * 10) / 10);
		character.position = fixedPosition;
	}
	
	vec3 finishLocation = ReadObjectFromID(FINISH_ID).GetTranslation();
	
	bool xOK = abs(player.position.x - finishLocation.x) <= 1.0f;
	bool yOKBottom = player.position.y >= finishLocation.y + 1.0f;
	bool yOKTop = player.position.y <= finishLocation.y + 1.5f;
	bool zOK = abs(finishLocation.z - player.position.z) <= 0.5f;
	int knockedOut = player.GetIntVar("knocked_out");
	bool playerAlive = knockedOut != _dead && knockedOut != _unconscious;
	
	if (xOK && yOKBottom && yOKTop && zOK && playerAlive)
	{
		if (!levelFinished)
		{
			levelFinished = true;
			advanceOrRestart = 0;
			timestampLevelFinished = ImGui_GetTime();
			
			PlaySound("Data/Sounds/magic-mouse/cheer.wav");
			GUI::SetEndOfLevelWindowVisibility(true);
			
			float levelTime = timestampLevelFinished - timestampLevelStart;
			
			if (pbTime == 0 || levelTime < pbTime)
			{
				pbTime = levelTime;
				SavePbTime(levelTime);
			}
		}
	}
		
	if (EditorModeActive() || GetMenuPaused())
	{
		if (!hotspotInfoDetailLevel && EditorModeActive())
		{
			DebugDrawText(
				ReadObjectFromID(START_ID).GetTranslation(),
				"Start [" + START_ID + "]", 1.0f, true, _delete_on_update
			);
			
			DebugDrawText(
				ReadCharacterID(PLAYER_ID).position,
				"Player [" + PLAYER_ID + "]", 1.0f, true, _delete_on_update
			);
			
			DebugDrawText(
				ReadObjectFromID(FINISH_ID).GetTranslation(),
				"Finish [" + FINISH_ID + "]", 1.0f, true, _delete_on_update
			);
		}
		
		// Otherwise if the player holds + or - while closing the menu, the camera will jump.
		timestampLastUpdate = ImGui_GetTime();
		return;
	}
	
	// If the player dies after the finish they should still have the ability to advance.
	// We need to wait one iteration before sending go_to_main_menu, otherwise the next level will bug out if one exists.
	if (levelFinished)
	{
		switch (advanceOrRestart)
		{
			case 0:
				if (GetInputPressed(player.controller_id, "c"))
				{
					GUI::SetEndOfLevelWindowVisibility(false);
					advanceOrRestart = 3;
				}
				else if (GetInputPressed(player.controller_id, "e"))
					++advanceOrRestart;
				break;
			
			case 1:
				SendGlobalMessage("levelwin");
				++advanceOrRestart;
				return;
			
			case 2:
				level.SendMessage("go_to_main_menu");
				return;
				
			case 3:
				if (GetInputPressed(player.controller_id, "c"))
				{
					GUI::SetEndOfLevelWindowVisibility(true);
					advanceOrRestart = 0;
				}
				break;
		}
	}
	
	if (GetInputPressed(player.controller_id, "h"))
		level.SendMessage("reset");
	
	HandleCamera();
	HandleHovering(playerAlive);
	HandleClicks(playerAlive);
	
	// Drawingbridges while Dragging might flicker, so we do it in DrawGUI.
	// HandleDragging(playerAlive);
	
	timestampLastUpdate = ImGui_GetTime();
}

void ReceiveMessage(string message)
{
	TokenIterator ti;
	ti.Init();
	
	if (!ti.FindNextToken(message)) return;
	
	if (ti.GetToken(message) == "post_reset")
	{
		for (int i = 0; i < int(bridges.length()); ++i)
			DeleteObjectID(bridges[i]);
		
		bridges.resize(0);
		
		timestampLevelStart = ImGui_GetTime();
		levelFinished = false;
		
		GUI::SetPbTime(LoadPbTime());
		
		remainingEnergy = maxEnergy;
		GUI::SetEnergy(maxEnergy, maxEnergy);
		
		GUI::SetEndOfLevelWindowVisibility(false);
		
		cameraDistance = DEFAULT_CAMERA_DISTANCE;
		
		zAxisStickValue = ReadObjectFromID(PLAYER_ID).GetTranslation().z;
	}
	else if (ti.GetToken(message) == MSG_TELEPORTED)
	{
		if (!ti.FindNextToken(message)) return;
		
		int hotspotTargetId = parseInt(ti.GetToken(message));
		
		float oldZAxisStickValue = zAxisStickValue;
		zAxisStickValue = ReadObjectFromID(hotspotTargetId).GetTranslation().z;
		
		if (oldZAxisStickValue < zAxisStickValue && cameraDistance - zAxisStickValue >= MINIMUM_CAMERA_DISTANCE)
			cameraDistance -= zAxisStickValue;
		else if (oldZAxisStickValue >= zAxisStickValue)
			cameraDistance += oldZAxisStickValue;
	}
	else if (ti.GetToken(message) == MSG_HOTSPOTINFO_DETAILLEVEL_CHANGED)
	{
		for (int i = 0; i < GetNumHotspots(); ++i)
			ReadObjectFromID(ReadHotspot(i).GetID()).ReceiveScriptMessage(MSG_HOTSPOTINFO_DETAILLEVEL_CHANGED);
		
		hotspotInfoDetailLevel = GetConfigValueBool(CONFIG_HOTSPOTINFO_DETAILLEVEL);
	}
	else if (ti.GetToken(message) == MSG_PB_WAS_RESET)
	{
		pbTime = 0.0f;
		GUI::SetPbTime(0.0f);
	}
}

bool DialogueCameraControl()
{
	return !EditorModeActive();
}

bool HasFocus()
{
	return !GetMenuPaused() && postInit;
}

void SetWindowDimensions(int width, int height)
{
	GUI::Resize();
}

void DrawGUI()
{
	GUI::Render();
	
	if (!EditorModeActive() && !GetMenuPaused())
	{
		int knockedOut = ReadCharacterID(PLAYER_ID).GetIntVar("knocked_out");
		bool playerAlive = knockedOut != _dead && knockedOut != _unconscious;
		
		HandleDragging(playerAlive);
	}
}

void ProtectBlocks()
{
	// Protect these objects from destructive/impossible manipulation.
	array<int> modObjects = { PLAYER_ID, START_ID, FINISH_ID };
	for (int i = 0; i < int(modObjects.length()); ++i)
	{
		Object@ object = ReadObjectFromID(modObjects[i]);
		object.SetScale(vec3(1.0f));
		object.SetDeletable(false);
		object.SetCopyable(false);
		object.SetRotatable(false);
		object.SetScalable(false);
	}
}

void HandleScriptParams()
{
	ScriptParams@ scriptParams = level.GetScriptParams();
	
	if (!scriptParams.HasParam(SP_MAX_ENERGY))
	{
		scriptParams.AddInt(SP_MAX_ENERGY, SPL_DEF_ENERGY);
		maxEnergy = SPL_DEF_ENERGY;
		remainingEnergy = SPL_DEF_ENERGY;
		
		GUI::SetEnergy(maxEnergy, maxEnergy);
	}
	
	int levelEnergy = scriptParams.GetInt(SP_MAX_ENERGY);
	if (levelEnergy < 0 || levelEnergy > SPL_MAX_ENERGY)
	{
		levelEnergy = (levelEnergy < 0) ? 0 : SPL_MAX_ENERGY;
		scriptParams.SetInt(SP_MAX_ENERGY, levelEnergy);
	}
	
	if (levelEnergy != int(maxEnergy))
	{
		maxEnergy = levelEnergy;
		remainingEnergy = levelEnergy;
		GUI::SetEnergy(maxEnergy, maxEnergy);
	}
}

void HandleCamera()
{
	MovementObject@ player = ReadCharacterID(PLAYER_ID);
	
	if (timestampLastUpdate != 0.0f)
	{
		if (GetInputDown(player.controller_id, "keypad+") || GetInputDown(player.controller_id, "r"))
			cameraDistance -= ((ImGui_GetTime() - timestampLastUpdate)) * CAMERA_INCREMENT_PER_MILLISECOND;
		if (GetInputDown(player.controller_id, "keypad-") || GetInputDown(player.controller_id, "f"))
			cameraDistance += ((ImGui_GetTime() - timestampLastUpdate)) * CAMERA_INCREMENT_PER_MILLISECOND;
	}

	cameraDistance = Limit(cameraDistance, MINIMUM_CAMERA_DISTANCE, MAXIMUM_CAMERA_DISTANCE);

	if (GetInputPressed(player.controller_id, "tab"))
	{
		stickCameraToLocation = !stickCameraToLocation;
		savedCameraLocation = player.position;
	}
	
	// FOV 10, Distance 250 looks better, but the LOD is terrible	
	camera.SetFOV(30.0f);
	camera.SetXRotation(0.0f);
	camera.SetYRotation(0.0f);
	camera.SetZRotation(0.0f);
	
	if (stickCameraToLocation)
		camera.SetPos(savedCameraLocation + vec3(0.0f, 0.5f, cameraDistance));
	else
		camera.SetPos(player.position + vec3(0.0f, 0.5f, cameraDistance));
}

void HandleHovering(bool playerAlive)
{
	vec3 start = camera.GetPos();
	vec3 end = camera.GetPos() + camera.GetMouseRay() * 1000.0f;
	
	col.GetObjRayCollision(start, end);
	
	float closestCollisionDistance;
	int closestId = -1;
	
	if (playerAlive)
	{
		for (int i = 0; i < sphere_col.NumContacts(); ++i)
		{
			CollisionPoint cp = sphere_col.GetContact(i);
			if (cp.id == -1) continue;
			
			float newCollisionDistance = distance_squared(camera.GetPos(), cp.position);
			
			if (closestId == -1)
			{
				closestId = cp.id;
				closestCollisionDistance = newCollisionDistance;
			}
			else if (newCollisionDistance < closestCollisionDistance)
			{
				closestId = cp.id;
				closestCollisionDistance = newCollisionDistance;
			}
		}
	}
	
	// There is a better way by registering the hotspots objects and sending only the message
	// to the hotspot which should light up, but that would mean so much more code
	// for a minuscule amount of more performance.
	// With CPU-bottleneck settings I get 5 fps for 14052 objects (with 6403 switches).
	// Disabling the hovering function completely yields 15 fps, basically no difference.
	
	for (int j = 0; j < GetNumHotspots(); ++j)
	{
		if (ReadHotspot(j).GetTypeString() == TYPE_SWITCH_HOTSPOT)
		{
			// Sending Id -1 will UnHover the hotspot.
			ReadObjectFromID(ReadHotspot(j).GetID()).ReceiveScriptMessage(MSG_HOVER + " " + closestId);
		}
	}
}

void HandleClicks(bool playerAlive)
{
	if (GetInputPressed(ReadCharacterID(PLAYER_ID).controller_id, "attack") && playerAlive)
	{
		vec3 start = camera.GetPos();
		vec3 end = camera.GetPos() + camera.GetMouseRay() * 1000.0f;
		
		col.GetObjRayCollision(start, end);
		
		float closestCollisionDistance;
		int closestId = -1;
		
		for (int i = 0; i < sphere_col.NumContacts(); ++i)
		{
			CollisionPoint cp = sphere_col.GetContact(i);
			if (cp.id == -1) continue;
			
			float newCollisionDistance = distance_squared(camera.GetPos(), cp.position);
			
			if (closestId == -1)
			{
				closestId = cp.id;
				closestCollisionDistance = newCollisionDistance;
			}
			else if (newCollisionDistance < closestCollisionDistance)
			{
				closestId = cp.id;
				closestCollisionDistance = newCollisionDistance;
			}
		}
		
		if (closestId != -1)
		{
			for (int j = 0; j < GetNumHotspots(); ++j)
			{
				if (ReadHotspot(j).GetTypeString() == TYPE_SWITCH_HOTSPOT)
				{
					ReadObjectFromID(ReadHotspot(j).GetID()).ReceiveScriptMessage(MSG_CLICK + " " + closestId);
				}
			}
		}
	}
}

void HandleDragging(bool playerAlive)
{
	if (maxEnergy == 0 || !playerAlive) return;

	MovementObject@ player = ReadCharacterID(PLAYER_ID);

	if (!dragging && GetInputDown(player.controller_id, "attack"))
	{
		dragging = true;
		startRay = camera.GetMouseRay();
		
		timestampDragStarted = ImGui_GetTime();
	}
	else if (dragging && !GetInputDown(player.controller_id, "attack"))
	{
		dragging = false;
		
		if (timestampDragStarted - 0.1f > timestampLevelStart)
		{
			endRay = camera.GetMouseRay();
			
			vec3 startPosition = camera.GetPos() + startRay * cameraDistance;
			vec3 endPosition = camera.GetPos() + endRay * cameraDistance;
			
			float requiredEnergy = distance(startPosition, endPosition);
			if (requiredEnergy < 0.95f || requiredEnergy > remainingEnergy) return;
			
			// Object@ line = ReadObjectFromID(CreateObject("Data/Objects/Environment/sand.xml", true));
			Object@ line = ReadObjectFromID(CreateObject("Data/Objects/magic-mouse/bridge.xml", true));
			bridges.insertLast(line.GetID());
			
			line.SetTint(
				ColorFromGradient(Limit(requiredEnergy - 1.0f, 0.0f, 12.0f) / 12.0f,
				vec3(1.5f, 0.0f, 0.0f),
				vec3(1.5f, 1.5f, 0.0f),
				vec3(0.0f, 1.5f, 0.0f)
				)
			);
			
			vec3 scale = requiredEnergy;
			scale.y = 0.5f;
			scale.z = 1.0f;
			scale /= 2.0f;
			
			vec3 position = startPosition + 0.5f * (endPosition - startPosition);
			position.z = zAxisStickValue;
			
			line.SetTranslation(position);
			line.SetScale(scale);
			
			quaternion rotation;
			GetRotationBetweenVectors(vec3(1.0f, 0.0f, 0.0f), endPosition - startPosition, rotation);
			line.SetRotation(rotation);
			
			remainingEnergy -= requiredEnergy;		
			GUI::SetEnergy(remainingEnergy, maxEnergy);
			
			int sound;
			if (requiredEnergy >= 1 && requiredEnergy <= 4) sound = 4;
			else if (requiredEnergy > 4 && requiredEnergy <= 8) sound = 3;
			else if (requiredEnergy > 8 && requiredEnergy <= 12) sound = 2;
			else /* if (requiredEnergy > 12) */ sound = 1;
			
			int idSound = PlaySound("Data/Sounds/magic-mouse/magic" + sound + ".wav");
			SetSoundGain(idSound, 0.2f);
		}
	}
	
	// Dragging is enabled after 0.1s to prevent accidental dragging through the Loading Screen.
	if (dragging && (timestampDragStarted - 0.1f > timestampLevelStart))
	{
		vec3 startPosition = camera.GetPos() + startRay * cameraDistance;
		vec3 endPosition = camera.GetPos() + camera.GetMouseRay() * cameraDistance;
		
		vec3 lineColor;
		float requiredEnergy = distance(startPosition, endPosition);
		
		if (requiredEnergy < 0.95f || requiredEnergy > remainingEnergy)
			lineColor = vec3(25.0f);
		else
			lineColor = ColorFromGradient(Limit(requiredEnergy - 1.0f, 0.0f, 12.0f) / 12.0f,
				vec3(50.0f, 0.0f, 0.0f),
				vec3(25.0f, 25.0f, 0.0f),
				vec3(0.0f, 50.0f, 0.0f)
			);
		
		DebugDrawLine(startPosition, endPosition, lineColor, _delete_on_draw);
	}
}