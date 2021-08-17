type all_stats
	dim as double totalDist 'm
	dim as double totalTime 's
	dim as double maxSpeed, avgSpeed 'm/s
	'dim as double minXpos, maxXpos 'm
	'dim as double minYpos, maxYpos 'm
	'dim as double minZpos, maxZpos 'm
	'dim as double xRange, xCenter 'm
	'dim as double yRange, yCenter 'm
	dim as double minLon, maxLon 'Longitude (BUG: At -180 to + 180 transition)
	dim as double minLat, maxLat 'Latitude
	dim as double minEle, maxEle 'Latitude
	'dim as double centerLat, centerLon '(BUG: At -180 to + 180 transition)
	'dim as double avgLat, avgLon 'average of centers of each track
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
	'print " X-range [km]: " & format(minXpos / 1000, "0.000") & " ... " & format(maxXpos / 1000, "0.000")
	'print " Y-range [km]: " & format(minYpos / 1000, "0.000") & " ... " & format(maxYpos / 1000, "0.000")
	'print " Z-range [m]: " & format(minZpos, "0.0") & " ... " & format(maxZpos, "0.0")
	print " Longitude []: " & format(minLon, "0.000000") & " ... " & format(maxLon, "0.000000")' & ", average center: " &  format(avgLon, "0.000000") & ", center: " & format(centerLon, "0.000000")
	print " Latitude []: " & format(minLat, "0.000000") & " ... " & format(maxLat, "0.000000")' & ", average center: " & format(avgLat, "0.000000") & ", center: " & format(centerLat, "0.000000")
	print " Elevation []: " & format(minEle, "0.000000") & " ... " & format(maxEle, "0.000000")
end sub

sub all_stats.create(track() as trkpt_list)
	for i as integer = 0 to ubound(track)
		with track(i)
			totalDist += .totalDist
			totalTime += .totalTime
			if i = 0 then 'starting values
				maxSpeed = .maxSpeed
				'minXpos = .minXpos : maxXpos = .maxXpos
				'minYpos = .minYpos : maxYpos = .maxYpos
				'minZpos = .minZpos : maxZpos = .maxZpos
				minEle = .minEle : maxEle = .maxEle
				minLat = .minLat : maxLat = .maxLat
				minLon = .minLon : maxLon = .maxLon
			else
				maxSpeed = MAX(maxSpeed, .maxSpeed)
				'minXpos = MIN(minXpos, .minXpos)
				'maxXpos = MAX(maxXpos, .maxXpos)
				'minYpos = MIN(minYpos, .minYpos)
				'maxYpos = MAX(maxYpos, .maxYpos)
				'minZpos = MIN(minZpos, .minZpos)
				'maxZpos = MAX(maxZpos, .maxZpos)
				minEle = MIN(minEle, .minEle)
				minLat = MIN(minLat, .minLat)
				minLon = MIN(minLon, .minLon)
				maxEle = MAX(maxEle, .maxEle)
				maxLat = MAX(maxLat, .maxLat)
				maxLon = MAX(maxLon, .maxLon)
			end if
			'avgLat += (.maxLat + .minLat) / 2
			'avgLon += (.maxLon + .minLon) / 2
		end with
	next
	avgSpeed = totalDist / totalTime
	'xRange = maxXpos - minXpos
	'yRange = maxYpos - minYpos
	'xCenter = (maxXpos + minXpos) / 2
	'yCenter = (maxYpos + minYpos) / 2
	'centerLat = (maxLat + minLat) / 2
	'centerLon = (maxLon + minLon) / 2
	'avgLat /= (ubound(track) + 1)
	'avgLon /= (ubound(track) + 1)
end sub

'~ sub track_stats.update(tracks() as trkpt_list)
	'~ dim as dbl2d dPos
	'~ dim as double dist, timeDiff
	'~ dim as integer last = track.size() - 1
	'~ 'reset_()
	'~ totalTime = DiffDateTimeSec(track.pt(0).dateTime, track.pt(last).dateTime)
	'~ 'compare sequential track points
	'~ track.pt(0).speed = 0
	'~ for i as integer = 1 to last
		'~ dPos = deltaPos(track.pt(i - 1), track.pt(i))
		'~ dist = sqr(dPos.x * dPos.x + dPos.y * dPos.y)
		'~ totalDist += dist
		'~ timeDiff = DiffDateTimeSec(track.pt(i - 1).dateTime, track.pt(i).dateTime)
		'~ track.pt(i).speed = dist / timeDiff
		'~ if track.pt(i).speed > maxSpeed then maxSpeed = track.pt(i).speed
	'~ next
	'~ avgSpeed = totalDist / totalTime
	'~ 'compare track points against first point
	'~ track.pt(0).p = dbl2d(0, 0)
	'~ minZpos = track.pt(0).ele
	'~ maxZpos = track.pt(0).ele
	'~ for i as integer = 1 to last
		'~ dim as dbl2d dPos = deltaPos(track.pt(i), track.pt(0))
		'~ track.pt(i).p = dPos
		'~ if dPos.x < minXpos then minXpos = dPos.x 
		'~ if dPos.x > maxXpos then maxXpos = dPos.x 
		'~ if dPos.y < minYpos then minYpos = dPos.y 
		'~ if dPos.y > maxYpos then maxYpos = dPos.y
		'~ dim as double ele = track.pt(i).ele
		'~ if ele < minZpos then minZpos = ele 
		'~ if ele > maxZpos then maxZpos = ele
	'~ next
	'~ xRange = maxXpos - minXpos
	'~ yRange = maxYpos - minYpos
	'~ xCenter = (maxXpos + minXpos) / 2
	'~ yCenter = (maxYpos + minYpos) / 2
'~ end sub
