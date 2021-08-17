' [S]imple [N]etwork [C]onnection
#include once "snc.bi"
' test of a printer client connection 
const as string ServerIP   = "10.0.0.196"
const as ushort ServerPort = 9100
' connect to printer server
var client = NetworkClient(ServerIP,ServerPort)
' get a connection from ConnectionFactory
var connection = client.GetConnection()
' ready to send ?
while connection->CanPut()<>1: sleep 100 : wend
' put data on the connection
connection->PutData(@yourData,SizeOfYourData)
sleep
