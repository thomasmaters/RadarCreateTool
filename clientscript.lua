local scx, scy = guiGetScreenSize()
local cameraOffset = 200
addEventHandler("onClientResourceStart", resourceRoot,
    function()

    end
)

addEventHandler( "onClientRender", root,
    function()
		if(isCursorShowing ( )) then
			local screenx, screeny, x, y, z = getCursorPosition()
			dxDrawText(string.format("x: %.2f\ny: %.2f\nz: %.2f", x,y,z),screenx * scx,screeny * scy)
		end
		
		local tl_x, tl_y, tl_z = getWorldFromPosition ( scx / 2 - 512 / 2, scy / 2 - 512 / 2, cameraOffset )
		local br_x, br_y, br_z = getWorldFromPosition ( scx / 2 + 512 / 2, scy / 2 + 512 / 2, cameraOffset )
		local c_x, c_y, c_z = getWorldFromPosition ( scx / 2, scy / 2, cameraOffset )
		
		dxDrawLine(scx / 2 - 256, scy / 2 - 256, scx / 2 + 256, scy / 2 - 256)
		dxDrawLine(scx / 2 + 256, scy / 2 - 256, scx / 2 + 256, scy / 2 + 256)
		dxDrawLine(scx / 2 + 256, scy / 2 + 256, scx / 2 - 256, scy / 2 + 256)
		dxDrawLine(scx / 2 - 256, scy / 2 + 256, scx / 2 - 256, scy / 2 - 256)
		
		dxDrawText(string.format("x: %.2f\ny: %.2f\nz: %.2f", tl_x, tl_y, tl_z),scx / 2 - 256, scy / 2 - 256)
		dxDrawText(string.format("x: %.2f\ny: %.2f\nz: %.2f", br_x, br_y, br_z),scx / 2 + 256, scy / 2 + 256)
		dxDrawText(string.format("x: %.2f\ny: %.2f\nz: %.2f", c_x, c_y, c_z),scx / 2, scy / 2)
   end
)

local lodModels = {}

function increaseObjectRenderDistance()
	for i,object in pairs (getElementsByType("object")) do
		local model = getElementModel(object)
		
		if model then
			local x,y,z = getElementPosition(object)
			local a,b,c = getElementRotation(object)
			lodModels[i] = createObject(model,x,y,z,a,b,c,true)
			setElementDimension(lodModels[i],getElementDimension(object))
			setObjectScale(lodModels[i],getObjectScale(object))
			setLowLODElement(object,lodModels[i])
			setElementDoubleSided(lodModels[i],isElementDoubleSided(object))
			engineSetModelLODDistance(model,1000)
		end
	end
end