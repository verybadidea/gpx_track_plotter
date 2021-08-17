#Include Once "libxml/xmlreader.bi"
#Define NULL 0

'===============================================================================

Type dbl2d
	As Double x, y
	Declare Constructor
	Declare Constructor(x As Double, y As Double)
End Type

Constructor dbl2d
End Constructor

Constructor dbl2d(x As Double, y As Double)
	This.x = x : This.y = y
End Constructor

'===============================================================================

Type trkpt_type
	'DATA FROM FILE:
	Dim As Double lat, lon 'latitude and longitude
	Dim As Double dateTime 'UTC
	Dim As Double ele 'elevation
	'dim as double ext_dir, ext_g_spd, ext_h_acc, ext_v_acc
	'DERIVED DATA:
	Dim As Double speed 'scalar
	Dim As dbl2d p 'position x,y relative to pt(0)
End Type

Type trkpt_list
	Dim As trkpt_type pt(Any)
	Declare Function Add() As Integer
	Declare Function size() As Integer
	Declare Function check() As Integer
End Type

Function trkpt_list.add() As Integer
	Dim As Integer ub = UBound(pt)
	ReDim Preserve pt(ub + 1)
	Return ub + 1
End Function

Function trkpt_list.size() As Integer
	Return UBound(pt) + 1
End Function

'simple data validity check 
Function trkpt_list.check() As Integer
	Dim As Integer errorCount = 0
	For i As Integer = 0 To UBound(pt)
		If pt(i).lat = 0 Then errorCount += 1
		If pt(i).lon = 0 Then errorCount += 1
		If pt(i).ele = 0 Then errorCount += 1
		If pt(i).dateTime = 0 Then errorCount += 1
	Next
	Return errorCount
End Function

'===============================================================================

#Include "vbcompat.bi"

Enum E_DATE_FORMAT
	DATE_FORMAT_ISO
	DATE_FORMAT_NL
	DATE_FORMAT_DE
	DATE_FORMAT_US
End Enum

Function dateString(dateTimeVal As Double, dateFormat As E_DATE_FORMAT) As String
	Select Case dateFormat
	Case DATE_FORMAT_ISO
		Return Format(dateTimeVal, "yyyy-mm-dd")
	Case DATE_FORMAT_NL
		Return Format(dateTimeVal, "dd-mm-yyyy")
	Case DATE_FORMAT_DE
		Return Format(dateTimeVal, "dd.mm.yyyy")
	Case DATE_FORMAT_US
		Return Format(dateTimeVal, "mm/dd/yyyy")
	End Select
	Return "<invalid>"
End Function

'day, month, year format must be: dd, mm, yyyy (e.g. not 7/5/20 or 2020-7-5)
Function dateValue2(dateStr As String, dateFormat As E_DATE_FORMAT) As Long
	If Len(dateStr) <> 10 Then Return -1
	Dim As String y, m, d 'years, months, days
	Select Case dateFormat
	Case DATE_FORMAT_ISO
		If Mid(dateStr, 5, 1) <> "-" Then Return -1
		If Mid(dateStr, 8, 1) <> "-" Then Return -1
		y = Mid(dateStr, 1, 4)
		m = Mid(dateStr, 6, 2)
		d = Mid(dateStr, 9, 2)
	Case DATE_FORMAT_NL
		If Mid(dateStr, 3, 1) <> "-" Then Return -1
		If Mid(dateStr, 6, 1) <> "-" Then Return -1
		y = Mid(dateStr, 7, 4)
		m = Mid(dateStr, 4, 2)
		d = Mid(dateStr, 1, 2)
	Case DATE_FORMAT_DE
		If Mid(dateStr, 3, 1) <> "." Then Return -1
		If Mid(dateStr, 6, 1) <> "." Then Return -1
		y = Mid(dateStr, 7, 4)
		m = Mid(dateStr, 4, 2)
		d = Mid(dateStr, 1, 2)
	Case DATE_FORMAT_US
		If Mid(dateStr, 3, 1) <> "/" Then Return -1
		If Mid(dateStr, 6, 1) <> "/" Then Return -1
		y = Mid(dateStr, 7, 4)
		m = Mid(dateStr, 1, 2)
		d = Mid(dateStr, 4, 2)
	Case Else
		Return -1
	End Select
	Return DateSerial(Val(y), Val(m), Val(d))
End Function

'Convert 2020-05-03T16:28:56Z to 43954.68675925926
Function gpxDateTimeValue(gpxDateTimeStr As String) As Double
	Return dateValue2(Mid(gpxDateTimeStr, 1, 10), DATE_FORMAT_ISO) _
		+ TimeValue(Mid(gpxDateTimeStr, 12, 8))
End Function

Function DiffDateTimeSec(dt1 As Double, dt2 As Double) As Double
	Return (dt2 - dt1) * 24 * 3600
End Function 

'===============================================================================

Const As Double PI = 4 * Atn(1)

'returns < 0 or error
Function readGpxFile(fileName As String, track As trkpt_list) As Integer
	Dim As xmlTextReaderPtr pReader = xmlReaderForFile(filename, NULL, 0)
	If (pReader = NULL) Then
		'print "readGpxFile: Unable to open: "; fileName
		Return -1
	End If
	
	Dim As Const ZString Ptr pConstName, pConstValue
	Dim As Const ZString Ptr pAttrName, pAttrValue
	Dim As Integer nodetype, iTrkpt = -1

	Dim As Integer ret = xmlTextReaderRead(pReader)
	While (ret = 1)
		pConstName = xmlTextReaderConstName(pReader)
		pConstValue = xmlTextReaderConstValue(pReader)
		nodetype = xmlTextReaderNodeType(pReader)
		If (nodetype = 1) Then
			If (*pConstName = "trkpt") Then
				iTrkpt = track.add()
				If xmlTextReaderHasAttributes(pReader) = 1 Then
					If xmlTextReaderMoveToAttributeNo(pReader, 0) Then
						pAttrName = xmlTextReaderConstName(pReader)
						pAttrvalue = xmlTextReaderConstValue(pReader)
						If *pAttrName = "lat" Then
							track.pt(iTrkpt).lat = CDbl(*pAttrvalue)
							'print "lat: " & *pAttrvalue
						End If
					End If
					If xmlTextReaderMoveToAttributeNo(pReader, 1) Then
						pAttrName = xmlTextReaderConstName(pReader)
						pAttrvalue = xmlTextReaderConstValue(pReader)
						If *pAttrName = "lon" Then
							track.pt(iTrkpt).lon = CDbl(*pAttrvalue)
							'print "lon: " & *pAttrvalue
						End If
					End If
				End If
			End If
			If (*pConstName = "time") Then
				'actual data is in next element
				ret = xmlTextReaderRead(pReader) 'read next
				pConstName = xmlTextReaderConstName(pReader)
				pConstValue = xmlTextReaderConstValue(pReader)
				If (ret = 1) Then
					track.pt(iTrkpt).dateTime = gpxDateTimeValue(*Cast(ZString Ptr, pConstValue))
					'print "datetime: " & *pConstValue
				End If
			End If
			If (*pConstName = "ele") Then
				'actual data is in next element
				ret = xmlTextReaderRead(pReader) 'read next
				pConstName = xmlTextReaderConstName(pReader)
				pConstValue = xmlTextReaderConstValue(pReader)
				If (ret = 1) Then
					track.pt(iTrkpt).ele = CDbl(*pConstValue)
					'print "ele: " & *pConstValue
					'print
					'getkey()
				End If
			End If
		End If
		'getkey()
		ret = xmlTextReaderRead(pReader)
	Wend

	xmlFreeTextReader(pReader)

	If (ret <> 0) Then Print "readGpxFile: Failed to parse: "; filename

	xmlCleanupParser()
	xmlMemoryDump()
End Function

'-------------------------------------------------------------------------------

'simple spherical earth approximation
Function deltaPos(pt1 As trkpt_type, pt2 As trkpt_type) As dbl2d
	Dim As dbl2d dPos
	dPos.x = (pt1.lon - pt2.lon) * 4e7 * Cos((pt1.lat + pt2.lat) * PI / 360) / 360
	dPos.y = (pt1.lat - pt2.lat) * 4e7 / 360
	Return dPos
End Function

'-------------------------------------------------------------------------------

Type track_stats
	Dim As Double totalDist 'm
	Dim As Double totalTime 's
	Dim As Double maxSpeed, avgSpeed 'm/s
	Dim As Double minXpos, maxXpos 'm
	Dim As Double minYpos, maxYpos 'm
	Dim As Double minZpos, maxZpos 'm
	Declare Sub reset_()
	Declare Sub print_()
	Declare Sub update(track As trkpt_list)
End Type

Sub track_stats.reset_()
	totalDist = 0 : totalTime = 0
	maxSpeed = 0 : avgSpeed = 0
	minXpos = 0 : maxXpos = 0
	minYpos = 0 : maxYpos = 0
	minZpos = 0 : maxZpos = 0
End Sub

Sub track_stats.print_()
	Print !"\nTrack stats:"
	Print " totalDist [km]: " & Format(totalDist / 1000, "0.000")
	Print " totalTime [s]: " & Format(totalTime, "0.0")
	Print " avgSpeed [km/h]: " & Format(avgSpeed * 3.6, "0.000") 
	Print " maxSpeed [km/h]: " & Format(maxSpeed * 3.6, "0.000")
	Print " X-range [km]: " & Format(minXpos / 1000, "0.000") & " ... " & Format(maxXpos / 1000, "0.000")
	Print " Y-range [km]: " & Format(minYpos / 1000, "0.000") & " ... " & Format(maxYpos / 1000, "0.000")
	Print " Z-range [m]: " & Format(minZpos, "0.0") & " ... " & Format(maxZpos, "0.0")
End Sub

Sub track_stats.update(track As trkpt_list)
	Dim As dbl2d dPos
	Dim As Double dist, timeDiff
	Dim As Integer last = track.size() - 1
	reset_()
	totalTime = DiffDateTimeSec(track.pt(0).dateTime, track.pt(last).dateTime)
	'compare sequential track points
	track.pt(0).speed = 0
	For i As Integer = 1 To last
		dPos = deltaPos(track.pt(i - 1), track.pt(i))
		dist = Sqr(dPos.x * dPos.x + dPos.y * dPos.y)
		totalDist += dist
		timeDiff = DiffDateTimeSec(track.pt(i - 1).dateTime, track.pt(i).dateTime)
		track.pt(i).speed = dist / timeDiff
		If track.pt(i).speed > maxSpeed Then maxSpeed = track.pt(i).speed
	Next
	avgSpeed = totalDist / totalTime
	'compare track points against first point
	track.pt(0).p = dbl2d(0, 0)
	minZpos = track.pt(0).ele
	maxZpos = track.pt(0).ele
	For i As Integer = 1 To last
		Dim As dbl2d dPos = deltaPos(track.pt(0), track.pt(i))
		track.pt(i).p = dPos
		If dPos.x < minXpos Then minXpos = dPos.x 
		If dPos.x > maxXpos Then maxXpos = dPos.x 
		If dPos.y < minYpos Then minYpos = dPos.y 
		If dPos.y > maxYpos Then maxYpos = dPos.y
		Dim As Double ele = track.pt(i).ele
		If ele < minZpos Then minZpos = ele 
		If ele > maxZpos Then maxZpos = ele
	Next
End Sub

'-------------------------------------------------------------------------------

Dim As trkpt_list track
Dim As track_stats stats
Dim As String fileName = "gpx_files/Skiing-downhill.gpx"
Dim As Integer result = readGpxFile(fileName, track)

Print "fileName: " & fileName
Print "readGpxFile: " & IIf(result >= 0, "Ok", "error")
Print "Num track points: " & track.size()
Print "Track error count: " & track.check()

If (result >= 0) And (track.size() > 0) And (track.check() = 0) Then

	stats.update(track)
	stats.print_()

	track.pt(0).p = dbl2d(0, 0)
	For i As Integer = 1 To track.size() - 1
		Dim As dbl2d dPos = deltaPos(track.pt(i), track.pt(0))
		Dim As Double dist = Sqr(dPos.x * dPos.x + dPos.y * dPos.y)
		track.pt(i).p = dPos
		'track.pt(i).speed = dPos / time
	Next
	
	Print !"\nFirst and last 10 data points:"
	'print " Index", "yyyy-mm-dd - hh:mm:ss", "Latitude", "Longitude", "Elevation", "x-pos", "y-pos"
	Print " Index", "yyyy-mm-dd - hh:mm:ss", "Elevation [m]", "X-pos [m]", "Y-pos [m]", "Speed [m/s]"
	If track.size() > 20 Then
		For i As Integer = 0 To track.size() - 1
			If i > 9 And i < track.size() - 10 Then Continue For
			With track.pt(i)
				Print i, Format(.dateTime, "yyyy-mm-dd - hh:mm:ss"), _
					Format(.ele, "#.000"), _
					Format(.p.x, "#.000"), Format(.p.y, "#.000"), _
					Format(.speed, "#.000")
					'format(.lat, "#.000000"), format(.lon, "#.000000"), _
			End With
		Next
	End If
End If

GetKey()

'-------------------------------------------------------------------------------

'See also:
'https://www.freebasic.net/forum/viewtopic.php?f=2&t=26187&p=240904&hilit=libxml#p240904
'http://xmlsoft.org/examples/index.html
'https://metacpan.org/pod/distribution/XML-LibXML/LibXML.pod
'https://www.codeproject.com/articles/15452/the-xmltextreader-a-beginner-s-guide

'~ /usr/lib/i386-linux-gnu/libxml2.so.2
'~ /usr/lib/i386-linux-gnu/libxml2.so.2.9.4
'~ /usr/lib/python2.7/dist-packages/drv_libxml2.py
'~ /usr/lib/python2.7/dist-packages/drv_libxml2.pyc
'~ /usr/lib/python2.7/dist-packages/libxml2.py
'~ /usr/lib/python2.7/dist-packages/libxml2.pyc
'~ /usr/lib/python2.7/dist-packages/libxml2mod.x86_64-linux-gnu.so
'~ /usr/lib/x86_64-linux-gnu/libxml2.so.2

'~ lrwxrwxrwx 1 root root      16 Feb  5 18:08 libxml2.so.2 -> libxml2.so.2.9.4
'~ -rw-r--r-- 1 root root 2011260 Feb  5 18:08 libxml2.so.2.9.4

'~ /usr/lib/i386-linux-gnu$ ls -l libxml*
'~ lrwxrwxrwx 1 root root      12 Jun 29 23:32 libxml2.so -> libxml2.so.2
'~ lrwxrwxrwx 1 root root      16 Feb  5 18:08 libxml2.so.2 -> libxml2.so.2.9.4
'~ -rw-r--r-- 1 root root 2011260 Feb  5 18:08 libxml2.so.2.9.4

'https://www.topografix.com/gpx.asp
'https://en.wikipedia.org/wiki/GPS_Exchange_Format
'https://en.wikipedia.org/wiki/World_Geodetic_System#A_new_World_Geodetic_System:_WGS_84
'http://www.movable-type.co.uk/scripts/latlong.html
'https://stackoverflow.com/questions/24617013/convert-latitude-and-longitude-to-x-and-y-grid-system-using-python

'~ Dim a As Double = DateSerial(2005, 11, 28)
'~ Print Format(a, "yyyy/mm/dd hh:mm:ss") 
'~ Dim ds As Double = TimeValue("07:12:28AM")
'~ result = DateSerial( year, month, day )
'~ Dim ds As Double = now 'DateSerial(2005, 11, 28) + TimeSerial(7, 30, 50)
'CONVERT TO RELATIVE TIME? NO
