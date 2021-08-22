#include "libxml/xmlreader.bi" 'libxml2 (http://xmlsoft.org/)

#include "map_image.bi" 'uses:
'- SNC (https://www.freebasic.net/forum/viewtopic.php?f=7&t=23421)
'- FBImage (https://www.freebasic.net/forum/viewtopic.php?t=24105)
'- Thunderforrest (https://www.thunderforest.com/)

#include "inc/macro.bi"
#include "inc/math.bi"
#include "inc/dbl3d.bi"
#include "inc/mouse.bi"
#include "inc/scaledgr_dbl_v01.bi"
#include "inc/trkpt.bi"
#include "inc/all_stats.bi"
#include "inc/file_list.bi"

'-------------------------------------------------------------------------------

const SW = 1024, SH = 1024 'graphics screen size

dim as trkpt_list track(any)
dim as integer numTracks = 0
dim as all_stats allStats

dim as integer mouseEvent, mouseDrag
dim as mouse_type mouse

dim as file_list fileList
fileList.create("gpx_files/", "*.gpx")
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
	track(i).filter()
	track(i).calculate()
	dim as integer activity = quessActivity(track(i).avgSpeed, track(i).totalDist)
	print "Activity (quess): " & activityString(activity)
	if track(i).maxSpeed > activityMaxSpeed(activity) then
		print "vMax exceeded: " & activityMaxSpeed(activity) * 3.6
	end if
	'more debug info
	track(i).printStats()
	track(i).printFirstLast()
	'track(i).saveTrackTsv("trackdump2.tsv")
	print
next
print "====================================="
allStats.create(track())
'allStats.maxSpeed = 40 / 3.6 'limit to 40 km/h
allStats.print_()
print "Number of files: " & str(numTracks)

dim as geo_pos refPos
refPos.Lon = AVG(allStats.minPos.Lon, allStats.maxPos.Lon)
refPos.Lat = AVG(allStats.minPos.Lat, allStats.maxPos.Lat)
refPos.Ele = AVG(allStats.minPos.Ele, allStats.maxPos.Ele)

dim as double dLon = (allStats.maxPos.Lon - allStats.minPos.Lon)
dim as double dLat = (allStats.maxPos.Lat - allStats.minPos.Lat)
print "dLon: "; dLon, "dLat: "; dLat

dim as integer zoomLevelLon = int(log(360 / dLon) / log(2) + 0.25) + 2 '+2 is 4x zoom = ~SW/256
dim as integer zoomLevelLat = int(log(180 / dLat) / log(2) + 0.25) + 2 '0.25 is because math fails
dim as integer zoomLevel = min(zoomLevelLon, zoomLevelLat)
print "zoomLevel: " & zoomLevel

print refPos.Lon, refPos.Lat, refPos.Ele
dim as double pixelWidth = earthc * cos360(refPos.Lat) / (2 ^ (zoomLevel + 8))
print "pixelWidth [m]: " & pixelWidth
dim as double mapWidth = pixelWidth * SW
print "mapWidth [km]: " & mapWidth / 1e3

'loop all tracks, calculate cartesian coordinates for all points
for i as integer = 0 to numTracks - 1
	track(i).calculateCart(refPos)
next

print : print "Press a key to continue. <Escape> to quit."
dim as long keyCode = getkey()
if keyCode = 27 then end
'sleep 1000

'switch to graphics screen
dim as scaled_graphics_type sg
sg.setScreen(SW, SH)
width SW \ 8, SH \ 16

print "Fetching image..."
'styles: atlas, landscape, outdoors, neighbourhood
dim as fb.image ptr pImg = getMapImage(refPos.Lon, refPos.Lat, zoomLevel, "atlas", SW, SH)
if pImg <> 0 then
	'put (0,0), pImg, pset
else
	print "Error getting image from Thunderforrest"
	getkey()
	end -1
end if

dim as double maxSpeed = 40 / 3.6 'limit to 40 km/h for color
dim as dbl2d p0, p1
dim as ulong c
dim as string key
dim as single scale = SW / mapWidth '[1/m]
dim as dbl2d centerPos = dbl2d(0, 0)
sg.setScaling(scale, centerPos)
while key <> chr(27) 'escape
	key = inkey()
	'zoom / drag view by mouse
	mouseEvent = handleMouse(mouse)
	if (mouse.buttons <> -1) then
		if (mouseEvent = MOUSE_LB_PRESSED) then mouseDrag = 1
		if (mouseEvent = MOUSE_LB_RELEASED) then mouseDrag = 0
		if (mouseEvent = MOUSE_WHEEl_UP) then
			if zoomLevel < 20 then sg.scale *= 2 : zoomLevel += 1
		end if
		if (mouseEvent = MOUSE_WHEEl_DOWN) then
			if zoomLevel > 2 then sg.scale /= 2 : zoomLevel -= 1
		end if
	end if
	if (mouseDrag) then
		sg.offset.x -= (mouse.posChange.x / sg.scale)
		sg.offset.y += (mouse.posChange.y / sg.scale)
	end if
	if key = chr(32) then 'space
		'read map from Thunderforrest at new zoomlevel and position
		locate 1,1 : print "Fetching new image..."
		ImageDestroy(pImg) : pImg = 0
		dim as dbl2d shift = centerPos - sg.offset
		dim as dbl3d dPos = type(shift.x, shift.y, 0)
		centerPos = sg.offset
		refPos = moveGeoPos(refPos, dPos)
		pImg = getMapImage(refPos.Lon, refPos.Lat, zoomLevel, "atlas", SW, SH)
		if pImg = 0 then
			print "Error getting image from Thunderforrest"
			exit while 'abort
		end if
		pixelWidth = earthc * cos360(refPos.Lat) / (2 ^ (zoomLevel + 8))
		mapWidth = pixelWidth * SW
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
	draw string(8, 8), "Mouse: zoom + pan view", rgba(127,0,0,255)
	'draw string(8, 8), "Mouse pos [m]: " & cint(mousePosMap.x) & ", " & cint(mousePosMap.y), rgba(127,0,0,255)
	draw string(8, 24), "Mouse pos [km]: " & format(mousePosMap.x / 1000, "0.00") _
		& ", " & format(mousePosMap.y / 1000, "0.00"), rgba(127,0,0,255)
	'~ draw string(8, 24), "Center Pos [km]: " & format(sg.offset.x / 1000, "0.00") _
		'~ & ", " & format(sg.offset.y / 1000, "0.00"), rgba(127,0,0,255)
	draw string(8, 40), "Press <space> to read map image", rgba(127,0,0,255)
	draw string(8, 56), "Zoomlevel: " & zoomLevel, rgba(127,0,0,255)

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
	dim as ulong cRuler = rgba(127,0,0,255)
	dim as integer x0 = 20
	dim as integer x1 = 20 + rulerLen * sg.scale
	draw string(20, sg.h - 40), rulerLenStr, cRuler
	line(x0, sg.h - 20) - (x1, sg.h - 20), cRuler
	line(x0, sg.h - 15) - (x0, sg.h - 25), cRuler
	line(x1, sg.h - 15) - (x1, sg.h - 25), cRuler
	'plot map certer marker
	line(SW \ 2, 0)-(SW \ 2, SH-1), rgba(127,0,0,127),,&b1110000011100000
	line(0, SH \ 2)-(SW-1, SH \ 2), rgba(127,0,0,127),,&b1110000011100000
	'plot center of tracks indicator
	sg.drawCircle(dbl2d(0, 0), 5, cRuler)
	sg.drawCircle(dbl2d(0, 0), 2, cRuler)
	'sg.drawLine(p0, p1, c)
	screenunlock
	sleep 1
wend

ImageDestroy(pImg)

'TODO:
' error with zoom & shift
' max & avg speed from <extentions>
' save gpx file

