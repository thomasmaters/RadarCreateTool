RadarCreate = newclass("RadarCreate")

CAMERA_OFFSET = 200
SCREEN_CAPTURE_SIZE = 512
CALIBRATION_OFFSET = 100
VISUALIZE_Z_OFFSET = 100

function RadarCreate:init()
  self.camera = getCamera()
  self.mainTimer = nil
  self.subTimer = nil
  self.mapMakeProgress = 0
  self.maxColumns = 0
  self.maxRows = 0
  self.screenSource = dxCreateScreenSource(SCREEN_WIDTH ,SCREEN_HEIGHT ) 
  self.bottomLeftCoordinate = Vector3()
  self.topRightCoordinate = Vector3()
  self.outputTexture = nil
  self.saveRadarParts = false
  
  addEventHandler("onClientRender",getRootElement(), self.drawInWorld)
end

function RadarCreate:enableSavingRadarParts()
  if(not self.saveRadarParts) then
    self.saveRadarParts = true
  end
end

function RadarCreate:disableSavingRadarParts()
  if(self.saveRadarParts) then
    self.saveRadarParts = false
  end
end

function RadarCreate:isMapMaking()
  if(self.mainTimer ~= nil or self.subTimer ~= nil) then
    return true
  end
  return false
end

function RadarCreate:stopMapMaking()
  if(isTimer(self.mainTimer)) then
    killTimer(self.mainTimer)
    self.mainTimer = nil --Nil out timer to prevent timer id reuse bugs.
  end
  if(isTimer(self.subTimer)) then
    killTimer(self.subTimer) 
    self.subTimer = nil --Nil out timer to prevent timer id reuse bugs.
  end
end

function RadarCreate:startMapMaking(x_step,y_step)
  removeEventHandler("onClientRender",getRootElement(), self.drawInWorld)

  --How many pictures do we need to take?
  self.maxColumns,self.maxRows = self:calculateSteps(x_step, y_step)
  
  local start_x,start_y = self.bottomLeftCoordinate.x, self.bottomLeftCoordinate.y

  --Create output texture
  self:createOutputTexture()
  local current_b,current_l = 0,0
  
  self.mainTimer = Timer(function()
    --Set the players camera matrix looking down.
    self:setCameraToGrid(current_b, current_l, x_step, y_step)
        
    --Timer to let the world render a bit before grabbing the screen source.
    self.subTimer = setTimer(function()
      self:grabScreenPixels(current_b, current_l) 
      --Next step.
      current_b = current_b + 1
      if current_b == self.maxColumns then
        current_l = current_l + 1
        
        if (current_l == self.maxRows and current_b == self.maxColumns) then
          --TODO will keyword 'local' here not lose its resources when passed to a function?
          local new_radar_map_file = fileCreate("gta_radar_"..getTickCount()..".jpeg")
          --Save outputTexture to file.
          self:savePicture(self.outputTexture, new_radar_map_file)
          
          self:mapMakingFinished()
          return
        end
        
        current_b = 0
        end
      end,500,1)
    end,1000,self.maxColumns * self.maxRows)
end

function RadarCreate:mapMakingFinished()
  addEventHandler("onClientRender",getRootElement(), self.drawInWorld)
  --Update the UI.
  GlobalUI:mapMakingFinished() 
end

function RadarCreate:calculateSteps(x_step, y_step)
  local delta_x_world_units = math.abs(self.bottomLeftCoordinate.x - self.topRightCoordinate.x)
  local delta_y_world_units = math.abs(self.bottomLeftCoordinate.y - self.topRightCoordinate.y)
  
  local x_columns = math.ceil(delta_x_world_units / x_step)
  local y_rows = math.ceil(delta_y_world_units / y_step)
  
  return x_columns, y_rows
end

function RadarCreate:setCamera(aX, aY)
  setElementPosition(getLocalPlayer(),aX,aY, CAMERA_OFFSET + 5)
  setCameraMatrix(aX, aY, CAMERA_OFFSET, aX, aY, 0)
  outputChatBox(aX .." ".. aY)
  
  setElementRotation(getCamera(),270, 0, 0)
end

--Create an ouput texture if we have don't have an output texture or the size of the output texture is not the same.
function RadarCreate:createOutputTexture()
  if(self.maxRows > 0 and self.maxColumns > 0) then
    if(self.outputTexture == nil) then
      self.outputTexture = dxCreateTexture(SCREEN_CAPTURE_SIZE * self.maxColumns, SCREEN_CAPTURE_SIZE * self.maxRows)
    else
      --Does size match?
      local texture_x, texture_y = self.outputTexture:getSize()
      if((self.maxColumns * SCREEN_CAPTURE_SIZE) ~= texture_x or (self.maxRows * SCREEN_CAPTURE_SIZE) ~= texture_y ) then
        self.outputTexture = dxCreateTexture(SCREEN_CAPTURE_SIZE * self.maxColumns, SCREEN_CAPTURE_SIZE * self.maxRows)
      end
    end
  else
    self:setCameraToGrid(0,0)
    self:createOutputTexture()
  end
end

function RadarCreate:setCameraToGrid(current_b, current_l, x_step, y_step)
  local start_x,start_y = self.bottomLeftCoordinate.x, self.bottomLeftCoordinate.y
  
  --Do we have a valid input for the grid positions we want to visit.
  if(current_b < 0 or current_b > self.maxColumns or current_l < 0 or current_l > self.maxRows) then
    return
  end
  
  --Set the camera to that column and row
  self:setCamera(start_x + current_b * x_step * SCREEN_CAPTURE_SIZE,start_y + current_l * y_step * SCREEN_CAPTURE_SIZE)
end

function RadarCreate:grabScreenPixels(current_b, current_l)
  dxUpdateScreenSource( self.screenSource )
  
  --Get a square from the center.
  local screen_part = dxGetTexturePixels(self.screenSource , 
    SCREEN_WIDTH / 2 - SCREEN_CAPTURE_SIZE / 2, 
    SCREEN_HEIGHT / 2 - SCREEN_CAPTURE_SIZE / 2,
    SCREEN_CAPTURE_SIZE, 
    SCREEN_CAPTURE_SIZE)
  
  --Safe smaller textures to a file if we want to.
  if(self.saveRadarParts) then
    local radar_part_file = File.new(string.format("radar/gta_radar_%d_%d.jpeg", current_b, current_l))
    local radar_part_texture = dxCreateTexture(SCREEN_CAPTURE_SIZE, SCREEN_CAPTURE_SIZE)
    self:savePicture(radar_part_texture, radar_part_file)
  end
  
  --Kill the loop if we didn't grab the pixels.
  if not screen_part then
    stopMapMaking()
  end
  
  --Set the pixels of the big texture.
  dxSetTexturePixels(self.outputTexture,
    screen_part,
    current_b * SCREEN_CAPTURE_SIZE,
    (self.maxRows - current_l - 1) * SCREEN_CAPTURE_SIZE,
    SCREEN_CAPTURE_SIZE,
    SCREEN_CAPTURE_SIZE)
end

function RadarCreate:savePicture(texture, file)
  if(file == nil) then
	  outputChatBox("No file specified")
    file = fileCreate("unnamed_image_"..getTickCount()..".jpeg")
  end
  local pixels_to_file = dxConvertPixels(dxGetTexturePixels(texture),"jpeg")
  fileWrite(file,pixels_to_file)
  fileClose(file)
end

function RadarCreate:syncCamera()
  setElementFrozen(getLocalPlayer(), true)  
  --Set the camera to the correct place and rotation.
  local x,y,z = getElementPosition(getLocalPlayer())
  self:setCamera(x,y)
  
  --Sleep 100ms to let mta catchup and render at least one frame before continuing.
  setTimer(function() 
    local x_pixels_world_unit, y_pixels_world_unit = self:getPixelsPerWorldUnit()
	outputChatBox("Calib offset: " ..CALIBRATION_OFFSET.. " x_pixel: " ..(x_pixels_world_unit * SCREEN_CAPTURE_SIZE).. " y_pixel: " ..(y_pixels_world_unit * SCREEN_CAPTURE_SIZE))
	
    self:startMapMaking(x_pixels_world_unit * SCREEN_CAPTURE_SIZE, y_pixels_world_unit * SCREEN_CAPTURE_SIZE)
  end, 100,1)
end

function RadarCreate:drawInWorld()
  local x_pixels_world_unit, y_pixels_world_unit = self:getPixelsPerWorldUnit()
  local x_step, y_step = x_pixels_world_unit * SCREEN_CAPTURE_SIZE, y_pixels_world_unit * SCREEN_CAPTURE_SIZE
  local _,_,z = getElementPosition(getLocalPlayer())
  local start_x, start_y = self.bottomLeftCoordinate.x, self.bottomLeftCoordinate.y
  
  --Draw vertical lines.
  for i=0, self.maxRows do
	  for j=0, self.maxColumns do
	    --TODO do we need to flip the i and the j in this loop?
      local x = start_x + i * x_step * SCREEN_CAPTURE_SIZE 
      local y = start_y + j * y_step * SCREEN_CAPTURE_SIZE
      dxDrawLine3D(x, y, z - VISUALIZE_Z_OFFSET, x, y, z + VISUALIZE_Z_OFFSET)
    end
  end
  
  --Draw horizontal lines.
  for i=0, self.maxRows - 1 do
    for j=0, self.maxColumns - 1 do
      --TODO do we need to flip the i and the j in this loop?
      local x1 = start_x + i * x_step * SCREEN_CAPTURE_SIZE 
      local y1 = start_y + j * y_step * SCREEN_CAPTURE_SIZE
      local x2 = start_x + (i + 1) * x_step * SCREEN_CAPTURE_SIZE 
      local y2 = start_y + (j + 1) * y_step * SCREEN_CAPTURE_SIZE
      dxDrawLine3D(x1, y1, z, x2, y2, z)
    end
  end  
end

function RadarCreate:getPixelsPerWorldUnit()
	local x,y,z = getElementPosition(getLocalPlayer())
    local x_tl, y_tl = GlobalViewShader:getScreenFromWorldCoordinates(x + CALIBRATION_OFFSET,y + CALIBRATION_OFFSET,0)
    local x_br, y_br = GlobalViewShader:getScreenFromWorldCoordinates(x - CALIBRATION_OFFSET,y - CALIBRATION_OFFSET,0)
    
    local x_pixel_offset = math.abs(x_tl - x_br)
    local y_pixel_offset = math.abs(y_tl - y_br)
    
    local x_pixels_world_unit = (2 * CALIBRATION_OFFSET) / x_pixel_offset
    local y_pixels_world_unit = (2 * CALIBRATION_OFFSET) / y_pixel_offset
	
	return x_pixels_world_unit, y_pixels_world_unit
end