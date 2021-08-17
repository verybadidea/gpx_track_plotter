#include "dir.bi"

type file_list
	dim as string fileName(any)
	declare sub add(newFile as string)
	declare sub clear_()
	declare sub create(path as string, fileSpec as string)
	declare sub print_()
	declare function size() as integer
end type

sub file_list.add(newFile as string)
	dim as integer ub = ubound(fileName)
	redim preserve fileName(ub + 1)
	fileName(ub + 1) = newFile
end sub

sub file_list.clear_()
	erase(fileName)
end sub

sub file_list.create(path as string, fileSpec as string)
	dim as uinteger out_attr '' unsigned integer to hold retrieved attributes
	dim as string fname = dir(path & fileSpec, fbNormal, out_attr) 'get first file match
	do until len(fname) = 0
		if (fname <> ".") and (fname <> "..") then
			add(path & fname)
		end if
		fname = dir(out_attr) 'find next file
	loop
end sub

sub file_list.print_()
	for i as integer = 0 to ubound(fileName)
		print fileName(i)
	next
end sub

function file_list.size() as integer
	return ubound(fileName) + 1
end function

'~ dim as file_list fileList
'~ fileList.create("gpx_files/", "*.gpx")
'~ fileList.print_()
'~ print fileList.size()
