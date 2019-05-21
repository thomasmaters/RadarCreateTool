RadarCreate = newclass("RadarCreate")

CAMERA_OFFSET = 200
SCREEN_CAPTURE_SIZE = 512
CALIBRATION_OFFSET = 100

function RadarCreate:init()
  self.camera = getCamera()
  self.mainTimer = nil
  self.subTimer = nil
  self.mapMakeProgress = 0
  self.screenSource = dxCreateScreenSource(SCREEN_WIDTH ,SCREEN_HEIGHT ) 
  outputChatBox("SCREEN WIDTH: " ..SCREEN_WIDTH.. " SCREEN HEIGHT: ".. SCREEN_HEIGHT )
  outputChatBox("SCREEN CAP SIZE: "..SCREEN_CAPTURE_SIZE)
  self.bottomLeftCoordinate = Vector3()
  self.topRightCoordinate = Vector3()
end

function RadarCreate:setCamera(aX, aY)
  --TODO does this work?
  setElementPosition(getLocalPlayer(),aX,aY, CAMERA_OFFSET + 5)
  setCameraMatrix(aX, aY, CAMERA_OFFSET, aX, aY, 0)
  outputChatBox(aX .." ".. aY)
  
  setElementRotation(getCamera(),270, 0, 0)
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
outputChatBox("xstep: " ..x_step.. " ystep: " ..y_step)
  --How many pictures do we need to take?
  local max_steps_x,max_steps_y = 10,29
  
  local x,y,_ = getElementPosition(getLocalPlayer())
  local start_x,start_y = x,y
  
  --Create output texture
  new_radar_map_picture = fileCreate("gta_radar_"..getTickCount()..".jpeg")

  local main_image = dxCreateTexture(SCREEN_CAPTURE_SIZE * max_steps_x, SCREEN_CAPTURE_SIZE * max_steps_y)
  local current_b,current_l = 0,0
  
  self.mainTimer = Timer(function()
      --Set the players camera matrix looking down.
	setElementPosition(getLocalPlayer(), start_x + current_b * x_step,start_y + current_l * y_step,200 + 5)
	setCameraMatrix(start_x + current_b * x_step,start_y + current_l * y_step,200,
					start_x + current_b * x_step,start_y + current_l * y_step,0)
					
	local cx, cy, cz, clx, cly, clz = getCameraMatrix () 
	outputChatBox((start_x + current_b * x_step) .." ".. (start_y + current_l * y_step))
	outputChatBox((cx) .." ".. (cy))
      --self:setCamera(start_x + current_b * x_step,start_y + current_l * y_step)
      
      --Timer to let the world render a bit before grabbing the screen source.
      self.subTimer = setTimer(function()
        dxUpdateScreenSource( self.screenSource )
        
        --Get a square from the center.
        local screen_part = dxGetTexturePixels(self.screenSource , 
          SCREEN_WIDTH / 2 - SCREEN_CAPTURE_SIZE / 2, 
          SCREEN_HEIGHT / 2 - SCREEN_CAPTURE_SIZE / 2,
          SCREEN_CAPTURE_SIZE, 
          SCREEN_CAPTURE_SIZE)
        
        --TODO safe smaller textures if we want to.
        
        --Kill it the loop if we didn't grab the pixels.
        if not screen_part then
          stopMapMaking()
        end
        
        --Set the pixels of the big texture.
        dxSetTexturePixels(main_image,
          screen_part,
          current_b * SCREEN_CAPTURE_SIZE,
          (max_steps_y-current_l - 1) * SCREEN_CAPTURE_SIZE,
          SCREEN_CAPTURE_SIZE,
          SCREEN_CAPTURE_SIZE)
        
        --Next step.
        current_b = current_b + 1
		if current_b == max_steps_x then
          current_l = current_l + 1
		  
		  outputChatBox(current_b .." ".. current_l)
		  if (current_l == max_steps_y and current_b == max_steps_x) then
			self:savePicture(main_image, new_radar_map_picture)
			GlobalViewShader:toggleShader()
			return
		  end
		  
          current_b = 0
        end
      end,500,1)
    end,1000,max_steps_x * max_steps_y)
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
  end, 1000,1)
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