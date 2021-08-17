#include once "FBImage.bi"

' load RGB jpg and convert to 16-bit

chdir exepath()

screenres 640,480,16 ' <- 16bit 

var img = Load16BitRGB("tire.jpg")
put (0,0),img,PSET

sleep
ImageDestroy img


