#include once "FBImage.bi"

' loading image from memory

chdir exepath()

var hFile = FreeFile()
if open("tire.jpg",for binary,access read,as #hFile) then
  print "error: can't read 'tire.jpg' !"
  beep:sleep:end
end if
var nBytes = LOF(hFile)
dim as ubyte ptr mem = allocate(nBytes)
get #hFile,,*mem,nBytes
close #hFile

screenres 640,480,24 ' <- RGB

var img = LoadRGBAMemory(mem,nBytes)
deallocate mem

put (0,0),img,PSET

sleep
ImageDestroy img

