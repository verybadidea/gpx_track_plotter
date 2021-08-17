#include "libxml/xmlreader.bi" 'libxml2 (http://xmlsoft.org/)

#include "map_image.bi" 'uses:
'- SNC (https://www.freebasic.net/forum/viewtopic.php?f=7&t=23421)
'- FBImage (https://www.freebasic.net/forum/viewtopic.php?t=24105)
'- Thunderforrest (https://www.thunderforest.com/)

#include "inc/dbl3d.bi"
#include "inc/sgl2d_v03.bi"
#include "inc/mouse.bi"
#include "inc/scaledgr_dbl_v01.bi"
#include "inc/trkpt.bi"
#include "inc/all_stats.bi"
#include "inc/file_list.bi"

function log10(value as double) as double
	return log(value) / log(10)
end function

function cos360(value as double) as double
	return cos(value * (PI / 180))
end function

'-------------------------------------------------------------------------------

const SW = 1024, SH = 1024 'graphics screen size

dim as trkpt_list track(any)
dim as integer numTracks = 0
dim as all_stats allStats

dim as integer mouseEvent, mouseDrag
dim as mouse_type mouse

dim as file_list fileList
fileList.create("gpx_files/Utrecht/", "*.gpx")
numTracks = fileList.size()
print "Number of files: " & str(numTracks)
redim track(numTracks-1)

'read all track/gpx files
for i as integer = 0 to numTracks - 1
	dim as string fileName = fileList.fileName(i)
	dim as integer result = track(i).readGpxFile(fileName)
	'debug info
	print "fileName: " & fileName
	print "readGpxFile: " & iif(result >= 0, "Ok", "error")
	print "Num track points: " & track(i).size()
	print "Track error count: " & track(i).check()
	print "trackName: " & track(i).name_
	'error
	if (result < 0) then
		print "Aborting..."
		getkey
		end -1
	end if
	track(i).calculate() 'derived data and stats
	'more debug info
	track(i).printStats()
	track(i).printFirstLast()
	print
next
print "====================================="
allStats.create(track())
'allStats.maxSpeed = 40 / 3.6 'limit to 40 km/h
allStats.print_()
print "Number of files: " & str(numTracks)
'track.saveTrackTsv("trackdump.tsv")

dim as trkpt_type ptRef
ptRef.Lon = AVG(allStats.minLon, allStats.maxLon)
ptRef.Lat = AVG(allStats.minLat, allStats.maxLat)
ptRef.Ele = AVG(allStats.minEle, allStats.maxEle)

dim as double dLon = (allStats.maxLon - allStats.minLon)
dim as double dLat = (allStats.maxLat - allStats.minLat)
print "dLon: "; dLon, "dLat: "; dLat

dim as integer zoomLevelLon = int(log(360 / dLon) / log(2) + 0.25) + 2 '+2 is 4x zoom = ~SW/256
dim as integer zoomLevelLat = int(log(180 / dLat) / log(2) + 0.25) + 2 '0.25 is because math fails
dim as integer zoomLevel = min(zoomLevelLon, zoomLevelLat)
print "zoomLevel: " & zoomLevel

print ptRef.Lon, ptRef.Lat, ptRef.Ele
dim as double pixelWidth = earthc * cos360(ptRef.Lat) / (2 ^ (zoomLevel + 8))
print "pixelWidth [m]: " & pixelWidth
dim as double mapWidth = pixelWidth * SW
print "mapWidth [km]: " & mapWidth / 1e3

'loop all tracks, calculate cartesian coordinates for all points
for i as integer = 0 to numTracks - 1
	track(i).calculateCart(ptRef)
next

print : print "Press a key to continue..."
getkey()
'sleep 1000

'switch to graphics screen
dim as scaled_graphics_type sg
sg.setScreen(SW, SH)
width SW \ 8, SH \ 16

print "Fetching image...", zoomLevel
'styles: atlas, landscape, outdoors, neighbourhood
dim as fb.image ptr pImg = getMapImage(ptRef.Lon, ptRef.Lat, zoomLevel, "atlas", SW, SH)
if pImg <> 0 then
	'put (0,0), pImg, pset
else
	print "image error"
	getkey()
	end -1
end if

dim as double maxSpeed = 40 / 3.6 'limit to 40 km/h for color
dim as dbl2d p0, p1
dim as ulong c
dim as single scale = SW / mapWidth '[1/m]
sg.setScaling(scale, dbl2d(0, 0))
while inkey <> chr(27)
	'zoom / drag view by mouse
	mouseEvent = handleMouse(mouse)
	if (mouse.buttons <> -1) then
		'if (mouseEvent = MOUSE_LB_PRESSED) then mouseDrag = 1
		'if (mouseEvent = MOUSE_LB_RELEASED) then mouseDrag = 0
		'if (mouseEvent = MOUSE_WHEEl_UP) then sg.scale *= 1.05
		'if (mouseEvent = MOUSE_WHEEl_DOWN) then sg.scale /= 1.05
	end if
	if (mouseDrag) then
		sg.offset.x -= (mouse.posChange.x / sg.scale)
		sg.offset.y += (mouse.posChange.y / sg.scale)
	end if
	'find track point closest to mouse
	dim as dbl2d mousePosMap = sg.screen2pos(mouse.pos)
	'~ dim as integer iNearMouse = 0
	'~ dim as double distToMouseSqrd = mousePosMap.distSqrd(track.pt(0).p)
	'~ for i as integer = 1 to track.size() - 1
		'~ if mousePosMap.distSqrd(track.pt(i).p) < distToMouseSqrd then
			'~ distToMouseSqrd = mousePosMap.distSqrd(track.pt(i).p)
			'~ iNearMouse = i
		'~ end if
	'~ next
	screenlock
	'sg.clearScreen(0)
	put (0,0), pImg, pset
	'~ draw string(0, 0), "FileName: " & fileName
	'draw string(8, 8), "Mouse: zoom + pan view", rgba(0,0,0,192)
	'draw string(8, 8), "Mouse pos [m]: " & cint(mousePosMap.x) & ", " & cint(mousePosMap.y), rgba(127,0,0,255)
	draw string(8, 8), "Mouse pos [km]: " & format(mousePosMap.x / 1000, "0.00") _
		& ", " & format(mousePosMap.y / 1000, "0.00"), rgba(127,0,0,255)
	'~ draw string(0, 48), "Index: " & iNearMouse
	'~ draw string(0, 65), "Speed [km/h]: " & format(track.pt(iNearMouse).speed * 3.6, "#.000")
	'draw tracks
	for iTr as integer = 0 to numTracks -1
		for iPt as integer = 0 to track(iTr).size() - 1
			'dim as single speedFraction = track(iTr).pt(iPt).speed / track(iTr).maxSpeed
			dim as single speedFraction = track(iTr).pt(iPt).speed / maxSpeed
			c = rgba(250 - 230 * speedFraction, 20 + 230 * speedFraction, 20, 127)
			p0 = p1 'copy last point
			p1 = dbl2d(track(iTr).pt(iPt).cartPos.x, track(iTr).pt(iPt).cartPos.y)
			if iPt <> 0 then
				sg.drawLine(p0, p1, c)
			end if
			sg.drawCircle(p1, 1.5, c)
		next
	next
	'put (0,0), pImg, alpha, 127
	'highlight track point closest to mouse cursor
	'~ sg.drawCircle(track.pt(iNearMouse).p, 1.0, rgb(255, 255, 255))
	'~ dim as int2d cursorPos = sg.pos2screen(track.pt(iNearMouse).p)
	'~ line(cursorPos.x, cursorPos.y - 5)-(cursorPos.x, cursorPos.y + 5)
	'~ line(cursorPos.x - 5, cursorPos.y)-(cursorPos.x + 5, cursorPos.y)
	dim as double rulerLen = 10 ^ int(log10(mapWidth / 2))
	dim as string rulerLenStr = str(int(rulerLen))
	select case rulerLenStr
		case"1000" : rulerLenStr = "1 km"
		case"10000" : rulerLenStr = "10 km"
		case"100000" : rulerLenStr = "100 km"
		case"1000000" : rulerLenStr = "1000 km"
		case else : rulerLenStr += " m"
	end select
	'plot distance ruler
	dim as integer x0 = 20
	dim as integer x1 = 20 + rulerLen * sg.scale
	draw string(20, sg.h - 40), rulerLenStr, rgba(127,0,0,255)
	line(x0, sg.h - 20) - (x1, sg.h - 20), rgba(127,0,0,255)
	line(x0, sg.h - 15) - (x0, sg.h - 25), rgba(127,0,0,255)
	line(x1, sg.h - 15) - (x1, sg.h - 25), rgba(127,0,0,255)
	'plot map certer marker
	line(SW \ 2, 0)-(SW \ 2, SH-1), rgba(127,0,0,127),,&b1110000011100000
	line(0, SH \ 2)-(SW-1, SH \ 2), rgba(127,0,0,127),,&b1110000011100000
	screenunlock
	sleep 1
wend

ImageDestroy(pImg)

'TODO:
' categorise on average speed walking (3...7 km/h), running (7...15), cycling(15...35), other
' filter data on max speed walking: 10, running: 20, cycling: 50
' optional fiter on too large elevation change (not for skiing)
' max & avg speed from <extentions>
' save gpx file

