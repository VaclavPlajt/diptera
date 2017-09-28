
local systemEventsHandler = {}



function systemEventsHandler:create(context)
    
    
    Runtime:addEventListener( "system", 
    function(event)
        --if ( event.type == "applicationExit" ) then
            --save_state()
        
        --elseif ( event.type == "applicationStart" ) then
            
        --elseif ( event.type == "applicationOpen" ) then
            --load_saved_state()
            
        if (event.type == "applicationSuspend") then
            --pause_game()
            context.soundManager:pauseMusic();
        elseif (event.type == "applicationResume") then
            --pause_game()
            context.soundManager:resumeMusic();
        end
    end
    
    )
    
end

















return systemEventsHandler;

