#include "magic-mouse/gui.as"

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

float timestampLevelStart = 0.0f;

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
	GUI::Init();
	GUI::SetEnergy(remainingEnergy, maxEnergy);
}

void Update(int is_paused)
{
	if (!postInit)
	{
		postInit = true;
		
		timestampLevelStart = ImGui_GetTime();
		
		Object@ playerObject = ReadObjectFromID(PLAYER_ID);
		playerObject.SetDeletable(false);
		playerObject.SetCopyable(false);
		playerObject.SetRotatable(false);
		playerObject.SetScalable(false);
		
		Object@ startObject = ReadObjectFromID(START_ID);
		startObject.SetDeletable(false);
		startObject.SetCopyable(false);
		startObject.SetRotatable(false);
		startObject.SetScalable(false);
		
		Object@ finishObject = ReadObjectFromID(FINISH_ID);
		finishObject.SetDeletable(false);
		finishObject.SetCopyable(false);
		finishObject.SetRotatable(false);
		finishObject.SetScalable(false);
		
		zAxisStickValue = playerObject.GetTranslation().z;
	}
		
	GUI::SetTimer(timestampLevelStart);
	
	MovementObject@ player = ReadCharacterID(PLAYER_ID);
	player.position.z = zAxisStickValue;
	
	vec3 finishLocation = ReadObjectFromID(FINISH_ID).GetTranslation();
	
	bool xOK = abs(player.position.x - finishLocation.x) <= 1.0f;
	bool bottomOK = player.position.y >= finishLocation.y + 1.0f;
	bool topOK = player.position.y <= finishLocation.y + 1.5f;
	bool zOK = abs(finishLocation.z - player.position.z) <= 0.5f;
	
	if (xOK && bottomOK && topOK && zOK)
		Log(fatal, ImGui_GetTime() + " Level won!");
	
	if (EditorModeActive() || GetMenuPaused())
	{	
		// Otherwise if the player holds + or - while closing the menu, the camera will jump.
		timestampLastUpdate = ImGui_GetTime();
		return;
	}

	HandleScriptParams();
	HandleCamera();
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
		
		remainingEnergy = maxEnergy;
		GUI::SetEnergy(maxEnergy, maxEnergy);
		
		cameraDistance = DEFAULT_CAMERA_DISTANCE;
		
		zAxisStickValue = ReadObjectFromID(PLAYER_ID).GetTranslation().z;
	}
	else if (ti.GetToken(message) == "tdh-teleported")
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
	if (!scriptParams.HasParam("Max Energy"))
	{
		scriptParams.AddInt("Max Energy", 100);
		maxEnergy = 100.0f;
		remainingEnergy = 100.0f;
		
		GUI::SetEnergy(maxEnergy, maxEnergy);
	}
	
	int levelEnergy = scriptParams.GetInt("Max Energy");
	if (levelEnergy < 0 || levelEnergy > 10000)
	{
		levelEnergy = (levelEnergy < 0) ? 0 : 10000;
		scriptParams.SetInt("Max Energy", levelEnergy);
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