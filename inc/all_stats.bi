type all_stats
	dim as double totalDist 'm
	dim as double totalTime 's
	dim as double maxSpeed, avgSpeed 'm/s
	dim as geo_pos minPos, maxPos
	'declare sub reset_()
	declare sub print_()
	declare sub create(track() as trkpt_list)
end type

'~ sub all_stats.reset_()
	'~ totalDist = 0 : totalTime = 0
	'~ maxSpeed = 0 : avgSpeed = 0
	'~ minXpos = 0 : maxXpos = 0
	'~ minYpos = 0 : maxYpos = 0
	'~ minZpos = 0 : maxZpos = 0
'~ end sub

sub all_stats.print_()
	print !"\nAll track stats:"
	print " totalDist [km]: " & format(totalDist / 1000, "0.000")
	print " totalTime [s]: " & format(totalTime, "0.0") & ", [h]: " & format(totalTime / 3600, "0.0")
	print " avgSpeed [km/h]: " & format(avgSpeed * 3.6, "0.000") 
	print " maxSpeed [km/h]: " & format(maxSpeed * 3.6, "0.000")
	print " Longitude []: " & format(minPos.Lon, "0.000000") & " ... " & format(maxPos.Lon, "0.000000")' & ", average center: " &  format(avgLon, "0.000000") & ", center: " & format(centerLon, "0.000000")
	print " Latitude []: " & format(minPos.Lat, "0.000000") & " ... " & format(maxPos.Lat, "0.000000")' & ", average center: " & format(avgLat, "0.000000") & ", center: " & format(centerLat, "0.000000")
	print " Elevation []: " & format(minPos.Ele, "0.000000") & " ... " & format(maxPos.Ele, "0.000000")
end sub

sub all_stats.create(track() as trkpt_list)
	for i as integer = 0 to ubound(track)
		with track(i)
			totalDist += .totalDist
			totalTime += .totalTime
			if i = 0 then 'starting values
				maxSpeed = .maxSpeed
				minPos = .minPos : maxPos = .maxPos
			else
				maxSpeed = MAX(maxSpeed, .maxSpeed)
				minPos.Ele = MIN(minPos.Ele, .minPos.Ele)
				minPos.Lat = MIN(minPos.Lat, .minPos.Lat)
				minPos.Lon = MIN(minPos.Lon, .minPos.Lon)
				maxPos.Ele = MAX(maxPos.Ele, .maxPos.Ele)
				maxPos.Lat = MAX(maxPos.Lat, .maxPos.Lat)
				maxPos.Lon = MAX(maxPos.Lon, .maxPos.Lon)
			end if
		end with
	next
	avgSpeed = totalDist / totalTime
end sub
