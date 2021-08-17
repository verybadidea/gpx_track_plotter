'Get map image from thunderforest using [S]imple [N]etwork [C]onnection

#include once "snc/snc.bi"
#include once "snc/snc_utility.bi"

'Latitude []: 51.457317 ... 51.502637, average center: 51.457360
'Longitude []: 5.489707 ... 5.768369, average center: 5.490290
const as string lon = "5.490290" 'longitude
const as string lat = "51.457360" 'latitude

'const as string lon = "5.1212" 'longitude
'const as string lat = "52.0906" 'latitude
const as string zoom = "10" 'https://wiki.openstreetmap.org/wiki/Zoom_levels
const as string wImg = "800" 'image width
const as string hImg = "800" 'image height
const as string apikey = "ff2cae05e1184f11ac6c2c0f7ed4cc05" 'please use your own

const as string ServerName = "tile.thunderforest.com"
const as string ServerPath = "/static/landscape/"
const as string ServerFile = lon & "," & lat & "," & zoom & "/" & wImg & "x" & hImg & ".png?apikey=" & apikey
const as string FileType = MIME_PNG

dim as string localFileName = "test.png"

'connect to web server at port 80
dim as NetworkClient client = type(ServerName, 80)
'get a connection from ConnectionFactory
var connection = client.GetConnection()
'build an HTTP GET request
dim as string request = HTTPGet(ServerName, ServerPath & ServerFile, FileType)
'ready to send ?
while connection->CanPut() <> 1
	sleep 100
wend
'put data on the connection
connection->PutData(strptr(request), len(request))
'ready to receive ?
while connection->CanGet() <> 1
	sleep 100
wend
print "receive data ..."
dim as zstring ptr buffer
var nBytes = connection->GetData(buffer)
print "number of received bytes " & nBytes
'get last char position of the HTTP asci header
var LastChar = instr(*buffer, HeaderEnd) - 1
var Header = left(*buffer, LastChar)
'? header
' is it a OK answer ?
if instr(Header, "200 OK") < 1 then
	print "can't get " & ServerName & ServerPath & ServerFile & " !"
else
	'get first byte behind the HTTP asci header
	var DataStart = LastChar+4
	'save it
	open localFileName for binary access write as #1
	dim as ubyte ptr FileBuffer = @buffer[DataStart]
	nBytes -= DataStart
	put #1 , , *FileBuffer, nBytes
	close #1
	print "file saved ..."
end if
'free the buffer (allocate by snc.bi)
deallocate buffer
'getkey()




