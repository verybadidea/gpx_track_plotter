'* Initial date = ????-??-??
'* Last revision = 2018-09-28
'* Indent = tab

type int2d
	as integer x, y
	declare constructor
	declare constructor(x as integer, y as integer)
	declare operator cast () as string
end type

constructor int2d
end constructor

constructor int2d(x as integer, y as integer)
	this.x = x : this.y = y
end constructor

' "x, y"
operator int2d.cast () as string
  return str(x) & "," & str(y)
end operator

operator = (a as int2d, b as int2d) as boolean
	if a.x <> b.x then return false
	if a.y <> b.y then return false
	return true
end operator

operator <> (a as int2d, b as int2d) as boolean
	if a.x = b.x and a.y = b.y then return false
	return true
end operator

' a + b 
operator + (a as int2d, b as int2d) as int2d
	return type(a.x + b.x, a.y + b.y)
end operator

' a - b
operator - (a as int2d, b as int2d) as int2d
	return type(a.x - b.x, a.y - b.y)
end operator

' -a
operator - (a as int2d) as int2d
	return type(-a.x, -a.y)
end operator

' a * b
operator * (a as int2d, b as int2d) as int2d
	return type(a.x * b.x, a.y * b.y)
end operator

' a * mul
operator * (a as int2d, mul as integer) as int2d
	return type(a.x * mul, a.y * mul)
end operator

' a \ b
operator \ (a as int2d, b as int2d) as int2d
	return type(a.x \ b.x, a.y \ b.y)
end operator

' a \ div
operator \ (a as int2d, divider as integer) as int2d
	return type(a.x \ divider, a.y \ divider)
end operator
