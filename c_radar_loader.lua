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
  self.maxRows = 3
  self.maxColumns = 3
  
  self.topLeftX = 0
  self.topLeftY = 0
  
  self.radarTextureWidth = 512
  self.radarTextureHeight = 512
  
  self.pixelsPerWorldUnit = 0.9
  
  self.gridPosX = nil
  self.gridPosY = nil
  
  --Loaded textures struct
  self.shaderTable = {}
  --Masking shader
  self.shader, self.tec = dxCreateShader( "fx/radar_mask.fx", 0,0,false,"all")
  --Texture to write to the shader
  self.radarTexture = DxTexture(self.radarTextureWidth * self.maxRows, self.radarTextureHeight * self.maxColumns)
  
  self:populateShaderTable()
  
  self.timer = setTimer ( function() self:checkTileLoading() end, 250, 0 )
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
    --local filePath = string.format("radar/radar_%d_%d.jpeg",tileX, tileY)
    local filePath = "shadertest.jpg"
	
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
	engineApplyShaderToWorldTexture( self.shader, "radardisc" )
  end
end

function RadarLoader:constructBigTexture()
  local radarBufferSize = 1 
  local playerPos = localPlayer:getPosition()
  
  local gridX = math.floor((playerPos.x - self.topLeftX) / (self.pixelsPerWorldUnit * self.radarTextureWidth))
  local gridY = math.floor((playerPos.y - self.topLeftY) / (self.pixelsPerWorldUnit * self.radarTextureHeight))
  
  --Reset the texture (TODO does it set the pixels to alpha?)
  self.radarTexture = DxTexture(self.radarTextureWidth * self.maxRows, self.radarTextureHeight * self.maxColumns)
  
  --Check which tiles to add to the big texture.
  for _,shaderTableEntry in pairs(self.shaderTable) do
    if(math.abs(shaderTableEntry.x - gridX) <= radarBufferSize and math.abs(shaderTableEntry.y - gridY) <= radarBufferSize) then  
      self.radarTexture:setPixels(shaderTableEntry.pixels, 
        (gridX - shaderTableEntry.x + radarBufferSize) * self.radarTextureWidth, 
        (shaderTableEntry.y - gridY + radarBufferSize) * self.radarTextureHeight,
        self.radarTextureWidth,
        self.radarTextureHeight)
    end
  end
  
  --Apply to shader
  dxSetShaderValue( self.shader, "uCustomRadarTexturePart", self.radarTexture)
end

function RadarLoader:checkTileLoading()
  local playerPos = localPlayer:getPosition()
  
  local gridX = math.floor((playerPos.x - self.topLeftX) / (self.pixelsPerWorldUnit * self.radarTextureWidth))
  local gridY = math.floor((playerPos.y - self.topLeftY) / (self.pixelsPerWorldUnit * self.radarTextureHeight))
  
  if(gridX ~= self.gridPosX or gridY ~= self.gridPosY) then
    self:constructBigTexture()
	self.gridPosX = gridX
	self.gridPosY = gridY
	outputChatBox("I am now in tile: " ..self.gridPosX.. " "..self.gridPosY)
  end
end

function RadarLoader:render()

	dxDrawImage(0,512,512,512,self.radarTexture)
  local playerPos = localPlayer:getPosition()
  local playerRot = localPlayer:getRotation()
  
  --Calculate grid position.
  local uvX = (playerPos.x - self.topLeftX) / (self.pixelsPerWorldUnit * self.radarTextureWidth)
  local uvY = (playerPos.y - self.topLeftY) / (self.pixelsPerWorldUnit * self.radarTextureHeight)
  if(self.shader and self.gridPosX and self.gridPosY) then
    --Set shader values on render.
    --dxSetShaderValue( self.shader, "uUVPosition", {uvX, uvY})
    --TODO is rotZ correct?
    dxSetShaderValue( self.shader, "uUVRotation", (-playerRot.z * math.pi / 180))
  end
end

addEventHandler("onClientResourceStart", getResourceRootElement(getThisResource()), 
  function()
    --Initalize instance
	outputChatBox("kaas")
    local instance = RadarLoader()
  end
)