'* Initial date = 2018-09-30
'* Last revision = 2019-12-11
'* Indent = tab

type sgl2d
	as single x, y
	declare constructor
	declare constructor(x as single, y as single)
	declare operator cast() as string
	declare function cross(b as sgl2d) as single
	declare function lengthSqrd() as single
	declare function dist(b as sgl2d) as single
	declare function distSqrd(b as sgl2d) as single
	declare function normalise() as sgl2d
end type

constructor sgl2d
end constructor

constructor sgl2d(x as single, y as single)
	this.x = x : this.y = y
end constructor

function sgl2d.cross(b as sgl2d) as single
	return this.x * b.y - this.y * b.x
end function

function sgl2d.lengthSqrd() as single
	return (this.x * this.x) + (this.y * this.y) 
end function

function sgl2d.dist(b as sgl2d) as single
	dim as single dx = this.x - b.x
	dim as single dy = this.y - b.y
	return sqr((dx * dx) + (dy * dy)) 
end function

function sgl2d.distSqrd(b as sgl2d) as single
	dim as single dx = this.x - b.x
	dim as single dy = this.y - b.y
	return (dx * dx) + (dy * dy) 
end function

function sgl2d.normalise() as sgl2d
	dim as single length = sqr((this.x * this.x) + (this.y * this.y))
	return sgl2d(this.x / length, this.y / length)
end function

' "x, y"
operator sgl2d.cast() as string
	return str(x) & "," & str(y)
end operator

'---- operators ---

' distance / lenth
operator len (a as sgl2d) as single
	return sqr(a.x * a.x + a.y * a.y)
end operator

' a = b ?
operator = (a as sgl2d, b as sgl2d) as boolean
	if a.x <> b.x then return false
	if a.y <> b.y then return false
	return true
end operator

' a != b ?
operator <> (a as sgl2d, b as sgl2d) as boolean
	if a.x = b.x and a.y = b.y then return false
	return true
end operator

' a + b 
operator + (a as sgl2d, b as sgl2d) as sgl2d
	return type(a.x + b.x, a.y + b.y)
end operator

' a - b
operator - (a as sgl2d, b as sgl2d) as sgl2d
	return type(a.x - b.x, a.y - b.y)
end operator

' -a
operator - (a as sgl2d) as sgl2d
	return type(-a.x, -a.y)
end operator

' a * b
operator * (a as sgl2d, b as sgl2d) as sgl2d
	return type(a.x * b.x, a.y * b.y)
end operator

' a * mul
operator * (a as sgl2d, mul as single) as sgl2d
	return type(a.x * mul, a.y * mul)
end operator

' a / div
operator / (a as sgl2d, div_ as single) as sgl2d
	return type(a.x / div_, a.y / div_)
end operator
