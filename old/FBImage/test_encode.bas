#include once "FBImage.bi"

const fileName = ' " YOR IMAGE FILE"
chdir exepath

' get resolution of the image
screenres 640,480,32
var img = LoadRGBAFile(fileName)
if img=0 then
  print "error: can't load `" & fileName & "' !" & *GetLastResult()
  beep : sleep : end 1
end if
dim as integer w,h
imageinfo img,w,h
imagedestroy img

' load image as binary buffer
var hFile=FreeFile()
if open(fileName,for binary,access read,as #hFile) then
  print "error: can't read '" & fileName & " !"
  beep : sleep : end 1
end if

var nBytes=lof(hFile)
dim as ubyte ptr buffer = allocate(nBytes)
get #hFile,,*buffer,nBytes
close #hFile

' encode the image as string
var encoded = Base64.EncodeMemory(buffer,nBytes)
var nChars = len(encoded)

' save encoded image as data statements
const nCharsPerline = 80
var nLines = nChars  \  nCharsPerline
var nRest  = nChars mod nCharsPerline
var iPos   = 1

' create include file
hFile=FreeFile()
if open("picture.bi",for output,as #hFile) then
  print "error: can't open 'picture.bi' !"
  beep : sleep : end 1
end if

print #hFile,"#ifndef __PICTURE_BI__"
print #hFile,"#define __PICTURE_BI__"

' create "optinal" an label for the restor command
print #hFile,"mypicture:"

' save width height and number of lines as a kind of header
print #hFile,"data " & str(w) & ", " & str(h) & ", " & str(nLines + iif(nRest>0,1,0))

' create data lines from encoded string
if nLines>0 then
  for i as integer=0 to nLines-1
    var aLine = mid(encoded,iPos,nCharsPerline) 
    print #hFile,"data " & chr(34) & aLine & chr(34)
    iPos+=nCharsPerline
  next
end if

if nRest>0 then
  var aLine = mid(encoded,iPos,nRest) 
  print #hFile,"data " & chr(34) & aLine & chr(34)
end if  
print #hFile,"#endif ' __PICTURE_BI__"
close #hFile
print "done ..."
sleep 2000


  
