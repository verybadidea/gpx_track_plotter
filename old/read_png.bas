#include once "FBImage.bi"

screenres 640,480,32

dim as any ptr pImg = LoadRGBAFile("test.png")
if pImg <> 0 then
	'put (0,0),img,ALPHA ' <- per pixel alpha blending
	put (0,0), pImg, pset
	ImageDestroy(pImg)
else
	print "file error"
end if
getkey()
