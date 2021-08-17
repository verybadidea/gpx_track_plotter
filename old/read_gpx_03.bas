#include once "libxml/xmlreader.bi"
#define NULL 0

#include once "inc/dbl2d_v03.bi"
#include once "inc/sgl2d_v03.bi"
#include once "inc/mouse.bi"
#include once "inc/scaledgr_dbl_v01.bi"
#include once "inc/trkpt.bi"
#include once "inc/all_stats.bi"
#include once "inc/file_list.bi"

'-------------------------------------------------------------------------------

const SW = 1200, SH = 800

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
	'more debug info
	track(i).printStats()
	track(i).printFirstLast()
	print
next
print "====================================="
allStats.create(track())
allStats.maxSpeed = 40 / 3.6 'limit to 40 km/h
allStats.print_()
print "Number of files: " & str(numTracks)
'track.saveTrackTsv("trackdump.tsv")

dim as double dLon = (allStats.maxLon - allStats.minLon)
dim as integer zoomLevel = int(log(360 / dLon)/log(2))
print "zoomLevel: " & zoomLevel
dim as double lat = allStats.avgLat
dim as double pixelWidth = earthc * cos(lat) / (2 ^ (zoomLevel + 8))
print "pixelWidth [m]: " & pixelWidth
dim as double mapWidth = pixelWidth * SW
print "mapWidth [km]: " & mapWidth / 1e3
dim as double trackWidth = allStats.xRange
print "trackWidth [km]: " & trackWidth / 1e3

getkey()
'sleep 1000

dim as scaled_graphics_type sg
sg.setScreen(SW, SH)

dim as ulong c
'dim as single scale = 0.9 * MIN(SW / allStats.xRange, SH / allStats.yRange) '[1/m]
dim as single scale = SW / mapWidth '[1/m]
sg.setScaling(scale, dbl2d(allStats.xCenter, allStats.yCenter))
while inkey <> chr(27)
	'zoom / drag view by mouse
	mouseEvent = handleMouse(mouse)
		if (mouse.buttons <> -1) then
		if (mouseEvent = MOUSE_LB_PRESSED) then mouseDrag = 1
		if (mouseEvent = MOUSE_LB_RELEASED) then mouseDrag = 0
		if (mouseEvent = MOUSE_WHEEl_UP) then sg.scale *= 1.25
		if (mouseEvent = MOUSE_WHEEl_DOWN) then sg.scale /= 1.25
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
	sg.clearScreen(0)
	'~ draw string(0, 0), "FileName: " & fileName
	draw string(0, 16), "Mouse: zoom + pan view"
	draw string(0, 32), "Mouse pos [m]: " & cint(mousePosMap.x) & ", " & cint(mousePosMap.y)
	'~ draw string(0, 48), "Index: " & iNearMouse
	'~ draw string(0, 65), "Speed [km/h]: " & format(track.pt(iNearMouse).speed * 3.6, "#.000")
	'draw tracks
	for iTr as integer = 0 to numTracks -1
		for iPt as integer = 0 to track(iTr).size() - 1
			'dim as single speedFraction = track(iTr).pt(iPt).speed / track(iTr).maxSpeed
			dim as single speedFraction = track(iTr).pt(iPt).speed / allStats.maxSpeed
			c = rgb(250 - 230 * speedFraction, 20 + 230 * speedFraction, 20)
			sg.drawCircle(track(iTr).pt(iPt).p, 1.0, c)
			if iPt <> 0 then
				sg.drawLine(track(iTr).pt(iPt - 1).p, track(iTr).pt(iPt).p, c)
			end if
		next
	next
	'highlight track point closest to mouse cursor
	'~ sg.drawCircle(track.pt(iNearMouse).p, 1.0, rgb(255, 255, 255))
	'~ dim as int2d cursorPos = sg.pos2screen(track.pt(iNearMouse).p)
	'~ line(cursorPos.x, cursorPos.y - 5)-(cursorPos.x, cursorPos.y + 5)
	'~ line(cursorPos.x - 5, cursorPos.y)-(cursorPos.x + 5, cursorPos.y)
	screenunlock
	sleep 1
wend

'TODO:
' max & avg speed from <extentions>
' save gpx file
' draw 10 km, 1 km grid for scale
' Categories: Red = Running, Blue = cycling, Green = other (walking, hiking, skiing, yoga)
' How to know category? from <description>
' Make intensity heatmap
' Load map (open street map)
