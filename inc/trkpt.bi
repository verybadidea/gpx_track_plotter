#include "vbcompat.bi"
#include once "dbl2d_v03.bi"
#include once "dateTime_extra.bi"

#define MIN(a, b)  iif((a) < (b), (a), (b))
#define MAX(a, b)  iif((a) > (b), (a), (b))
#define AVG(a, b)  ((a + b) / 2)

const as double PI = 4 * atn(1)
const as string HT = !"\t" 'horizontal tab

'global position & time struct
type trkpt_type
	'DATA FROM FILE:
	dim as double lon, lat 'longitude (E-W), latitude (N-S)
	dim as double dateTime 'UTC
	dim as double ele 'elevation
	'dim as double ext_dir, ext_g_spd, ext_h_acc, ext_v_acc
	'CALCULATED DATA:
	dim as double speed
	dim as dbl3d cartPos 'Cartesian coordinate system x,y,x
end type

'simple spherical earth approximation
const as double EARTHC = 4e7 'circumfence [m] 360° 40075e3'
'dx = dLon * 4e7 * cos(avg(Lat1, Lat2) * PI / 180) / 360
'dy = dLat * 4e7 / 360
function deltaPos(pt1 as trkpt_type, pt2 as trkpt_type) as dbl3d
	dim as dbl3d dPos
	dPos.x = (pt1.lon - pt2.lon) * cos(AVG(pt1.lat, pt2.lat) * PI / 180) * earthc / 360
	dPos.y = (pt1.lat - pt2.lat) * earthc / 360
	dPos.z = (pt1.ele - pt2.ele)
	return dPos
end function

function distPos(pt1 as trkpt_type, pt2 as trkpt_type) as double
	dim as dbl3d dPos = deltaPos(pt1, pt2)
	return sqr(dPos.x * dPos.x + dPos.y * dPos.y + dPos.z * dPos.z)
end function

'-------------------------------------------------------------------------------

#define TRACK_OK 0
#define TRACK_XML_ERR -1
#define TRACK_SIZE_ERR -2
#define TRACK_BAD_DATA -3

type trkpt_list
	dim as string name_
	dim as trkpt_type pt(any)
	'calculated stats
	dim as double totalDist 'm
	dim as double totalTime 's
	dim as double maxSpeed, avgSpeed 'm/s
	dim as double minEle, maxEle 'm
	dim as double minLat, maxLat 'Latitude
	dim as double minLon, maxLon 'Longitude (BUG: At -180 to + 180 transition)
	'routines
	declare function addPoint() as integer
	declare function size() as integer
	declare function check() as integer
	declare sub clear_()
	declare function readGpxFile(fileName as string) as integer
	declare sub calculate()
	declare sub calculateCart(ptRef as trkpt_type)
	declare sub saveTrackTsv(fileName as string) 'should be a function!
	declare sub printFirstLast()
	declare sub resetStats()
	declare sub printStats()
end type

function trkpt_list.addPoint() as integer
	dim as integer ub = ubound(pt)
	redim preserve pt(ub + 1)
	return ub + 1
end function

function trkpt_list.size() as integer
	return ubound(pt) + 1
end function

'simple data validity check 
function trkpt_list.check() as integer
	dim as integer errorCount = 0
	for i as integer = 0 to ubound(pt)
		if pt(i).lat = 0 then errorCount += 1
		if pt(i).lon = 0 then errorCount += 1
		if pt(i).ele = 0 then errorCount += 1
		if pt(i).dateTime = 0 then errorCount += 1
	next
	return errorCount
end function

sub trkpt_list.clear_()
	erase(pt)
end sub

'returns < 0 or error
function trkpt_list.readGpxFile(fileName as string) as integer
	dim as xmlTextReaderPtr pReader = xmlReaderForFile(filename, NULL, 0)
	if (pReader = NULL) then
		'print "readGpxFile: Unable to open: "; fileName
		return TRACK_XML_ERR
	end if
	dim as const zstring ptr pConstName, pConstValue
	dim as const zstring ptr pAttrName, pAttrValue
	dim as integer nodetype, iTrkpt = -1
	dim as integer ret = xmlTextReaderRead(pReader)
	while (ret = 1)
		pConstName = xmlTextReaderConstName(pReader)
		pConstValue = xmlTextReaderConstValue(pReader)
		nodetype = xmlTextReaderNodeType(pReader)
		'print *pConstName, *pConstValue, nodetype
		if (nodetype = 1) then
			if (*pConstName = "name") then
				'check if not set already (name is a bit generic)
				if this.name_ = "" then
					'actual data is in next element
					ret = xmlTextReaderRead(pReader) 'read next
					pConstName = xmlTextReaderConstName(pReader)
					pConstValue = xmlTextReaderConstValue(pReader)
					if (ret = 1) then
						this.name_ = *pConstValue
					end if
				end if
			end if
			if (*pConstName = "trkpt") then
				iTrkpt = this.addPoint()
				if xmlTextReaderHasAttributes(pReader) = 1 then
					if xmlTextReaderMoveToAttributeNo(pReader, 0) then
						pAttrName = xmlTextReaderConstName(pReader)
						pAttrvalue = xmlTextReaderConstValue(pReader)
						if *pAttrName = "lat" then
							this.pt(iTrkpt).lat = cdbl(*pAttrvalue)
							'print "lat: " & *pAttrvalue
						end if
					end if
					if xmlTextReaderMoveToAttributeNo(pReader, 1) then
						pAttrName = xmlTextReaderConstName(pReader)
						pAttrvalue = xmlTextReaderConstValue(pReader)
						if *pAttrName = "lon" then
							this.pt(iTrkpt).lon = cdbl(*pAttrvalue)
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
					this.pt(iTrkpt).dateTime = gpxDateTimeValue(*cast(zstring ptr, pConstValue))
					'print "datetime: " & *pConstValue
				end if
			end if
			if (*pConstName = "ele") then
				'actual data is in next element
				ret = xmlTextReaderRead(pReader) 'read next
				pConstName = xmlTextReaderConstName(pReader)
				pConstValue = xmlTextReaderConstValue(pReader)
				if (ret = 1) then
					this.pt(iTrkpt).ele = cdbl(*pConstValue)
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
	if size() <= 0 then
		return TRACK_SIZE_ERR
	elseif check() <> 0 then
		return TRACK_BAD_DATA
	else
		return TRACK_OK
	end if
end function

sub trkpt_list.calculate() 'derived data and statistics
	dim as double dist, timeDiff
	dim as integer last = size() - 1
	'reset_()
	totalTime = DiffDateTimeSec(pt(0).dateTime, pt(last).dateTime)
	'compare sequential track points
	pt(0).speed = 0
	for i as integer = 1 to last
		dist = distPos(pt(i - 1), pt(i))
		totalDist += dist
		timeDiff = DiffDateTimeSec(pt(i - 1).dateTime, pt(i).dateTime)
		if timeDiff = 0 then
			pt(i).speed = 0
		else
			pt(i).speed = dist / timeDiff
			maxSpeed = max(maxSpeed, pt(i).speed)
		end if
	next
	avgSpeed = totalDist / totalTime
	minEle = pt(0).ele : maxEle = pt(0).ele
	minLat = pt(0).lat : maxLat = pt(0).lat
	minLon = pt(0).lon : maxLon = pt(0).lon
	for i as integer = 1 to last
		minEle = min(minEle, pt(i).ele)
		maxEle = max(maxEle, pt(i).ele)
		minLon = min(minLon, pt(i).Lon)
		maxLon = max(maxLon, pt(i).Lon)
		minLat = min(minLat, pt(i).Lat)
		maxLat = max(maxLat, pt(i).Lat)
	next
end sub

sub trkpt_list.calculateCart(ptRef as trkpt_type)
	for i as integer = 0 to size() - 1
		pt(i).cartPos = deltaPos(pt(i), ptRef)
	next
end sub

sub trkpt_list.saveTrackTsv(fileName as string)
	dim as integer fileNum = freefile()
	dim as string outStr = ""
	if open(fileName, for output, as fileNum) = 0 then
		outStr = "Index" & HT & "yyyy-mm-dd - hh:mm:ss" & HT & _
			"Longitude" & HT & "Latitude" & HT & "Elevation [m]" & HT & "Speed [m/s]"
		print #fileNum, outStr
		for i as integer = 0 to this.size() - 1
			with this.pt(i)
				outStr = str(i) & HT & format(.dateTime, "yyyy-mm-dd - hh:mm:ss") & HT & _
					format(.lon, "#.000000") & HT & format(.lat, "#.000000") & HT & _
					format(.ele, "0.0") & HT & format(.speed, "#.000")
				print #fileNum, outStr
			end with
		next
		close #fileNum
		print "saveTrackTsv: Track saved to: " & fileName
	else
		print "saveTrackTsv: Error opening for output: " & fileName
	end if
end sub

sub trkpt_list.printFirstLast()
	print !"\nFirst and last 3 data points:"
	print " Index", "yyyy-mm-dd - hh:mm:ss", "Longitude", "Latitude", "Elevation", "Speed [m/s]"
	if size() > 6 then
		for i as integer = 0 to size() - 1
			if i >= 3 and i < size() - 3 then continue for
			with pt(i)
				print i, format(.dateTime, "yyyy-mm-dd - hh:mm:ss"), _
					format(.lon, "#.000000"), format(.lat, "#.000000"), _
					format(.ele, "0.0"), format(.speed, "#.000")
			end with
		next
	end if
end sub

sub trkpt_list.resetStats()
	totalDist = 0 : totalTime = 0
	maxSpeed = 0 : avgSpeed = 0
	minLon = 0 : maxLon = 0
	minLat = 0 : maxLat = 0
	minEle = 0 : maxEle = 0
end sub

sub trkpt_list.printStats()
	print !"\nTrack stats:"
	print " totalDist [km]: " & format(totalDist / 1000, "0.000")
	print " totalTime [s]: " & format(totalTime, "0.0")
	print " avgSpeed [km/h]: " & format(avgSpeed * 3.6, "0.000") 
	print " maxSpeed [km/h]: " & format(maxSpeed * 3.6, "0.000")
	print " Longitude []: " & format(minLon, "0.000000") & " ... " & format(maxLon, "0.000000")
	print " Latitude []: " & format(minLat, "0.000000") & " ... " & format(maxLat, "0.000000")
	print " Elevation [m]: " & format(minEle, "0.0") & " ... " & format(maxEle, "0.0")
end sub
