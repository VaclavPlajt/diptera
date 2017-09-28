__author__ = 'plastique'

#from scipy import misc;
import matplotlib.pyplot as plt
import math
from PIL import Image

show_results = False

icon_set = [
# File 	iOS Version 	Size (wxh) 	Usage
{'file':'Icon-60@3x.png', 'version' : 8.0, 'size' :	180},#  180 	App Icon  iPhone 6 Plus
{'file':'Icon-Small-40@3x.png','version' : 8.0, 'size' : 120},#  120 	Search  iPhone 6 Plus
{'file':'Icon-Small@3x.png','version' : 8.0, 'size' : 87},#  87 	Settings  iPhone 6 Plus
{'file':'Icon-60.png','version' :  7.0, 'size' : 60},#  60 	App Icon  iPhone
{'file':'Icon-60@2x.png','version' :  7.0, 'size' : 120},#  120 	App Icon  Retina iPhone
{'file':'Icon-76.png', 'version' : 7.0, 'size' :  	76},#  76 	App Icon  iPad
{'file':'Icon-76@2x.png', 'version' :  7.0, 'size' : 152},#  152 	App Icon  Retina iPad
{'file':'Icon-Small-40.png','version' :  7.0, 'size' : 	40},#  40 	Search/Settings  all devices
{'file':'Icon-Small-40@2x.png','version' :  7.0 , 'size' : 80},#  80 	Search/Settings  all devices
{'file':'Icon.png','version' :  6.1 , 'size' : 	57},#  57 	App Icon  iPhone
{'file':'Icon@2x.png','version' :  6.1, 'size' :  	114},#  114 	App Icon  Retina iPhone
{'file':'Icon-72.png','version' :  6.1, 'size' :  	72},#  72 	App Icon  iPad
{'file':'Icon-72@2x.png','version' :  6.1, 'size' :  	144},#  144 	App Icon  Retina iPad
{'file':'Icon-Small-50.png','version' :  6.1, 'size' :  	50},#  50 	Search/Settings  iPad
{'file':'Icon-Small-50@2x.png','version' :  6.1, 'size' :  	100},#  100 	Search/Settings  Retina iPad
{'file':'Icon-Small.png','version' :  6.1, 'size' :  	29},# 29 	Search/Settings  iPhone
{'file':'Icon-Small@2x.png','version' :  6.1, 'size' :  	58},#  58 	Search/Settings  Retina iPhone
{'file':'Icon-xxxhdpi.png', 'size' :	192},#  192
{'file':'Icon-xxhdpi.png', 'size' :  	144},#  144
{'file':'Icon-xhdpi.png', 'size' :  	96},#  96
{'file':'Icon-hdpi.png', 'size' : 	72},#  72
{'file':'Icon-mdpi.png', 'size' :  	48},#  48
{'file':'Icon-ldpi.png', 'size' :  	36},#  36
]

base_image_name = "icon_base_1024.png";
#base_image = misc.imread(base_image_name);
base_image = Image.open(base_image_name);

icon_count  =  len(icon_set)
print("creating icons("+str(icon_count)+"): ")
# --- using pySci and numpy produces lower quality aliased images
#resized_image = misc.imresize(base_image,(180, 180))#, 'bicubic');
#resized_image = misc.imfilter(resized_image,'smooth');
#misc.imsave("icons/resized_image.png", resized_image);

if show_results :
    n_rows = 2.0;
    n_cols = math.ceil(icon_count/n_rows);
    print("subplots :" + str((n_rows, n_cols)));
    #plt.subplot(1,math.floor(n_cols/2), 1);
    #plt.imshow(base_image)
    #plt.axis('off')
    #plt.title(base_image_name);
    count = 0;


for iconDef in icon_set:
    print(iconDef['file']);
    size = iconDef['size'];
    # see http://effbot.org/imagingbook/image.htm
    resized_image = base_image.resize((size,size), Image.ANTIALIAS);
    resized_image.save("icons/"+ iconDef['file'], "PNG");

    if show_results :
        count = count+1;
        index = count;#(count-1) % n_cols+1;
        #print("index :" + str(index))
        plt.subplot(n_rows,n_cols, index);
        plt.imshow(resized_image);
        plt.axis('off')
        #plt.title(base_image_name);


if show_results :
    plt.show()


print("Done")