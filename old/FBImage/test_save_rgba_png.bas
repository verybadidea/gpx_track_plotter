#include once "FBImage.bi"

chdir exepath()

screenres 640,480,32 ' <- RGBA

var img = LoadRGBAFile("lights_alpha.png")

put (0,0),img,ALPHA ' <- per pixel alpha blending

var ok = SavePNGFile(img,"test_rgba.png",true) ' true = save with alpha channel
windowtitle "SavePNGFile() = " & ok
sleep
