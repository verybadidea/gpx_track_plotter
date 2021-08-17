#include "map_image.bi"

const SW = 800, SH = 600
screenres SW, SH, 32
width SW \ 8, SH \ 16

print "Fetching image..."
dim as fb.image ptr pImg = getMapImage(5.490290, 51.457360, 13, "neighbourhood", SW, SH)
if pImg <> 0 then
	put (0,0), pImg, pset
	ImageDestroy(pImg)
else
	print "image error"
end if

getkey()
