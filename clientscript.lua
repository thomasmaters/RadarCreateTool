local scx, scy = guiGetScreenSize()
local cameraOffset = 200

local obj_left = createObject(3877,0,0,0)
local obj_right = createObject(3877,0,0,0)

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
		setElementPosition(obj_left, x + 50, y + 50 ,1)
		setElementPosition(obj_right, x - 50, y - 50 ,1)
		
		local scr_x, scr_y = getScreenFromWorldCoordinates(x + 50,y + 50,2)
		local scr_x_r, scr_y_r = getScreenFromWorldCoordinates(x - 50,y - 50,2)
		local rot_x,rot_y,rot_z = getElementRotation ( getCamera() )
		dxDrawLine(scr_x, scr_y, scr_x_r, scr_y_r)
		dxDrawText(string.format("x: %.2f\ny: %.2f", scr_x, scr_y),500, 100)
		dxDrawText(string.format("x: %.2f\ny: %.2f", scr_x_r, scr_y_r),600, 100)
		dxDrawText(string.format("x: %.2f\ny: %.2f", math.abs(scr_x_r - scr_x), math.abs(scr_y_r - scr_y)),700, 100)
		dxDrawText(string.format("x: %.2f\ny: %.2f\nz: %.2f", rot_x, rot_y, rot_z),500, 200)
		setElementRotation(getCamera(),270,0,0)
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