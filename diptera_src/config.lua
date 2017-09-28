
application =
{
    
    content = 
    {
        width = 640,
        height = 960,
        scale = "letterbox",
        
        --[[
        imageSuffix =
        {
            ["@2x"] = 1.5
            --high-resolution devices (Retina iPad, Kindle Fire HD 9", Nexus 10, etc.) will use @2x-suffixed images
            --devices less than 1200 pixels in width (iPhone4, iPad2, Kindle Fire 7", etc.) will use non-suffixed images
        }
        ]]
    },

    -- https://docs.coronalabs.com/api/library/licensing/index.html
    -- The Corona licensing library lets you check to see if the app was bought from a store. Currently, only Google Play is supported.
     license =
    {
        google =
        {
            key = "suply a key of your own if needed",
            policy = "serverManaged"
        },
    },
    
}