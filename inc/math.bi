const as double PI = 4 * atn(1)

function log10(value as double) as double
	return log(value) / log(10)
end function

function cos360(value as double) as double
	return cos(value * (PI / 180))
end function
