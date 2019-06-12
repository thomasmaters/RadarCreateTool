local SCREEN_WIDTH, SCREEN_HEIGHT = guiGetScreenSize()
local RadarLoader = {}
RadarLoader.__index = RadarLoader

setmetatable(RadarLoader, {
  __call = function (cls, ...)
    return cls.new(...)
  end,
})

function RadarLoader.new(init)
  local self = setmetatable({}, RadarLoader)
  self.maxRows = 0
  self.maxColumns = 0
  
  self.topLeftX = 0
  self.topLeftY = 0
  
  self.radarTextureWidth = 0
  self.radarTextureHeight = 0
  
  self.pixelsPerWorldUnit = 0
  
  self.gridPosX = nil
  self.gridPosY = nil
  
  --Loaded textures struct
  self.shaderTable = {}
  --Masking shader
  self.shader, self.tec = dxCreateShader( "fx/radar_mask.fx", 0,0,false,"all")
  --Texture to write to the shader
  self.radarTexture = DxTexture(self.radarTextureWidth * self.maxRows, self.radarTextureHeight * self.maxColumns)
  
  self:populateShaderTable()
  
  self.timer = setTimer ( function() self:handleTileLoading() end, 250, 0 )
  addEventHandler( "onClientRender", getRootElement(),
    function()
      self:render()
    end
  )
  return self
end

function RadarLoader:populateShaderTable()
  for i=1, self.maxRows * self.maxColumns do
    --Calculate tile
    local tileX, tileY = (i - 1) % self.maxColumns, math.floor((i - 1) / self.maxRows)
    --Load tile part.
    local filePath = string.format("radar/radar_%d_%d.jpeg",self.shaderTable[i].x,self.shaderTable[i].y)
    
    --Does it exist
    if(File.exists(filePath)) then
      self.shaderTable[i] = {}
      self.shaderTable[i].x = tileX
      self.shaderTable[i].y = tileY
      self.shaderTable[i].loaded = false
      self.shaderTable[i].texture = dxCreateTexture(filePath)
      self.shaderTable[i].pixels = dxGetTexturePixels(self.shaderTable[i].texture)
    end
  end
  
    --Is the shader loaded?
  if(self.shader) then
    dxSetShaderValue( self.shader, "uCustomRadarTexturePart", self.radarTexture)
    dxSetShaderValue( self.shader, "uScreenWidth", SCREEN_WIDTH)
    dxSetShaderValue( self.shader, "uScreenHeight", SCREEN_HEIGHT)
  end
end

function RadarLoader:constructBigTexture()
  local radarBufferSize = 1 
  local playerX, playerY, _ = localPlayer:getPosition()
  local gridX = math.floor((playerX - self.topLeftX) / (self.pixelsPerWorldUnit * self.radarTextureWidth))
  local gridY = math.floor((playerY - self.topLeftY) / (self.pixelsPerWorldUnit * self.radarTextureHeight))
  
  --Reset the texture (TODO does it set the pixels to alpha?)
  self.radarTexture = DxTexture(self.radarTextureWidth * self.maxRows, self.radarTextureHeight * self.maxColumns)
  
  --Check which tiles to add to the big texture.
  for _,shaderTableEntry in pairs(self.shaderTable) do
    if(math.abs(shaderTableEntry.x - gridX) <= radarBufferSize and math.abs(shaderTableEntry.y - gridY) <= radarBufferSize) then  
      self.radarTexture:setPixels(shaderTableEntry.pixels, 
        (shaderTableEntry.x - gridX + radarBufferSize) * self.radarTextureWidth, 
        (shaderTableEntry.y - gridY + radarBufferSize) * self.radarTextureHeight,
        self.radarTextureWidth,
        self.radarTextureHeight)
    end
  end
  
  --Apply to shader
  dxSetShaderValue( self.shader, "uCustomRadarTexturePart", self.radarTexture)
end

function RadarLoader:checkTileLoading()
  local playerX, playerY, _ = localPlayer:getPosition()
  
  local gridX = math.floor((playerX - self.topLeftX) / (self.pixelsPerWorldUnit * self.radarTextureWidth))
  local gridY = math.floor((playerY - self.topLeftY) / (self.pixelsPerWorldUnit * self.radarTextureHeight))
  
  if(gridX ~= self.gridPosX or gridY ~= self.gridPosY) then
    self:constructBigTexture()
  end
end

function RadarLoader:render()
  local playerX, playerY, _ = localPlayer:getPosition()
  local rotX, rotY, rotZ = localPlayer:getRotation()
  
  --Calculate grid position.
  local uvX = (playerX - self.topLeftX) / (self.pixelsPerWorldUnit * self.radarTextureWidth)
  local uvY = (playerY - self.topLeftY) / (self.pixelsPerWorldUnit * self.radarTextureHeight)
  if(self.shader) then
    --Set shader values on render.
    dxSetShaderValue( self.shader, "uUVPosition", {uvX - shaderTableEntry.x, uvY - shaderTableEntry.y})
    --TODO is rotZ correct?
    dxSetShaderValue( self.shader, "uUVRotation", (rotZ * math.pi / 180))
  end
end

addEventHandler("onClientResourceStart", getResourceRootElement(getThisResource()), 
  function()
    --Initalize instance
    --local instance = RadarLoader()
  end
)