__author__ = 'plastique'

import sys; #print("python version: " + sys.version); print("python version info: " + str(sys.version_info));

if sys.version_info[1] < 3 :
    print("Python major version must be at least 3!!");


import math;

# valid for landscape orientation
apple = [
    {"name":"4.7 inch", "w":1334, "h":750},
    {"name":"5.5 inch", "w":2208, "h":1242},
    {"name":"4 inch", "w":1136, "h":640},
    {"name":"3.5 inch", "w":960, "h":640},
    {"name":"ipad", "w":1024, "h":768},
    {"name":"ipad hi-res", "w":2048, "h":1536}
]


margin = 21;
max_screen = {"w" :1024+1920-margin, "h":1200-margin}
print("max screen size: " + str(max_screen))

screens = apple;


for screen in screens :
    screen["aspect_ratio"] = screen["w"]/screen["h"];

    if (screen["w"] <= max_screen["w"]) & (screen["h"] <= max_screen["h"]) :
        print(str(screen) + " <-- fits to max screen");

    else :
        w,h = 0,0;

        # both width and height do not fits
        scaleW = max_screen["w"]/screen["w"];
        scaleH = max_screen["h"]/screen["h"];

        if scaleW < scaleH :
            # scale to fit width
            w = scaleW*screen["w"];
            h = scaleW*screen["h"];
        else:
            # scale to fit heught
            w = scaleH*screen["w"];
            h = scaleH*screen["h"];


        print(str(screen)+ " <-- do not fit to max screen, use size: " + str({"w":w,"h":h}));
