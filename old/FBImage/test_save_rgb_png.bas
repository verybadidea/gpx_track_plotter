#include once "FBImage.bi"

chdir exepath()

screenres 640,480,24 ' <- RGB

var img = LoadRGBAFile("tire.jpg")
put (0,0),img,PSET

var ok = SavePNGFile(img,"test_rgb.png") ' <- default save with alpha channel = false
windowtitle "SavePNGile() = " & ok
sleep
