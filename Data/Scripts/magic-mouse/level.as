#include "magic-mouse/gui.as"
#include "magic-mouse/shared.as"

array<int> lines;
bool postInit = false;

const int PLAYER_ID = 1;
const int START_ID = 2;
const int FINISH_ID = 3;

const float DEFAULT_CAMERA_DISTANCE = 100.0f;
const float MINIMUM_CAMERA_DISTANCE = 10.0f;
const float CAMERA_INCREMENT_PER_MILLISECOND = 100.0f;

float cameraDistance = DEFAULT_CAMERA_DISTANCE;
float timestampLastUpdate;

bool stickCameraToLocation = false;
vec3 savedCameraLocation;

bool dragging = false;
vec3 startRay;
vec3 endRay;

float maxEnergy = 100.0f;
float remainingEnergy = maxEnergy;

float timestampLevelStart;
float timestampLevelFinished;
bool levelFinished;

float pbTime;

// Reset player to this Z-Axis value.
float zAxisStickValue;

// Only really needed for debugging purposes.
void PostScriptReload()
{
	Init("");
}

// KAMERA FIXIEREN MIT TAB UND DANN TÜR BENUTZEN?

void Init(string level_name)
{
	pbTime = LoadPbTime();

	GUI::Init();
	GUI::SetPbTime(pbTime);
	GUI::SetEnergy(remainingEnergy, maxEnergy);
}

void Update(int is_paused)
{
	if (!postInit)
	{
		postInit = true;
		
		timestampLevelStart = ImGui_GetTime();
		levelFinished = false;
		
		// Protect these objects from destructive/impossible manipulation.
		array<int> modObjects = { PLAYER_ID, START_ID, FINISH_ID };
		for (int i = 0; i < int(modObjects.length()); ++i)
		{
			Object@ object = ReadObjectFromID(modObjects[i]);
			object.SetDeletable(false);
			object.SetCopyable(false);
			object.SetRotatable(false);
			object.SetScalable(false);
		}
		
		zAxisStickValue = ReadObjectFromID(PLAYER_ID).GetTranslation().z;
	}
	
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
	bool bottomOK = player.position.y >= finishLocation.y + 1.0f;
	bool topOK = player.position.y <= finishLocation.y + 1.5f;
	bool zOK = abs(finishLocation.z - player.position.z) <= 0.5f;
	int knockedOut = player.GetIntVar("knocked_out");
	bool playerAlive = knockedOut != _dead && knockedOut != _unconscious;
	
	if (xOK && bottomOK && topOK && zOK && playerAlive)
	{
		if (!levelFinished)
		{
			levelFinished = true;
			timestampLevelFinished = ImGui_GetTime();
			
			PlaySound("Data/Sounds/magic-mouse/cheer.wav");
			
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
		// Otherwise if the player holds + or - while closing the menu, the camera will jump.
		timestampLastUpdate = ImGui_GetTime();
		return;
	}

	HandleCamera();
	HandleHovering();
	HandleClicks();
	HandleDragging();
	
	timestampLastUpdate = ImGui_GetTime();
}

void ReceiveMessage(string message)
{
	TokenIterator ti;
	ti.Init();
	
	if (!ti.FindNextToken(message)) return;
	
	if (ti.GetToken(message) == "post_reset")
	{
		for (int i = 0; i < int(lines.length()); ++i)
			DeleteObjectID(lines[i]);
		
		lines.resize(0);
		
		timestampLevelStart = ImGui_GetTime();
		levelFinished = false;
		
		GUI::SetPbTime(LoadPbTime());
		
		remainingEnergy = maxEnergy;
		GUI::SetEnergy(maxEnergy, maxEnergy);
		
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
}

void HandleScriptParams()
{
	ScriptParams@ scriptParams = level.GetScriptParams();
	if (!scriptParams.HasParam(SP_MAX_ENERGY))
	{
		scriptParams.AddInt(SP_MAX_ENERGY, 100);
		maxEnergy = 100.0f;
		remainingEnergy = 100.0f;
		
		GUI::SetEnergy(maxEnergy, maxEnergy);
	}
	
	int levelEnergy = scriptParams.GetInt(SP_MAX_ENERGY);
	if (levelEnergy < 0 || levelEnergy > 10000)
	{
		levelEnergy = (levelEnergy < 0) ? 0 : 10000;
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
	
	if (GetInputDown(player.controller_id, "keypad+") || GetInputDown(player.controller_id, "r"))
		cameraDistance -= ((ImGui_GetTime() - timestampLastUpdate)) * CAMERA_INCREMENT_PER_MILLISECOND;
	if (GetInputDown(player.controller_id, "keypad-") || GetInputDown(player.controller_id, "f"))
		cameraDistance += ((ImGui_GetTime() - timestampLastUpdate)) * CAMERA_INCREMENT_PER_MILLISECOND;

	if (cameraDistance <= MINIMUM_CAMERA_DISTANCE)
		cameraDistance = MINIMUM_CAMERA_DISTANCE;

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

void HandleHovering()
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

void HandleClicks()
{
	if (GetInputPressed(ReadCharacterID(PLAYER_ID).controller_id, "attack"))
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

void HandleDragging()
{
	if (maxEnergy == 0) return;

	MovementObject@ player = ReadCharacterID(PLAYER_ID);

	if (!dragging && GetInputDown(player.controller_id, "attack"))
	{
		dragging = true;
		startRay = camera.GetMouseRay();
	}
	else if (dragging && !GetInputDown(player.controller_id, "attack"))
	{
		dragging = false;
		endRay = camera.GetMouseRay();
		
		vec3 startPosition = camera.GetPos() + startRay * cameraDistance;
		vec3 endPosition = camera.GetPos() + endRay * cameraDistance;
		
		float requiredEnergy = distance(startPosition, endPosition);
		if (requiredEnergy < 0.95f || requiredEnergy > remainingEnergy) return;
		
		Object@ line = ReadObjectFromID(CreateObject("Data/Objects/Environment/sand.xml", true));
		lines.insertLast(line.GetID());
		
		line.SetTint(vec3(0.0f));
		
		vec3 scale = distance(startPosition, endPosition);
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
		
		remainingEnergy -= distance(startPosition, endPosition);
		
		GUI::SetEnergy(remainingEnergy, maxEnergy);
	}
	
	if (dragging)
	{
		vec3 startPosition = camera.GetPos() + startRay * cameraDistance;
		vec3 endPosition = camera.GetPos() + camera.GetMouseRay() * cameraDistance;
		
		vec3 lineColor;
		float requiredEnergy = distance(startPosition, endPosition);
		
		if (requiredEnergy < 0.95f || requiredEnergy > remainingEnergy) lineColor.x = 50.0f;
		else lineColor.y = 50.0f;
		
		DebugDrawLine(startPosition, endPosition, lineColor, _delete_on_update);
	}
}