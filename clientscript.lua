local scx, scy = guiGetScreenSize()

local obj_left = createObject(3877,0,0,0)
local obj_right = createObject(3877,0,0,0)

RADAR_PREVIEW_X = 1000
RADAR_PREVIEW_Y = 100
RADAR_PREVIEW_WIDTH = 500
RADAR_PREVIEW_HEIGHT = 500

addEventHandler( "onClientRender", root,
    function()
		if(isCursorShowing ( )) then
			local screenx, screeny, x, y, z = getCursorPosition()
			dxDrawText(string.format("sx: %.2f\nsy: %.2f\nx: %.2f\ny: %.2f\nz: %.2f", screenx * scx, screeny * scy,x,y,z),screenx * scx,screeny * scy)
		end
		
		--local tl_x, tl_y, tl_z = getWorldFromPosition ( scx / 2 - 512 / 2, scy / 2 - 512 / 2, cameraOffset )
		--local br_x, br_y, br_z = getWorldFromPosition ( scx / 2 + 512 / 2, scy / 2 + 512 / 2, cameraOffset )
		--local c_x, c_y, c_z = getWorldFromPosition ( scx / 2, scy / 2, cameraOffset )
		
		dxDrawLine(scx / 2 - 256, scy / 2 - 256, scx / 2 + 256, scy / 2 - 256)
		dxDrawLine(scx / 2 + 256, scy / 2 - 256, scx / 2 + 256, scy / 2 + 256)
		dxDrawLine(scx / 2 + 256, scy / 2 + 256, scx / 2 - 256, scy / 2 + 256)
		dxDrawLine(scx / 2 - 256, scy / 2 + 256, scx / 2 - 256, scy / 2 - 256)
		
		--dxDrawText(string.format("x: %.2f\ny: %.2f\nz: %.2f", tl_x, tl_y, tl_z),scx / 2 - 256, scy / 2 - 256)
		--dxDrawText(string.format("x: %.2f\ny: %.2f\nz: %.2f", br_x, br_y, br_z),scx / 2 + 256, scy / 2 + 256)
		--dxDrawText(string.format("x: %.2f\ny: %.2f\nz: %.2f", c_x, c_y, c_z),scx / 2, scy / 2)
		
		local x,y,z = getElementPosition(getLocalPlayer())
		setElementPosition(obj_left, x + 100, y + 100 ,1)
		setElementPosition(obj_right, x - 100, y - 100 ,1)
		
		local scr_x, scr_y = GlobalViewShader:getScreenFromWorldCoordinates(x + 100,y + 100,0)
		local scr_x_r, scr_y_r = GlobalViewShader:getScreenFromWorldCoordinates(x - 100,y - 100,0)
		local x_pixels_world_unit, y_pixels_world_unit = GlobalRadarCreate:getPixelsPerWorldUnit()
		local rot_x,rot_y,rot_z = getElementRotation ( getCamera() )
		dxDrawLine(scr_x+5, scr_y, scr_x_r+5, scr_y_r)
		dxDrawText(string.format("x: %.2f\ny: %.2f", scr_x, scr_y),500, 100)
		dxDrawText(string.format("x: %.2f\ny: %.2f", scr_x_r, scr_y_r),600, 100)
		dxDrawText(string.format("x: %.5f\ny: %.5f", math.abs(scr_x_r - scr_x), math.abs(scr_y_r - scr_y)),700, 100)
		dxDrawText(string.format("x: %.2f\ny: %.2f\nz: %.2f", rot_x, rot_y, rot_z),500, 200)
		dxDrawText(string.format("x: %.4f\ny: %.4f", x_pixels_world_unit, y_pixels_world_unit),500, 300)
		
		if(GlobalRadarCreate.outputTexture and GlobalRadarCreate.maxRows ~= 0 and GlobalRadarCreate.maxColumns ~= 0) then
		  dxDrawImage(RADAR_PREVIEW_X,RADAR_PREVIEW_Y,RADAR_PREVIEW_WIDTH,RADAR_PREVIEW_HEIGHT,GlobalRadarCreate.outputTexture)
		  for i=0, GlobalRadarCreate.maxRows do
		  	dxDrawLine(
		  	 RADAR_PREVIEW_X, 
		  	 RADAR_PREVIEW_Y + i * (RADAR_PREVIEW_HEIGHT / GlobalRadarCreate.maxRows), 
		  	 RADAR_PREVIEW_X + RADAR_PREVIEW_WIDTH, 
		  	 RADAR_PREVIEW_Y + i * (RADAR_PREVIEW_HEIGHT / GlobalRadarCreate.maxRows)
		  	)
		  end
		  for i=0, GlobalRadarCreate.maxColumns do
			dxDrawLine(
			 RADAR_PREVIEW_X + i * (RADAR_PREVIEW_WIDTH / GlobalRadarCreate.maxColumns),
			 RADAR_PREVIEW_Y, 
			 RADAR_PREVIEW_X + i * (RADAR_PREVIEW_WIDTH / GlobalRadarCreate.maxColumns), 
			 RADAR_PREVIEW_Y + RADAR_PREVIEW_HEIGHT
			)
		  end
		end
		
		--setElementRotation(getCamera(),270,0,0)
   end
)

function writeOutput()
  local templateFile = File("c_radar_loader.lua")
  local destinationFile = File("output/c_radar_loader.lua")
  local destinationConfigFile = XML("output/meta_xml.xml", "copy_between_these_tags_to_your_maps_meta_xml")
  
  if(not(templateFile and destinationFile and destinationConfigFile)) then
    outputChatBox("File creation failed while exporting")
    return
  end
  
  --Write client rendering script
  local templateFileData = templateFile:read(templateFile:getSize())
  templateFileData = string.gsub(templateFileData, "self.maxRows = 0", string.format("self.maxRows = %d", 1))
  templateFileData = string.gsub(templateFileData, "self.maxColumns = 0", string.format("self.maxColumns = %d", 1))
  templateFileData = string.gsub(templateFileData, "self.topLeftX = 0", string.format("self.topLeftX = %f",1.0))
  templateFileData = string.gsub(templateFileData, "self.topLeftY = 0", string.format("self.topLeftY = %f",1.0))
  templateFileData = string.gsub(templateFileData, "self.radarTextureWidth = 0", string.format("self.radarTextureWidth = %d",1))
  templateFileData = string.gsub(templateFileData, "self.radarTextureHeight = 0", string.format("self.radarTextureHeight = %d",1))
  templateFileData = string.gsub(templateFileData, "self.pixelsPerWorldUnit = 0", string.format("self.pixelsPerWorldUnit = %f",1.0))
  
  
  --Write xml that can be copied to a meta.xml
  for i=0, GlobalRadarCreate.maxRows do
    for j=0, GlobalRadarCreate.maxColumns do
      local radarPartXmlNode = destinationConfigFile:createChild("file")
      radarPartXmlNode:setAttribute("src",string.format("radar/radar_%d_%d.jpeg",j,i))
    end
  end
  local radarScriptXmlNode = destinationConfigFile:createChild("script")
  radarScriptXmlNode:setAttribute("src","c_radar_loader.lua")
  radarScriptXmlNode:setAttribute("type","client")
  
  local radarShaderXmlNode = destinationConfigFile:createChild("script")
  radarShaderXmlNode:setAttribute("src","fx/radar_mask.fx")
  radarShaderXmlNode:setAttribute("type","client")
  
  --Close xml file
  destinationConfigFile:saveFile()
  destinationConfigFile:unload()
  
  --Close script file
  destinationFile:write(templateFileData)
  destinationFile:close()
  
  --Close template file
  templateFile:close()
end







