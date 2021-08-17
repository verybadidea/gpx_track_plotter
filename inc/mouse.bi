#include once "int2d_v02.bi"

#DEFINE MOUSE_IDLE 0
#DEFINE MOUSE_POS_CHANGED 1
#DEFINE MOUSE_LB_PRESSED 2
#DEFINE MOUSE_LB_RELEASED 3
#DEFINE MOUSE_RB_PRESSED 4
#DEFINE MOUSE_RB_RELEASED 5
#DEFINE MOUSE_MB_PRESSED 6
#DEFINE MOUSE_MB_RELEASED 7
#DEFINE MOUSE_WHEEL_UP 8
#DEFINE MOUSE_WHEEL_DOWN 9

type mouse_type
	pos as int2d
	posChange as int2d
	wheel as integer
	buttons as integer
	lb as integer 'left button
	rb as integer 'right button
	mb as integer 'middle button
end type

function handleMouse(byref mouse as mouse_type) as integer
	static previous as mouse_type
	dim as integer change = MOUSE_IDLE
	getmouse mouse.pos.x, mouse.pos.y, mouse.wheel, mouse.buttons
	if (mouse.buttons = -1) then
		mouse.lb = 0
		mouse.rb = 0
		mouse.mb = 0
		mouse.posChange.x = 0
		mouse.posChange.y = 0
	else
		mouse.lb = (mouse.buttons and 1)
		mouse.rb = (mouse.buttons shr 1) and 1
		mouse.mb = (mouse.buttons shr 2) and 1
		if (previous.pos.x <> mouse.pos.x or previous.pos.y <> mouse.pos.y) then
			change = MOUSE_POS_CHANGED
		end if
		mouse.posChange.x = mouse.pos.x - previous.pos.x
		mouse.posChange.y = mouse.pos.y - previous.pos.y
		if (previous.buttons <> mouse.buttons) then
			if (previous.lb = 0 and mouse.lb = 1) then change = MOUSE_LB_PRESSED
			if (previous.lb = 1 and mouse.lb = 0) then change = MOUSE_LB_RELEASED
			if (previous.rb = 0 and mouse.rb = 1) then change = MOUSE_RB_PRESSED
			if (previous.rb = 1 and mouse.rb = 0) then change = MOUSE_RB_RELEASED
			if (previous.mb = 0 and mouse.mb = 1) then change = MOUSE_MB_PRESSED
			if (previous.mb = 1 and mouse.mb = 0) then change = MOUSE_MB_RELEASED
		end if
		if (mouse.wheel > previous.wheel) then change = MOUSE_WHEEl_UP
		if (mouse.wheel < previous.wheel) then change = MOUSE_WHEEl_DOWN
		previous = mouse
	end if
	return change
end function
