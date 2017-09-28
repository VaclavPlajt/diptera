__author__ = 'plastique'

import Image;
import ImageEnhance;

input_dir = "postproces_inputs";
output_dir = "postproces_output";



def processImageFile(im_file, out_file):
    im = Image.open(im_file);
    enh = ImageEnhance.Contrast(im);
    eim = enh.enhance(1.25)#.show("30% more contrast");
    eim.save(out_file);



im_file = input_dir + "/walls/W.png";
out_file = output_dir + "/walls/W.png";

#processImageFile(im_file, out_file);

#process all png files in input directory and its subdirectories
import os
count =0;

for dirname, dirnames, filenames in os.walk(input_dir):

    # print path to all subdirectories first.
    #for subdirname in dirnames:
    #    print os.path.join(dirname, subdirname)

    # print path to all filenames.
    for filename in filenames:

        if '.png' in filename :
            #print("dirname: " + dirname)
            file_path = os.path.join(dirname, filename)
            #print("process: " + file_path)


            out_path = dirname.replace(input_dir, output_dir)


            # create otput directory if necessary
            if os.path.exists(out_path) == False :
                print("creating directory:" + out_path);
                os.mkdir(out_path);

            out_file = os.path.join(out_path, filename)
            #print("and save to: " + out_file)

            processImageFile(file_path, out_file);
            count+=1;
            print(out_file)
print(str(count)  + " files processed.")

