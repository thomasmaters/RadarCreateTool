main_timer = nil

function map(x, in_min, in_max, out_min, out_max) 
  return (x - in_min) * (out_max - out_min) / (in_max - in_min) + out_min
end

SCREEN_WIDTH, SCREEN_HEIGHT = guiGetScreenSize()

GlobalViewShader = ViewShader()

function main()
  --setCameraTarget(getLocalPlayer())
  setCloudsEnabled(false)
  setFogDistance(1000)
  setFarClipDistance(1000)
  setHeatHaze(0)
  createUI()
end
addEventHandler ( "onClientResourceStart", getResourceRootElement(getThisResource()), main)