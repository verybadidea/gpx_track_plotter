#include once "int2d_v02.bi"
#include once "dbl2d_v03.bi"

'Note: y+ = up, x+ = right, (0,0) = center
type scaled_graphics_type
	dim as double scale = 1 ' = 1 / pixel_size 'pixels / meter
	'dim as int2d offset' = (scrn_w \ 2, h \ 2) 'offset in pixels
	dim as dbl2d offset
	dim as integer w = -1, h = -1
	dim as integer wc = -1, hc = -1 'width/height half, center x,y
	declare sub setScreen(w as integer, h as integer)
	declare sub setScaling(scale as double, offset as dbl2d)
	declare sub clearScreen(c as ulong)
	declare function pos2screen(p as dbl2d) as int2d
	declare function screen2pos(p as int2d) as dbl2d 'reverse
	declare sub drawPixel(p as dbl2d, c as ulong)
	declare sub drawCircle(p as dbl2d, r as single, c as ulong)
	declare sub drawCircleFilled(p as dbl2d, r as single, c as ulong, cFill as ulong)
	declare sub drawElipse(p as dbl2d, r as single, aspect as single, c as ulong)
	declare sub drawLine(p1 as dbl2d, p2 as dbl2d, c as ulong)
end type

sub scaled_graphics_type.setScreen(w as integer, h as integer)
	this.w = w 'width
	this.h = h 'height
	wc = w \ 2
	hc = h \ 2
	'screenres w, h, 32
	screenres w, h, 32, , fb.GFX_ALPHA_PRIMITIVES
	width w \ 8, h \ 16 'bigger font
end sub

sub scaled_graphics_type.setScaling(scale as double, offset as dbl2d)
	this.scale = scale
	this.offset = offset
end sub

sub scaled_graphics_type.clearScreen(c as ulong)
	line(0, 0)-(w - 1, h - 1), c, bf
end sub

function scaled_graphics_type.pos2screen(p as dbl2d) as int2d
	return int2d( _
		int(wc + (p.x - offset.x) * scale), _
		h - int(hc + (p.y - offset.y) * scale))
end function

function scaled_graphics_type.screen2pos(p as int2d) as dbl2d
	return dbl2d( _
		(p.x - wc + 0.5) / scale + offset.x, _
		((h - p.y) - hc + 0.5) / scale + offset.y)
end function

sub scaled_graphics_type.drawPixel(p as dbl2d, c as ulong)
	dim as int2d posScrn = pos2screen(p)
	pset(posScrn.x, posScrn.y), c
end sub

sub scaled_graphics_type.drawCircle(p as dbl2d, r as single, c as ulong)
	dim as int2d posScrn = pos2screen(p)
	'circle(posScrn.x, posScrn.y), r * scale, c
	circle(posScrn.x, posScrn.y), r, c
end sub

sub scaled_graphics_type.drawCircleFilled(p as dbl2d, r as single, c as ulong, cFill as ulong)
	dim as int2d posScrn = pos2screen(p)
	circle(posScrn.x, posScrn.y), r * scale, 0,,,,f
	circle(posScrn.x, posScrn.y), r * scale, c
end sub

sub scaled_graphics_type.drawElipse(p as dbl2d, r as single, aspect as single, c as ulong)
	dim as int2d posScrn = pos2screen(p)
	circle(posScrn.x, posScrn.y), r * scale, c, , , aspect
end sub

sub scaled_graphics_type.drawLine(p1 as dbl2d, p2 as dbl2d, c as ulong)
	dim as int2d posScrn1 = pos2screen(p1)
	dim as int2d posScrn2 = pos2screen(p2)
	line(posScrn1.x, posScrn1.y)-(posScrn2.x, posScrn2.y), c
end sub
