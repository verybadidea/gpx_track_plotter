' [S]imple [N]etwork [C]onnection
#include once "../snc.bi"
#include once "../snc_utility.bi"

const as string HOST            = "maps.googleapis.com"
const as string PATH            = "/maps/api/staticmap?"

'const as string MAP_TYPE        = "&maptype=satellite"
'const as string MAP_TYPE        = "&maptype=roadmap"
const as string MAP_TYPE        = "&maptype=terrain"
'const as string MAP_TYPE        = "&maptype=hybrid"

const as string MAP_ZOOM        = "&zoom=18"

const as string MAP_SCALE       = "&scale=2"

const as string IMAGE_SIZE      = "&size=640x640" ' !!! multiply by MAP_SCALE of 2 = 1280x1280 pixels !!!

'const as string IMAGE_FORMAT    = "&format=gif"
const as string IMAGE_FORMAT    = "&format=png"
'const as string IMAGE_FORMAT    = "&format=jpg"
'const as string IMAGE_FORMAT    = "&format=jpg-baseline"

const as string STYLE_ROAD      = "&style=feature:road%7Cvisibility:on" ' or off

const as string STYLE_LANDSCAPE = "&style=feature:landscape%7Celement:geometry%7Csaturation:100"

const as string STYLE_WATER     = "&style=feature:water%7Csaturation:-100%7Cinvert_lightness:false" ' or true

const as string STYLE_LABELS    = "&style=element:labels%7Cvisibility:on" ' or off

const as string STYLE_GEOMETRY  = "&style=element:geometry.stroke%7Cvisibility:on" ' or off

const as string STYLE_ALL = STYLE_LANDSCAPE & STYLE_ROAD & STYLE_WATER & STYLE_LABELS & STYLE_GEOMETRY

' use any latitude and longitude
const lat= 38.8976763 ' white house
const lng=-77.0365298
'const as string CENTER = "center=" & lat & "," & lng

' or a address
const as string CENTER = "center=USA+white+house"

var REQUEST = CENTER       & _
              IMAGE_SIZE   & _
              IMAGE_FORMAT & _
              MAP_TYPE     & _
              MAP_ZOOM     & _
              MAP_SCALE    & _
              STYLE_ALL


' save as ... gif/png/jpg
var LocalFile = "test.png"

' connect to web server at port 80
dim as NetworkClient client = type(HOST,80)

' get a connection from ConnectionFactory
var connection = client.GetConnection()

' build an HTTP GET request
var strRequest = HTTPGet(HOST,PATH & REQUEST)

' ready to send ?
while connection->CanPut()<>1
  sleep 100
wend
' put data on the connection
connection->PutData(strptr(strRequest),len(strRequest))

' ready to receive ?
while connection->CanGet()<>1
  sleep 100
wend

print "receive " & LocalFile
dim as zstring ptr buffer
var nBytes = connection->GetData(buffer)
print "number of received bytes " & nBytes

' get last char position of the HTTP asci header
var LastChar=instr(*buffer,HeaderEnd)-1
var Header  =left(*buffer,LastChar)
' is it a OK answer ?
if instr(Header,"200 OK")<1 then
  print "can't get map from " & HOST & PATH & " !"
  beep:sleep:end
end if

' get first byte behind the HTTP header
var DataStart=LastChar+4

' save it
open LocalFile for binary access write as #1
dim as ubyte ptr FileBuffer=@buffer[DataStart]
nBytes-=DataStart
put #1,,*FileBuffer,nBytes
close #1
print "file saved ..."
' free the buffer (allocate by snc.bi)
deallocate buffer
sleep
