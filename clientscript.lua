local scx, scy = guiGetScreenSize()
addEventHandler("onClientResourceStart", resourceRoot,
    function()
		setCameraTarget(getLocalPlayer())
		setCameraFieldOfView("player",70)
		
		myScreenSource = dxCreateScreenSource( scx/2, scy/2 )
		defaultScreenSource = dxCreateScreenSource( scx/2, scy/2 )
		
        myShader,tecName = dxCreateShader( "clientshader.fx", 0,0,false,"vehicle")
		engineApplyShaderToWorldTexture ( myShader, "*" )
		
        --myImage = dxCreateTexture( "hurry.png" )
        if myShader then
            --dxSetShaderValue( myShader, "TEX0", myScreenSource )
            outputChatBox( "Shader using techinque " .. tecName )
        else
            outputChatBox( "Problem - use: debugscript 3" )
        end
    end
)

addEventHandler( "onClientRender", root,
    function()
        if myShader then
			local px, py, pz = getElementPosition ( getLocalPlayer ( ) )
			setCameraMatrix(px,py,pz + 25, px,py,pz)
			--dxUpdateScreenSource(myScreenSource)
			--dxUpdateScreenSource(defaultScreenSource)
            --dxDrawImage( 200, 300, 800, 400, myShader)
			--dxDrawImage( 200, 700, 800, 400, defaultScreenSource)
        end
   end
)