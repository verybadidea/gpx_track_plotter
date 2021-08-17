'* Initial date = 2018-09-30
'* Last revision = 2019-12-11
'* Indent = tab

type dbl2d
	as double x, y
	declare constructor
	declare constructor(x as double, y as double)
	declare operator cast() as string
	declare function cross(b as dbl2d) as double
	declare function lengthSqrd() as double
	declare function dist(b as dbl2d) as double
	declare function distSqrd(b as dbl2d) as double
	declare function normalise() as dbl2d
end type

constructor dbl2d
end constructor

function dbl2d.cross(b as dbl2d) as double
	return this.x * b.y - this.y * b.x
end function

function dbl2d.lengthSqrd() as double
	return (this.x * this.x) + (this.y * this.y) 
end function

function dbl2d.dist(b as dbl2d) as double
	dim as double dx = this.x - b.x
	dim as double dy = this.y - b.y
	return sqr((dx * dx) + (dy * dy)) 
end function

function dbl2d.distSqrd(b as dbl2d) as double
	dim as double dx = this.x - b.x
	dim as double dy = this.y - b.y
	return (dx * dx) + (dy * dy) 
end function

function dbl2d.normalise() as dbl2d
	dim as double length = sqr((this.x * this.x) + (this.y * this.y))
	return dbl2d(this.x / length, this.y / length)
end function

constructor dbl2d(x as double, y as double)
	this.x = x : this.y = y
end constructor

' "x, y"
operator dbl2d.cast() as string
	return str(x) & "," & str(y)
end operator

'---- operators ---

' distance / lenth
operator len (a as dbl2d) as double
	return sqr(a.x * a.x + a.y * a.y)
end operator

' a = b ?
operator = (a as dbl2d, b as dbl2d) as boolean
	if a.x <> b.x then return false
	if a.y <> b.y then return false
	return true
end operator

' a != b ?
operator <> (a as dbl2d, b as dbl2d) as boolean
	if a.x = b.x and a.y = b.y then return false
	return true
end operator

' a + b 
operator + (a as dbl2d, b as dbl2d) as dbl2d
	return type(a.x + b.x, a.y + b.y)
end operator

' a - b
operator - (a as dbl2d, b as dbl2d) as dbl2d
	return type(a.x - b.x, a.y - b.y)
end operator

' -a
operator - (a as dbl2d) as dbl2d
	return type(-a.x, -a.y)
end operator

' a * b
operator * (a as dbl2d, b as dbl2d) as dbl2d
	return type(a.x * b.x, a.y * b.y)
end operator

' a * mul
operator * (a as dbl2d, mul as double) as dbl2d
	return type(a.x * mul, a.y * mul)
end operator

' a / div
operator / (a as dbl2d, div_ as double) as dbl2d
	return type(a.x / div_, a.y / div_)
end operator
