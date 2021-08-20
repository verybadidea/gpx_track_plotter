'* Initial date = 2018-09-30
'* Last revision = 2019-12-11
'* Indent = tab

type dbl3d
	as double x, y, z
	declare constructor
	declare constructor(x as double, y as double, z as double)
	declare operator cast() as string
	declare function cross(b as dbl3d) as double
	declare function lengthSqrd() as double
	declare function dist(b as dbl3d) as double
	declare function distSqrd(b as dbl3d) as double
	declare function normalise() as dbl3d
end type

constructor dbl3d
end constructor

'~ function dbl3d.cross(b as dbl3d) as double
	'~ return this.x * b.y - this.y * b.x
'~ end function

'~ function dbl3d.lengthSqrd() as double
	'~ return (this.x * this.x) + (this.y * this.y) 
'~ end function

'~ function dbl3d.dist(b as dbl3d) as double
	'~ dim as double dx = this.x - b.x
	'~ dim as double dy = this.y - b.y
	'~ return sqr((dx * dx) + (dy * dy)) 
'~ end function

'~ function dbl3d.distSqrd(b as dbl3d) as double
	'~ dim as double dx = this.x - b.x
	'~ dim as double dy = this.y - b.y
	'~ return (dx * dx) + (dy * dy) 
'~ end function

'~ function dbl3d.normalise() as dbl3d
	'~ dim as double length = sqr((this.x * this.x) + (this.y * this.y))
	'~ return dbl3d(this.x / length, this.y / length)
'~ end function

constructor dbl3d(x as double, y as double, z as double)
	this.x = x : this.y = y : this.z = z
end constructor

' "x, y, y"
operator dbl3d.cast() as string
	return str(x) & "," & str(y) & "," & str(z)
end operator

'~ '---- operators ---

'~ ' distance / lenth
'~ operator len (a as dbl3d) as double
	'~ return sqr(a.x * a.x + a.y * a.y)
'~ end operator

'~ ' a = b ?
'~ operator = (a as dbl3d, b as dbl3d) as boolean
	'~ if a.x <> b.x then return false
	'~ if a.y <> b.y then return false
	'~ return true
'~ end operator

'~ ' a != b ?
'~ operator <> (a as dbl3d, b as dbl3d) as boolean
	'~ if a.x = b.x and a.y = b.y then return false
	'~ return true
'~ end operator

'~ ' a + b 
'~ operator + (a as dbl3d, b as dbl3d) as dbl3d
	'~ return type(a.x + b.x, a.y + b.y)
'~ end operator

'~ ' a - b
'~ operator - (a as dbl3d, b as dbl3d) as dbl3d
	'~ return type(a.x - b.x, a.y - b.y)
'~ end operator

'~ ' -a
'~ operator - (a as dbl3d) as dbl3d
	'~ return type(-a.x, -a.y)
'~ end operator

'~ ' a * b
'~ operator * (a as dbl3d, b as dbl3d) as dbl3d
	'~ return type(a.x * b.x, a.y * b.y)
'~ end operator

' a * mul
operator * (a as dbl3d, mul as double) as dbl3d
	return type(a.x * mul, a.y * mul, a.z * mul)
end operator

' a / div
operator / (a as dbl3d, div_ as double) as dbl3d
	return type(a.x / div_, a.y / div_, a.z / div_,)
end operator
