#include "vbcompat.bi"

enum E_DATE_FORMAT
	DATE_FORMAT_ISO
	DATE_FORMAT_NL
	DATE_FORMAT_DE
	DATE_FORMAT_US
end enum

function dateString(dateTimeVal as double, dateFormat as E_DATE_FORMAT) as string
	select case dateFormat
	case DATE_FORMAT_ISO
		return format(dateTimeVal, "yyyy-mm-dd")
	case DATE_FORMAT_NL
		return format(dateTimeVal, "dd-mm-yyyy")
	case DATE_FORMAT_DE
		return format(dateTimeVal, "dd.mm.yyyy")
	case DATE_FORMAT_US
		return format(dateTimeVal, "mm/dd/yyyy")
	end select
	return "<invalid>"
end function

'day, month, year format must be: dd, mm, yyyy (e.g. not 7/5/20 or 2020-7-5)
function dateValue2(dateStr as string, dateFormat as E_DATE_FORMAT) as long
	if len(dateStr) <> 10 then return -1
	dim as string y, m, d 'years, months, days
	select case dateFormat
	case DATE_FORMAT_ISO
		if mid(dateStr, 5, 1) <> "-" then return -1
		if mid(dateStr, 8, 1) <> "-" then return -1
		y = mid(dateStr, 1, 4)
		m = mid(dateStr, 6, 2)
		d = mid(dateStr, 9, 2)
	case DATE_FORMAT_NL
		if mid(dateStr, 3, 1) <> "-" then return -1
		if mid(dateStr, 6, 1) <> "-" then return -1
		y = mid(dateStr, 7, 4)
		m = mid(dateStr, 4, 2)
		d = mid(dateStr, 1, 2)
	case DATE_FORMAT_DE
		if mid(dateStr, 3, 1) <> "." then return -1
		if mid(dateStr, 6, 1) <> "." then return -1
		y = mid(dateStr, 7, 4)
		m = mid(dateStr, 4, 2)
		d = mid(dateStr, 1, 2)
	case DATE_FORMAT_US
		if mid(dateStr, 3, 1) <> "/" then return -1
		if mid(dateStr, 6, 1) <> "/" then return -1
		y = mid(dateStr, 7, 4)
		m = mid(dateStr, 1, 2)
		d = mid(dateStr, 4, 2)
	case else
		return -1
	end select
	return dateSerial(val(y), val(m), val(d))
end function

'Convert 2020-05-03T16:28:56Z to 43954.68675925926
function gpxDateTimeValue(gpxDateTimeStr as string) as double
	return dateValue2(mid(gpxDateTimeStr, 1, 10), DATE_FORMAT_ISO) _
		+ timeValue(mid(gpxDateTimeStr, 12, 8))
end function

function DiffDateTimeSec(dt1 as double, dt2 as double) as double
	return (dt2 - dt1) * 24 * 3600
end function 

'-------------------------------------------------------------------------------

'~ dim as double dateVal = now
'~ print dateVal

'~ print "ISO:    " & dateString(dateVal, DATE_FORMAT_ISO)
'~ print "Dutch:  " & dateString(dateVal, DATE_FORMAT_NL)
'~ print "German: " & dateString(dateVal, DATE_FORMAT_DE)
'~ print "US:     " & dateString(dateVal, DATE_FORMAT_US)

'~ print "Days since 1900:"
'~ print dateValue2("2020-07-05", DATE_FORMAT_ISO)
'~ print dateValue2("05-07-2020", DATE_FORMAT_NL)
'~ print dateValue2("05.07.2020", DATE_FORMAT_DE)
'~ print dateValue2("07/05/2020", DATE_FORMAT_US)

'~ 'convert gpxDateTimeStr to DateTimeValue
'~ dim as string gpxDateTimeStr = "2020-05-03T16:28:56Z"
'~ print "gpxDateTimeStr: " & gpxDateTimeStr
'~ print "gpxDateTimeVal: " & gpxDateTimeValue(gpxDateTimeStr)

'~ dim as double dt1 = gpxDateTimeValue("2020-05-03T16:28:56Z")
'~ dim as double dt2 = gpxDateTimeValue("2020-05-03T16:28:59Z")

'~ print DiffDateTimeSec(dt1, dt2)
'~ print DateDiff("s", dt1, dt2)

