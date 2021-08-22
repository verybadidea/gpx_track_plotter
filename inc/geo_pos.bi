type geo_pos
	dim as double lon, lat 'longitude (E-W), latitude (N-S)
	dim as double ele 'elevation
end type

'simple spherical earth approximation
const as double EARTHC = 4e7 'circumfence [m] 360° 40075e3'
'dx = dLon * 4e7 * cos(avg(Lat1, Lat2) * PI / 180) / 360
'dy = dLat * 4e7 / 360
function deltaPos(pos1 as geo_pos, pos2 as geo_pos) as dbl3d
	dim as dbl3d dPos
	dim as double dLon = pos1.lon - pos2.lon
	dim as double dLat = pos1.lat - pos2.lat
	dim as double avgLat = AVG(pos1.lat, pos2.lat)
	dPos.x = dLon * cos(avgLat * PI / 180) * earthc / 360
	dPos.y = dLat * earthc / 360
	dPos.z = (pos1.ele - pos2.ele)
	return dPos
end function

function distPos(pos1 as geo_pos, pos2 as geo_pos) as double
	dim as dbl3d dPos = deltaPos(pos1, pos2)
	return sqr(dPos.x * dPos.x + dPos.y * dPos.y + dPos.z * dPos.z)
end function

function flatDistPos(pos1 as geo_pos, pos2 as geo_pos) as double
	dim as dbl3d dPos = deltaPos(pos1, pos2)
	return sqr(dPos.x * dPos.x + dPos.y * dPos.y) 'ignore z / height
end function

function heightDiffPos(pos1 as geo_pos, pos2 as geo_pos) as double
	dim as dbl3d dPos = deltaPos(pos1, pos2)
	return abs(dPos.z)
end function

function moveGeoPos(refPos as geo_pos, dPos as dbl3d) as geo_pos
	dim as geo_pos tempPos = refPos 'copy
	tempPos.ele -= dPos.z
	tempPos.lat -= 360 * (dPos.y / earthc)
	dim as double avgLat = AVG(tempPos.lat, refPos.lat)
	tempPos.lon -= 360 * dPos.x / (earthc * cos(avgLat * PI / 180))
	return tempPos
end function
