' [S]imple [N]etwork [C]onnection

#include once "snc.bi"

#include once "snc_utility.bi"

' test of a client connection 
const as string ServerName = "shiny3d.de"
const as string ServerPath = "/"
const as string ServerFile = ""
const as string FileType   = MIME_HTM & ";" & MIME_TXT

' connect to web server at port 80
dim as NetworkClient client=type(ServerName,80)
' get a connection from ConnectionFactory
var connection = client.GetConnection()
' build an HTTP GET request
dim as string request =HTTPGet(ServerName,ServerPath & ServerFile,FileType)

' ready to send ?
while connection->CanPut()<>1
  sleep 100
wend
' put data on the connection
connection->PutData(strptr(request),len(request))
' ready to receive ?
while connection->CanGet()<>1
  sleep 100
wend

dim as zstring ptr buffer
var nBytes = connection->GetData(buffer)
print "number of received bytes " & nBytes
' get last char position of the HTTP asci header
var LastChar=instr(*buffer,HeaderEnd)-1
var Header  =left(*buffer,LastChar)
' is it a OK answer ?
if instr(Header,"200 OK")<1 then
  print *buffer
  print "can't get " & ServerName & ServerPath & ServerFile & " !"
  beep:sleep:end
end if
' get first byte behind the HTTP asci header
var DataStart=LastChar+4
' save it
open "mypage.html" for binary access write as #1
dim as ubyte ptr FileBuffer=@buffer[DataStart]
nBytes-=DataStart
put #1,,*FileBuffer,nBytes
close #1
print "file saved ..."
' free the buffer (allocate by snc.bi)
deallocate buffer
sleep




