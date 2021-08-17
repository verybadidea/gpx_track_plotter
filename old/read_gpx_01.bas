#include once "libxml/xmlreader.bi"
#define NULL 0

#include once "inc/dbl2d_v03.bi"
#include once "inc/sgl2d_v03.bi"
#include once "inc/trkpt.bi"
#include once "inc/dateTime_extra.bi"
#include once "inc/scaledgr_v01.bi"
#include once "inc/mouse.bi"

const as double PI = 4 * atn(1)
#define MIN(a, b)  iif((a) < (b), (a), (b))
#define MAX(a, b)  iif((a) > (b), (a), (b))
const as string HT = !"\t" 'horizontal tab

'-------------------------------------------------------------------------------

'returns < 0 or error
function readGpxFile(fileName as string, track as trkpt_list) as integer
	dim as xmlTextReaderPtr pReader = xmlReaderForFile(filename, NULL, 0)
	if (pReader = NULL) then
		'print "readGpxFile: Unable to open: "; fileName
		return -1
	end if
	
	dim as const zstring ptr pConstName, pConstValue
	dim as const zstring ptr pAttrName, pAttrValue
	dim as integer nodetype, iTrkpt = -1

	dim as integer ret = xmlTextReaderRead(pReader)
	while (ret = 1)
		pConstName = xmlTextReaderConstName(pReader)
		pConstValue = xmlTextReaderConstValue(pReader)
		nodetype = xmlTextReaderNodeType(pReader)
		if (nodetype = 1) then
			if (*pConstName = "trkpt") then
				iTrkpt = track.add()
				if xmlTextReaderHasAttributes(pReader) = 1 then
					if xmlTextReaderMoveToAttributeNo(pReader, 0) then
						pAttrName = xmlTextReaderConstName(pReader)
						pAttrvalue = xmlTextReaderConstValue(pReader)
						if *pAttrName = "lat" then
							track.pt(iTrkpt).lat = cdbl(*pAttrvalue)
							'print "lat: " & *pAttrvalue
						end if
					end if
					if xmlTextReaderMoveToAttributeNo(pReader, 1) then
						pAttrName = xmlTextReaderConstName(pReader)
						pAttrvalue = xmlTextReaderConstValue(pReader)
						if *pAttrName = "lon" then
							track.pt(iTrkpt).lon = cdbl(*pAttrvalue)
							'print "lon: " & *pAttrvalue
						end if
					end if
				end if
			end if
			if (*pConstName = "time") then
				'actual data is in next element
				ret = xmlTextReaderRead(pReader) 'read next
				pConstName = xmlTextReaderConstName(pReader)
				pConstValue = xmlTextReaderConstValue(pReader)
				if (ret = 1) then
					track.pt(iTrkpt).dateTime = gpxDateTimeValue(*cast(zstring ptr, pConstValue))
					'print "datetime: " & *pConstValue
				end if
			end if
			if (*pConstName = "ele") then
				'actual data is in next element
				ret = xmlTextReaderRead(pReader) 'read next
				pConstName = xmlTextReaderConstName(pReader)
				pConstValue = xmlTextReaderConstValue(pReader)
				if (ret = 1) then
					track.pt(iTrkpt).ele = cdbl(*pConstValue)
					'print "ele: " & *pConstValue
					'print
					'getkey()
				end if
			end if
		end if
		'getkey()
		ret = xmlTextReaderRead(pReader)
	wend

	xmlFreeTextReader(pReader)

	if (ret <> 0) then print "readGpxFile: Failed to parse: "; filename

	xmlCleanupParser()
	xmlMemoryDump()
end function

sub saveTrackTsv(fileName as string, track as trkpt_list)
	dim as integer fileNum = freefile()
	dim as string outStr = ""
	if open(fileName, for output, as fileNum) = 0 then
		outStr = "Index" & HT & "yyyy-mm-dd - hh:mm:ss" & HT & _
			"Latitude" & HT & "Longitude" & HT & "Elevation [m]" & HT & _
			"X-pos [m]" & HT & "Y-pos [m]" & HT & "Speed [m/s]"
		print #fileNum, outStr
		for i as integer = 0 to track.size() - 1
			with track.pt(i)
				outStr = str(i) & HT & format(.dateTime, "yyyy-mm-dd - hh:mm:ss") & HT & _
					format(.lat, "#.000000") & HT & format(.lon, "#.000000") & HT & format(.ele, "0.0") & HT & _ 
					format(.p.x, "0.0") & HT & format(.p.y, "0.0") & HT & format(.speed, "#.000")
				print #fileNum, outStr
			end with
		next
		close #fileNum
		print "saveTrackTsv: Track saved to: " & fileName
	else
		print "saveTrackTsv: Error opening for output: " & fileName
	end if
end sub

'-------------------------------------------------------------------------------

'simple spherical earth approximation
function deltaPos(pt1 as trkpt_type, pt2 as trkpt_type) as dbl2d
	dim as dbl2d dPos
	dPos.x = (pt1.lon - pt2.lon) * 4e7 * cos((pt1.lat + pt2.lat) * PI / 360) / 360
	dPos.y = (pt1.lat - pt2.lat) * 4e7 / 360
	return dPos
end function

'-------------------------------------------------------------------------------

type track_stats
	dim as double totalDist 'm
	dim as double totalTime 's
	dim as double maxSpeed, avgSpeed 'm/s
	dim as double minXpos, maxXpos 'm
	dim as double minYpos, maxYpos 'm
	dim as double minZpos, maxZpos 'm
	dim as double xRange, xCenter 'm
	dim as double yRange, yCenter 'm
	declare sub reset_()
	declare sub print_()
	declare sub update(track as trkpt_list)
end type

sub track_stats.reset_()
	totalDist = 0 : totalTime = 0
	maxSpeed = 0 : avgSpeed = 0
	minXpos = 0 : maxXpos = 0
	minYpos = 0 : maxYpos = 0
	minZpos = 0 : maxZpos = 0
end sub

sub track_stats.print_()
	print !"\nTrack stats:"
	print " totalDist [km]: " & format(totalDist / 1000, "0.000")
	print " totalTime [s]: " & format(totalTime, "0.0")
	print " avgSpeed [km/h]: " & format(avgSpeed * 3.6, "0.000") 
	print " maxSpeed [km/h]: " & format(maxSpeed * 3.6, "0.000")
	print " X-range [km]: " & format(minXpos / 1000, "0.000") & " ... " & format(maxXpos / 1000, "0.000")
	print " Y-range [km]: " & format(minYpos / 1000, "0.000") & " ... " & format(maxYpos / 1000, "0.000")
	print " Z-range [m]: " & format(minZpos, "0.0") & " ... " & format(maxZpos, "0.0")
end sub

sub track_stats.update(track as trkpt_list)
	dim as dbl2d dPos
	dim as double dist, timeDiff
	dim as integer last = track.size() - 1
	reset_()
	totalTime = DiffDateTimeSec(track.pt(0).dateTime, track.pt(last).dateTime)
	'compare sequential track points
	track.pt(0).speed = 0
	for i as integer = 1 to last
		dPos = deltaPos(track.pt(i - 1), track.pt(i))
		dist = sqr(dPos.x * dPos.x + dPos.y * dPos.y)
		totalDist += dist
		timeDiff = DiffDateTimeSec(track.pt(i - 1).dateTime, track.pt(i).dateTime)
		track.pt(i).speed = dist / timeDiff
		if track.pt(i).speed > maxSpeed then maxSpeed = track.pt(i).speed
	next
	avgSpeed = totalDist / totalTime
	'compare track points against first point
	track.pt(0).p = dbl2d(0, 0)
	minZpos = track.pt(0).ele
	maxZpos = track.pt(0).ele
	for i as integer = 1 to last
		dim as dbl2d dPos = deltaPos(track.pt(i), track.pt(0))
		track.pt(i).p = dPos
		if dPos.x < minXpos then minXpos = dPos.x 
		if dPos.x > maxXpos then maxXpos = dPos.x 
		if dPos.y < minYpos then minYpos = dPos.y 
		if dPos.y > maxYpos then maxYpos = dPos.y
		dim as double ele = track.pt(i).ele
		if ele < minZpos then minZpos = ele 
		if ele > maxZpos then maxZpos = ele
	next
	xRange = maxXpos - minXpos
	yRange = maxYpos - minYpos
	xCenter = (maxXpos + minXpos) / 2
	yCenter = (maxYpos + minYpos) / 2
end sub

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
dim as string fileName = "gpx/biking-Sun Jul 12 15:52:45 2020-50.3km.gpx"
dim as integer result = readGpxFile(fileName, track)

print "fileName: " & fileName
print "readGpxFile: " & iif(result >= 0, "Ok", "error")
print "Num track points: " & track.size()
print "Track error count: " & track.check()

if (result < 0) or (track.size() <= 0) and (track.check() <> 0) then
	print "Aborting..."
	getkey
	end -1
end if

stats.update(track)
stats.print_()

saveTrackTsv("trackdump.tsv", track)

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
sg.setScaling(scale, sgl2d(stats.xCenter, stats.yCenter))
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

	screenlock
	sg.clearScreen(0)
	draw string(0, 0), "fileName: " & fileName
	draw string(0, 16), "Mouse: zoom + pan view"
	
	for i as integer = 0 to track.size() - 1
		with track.pt(i)
			c = rgb(250 - 230 * (.speed / stats.maxSpeed), 20 + 230 * (.speed / stats.maxSpeed), 20)
			'sg.drawPixel(sgl2d(.p.x, .p.y), c)
			sg.drawCircle(sgl2d(.p.x, .p.y), 1.0, c)
			if i <> 0 then
				sg.drawLine(sgl2d(track.pt(i - 1).p.x, track.pt(i - 1).p.y), _
					sgl2d(.p.x, .p.y), c)
			end if
		end with
	next
	screenunlock
	sleep 1
wend

'TODO
'load name
'highlight closest data point
'safe file
