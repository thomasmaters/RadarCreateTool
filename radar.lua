-- No touch, kthxbai
local tiles = { }
local timer
local enabled = true

local ROW_COUNT = 12
local CALIBRATION_OFFSET = 100

viewShader = nil;

local screen_x, screen_y = guiGetScreenSize()

uZoom = 2.0;
uFarClip = 1000.0;
uNearClip = 0.1;

function toggleCustomTiles ( )
	-- Toggle!
	disabled = not enabled
	
	-- Check whether we enabled it
	if enabled then
		-- Load all tiles
		handleTileLoading ( )
		
		-- Set a timer to check whether new tiles should be loaded (less resource hungry than doing it on render)
		timer = setTimer ( handleTileLoading, 250, 0 )
	else
		-- If our timer is still running, kill it with fire
		if isTimer ( timer ) then killTimer ( timer ) end
		
		-- Unload all tiles, so the memory footprint has disappeared magically
		for name, data in pairs ( tiles ) do
			unloadTile ( name )
		end
	end
end

function setupEnvironment()
	--setCameraTarget(getLocalPlayer())
	setCloudsEnabled(false)
	setFogDistance(1000)
	setFarClipDistance(1000)
	setHeatHaze(0)
	
	viewShader,tecName = dxCreateShader( "fx/clientshader.fx", 0,0,false,"all")
	engineApplyShaderToWorldTexture ( viewShader, "*" )
	
	local scx, scy = guiGetScreenSize()
	dxSetShaderValue( viewShader, "uScreenHeight", scy)
	dxSetShaderValue( viewShader, "uScreenWidth", scx)
	
	if viewShader then
		outputChatBox( "Shader using techinque " .. tecName )
	else
		outputChatBox( "Problem - use: debugscript 3" )
	end
	createUI()
	--increaseObjectRenderDistance()
end

function createUI()
	local WINDOW_WIDTH = 300
	local WINDOW_HEIGHT = 500
	local EDGE_OFFSET = 4
	local EDGE_OFFSET_L = EDGE_OFFSET + 10
	local ITEM_HEIGHT = 20
	local ITEM_WIDTH = WINDOW_WIDTH - 2 * EDGE_OFFSET
	local TOTAL_ITEM_HEIGHT = ITEM_HEIGHT + EDGE_OFFSET
	local UI_START = 20 + EDGE_OFFSET
	
	local mainWindow = GuiWindow(100,100,WINDOW_WIDTH,WINDOW_HEIGHT,"ANoniem's - Radar create tool",false)
	
			GuiLabel(EDGE_OFFSET_L ,	EDGE_OFFSET						,	ITEM_WIDTH,	ITEM_HEIGHT,"Zoommnmmmmmmmmmmmmmmm:",false,mainWindow)
	local zoomScroll = 
	guiCreateScrollBar(	EDGE_OFFSET,	UI_START + TOTAL_ITEM_HEIGHT	,	ITEM_WIDTH,	ITEM_HEIGHT,true,false,mainWindow)
	guiScrollBarSetScrollPosition(zoomScroll, map(2.0, 0.5, 10.0, 0, 100))
	
			GuiLabel(EDGE_OFFSET_L ,	UI_START + 2 * TOTAL_ITEM_HEIGHT,	ITEM_WIDTH,	ITEM_HEIGHT,"Far clip:",false,mainWindow)
	local farScroll = 
	guiCreateScrollBar(	EDGE_OFFSET,	UI_START + 3 * TOTAL_ITEM_HEIGHT,	ITEM_WIDTH,	ITEM_HEIGHT,true,false,mainWindow)	
	guiScrollBarSetScrollPosition(farScroll, map(1000.0, 100, 2000, 0, 100 ))
			
			GuiLabel(EDGE_OFFSET_L ,	UI_START + 4 * TOTAL_ITEM_HEIGHT,	ITEM_WIDTH,	ITEM_HEIGHT,"Near clip:",false,mainWindow)
	local nearScroll = 
	guiCreateScrollBar(	EDGE_OFFSET,	UI_START + 5 * TOTAL_ITEM_HEIGHT,	ITEM_WIDTH,	ITEM_HEIGHT,true,false,mainWindow)
	guiScrollBarSetScrollPosition(nearScroll, map(2.0, -100, 100, 0, 100))
	
			GuiLabel(EDGE_OFFSET_L ,	UI_START + 6 * TOTAL_ITEM_HEIGHT,	ITEM_WIDTH,	ITEM_HEIGHT,"Saturation:",false,mainWindow)
	local saturationScroll = 
	guiCreateScrollBar(	EDGE_OFFSET,	UI_START + 7 * TOTAL_ITEM_HEIGHT,	ITEM_WIDTH,	ITEM_HEIGHT,true,false,mainWindow)
	guiScrollBarSetScrollPosition(saturationScroll, map(1.0, -6, 6, 0, 100))
	
	local checkLighting = 
		GuiCheckBox(	EDGE_OFFSET,	UI_START + 8 * TOTAL_ITEM_HEIGHT,	ITEM_WIDTH,	ITEM_HEIGHT,"Lighting",true,false,mainWindow)
	local checkAverageTexColor = 
		GuiCheckBox(	EDGE_OFFSET,	UI_START + 9 * TOTAL_ITEM_HEIGHT,	ITEM_WIDTH,	ITEM_HEIGHT,"Equal color (Might not work with textures with alpha)",false,false,mainWindow)
	local checkEdgeFade = 
		GuiCheckBox(	EDGE_OFFSET,	UI_START + 10 * TOTAL_ITEM_HEIGHT,	ITEM_WIDTH,	ITEM_HEIGHT,"Fade radar edge to alpha",false,false,mainWindow)
	local checkOneTexture =
		GuiCheckBox(	EDGE_OFFSET,	UI_START + 11 * TOTAL_ITEM_HEIGHT,	ITEM_WIDTH,	ITEM_HEIGHT,"Output as one texture",false,false,mainWindow)
	
	local qualityComboBox = 
		GuiComboBox(	EDGE_OFFSET,	UI_START + 12 * TOTAL_ITEM_HEIGHT,	ITEM_WIDTH,	ITEM_HEIGHT,"Output Quality",false,mainWindow)
	qualityComboBox:addItem("4 units : 1 pixel (default)")
	qualityComboBox:addItem("2 units : 1 pixel")
	qualityComboBox:addItem("1 units : 1 pixel")
	qualityComboBox:addItem("1 units : 2 pixel")
	qualityComboBox:setSelected(0) --Select the first item.
	
			GuiLabel(EDGE_OFFSET_L ,	UI_START + 13 * TOTAL_ITEM_HEIGHT,	ITEM_WIDTH,	ITEM_HEIGHT,"Top-Left corner of map:",false,mainWindow)
	local buttonTopLeft = 
			GuiButton(	EDGE_OFFSET,	UI_START + 14 * TOTAL_ITEM_HEIGHT,	ITEM_WIDTH,	ITEM_HEIGHT,"Set to current position",false,mainWindow)
			GuiLabel(EDGE_OFFSET_L ,	UI_START + 15 * TOTAL_ITEM_HEIGHT,	ITEM_WIDTH,	ITEM_HEIGHT,"Bottom-Right corner of map:",false,mainWindow)
	local buttonBottomRight = 
			GuiButton(	EDGE_OFFSET,	UI_START + 16 * TOTAL_ITEM_HEIGHT,	ITEM_WIDTH,	ITEM_HEIGHT,"Set to current position",false,mainWindow)
	local buttonStart = 
			GuiButton(	EDGE_OFFSET,	UI_START + 17 * TOTAL_ITEM_HEIGHT,	ITEM_WIDTH,	ITEM_HEIGHT,"Create map",false,mainWindow)
		
	addEventHandler("onClientGUIClick", checkLighting, 
	function(button) 
		if(button == "left") then
			dxSetShaderValue( viewShader, "uLighting", checkLighting:getSelected())
		end
	end, 
	false)
	
	addEventHandler("onClientGUIClick", checkAverageTexColor, 
	function(button) 
		if(button == "left") then
			dxSetShaderValue( viewShader, "uEqualColor", checkAverageTexColor:getSelected())
		end
	end, 
	false)
	
	addEventHandler("onClientGUIClick", buttonTopLeft, 
	function(button) 
		if(button == "left") then
			local x,y,z = getElementPosition(getLocalPlayer())		
			buttonTopLeft:setText(string.format("x: %.2f y: %.2f z: %.2f", x,y,z))
		end
	end, 
	false)
	
	addEventHandler("onClientGUIClick", buttonStart, 
	function(button) 
		if(button == "left") then
			syncCamera()
		end
	end, 
	false)
	
	addEventHandler("onClientGUIClick", buttonBottomRight, 
	function(button) 
		if(button == "left") then
			local x,y,z = getElementPosition(getLocalPlayer())
			buttonBottomRight:setText(string.format("x: %.2f y: %.2f z: %.2f", x,y,z))
		end
	end, 
	false)
	
	addEventHandler ( "onClientGUIComboBoxAccepted", guiRoot,
    function ( comboBox )
		if(comboBox == qualityComboBox) then
			local selectedIndex = qualityComboBox:getSelected()
		end
	end
	)
	
	--Scroll callback.
	addEventHandler( "onClientGUIScroll", root, function()
		if(source == zoomScroll) then
			uZoom = map(guiScrollBarGetScrollPosition(source), 0, 100, 0.5, 10.0)
			dxSetShaderValue( viewShader, "uZoom", uZoom)
			outputChatBox(uZoom)
		elseif(source == nearScroll) then
			uNearClip = map(guiScrollBarGetScrollPosition(source), 0, 100, -20, 1)
			dxSetShaderValue( viewShader, "uNearClip", uNearClip)
			outputChatBox(uNearClip)
		elseif(source == farScroll) then
			uFarClip = map(guiScrollBarGetScrollPosition(source), 0, 100, 100, 2000)
			dxSetShaderValue( viewShader, "uFarClip", uFarClip)
			outputChatBox(uFarClip)
		elseif(source == saturationScroll) then
			outputChatBox(tostring(map(guiScrollBarGetScrollPosition(source), 0, 100, -6, 6)))
			dxSetShaderValue( viewShader, "uSaturation", map(guiScrollBarGetScrollPosition(source), 0, 100, -6, 6))
		end
	end
	)
end

function map(x, in_min, in_max, out_min, out_max) 
  return (x - in_min) * (out_max - out_min) / (in_max - in_min) + out_min
end

function getProjectionMatrix()
	K = matrix{
		{0.6328 / screen_y * uZoom,0,0,0},
		{0,2.0 / screen_x * uZoom,0,0},
		{0,0,1.0 / (uFarClip - uNearClip), -uNearClip/(uFarClip-uNearClip)},
		{0,0,0,1}
	}
	return K
end

function getViewMatrix()
--sCameraPosition, sCameraForward, sCameraUp
	local cameraMatrix = getElementMatrix(getCamera())
	local pos = matrix{cameraMatrix[4][1],cameraMatrix[4][2],cameraMatrix[4][3]}
	local fwVec = matrix{cameraMatrix[2][1],cameraMatrix[2][2],cameraMatrix[2][3]}
	local upVec = matrix{cameraMatrix[3][1],cameraMatrix[3][2],cameraMatrix[3][3]}
	
	--fwVec = fwVec - pos
	--fwLen = matrix.len(fwVec)
    zaxis = fwVec    -- The "forward" vector.
	temp_xaxis = matrix.cross( upVec, fwVec )
	--temp_xaxis_len = matrix.len(temp_xaxis)
    --xaxis = temp_xaxis / temp_xaxis_len-- The "right" vector.
	xaxis = temp_xaxis
    yaxis = matrix.cross( zaxis, xaxis )-- The "up" vector.

    -- Create a 4x4 view matrix from the right, up, forward and eye position vectors
    viewMatrix = matrix{
        {      xaxis[1][1],            yaxis[1][1],            zaxis[1][1],       0 },
        {      xaxis[2][1],            yaxis[2][1],            zaxis[2][1],       0 },
        {      xaxis[3][1],            yaxis[3][1],            zaxis[3][1],       0 },
        {-matrix.scalar(xaxis,pos), -matrix.scalar(yaxis,pos), -matrix.scalar(zaxis,pos),  1 }
    }
	
    return viewMatrix;
end

function getInverseProjectionMatrix()
	return matrix.invert(getProjectionMatrix())
end

function getScreenFromWorldCoordinates(x,y,z)
	local worldPos = matrix{{x,y,z,1}}
	local projection = matrix.copy(getProjectionMatrix())
	local view = matrix.copy(getViewMatrix())
	
	local posWorldView = matrix.mul(worldPos,view)
	local position = matrix.mul(posWorldView, projection)
	
	position[1][1] = position[1][1] / position[1][4]
	position[1][2] = position[1][2] / position[1][4]
	
	position[1][1] = (position[1][1] + 1) * screen_x / 2
	position[1][2] = (position[1][2] + 1) * screen_y / 2
	return position[1][1], position[1][2]
end

function getWorldFromPosition(x,y, worldZ)
        x = (2.0 * x) / screen_x - 1.0
        y =  - 2.0 * y / screen_y + 1
	local world = matrix.transpose(matrix{{x,y,0,1}})
	--outputChatBox("GOT WORLD" .. #world .. " ".. #world[1].. ": " ..tostring(world) )
	local view = matrix.copy(getViewMatrix())
	--outputChatBox("GOT VIEW" .. #view .. " ".. #view[1])--.. ": " .. tostring(view))
	local projection = matrix.copy(getProjectionMatrix())
	--outputChatBox("GOT PROJECTION" .. #projection .. " ".. #projection[1])--.. ": "  .. tostring(projection))
	--local projectionInverse = matrix.invert(projection)
	--local viewInverse = matrix.invert(view)
	--local posWorldView = matrix.mul(world,view)
	--world = matrix.mul(posWorldView,projection)
	local viewProjection = matrix.mul(projection,view)
	
	
	--local inverseViewProjection = matrix.mul(projectionInverse,viewInverse)
	--outputChatBox("GOT VIEWPROJECTION" .. #viewProjection .. " ".. #viewProjection[1])
	local inverseViewProjection = matrix.invert(matrix.copy(viewProjection))
	--outputChatBox("GOT INVERSEVIEWPROJECTION" .. #inverseViewProjection .. " ".. #inverseViewProjection[1])
	world = matrix.mul(matrix.copy(world),matrix.copy(inverseViewProjection))
	--outputChatBox("GOT RESULT " ..tostring(world))
	--[[world[1][4] = 1 / world[1][4]
	world[1][1] = world[1][1] * world[1][4]
	world[1][2] = world[1][2] * world[1][4]
	world[1][3] = world[1][3] * world[1][4]
	outputChatBox("GOT RESULT " ..tostring(world))]]
	--outputChatBox(tostring(matrix.mul(matrix.invert(projection),matrix.transpose(world))))
	return world[1][1],world[1][2],0
	--[[local cam_x, cam_y, cam_z, cam_lx, cam_ly, cam_lz = getCameraMatrix ()
	local x_world = (x - screen_x / 2) * worldZ / cam_x
	local y_world = (y - screen_y / 2) * worldZ / cam_y
	return x_world, y_world, 0]]
end
addEventHandler ( "onClientResourceStart", getResourceRootElement(getThisResource()), setupEnvironment)

function startMapMaking(x_step,y_step)
	--How many pictures do we need to take?
	local max_steps_x,max_steps_y = 10,10
	
	local screen_x, screen_y = guiGetScreenSize()
	local x,y,z = getElementPosition(getLocalPlayer())
	local cameraOffset = 200
	
	setElementFrozen(getLocalPlayer(),true)
	
	i,j = x,y
	
	--Create output texture
    new_radar_map_picture= fileCreate("gta_radar_"..getTickCount()..".jpeg")
	--Pixels to grab.
	local x_pixels,y_pixels = 512 ,512
	
	screen_picture = dxCreateScreenSource(screen_x  ,screen_y )	
	main_image = dxCreateTexture(x_pixels * max_steps_x, y_pixels * max_steps_y)
	current_b,current_l = 0,0
	
		main_timer = setTimer(function()
			setElementPosition(getLocalPlayer(), i + current_b * x_step,j + current_l * y_step,cameraOffset + 5)
			setCameraMatrix(i + current_b * x_step,j + current_l * y_step,cameraOffset,
							i + current_b * x_step,j + current_l * y_step,0)
			
			setTimer(function()
				dxUpdateScreenSource( screen_picture )
				screen_part = dxGetTexturePixels(screen_picture, 
					screen_x / 2 - x_pixels / 2, 
					screen_y / 2 - y_pixels / 2,
					x_pixels, 
					y_pixels)
				
				if not screen_part then
					killTimer(main_timer)
				end
				dxSetTexturePixels(main_image,
					screen_part,
					current_b * x_pixels,
					(max_steps_y-current_l - 1) * y_pixels,
					x_pixels,
					y_pixels)
				
				outputChatBox(current_b .."   ".. current_l)
				current_b = current_b + 1
				if current_b == max_steps_x then
					current_l = current_l + 1
					current_b = 0
				end
			end,500,1)
		end,1000,max_steps_x * max_steps_y + 1)
		
		setTimer(function()
			local pixels_to_file = dxConvertPixels(dxGetTexturePixels(main_image),"jpeg")
			fileWrite(new_radar_map_picture,pixels_to_file)
			fileClose(new_radar_map_picture)
		end, (max_steps_x * max_steps_y) * 1100 ,1)
end

function syncCamera()
	local x,y,z = getElementPosition(getLocalPlayer())
	--Set lookat
	setCameraMatrix(x,y,z,cameraOffset,x,y,0)
	--Set rotation
	setElementRotation(getCamera(),270,0,0)
	
	--Sleep 100ms to let mta catchup and render at least one frame before continuing.
	setTimer(function() 
		local x_tl, y_tl = getScreenFromWorldCoordinates(x + CALIBRATION_OFFSET,y + CALIBRATION_OFFSET,0)
		local x_br, y_br = getScreenFromWorldCoordinates(x - CALIBRATION_OFFSET,y - CALIBRATION_OFFSET,0)
		
		local x_pixel_offset = math.abs(x_tl - x_br)
		local y_pixel_offset = math.abs(y_tl - y_br)
		
		local x_pixels_world_unit = (2 * CALIBRATION_OFFSET) / x_pixel_offset
		local y_pixels_world_unit = (2 * CALIBRATION_OFFSET) / y_pixel_offset
		
		startMapMaking(x_pixels_world_unit * 512, y_pixels_world_unit * 512)
	end, 100,1)
end

function handleTileLoading ( )
	-- Get all visible radar textures
	local visibleTileNames = table.merge ( engineGetVisibleTextureNames ( "radar??" ), engineGetVisibleTextureNames ( "radar???" ) )
	
	-- Unload tiles we don't see
	for name, data in pairs ( tiles ) do
		if not table.find ( visibleTileNames, name ) then
			unloadTile ( name )
		end
	end
	
	-- Load tiles we do see
	for index, name in ipairs ( visibleTileNames ) do
		loadTile ( name )
	end
end

function table.merge ( ... )
	local ret = { }
	
	for index, tbl in ipairs ( {...} ) do
		for index, val in ipairs ( tbl ) do
			table.insert ( ret, val )
		end
	end
	
	return ret
end

function table.find ( tbl, val )
	for index, value in ipairs ( tbl ) do
		if value == val then
			return index
		end
	end
	
	return false
end

-------------------------------------------
--
-- Tile loading and unloading functions
--
-------------------------------------------

function loadTile ( name )
	-- Make sure we have a string
	if type ( name ) ~= "string" then
		return false
	end
	
	-- Check whether we already loaded this tile
	if tiles[name] then
		return true
	end
	
	-- Extract the ID
	local id = tonumber ( name:match ( "%d+" ) )
	
	-- If not a valid ID, abort
	if not id then
		return false
	end
	
	-- Calculate row and column
	local row = math.floor ( id / ROW_COUNT )
	local col = id - ( row * ROW_COUNT )
	
	-- Now just calculate start and end positions
	local posX = -3000 + 500 * col
	local posY =  3000 - 500 * row
	
	-- Fetch the filename
	local file = string.format ( "sattelite/sattelite_%d_%d.jpeg", row, col )
	
	-- Now, load that damn file! (Also create a transparent overlay texture)
	local texture = dxCreateTexture ( file )
	
	-- If it failed to load, abort
	if not texture --[[or not overlay]] then
		outputChatBox ( string.format ( "Failed to load texture for %q (%q)", tostring ( name ), tostring ( file ) ) )
		return false
	end
	
	-- Now we just need the shader
	local shader = dxCreateShader ( "fx/texturereplace.fx" )
	
	-- Abort if failed (don't forget to destroy the texture though!!!)
	if not shader then
		outputChatBox ( "Failed to load shader" )
		destroyElement ( texture )
		return false
	end
	
	-- Now hand the texture to the shader
	dxSetShaderValue ( shader, "gTexture", texture )
	
	-- Now apply this stuff on the tile
	engineApplyShaderToWorldTexture ( shader, name )
	
	-- Store the stuff
	tiles[name] = { shader = shader, texture = texture }
	
	-- Return success
	return true
end

function unloadTile ( name )
	-- Get the tile data
	local tile = tiles[name]
	
	-- If no data is present, we failed
	if not tile then
		return false
	end
	
	-- Destroy the shader and texture elements, if they exist
	if isElement ( tile.shader )  then destroyElement ( tile.shader )  end
	if isElement ( tile.texture ) then destroyElement ( tile.texture ) end
	
	-- Now remove all reference to it
	tiles[name] = nil
	
	-- We succeeded
	return true
end