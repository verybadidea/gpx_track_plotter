#include once "FBImage.bi"

' load RGB jpg

chdir exepath()

screenres 640,480,24 ' <- RGB

var img = LoadRGBAFile("tire.jpg")

put (0,0),img,PSET

sleep
ImageDestroy img
