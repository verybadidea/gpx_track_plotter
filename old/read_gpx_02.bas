#include once "libxml/xmlreader.bi"
#define NULL 0

#include once "inc/dbl2d_v03.bi"
#include once "inc/sgl2d_v03.bi"
#include once "inc/mouse.bi"
#include once "inc/scaledgr_dbl_v01.bi"
#include once "inc/trkpt.bi"
#include once "inc/stats.bi"

'-------------------------------------------------------------------------------

dim as trkpt_list track
dim as track_stats stats

const SW = 800, SH = 600
dim as scaled_graphics_type sg
sg.setScreen(SW, SH)

dim as integer mouseEvent, mouseDrag
dim as mouse_type mouse

'dim as string fileName = "gpx/Skiing-downhill.gpx"
'dim as string fileName = "gpx/biking-Sun May 3 17:27:23 2020-23.2km.gpx"
dim as string fileName = "gpx_files/2020-11-29 16-31 Running.gpx"
dim as integer result = track.readGpxFile(fileName)

print "fileName: " & fileName
print "readGpxFile: " & iif(result >= 0, "Ok", "error")
print "Num track points: " & track.size()
print "Track error count: " & track.check()
print "trackName: " & track.name_

if (result < 0) or (track.size() <= 0) and (track.check() <> 0) then
	print "Aborting..."
	getkey
	end -1
end if

stats.update(track)
stats.print_()

'track.saveTrackTsv("trackdump.tsv")

print !"\nFirst and last 8 data points:"
'print " Index", "yyyy-mm-dd - hh:mm:ss", "Latitude", "Longitude", "Elevation", "x-pos", "y-pos"
print " Index", "yyyy-mm-dd - hh:mm:ss", "Elevation [m]", "X-pos [m]", "Y-pos [m]", "Speed [m/s]"
if track.size() > 16 then
	for i as integer = 0 to track.size() - 1
		if i > 7 and i < track.size() - 8 then continue for
		with track.pt(i)
			print i, format(.dateTime, "yyyy-mm-dd - hh:mm:ss"), _
				format(.ele, "0.0"), _
				format(.p.x, "0.0"), format(.p.y, "0.0"), _
				format(.speed, "#.000")
				'format(.lat, "#.000000"), format(.lon, "#.000000"), _
		end with
	next
end if
getkey()

dim as ulong c
dim as single scale = 0.9 * MIN(SW / stats.xRange, SH / stats.yRange)
sg.setScaling(scale, dbl2d(stats.xCenter, stats.yCenter))
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
	dim as integer iNearMouse = 0
	dim as double distToMouseSqrd = mousePosMap.distSqrd(track.pt(0).p)
	for i as integer = 1 to track.size() - 1
		if mousePosMap.distSqrd(track.pt(i).p) < distToMouseSqrd then
			distToMouseSqrd = mousePosMap.distSqrd(track.pt(i).p)
			iNearMouse = i
		end if
	next

	screenlock
	sg.clearScreen(0)
	draw string(0, 0), "FileName: " & fileName
	draw string(0, 16), "Mouse: zoom + pan view"
	draw string(0, 32), "Mouse pos [m]: " & cint(mousePosMap.x) & ", " & cint(mousePosMap.y)
	draw string(0, 48), "Index: " & iNearMouse
	draw string(0, 65), "Speed [km/h]: " & format(track.pt(iNearMouse).speed * 3.6, "#.000")
	for i as integer = 0 to track.size() - 1
		with track.pt(i)
			c = rgb(250 - 230 * (.speed / stats.maxSpeed), 20 + 230 * (.speed / stats.maxSpeed), 20)
			sg.drawCircle(.p, 1.0, c)
			if i <> 0 then
				sg.drawLine(track.pt(i - 1).p, .p, c)
			end if
		end with
	next
	'highlight track point closest to mouse cursor
	sg.drawCircle(track.pt(iNearMouse).p, 1.0, rgb(255, 255, 255))
	dim as int2d cursorPos = sg.pos2screen(track.pt(iNearMouse).p)
	line(cursorPos.x, cursorPos.y - 5)-(cursorPos.x, cursorPos.y + 5)
	line(cursorPos.x - 5, cursorPos.y)-(cursorPos.x + 5, cursorPos.y)
	screenunlock
	sleep 1
wend

'TODO:
' max & avg speed from <extentions>
' highlight closest data point
' safe gpx file
' draw 10 km, 1 km grid for scale
'NEW:
' Read list of files
' Categories: Red = Running, Blue = cycling, Green = other (walking, hiking, skiing, yoga)
' How to know category?
' Make intensity heatmap
' Total stats
' Load map (open street map)

