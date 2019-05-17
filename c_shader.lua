ViewShader = newclass("ViewShader")

function ViewShader:init()
  self.zoom = 2.0
  self.farClip = 1000.0
  self.nearClip = 0.1
  self.saturation = 1.0
  self.ligthing = true
  self.equalColor = false
  self.camera = getCamera()
  self.shader, tec = dxCreateShader( "fx/clientshader.fx", 0,0,false,"all")
  self.shaderEnabled = false
  
  if viewShader then
    dxSetShaderValue( self.shader, "uScreenHeight", SCREEN_HEIGHT)
    dxSetShaderValue( self.shader, "uScreenWidth", SCREEN_WIDTH)
  else
    --TODO error?
  end
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
    engineRemoveShaderFromWorldTexture ( self.shader, "*" )
  else
    engineApplyShaderToWorldTexture ( self.shader, "*" )
  end
  self.shaderEnabled = not self.shaderEnabled
end

function ViewShader:isShaderEnabled()
  return self.shaderEnabled
end

function ViewShader:getProjectionMatrix()
  local K = matrix{
    {0.6328 / SCREEN_HEIGHT * self.zoom,0,0,0},
    {0,2.0 / SCREEN_WIDTH * self.zoom,0,0},
    {0,0,1.0 / (self.farClip - self.nearClip), -self.nearClip / (self.farClip - self.nearClip)},
    {0,0,0,1}
  }
  return K
end

function ViewShader:getViewMatrix()
  --Normalized fwVec and upVec.
  local cameraMatrix = getElementMatrix(self.camera)
  local pos = matrix{cameraMatrix[4][1],cameraMatrix[4][2],cameraMatrix[4][3]}
  local fwVec = matrix{cameraMatrix[2][1],cameraMatrix[2][2],cameraMatrix[2][3]}
  local upVec = matrix{cameraMatrix[3][1],cameraMatrix[3][2],cameraMatrix[3][3]}
  
  -- The "forward" vector.
  local zaxis = fwVec 
  -- The left vector.
  local xaxis = matrix.cross( upVec, fwVec )
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
  x = (2.0 * x) / SCREEN_WIDTH - 1.0
  y =  - 2.0 * y / SCREEN_HEIGHT + 1
  
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