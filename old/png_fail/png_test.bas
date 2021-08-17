#include "png.bi"
const SCR_W = 640, SCR_H = 480, SCR_BPP = 32

screenres SCR_W, SCR_H, SCR_BPP

dim as FB.IMAGE ptr pImage
pImage = imageread_png("crop.png", SCR_BPP )
if pImage = 0 then
	print "Image error"
else
	put (0,100), pImage
	imagedestroy(pImage)
end if
sleep

