ViewShader = newclass("ViewShader")

SHADER_ZOOM_DEFAULT = 2.0
SHADER_ZOOM_MIN = 0.5
SHADER_ZOOM_MAX = 10.0
SHADER_FARCLIP_DEFAULT = 1000.0
SHADER_FARCLIP_MIN = 100
SHADER_FARCLIP_MAX = 2000
SHADER_NEARCLIP_DEFAULT = 0.1
SHADER_NEARCLIP_MIN = -100.0
SHADER_NEARCLIP_MAX = 100.0
SHADER_SATURATION_DEFAULT = 1.0
SHADER_SATURATION_MIN = -6
SHADER_SATURATION_MAX = 6

function ViewShader:init()
  self.zoom = SHADER_ZOOM_DEFAULT
  self.farClip = SHADER_FARCLIP_DEFAULT
  self.nearClip = SHADER_NEARCLIP_DEFAULT
  self.saturation = SHADER_SATURATION_DEFAULT
  self.ligthing = true
  self.equalColor = false
  self.camera = getCamera()
  self.shader, self.tec = dxCreateShader( "fx/clientshader.fx", 0,0,false,"all")
  self.shaderEnabled = false
  
  self.lodModels = {}
  
  if self.shader then
    dxSetShaderValue( self.shader, "uScreenHeight", SCREEN_HEIGHT)
    dxSetShaderValue( self.shader, "uScreenWidth", SCREEN_WIDTH)
    outputChatBox("Loaded shader with tec: " ..self.tec)
  else
    outputChatBox("Could not load shader")
    --TODO error?
  end
end
--TODO does this work or does it always set self.lighting to true?
function ViewShader:setLightingEnabled(aValue)
	self.ligthing = aValue or true
	dxSetShaderValue( self.shader, "uLighting", self.ligthing)
end
function ViewShader:setEqualColorEnabled(aValue)
	self.equalColor = aValue or true
	dxSetShaderValue( self.shader, "uEqualColor", self.equalColor)
end
function ViewShader:setZoom(aValue) 
  self.zoom = aValue
  dxSetShaderValue( self.shader, "uZoom", self.zoom)
end
function ViewShader:setFarClip(aValue) 
  self.farClip = aValue 
  dxSetShaderValue( self.shader, "uFarClip", self.farClip)
end
function ViewShader:setNearClip(aValue) 
  self.nearClip = aValue 
  dxSetShaderValue( self.shader, "uNearClip", self.nearClip)
end
function ViewShader:setSaturation(aValue)
  self.saturation = aValue
  dxSetShaderValue( self.shader, "uSaturation", self.saturation)
end

function ViewShader:toggleShader()
  if(self.shaderEnabled) then
    self:disableShader()
  else
    self:enableShader()
  end
end

function ViewShader:enableShader()
  if(not self.shaderEnabled) then
    engineApplyShaderToWorldTexture ( self.shader, "*" )
    dxSetShaderValue( self.shader, "uZoom", self.zoom)
    dxSetShaderValue( self.shader, "uFarClip", self.farClip)
    dxSetShaderValue( self.shader, "uNearClip", self.nearClip)
    
    self.shaderEnabled = true
  end
end

function ViewShader:disableShader()
  if(self.shaderEnabled) then
    engineRemoveShaderFromWorldTexture ( self.shader, "*" )
    
    self.shaderEnabled = false
  end
end

function ViewShader:isShaderEnabled()
  return self.shaderEnabled
end

function ViewShader:getProjectionMatrix()
  local K = matrix{
    {0.63281273 / SCREEN_HEIGHT * self.zoom,0,0,0},
    {0,2.0 / SCREEN_WIDTH * self.zoom,0,0},
    {0,0,1.0 / (self.farClip - self.nearClip), -self.nearClip / (self.farClip - self.nearClip)},
    {0,0,0,1}
  }
  return K
end

function ViewShader:getViewMatrix()
  --Normalized fwVec and upVec.
  local cameraMatrix = getElementMatrix(getCamera())
  local pos = matrix{cameraMatrix[4][1],cameraMatrix[4][2],cameraMatrix[4][3]}
  local fwVec = matrix{cameraMatrix[2][1],cameraMatrix[2][2],cameraMatrix[2][3]}
  local upVec = matrix{cameraMatrix[3][1],cameraMatrix[3][2],cameraMatrix[3][3]}
  
  -- The "forward" vector.
  local zaxis = fwVec 
  -- The left vector.
  local temp_xaxis = matrix.cross( upVec, fwVec )
	--temp_xaxis_len = matrix.len(temp_xaxis)
    --xaxis = temp_xaxis / temp_xaxis_len-- The "right" vector.
  local xaxis = temp_xaxis
  -- The "up" vector.
  local yaxis = matrix.cross( zaxis, xaxis )

    -- Create a 4x4 view matrix from the right, up, forward and eye position vectors
  local viewMatrix = matrix{
        {      xaxis[1][1],            yaxis[1][1],            zaxis[1][1],       0 },
        {      xaxis[2][1],            yaxis[2][1],            zaxis[2][1],       0 },
        {      xaxis[3][1],            yaxis[3][1],            zaxis[3][1],       0 },
        {-matrix.scalar(xaxis,pos), -matrix.scalar(yaxis,pos), -matrix.scalar(zaxis,pos),  1 }
    }
  
    return viewMatrix;
end

function ViewShader:getInverseProjectionMatrix()
  return matrix.invert(self:getProjectionMatrix())
end

function ViewShader:getScreenFromWorldCoordinates(x,y,z)
  local worldPos = matrix{{x,y,z,1}}
  local projection = matrix.copy(self:getProjectionMatrix())
  local view = matrix.copy(self:getViewMatrix())
  
  local posWorldView = matrix.mul(worldPos,view)
  local position = matrix.mul(posWorldView, projection)
  
  position[1][1] = position[1][1] / position[1][4]
  position[1][2] = position[1][2] / position[1][4]
  
  position[1][1] = (position[1][1] + 1) * SCREEN_WIDTH / 2
  position[1][2] = (position[1][2] + 1) * SCREEN_HEIGHT / 2
  return position[1][1], position[1][2]
end

function ViewShader:getWorldFromPosition(x,y, worldZ)
  local x = (2.0 * x) / SCREEN_WIDTH - 1.0
  local y =  - 2.0 * y / SCREEN_HEIGHT + 1
  
  --Get World, View and Projection matrix.
  local world = matrix.transpose(matrix{{x,y,0,1}})
  local view = matrix.copy(self:getViewMatrix())
  local projection = matrix.copy(self:getProjectionMatrix())
  
  local viewProjection = matrix.mul(projection,view)
  
  --Get inverse of matrix.
  local inverseViewProjection = matrix.invert(matrix.copy(viewProjection))
  
  --Calculate world position.
  world = matrix.mul(matrix.copy(world),matrix.copy(inverseViewProjection))
  return world[1][1],world[1][2],0
end

function ViewShader:increaseObjectRenderDistance()
	for i,object in pairs (getElementsByType("object")) do
		local model = getElementModel(object)
		
		if model then
			local x,y,z = getElementPosition(object)
			local a,b,c = getElementRotation(object)
			self.lodModels[i] = createObject(model,x,y,z,a,b,c,true)
			setElementDimension(self.lodModels[i],getElementDimension(object))
			setObjectScale(self.lodModels[i],getObjectScale(object))
			setLowLODElement(object,self.lodModels[i])
			setElementDoubleSided(self.lodModels[i],isElementDoubleSided(object))
			engineSetModelLODDistance(model,1000)
		end
	end
end

function ViewShader:resetObjectRenderDistance()
	for i,object in pairs (self.lodModels) do
		destroyElement(object)
	end
end