UserInterface = newclass("UserInterface")

function UserInterface:init()
 local WINDOW_WIDTH = 300
  local WINDOW_HEIGHT = 500
  local EDGE_OFFSET = 4
  local EDGE_OFFSET_L = EDGE_OFFSET + 10
  local ITEM_HEIGHT = 20
  local ITEM_WIDTH = WINDOW_WIDTH - 2 * EDGE_OFFSET
  local TOTAL_ITEM_HEIGHT = ITEM_HEIGHT + EDGE_OFFSET
  local UI_START = 20 + EDGE_OFFSET
  
  self.mainWindow = GuiWindow(100,100,WINDOW_WIDTH,WINDOW_HEIGHT,"ANoniem's - Radar create tool",false)
  
      GuiLabel(EDGE_OFFSET_L ,  EDGE_OFFSET           , ITEM_WIDTH, ITEM_HEIGHT,"Zoommnmmmmmmmmmmmmmmm:",false,self.mainWindow)
  self.zoomScroll = 
  guiCreateScrollBar( EDGE_OFFSET,  UI_START + TOTAL_ITEM_HEIGHT  , ITEM_WIDTH, ITEM_HEIGHT,true,false,self.mainWindow)
  guiScrollBarSetScrollPosition(self.zoomScroll, map(SHADER_ZOOM_DEFAULT, SHADER_ZOOM_MIN, SHADER_ZOOM_MAX, 0, 100))
  
      GuiLabel(EDGE_OFFSET_L ,  UI_START + 2 * TOTAL_ITEM_HEIGHT, ITEM_WIDTH, ITEM_HEIGHT,"Far clip:",false,self.mainWindow)
  self.farScroll = 
  guiCreateScrollBar( EDGE_OFFSET,  UI_START + 3 * TOTAL_ITEM_HEIGHT, ITEM_WIDTH, ITEM_HEIGHT,true,false,self.mainWindow)  
  guiScrollBarSetScrollPosition(self.farScroll, map(SHADER_FARCLIP_DEFAULT, SHADER_FARCLIP_MIN, SHADER_FARCLIP_MAX, 0, 100 ))
      
      GuiLabel(EDGE_OFFSET_L ,  UI_START + 4 * TOTAL_ITEM_HEIGHT, ITEM_WIDTH, ITEM_HEIGHT,"Near clip:",false,self.mainWindow)
  self.nearScroll = 
  guiCreateScrollBar( EDGE_OFFSET,  UI_START + 5 * TOTAL_ITEM_HEIGHT, ITEM_WIDTH, ITEM_HEIGHT,true,false,self.mainWindow)
  guiScrollBarSetScrollPosition(self.nearScroll, map(SHADER_NEARCLIP_DEFAULT, SHADER_NEARCLIP_MIN, SHADER_NEARCLIP_MAX, 0, 100))
  
      GuiLabel(EDGE_OFFSET_L ,  UI_START + 6 * TOTAL_ITEM_HEIGHT, ITEM_WIDTH, ITEM_HEIGHT,"Saturation:",false,self.mainWindow)
  self.saturationScroll = 
  guiCreateScrollBar( EDGE_OFFSET,  UI_START + 7 * TOTAL_ITEM_HEIGHT, ITEM_WIDTH, ITEM_HEIGHT,true,false,self.mainWindow)
  guiScrollBarSetScrollPosition(self.saturationScroll, map(SHADER_SATURATION_DEFAULT, SHADER_SATURATION_MIN, SHADER_SATURATION_MAX, 0, 100))
  
  self.checkEnableShader = 
    GuiCheckBox(  EDGE_OFFSET,  UI_START + 8 * TOTAL_ITEM_HEIGHT,  ITEM_WIDTH, ITEM_HEIGHT,"Enable shader",false,false,self.mainWindow)
  self.checkLighting = 
    GuiCheckBox(  EDGE_OFFSET,  UI_START + 9 * TOTAL_ITEM_HEIGHT, ITEM_WIDTH, ITEM_HEIGHT,"Lighting",true,false,self.mainWindow)
  self.checkAverageTexColor = 
    GuiCheckBox(  EDGE_OFFSET,  UI_START + 10 * TOTAL_ITEM_HEIGHT, ITEM_WIDTH, ITEM_HEIGHT,"Equal color (Might not work with textures with alpha)",false,false,self.mainWindow)
  self.checkOneTexture =
    GuiCheckBox(  EDGE_OFFSET,  UI_START + 11 * TOTAL_ITEM_HEIGHT,  ITEM_WIDTH, ITEM_HEIGHT,"Output radar parts",false,false,self.mainWindow)
  self.increaseObjectRenderDistance =
    GuiCheckBox(  EDGE_OFFSET,  UI_START + 12 * TOTAL_ITEM_HEIGHT,  ITEM_WIDTH, ITEM_HEIGHT,"Increase object render distance(LOD's)",false,false,self.mainWindow)
  
  self.qualityComboBox = 
    GuiComboBox(  EDGE_OFFSET,  UI_START + 13 * TOTAL_ITEM_HEIGHT,  ITEM_WIDTH, ITEM_HEIGHT,"Output Quality",false,self.mainWindow)
  self.qualityComboBox:addItem("4 units : 1 pixel (default)")
  self.qualityComboBox:addItem("2 units : 1 pixel")
  self.qualityComboBox:addItem("1 units : 1 pixel")
  self.qualityComboBox:addItem("1 units : 2 pixel")
  self.qualityComboBox:setSelected(0) --Select the first item.
  
      GuiLabel(EDGE_OFFSET_L ,  UI_START + 14 * TOTAL_ITEM_HEIGHT,  ITEM_WIDTH, ITEM_HEIGHT,"Bottom-Left corner of map:",false,self.mainWindow)
  self.buttonBottomLeft = 
      GuiButton(  EDGE_OFFSET,  UI_START + 15 * TOTAL_ITEM_HEIGHT,  ITEM_WIDTH, ITEM_HEIGHT,"Set to current position",false,self.mainWindow)
      GuiLabel(EDGE_OFFSET_L ,  UI_START + 16 * TOTAL_ITEM_HEIGHT,  ITEM_WIDTH, ITEM_HEIGHT,"Top-Right corner of map:",false,self.mainWindow)
  self.buttonTopRight = 
      GuiButton(  EDGE_OFFSET,  UI_START + 17 * TOTAL_ITEM_HEIGHT,  ITEM_WIDTH, ITEM_HEIGHT,"Set to current position",false,self.mainWindow)
  self.buttonStart = 
      GuiButton(  EDGE_OFFSET,  UI_START + 18 * TOTAL_ITEM_HEIGHT,  ITEM_WIDTH, ITEM_HEIGHT,"Create map",false,self.mainWindow)
	  
  addEventHandler("onClientGUIClick", self.checkEnableShader, 
  function(button) 
    if(button == "left") then
      if(self.checkLighting:getSelected()) then
        GlobalViewShader:enableShader()
      else
        GlobalViewShader:disableShader()
      end
    end
  end, 
  false)
	  
	addEventHandler("onClientGUIClick", self.checkLighting, 
	function(button) 
	  if(button == "left") then
		  GlobalViewShader:setLightingEnabled(self.checkLighting:getSelected())
	  end
	end, 
	false)

	addEventHandler("onClientGUIClick", self.checkAverageTexColor, 
	function(button) 
	  if(button == "left") then
		  GlobalViewShader:setEqualColorEnabled(self.checkAverageTexColor:getSelected())
	  end
	end, 
	false)
	
  addEventHandler("onClientGUIClick", self.checkOneTexture, 
  function(button) 
    if(button == "left") then
      if(self.checkOneTexture:getSelected()) then
        GlobalRadarCreate:enableSavingRadarParts()
      else
        GlobalRadarCreate:disableSavingRadarParts()
      end
    end
  end, 
  false)
	
	addEventHandler("onClientGUIClick", self.increaseObjectRenderDistance, 
	function(button) 
	  if(button == "left") then
  		if(#GlobalViewShader.lodModels == 0) then
  			GlobalViewShader:increaseObjectRenderDistance()
  		else
  			GlobalViewShader:resetObjectRenderDistance()
  		end
	  end
	end, 
	false)

	addEventHandler("onClientGUIClick", self.buttonBottomLeft, 
	function(button) 
	  if(button == "left") then
  		local x,y,z = getElementPosition(getLocalPlayer())    
  		self.buttonBottomLeft:setText(string.format("x: %.2f y: %.2f z: %.2f", x,y,z))
  		GlobalRadarCreate.bottomLeftCoordinate = Vector3(x,y,z)
	  end
	end, 
	false)
	
  addEventHandler("onClientGUIClick", self.buttonTopRight, 
  function(button) 
    if(button == "left") then
      local x,y,z = getElementPosition(getLocalPlayer())
      self.buttonTopRight:setText(string.format("x: %.2f y: %.2f z: %.2f", x,y,z))
      GlobalRadarCreate.topRightCoordinate = Vector3(x,y,z)
    end
  end, 
  false)

	addEventHandler("onClientGUIClick", self.buttonStart, 
	function(button) 
	  if(button == "left") then
  	  if(GlobalRadarCreate:isMapMaking()) then
  	    self.buttonStart:setText("Create map")
        GlobalViewShader:disableShader()
        GlobalRadarCreate:stopMapMaking()
  	  else
        self.buttonStart:setText("Stop creating map")
        GlobalViewShader:enableShader()
        GlobalRadarCreate:syncCamera()
  	  end
	  end
	end, 
	false)

	addEventHandler ( "onClientGUIComboBoxAccepted", guiRoot,
	  function ( comboBox )
	  if(comboBox == self.qualityComboBox) then
		  local selectedIndex = self.qualityComboBox:getSelected()
	  end
	end
	)

	--Scroll callback.
	addEventHandler( "onClientGUIScroll", root, function()
	  if(source == self.zoomScroll) then
		GlobalViewShader:setZoom(map(guiScrollBarGetScrollPosition(source), 0, 100, SHADER_ZOOM_MIN, SHADER_ZOOM_MAX))
	  elseif(source == self.nearScroll) then
		GlobalViewShader:setNearClip(map(guiScrollBarGetScrollPosition(source), 0, 100, SHADER_NEARCLIP_MIN, SHADER_NEARCLIP_MAX))
	  elseif(source == self.farScroll) then
		GlobalViewShader:setFarClip(map(guiScrollBarGetScrollPosition(source), 0, 100, SHADER_FARCLIP_MIN, SHADER_FARCLIP_MAX))
	  elseif(source == self.saturationScroll) then
		GlobalViewShader:setSaturation(map(guiScrollBarGetScrollPosition(source), 0, 100, SHADER_SATURATION_MIN, SHADER_SATURATION_MAX))
	  end
	end
	)
end

function UserInterface:mapMakingFinished()
  self.buttonStart:setText("Create map")
  GlobalViewShader:disableShader()
  GlobalRadarCreate:stopMapMaking()
end