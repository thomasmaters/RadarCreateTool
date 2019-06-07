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
  
  self.shaderTable = {}
  
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
      self.shaderTable[i].shader, self.shaderTable[i].tec = dxCreateShader( "fx/radar_mask.fx", 0,0,false,"all")
      
      --Is the shader loaded?
      if(shader_table[i].shader) then
        dxSetShaderValue( self.shaderTable[i].shader, "uCustomRadarTexturePart", self.shaderTable[i].texture)
        dxSetShaderValue( self.shaderTable[i].shader, "uScreenWidth", SCREEN_WIDTH)
        dxSetShaderValue( self.shaderTable[i].shader, "uScreenHeight", SCREEN_HEIGHT)
      end
    end
  end
end

function RadarLoader:checkTileLoading()
  local playerX, playerY, _ = localPlayer:getPosition()
  
  local gridX = math.floor((playerX - self.topLeftX) / (self.pixelsPerWorldUnit * self.radarTextureWidth))
  local gridY = math.floor((playerY - self.topLeftY) / (self.pixelsPerWorldUnit * self.radarTextureHeight))
  
  for _,shaderTableEntry in pairs(self.shaderTable) do
    if(shaderTableEntry.shader ~= nil and math.abs(shaderTableEntry.x - gridX) <= 0 and math.abs(shaderTableEntry.y - gridY)) then
      engineApplyShaderToWorldTexture( shaderTableEntry.shader, "radardisc" )
      shaderTableEntry.loaded = true
    else
      engineRemoveShaderFromWorldTexture( shaderTableEntry.shader, "radardisc" )
      shaderTableEntry.loaded = false
    end
  end 
end

function RadarLoader:render()
  local playerX, playerY, _ = localPlayer:getPosition()
  local rotX, rotY, rotZ = localPlayer:getRotation()
  
  --Calculate grid position.
  local uvX = (playerX - self.topLeftX) / (self.pixelsPerWorldUnit * self.radarTextureWidth)
  local uvY = (playerY - self.topLeftY) / (self.pixelsPerWorldUnit * self.radarTextureHeight)
  for _,shaderTableEntry in pairs(self.shaderTable) do
    --Is shader loaded.
    if(shaderTableEntry.loaded) then
        --Set shader values on render.
        dxSetShaderValue( shaderTableEntry.shader, "uUVPosition", {uvX - shaderTableEntry.x, uvY - shaderTableEntry.y})
        --TODO is rotZ correct?
        dxSetShaderValue( shaderTableEntry.shader, "uUVRotation", (rotZ * math.pi / 180))
    end
  end
end

addEventHandler("onClientResourceStart", getResourceRootElement(getThisResource()), 
  function()
    --Initalize instance
    local instance = RadarLoader()
  end
)