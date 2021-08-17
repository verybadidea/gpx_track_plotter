'Display map image from thunderforest using SNC & FBImage

#include once "snc/snc.bi"
#include once "snc/snc_utility.bi"
#include once "FBImage.bi" 'do not confuse with fb.image
#include once "fbgfx.bi"

'get image from Thunderforest
function getMapImage(lon as double, lat as double, zoom as integer,_
	style as string, wImg as integer, hImg as integer) as fb.image ptr
	'
	'dim as string lon = "5.490290" 'longitude
	'dim as string lat = "51.457360" 'latitude
	'dim as string zoom = "10" 'https://wiki.openstreetmap.org/wiki/Zoom_levels
	'dim as string style = "atlas"
	'dim as string wImg = "800" 'image width
	'dim as string hImg = "800" 'image height
	'
	dim as string apikey = "ff2cae05e1184f11ac6c2c0f7ed4cc05" 'please use your own
	dim as string ServerName = "tile.thunderforest.com"
	dim as string ServerPath = "/static/" & style & "/"
	dim as string ServerFile = "" & lon & "," & lat & "," & zoom & "/" & wImg & "x" & hImg & ".png?apikey=" & apikey
	dim as string FileType = MIME_PNG

	dim as fb.image ptr pImg
	'connect to web server at port 80
	dim as NetworkClient client = type(ServerName, 80)
	'get a connection from ConnectionFactory
	var connection = client.GetConnection()
	'build an HTTP GET request
	dim as string request = HTTPGet(ServerName, ServerPath & ServerFile, FileType)
	'ready to send ?
	while connection->CanPut() <> 1 : sleep 100 : wend
	'put data on the connection
	connection->PutData(strptr(request), len(request))
	'ready to receive ?
	while connection->CanGet() <> 1 : sleep 100 : wend
	'print "receive data ..."
	dim as zstring ptr replyBuffer
	var nBytes = connection->GetData(replyBuffer)
	'print "number of received bytes " & nBytes
	'get last char position of the HTTP asci header
	var LastChar = instr(*replyBuffer, HEADEREND) - 1
	var Header = left(*replyBuffer, LastChar)
	'is it a OK answer ?
	if instr(Header, "200 OK") < 1 then
		print "can't get " & ServerName & ServerPath & ServerFile & " !"
	else
		'get first byte behind the HTTP asci header
		var DataStart = LastChar + 4
		dim as ubyte ptr DataBuffer = @replyBuffer[DataStart]
		nBytes -= DataStart
		'convert to freebasic image format (data is copied?)
		pImg = LoadRGBAMemory(DataBuffer, nBytes)
	end if
	'free the buffer (allocate by snc.bi)
	deallocate(replyBuffer)

	return pImg
end function

'dim as string localFileName = "test.png"
'save it
'~ open localFileName for binary access write as #1
'~ put #1 , , *FileBuffer, nBytes
'~ close #1
'~ print "file saved ..."
'dim as any ptr pImg = LoadRGBAFile("test.png")
