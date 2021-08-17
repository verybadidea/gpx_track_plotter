#include once "FBImage.bi"

' test for GetLastResult()

chdir exepath()

screenres 640,480,32 ' RGBA

var img = LoadRGBAFile("test.pcx")
if img=0 then
  print "error: loading test.pcx " & *GetLastResult()
  beep:sleep:end
end if
