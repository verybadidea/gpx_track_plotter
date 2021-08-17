#ifndef __SNC_BI__
#define __SNC_BI__

' Modified version of:
' file: snc.bi [S]imple [N]etwork [C]onnection
' needs uptodate include files.
' see at: http://www.freebasic.net/forum/viewtopic.php?f=7&t=23421

#include "crt/mem.bi" ' memcpy

#ifdef __FB_WIN32__
	#include "windows.bi"
	#include "win/windef.bi"
	#include "win/winsock2.bi"

	sub NetworkInit constructor
		dim as WSAData wd
		WSAStartup(WINSOCK_VERSION, @wd)
	end sub

	sub Network_Exit() destructor
		WSACleanup()
	end sub

#else
	#include "crt/unistd.bi"     ' close_ ...
	#include "crt/netinet/in.bi" ' socket.bi ...
	#include "crt/sys/select.bi" ' FD_SET ...
	#include "crt/netdb.bi"      ' hostent ...
	#include "crt/arpa/inet.bi"  ' inet_ntoa ...
#endif

#ifdef __FB_WIN32__
	#ifdef __FB_64BIT__
		type SNC_SOCKET as ulongint
		const as SNC_SOCKET SNC_SOCK_ERROR  = &HFFFFFFFFFFFFFFFF
	#else
		type SNC_SOCKET as ulong
		const as SNC_SOCKET SNC_SOCK_ERROR  = &HFFFFFFFF
	#endif
#elseif defined(__FB_LINUX__)
	type SNC_SOCKET as long
	const as SNC_SOCKET SNC_SOCK_ERROR  = &HFFFFFFFF
#else
	#error 666: Target must be Windows or Linux !
#endif

enum NETWORK_ERROR
	ERROR_NO_ERROR = 0
	' connection
	ERROR_DISCONNECTED = -01
	ERROR_PUT_PTR = -02
	ERROR_PUT_SIZE = -03
	ERROR_PUT_SEND = -04
	ERROR_GET = -05
	' socket
	ERROR_SOCKET = -11
	ERROR_SETSOCKOPT = -12
	ERROR_SELECT = -13
	' client
	ERROR_CONNECT = -21
	ERROR_RESOLVE = -22
	' server
	ERROR_BIND = -31
	ERROR_LISTEN = -32
	ERROR_ACCEPT = -33
end enum

function GetNetworkErrorText(byval errorcode as NETWORK_ERROR) as string
	select case as const errorcode
		case ERROR_NO_ERROR     : return "no error !"
		' connection
		'case ERROR_PUT          : return "error: put data !" 
		case ERROR_GET          : return "error: get data !"
		case ERROR_DISCONNECTED : return "error: disconnected !"
		' socket
		case ERROR_SOCKET       : return "error: socket !"
		case ERROR_SETSOCKOPT   : return "error: setsockopt !"
		case ERROR_SELECT       : return "error: select !"
		' client
		case ERROR_CONNECT      : return "error: client connect !"
		case ERROR_RESOLVE      : return "error: client resolve IP"
		' server
		case ERROR_BIND         : return "error: server bind() !"
		case ERROR_LISTEN       : return "error: server listen() !"
		case ERROR_ACCEPT       : return "error: server accept() !"
		case else               : return "error: " & errorcode & " unknow !"
	end select
end function

' A NetworkConnection has to be constructed with a server or a client.
' You can send and receive any data to/from your peer with it.
type NetworkConnection
	public:
	declare constructor (byval aSocket as SNC_SOCKET)
	declare destructor

	' returns: 1 = you can send data
	' returns: 0 = not ATM. try again
	' returns:-1 = error
	declare function CanPut() as integer

	' returns: 1 = you can get data
	' returns: 0 = no data
	' returns:-1 = error
	declare function CanGet() as integer

	' Sends any data
	' NOTE: send a string like this: PutData(strptr(txt),len(txt)+1)
	' returns number of bytes sended
	' returns -1 as error signal
	declare function PutData(byval pData as any ptr, byval dataSize as integer) as integer

	' Receives any data (pData will be reallocated)
	' returns number of reseived bytes 
	' returns  0 if other connection are closed
	' returns -1 as error signal
	declare function GetData(byref pData as any ptr, byval maxSize as integer = 0) as integer

	'declare function GetLastError as NETWORK_ERROR
	declare function GetSocketError as NETWORK_ERROR
	protected:
	as SNC_SOCKET sock 
	as any ptr pInData
	as fd_set read_fds, write_fds
	as timeval timeout
	'as NETWORK_ERROR lastError
	as NETWORK_ERROR socketError 'added
end type

constructor NetworkConnection(byval aSocket as SNC_SOCKET)
	sock = aSocket
	socketError = iif(sock = SNC_SOCK_ERROR, ERROR_SOCKET, ERROR_NO_ERROR)
end constructor

'~ function NetworkConnection.GetLastError as NETWORK_ERROR
	'~ return lasterror
'~ end function

function NetworkConnection.GetSocketError as NETWORK_ERROR
	return socketError
end function

destructor NetworkConnection
	if sock <> SNC_SOCK_ERROR then closesocket(sock)
end destructor

function NetworkConnection.CanPut as integer
	if sock = SNC_SOCK_ERROR then return ERROR_SOCKET
	FD_ZERO(@write_fds)
	FD_SET_(sock, @write_fds)
	if select_(sock + 1, 0, @write_fds, 0, @timeout) = -1 then return ERROR_SELECT
	return iif(FD_ISSET(sock, @write_fds), 1, 0)
end function

function NetworkConnection.PutData(byval pData as any ptr, byval dataSize as integer) as integer
	if sock = SNC_SOCK_ERROR then return ERROR_SOCKET
	if pData = 0 then return ERROR_PUT_PTR
	if dataSize < 1 then return ERROR_PUT_SIZE
	dim as integer size, dSize = dataSize
	' as long as not all data has been send
	while (size < dataSize)
		dim as integer nBytes = send(sock, pData, dSize, 0)
		if nBytes < 0 then return ERROR_PUT_SEND
		pData += nBytes
		dSize -= nBytes
		size += nBytes
	wend
	return size
end function

function NetworkConnection.CanGet as integer
	if sock = SNC_SOCK_ERROR then return ERROR_SOCKET
	FD_ZERO(@read_fds)
	FD_SET_(sock, @read_fds)
	if select_(sock + 1, @read_fds, 0, 0, @timeout) = -1 then return ERROR_SELECT
	return iif(FD_ISSET(sock, @read_fds), 1, 0)
end function

'maxSize should be minSize?
function NetworkConnection.GetData(byref pData as any ptr, byval maxSize as integer) as integer
	const CHUNK_SIZE = 1024 * 8
	static as ubyte chunk(CHUNK_SIZE - 1)
	if sock = SNC_SOCK_ERROR then return ERROR_SOCKET
	dim as integer dSize = 0 'totalizer
	if pData then deallocate pData : pData = 0
	do
		'receive in buffer: chuck
		dim as integer nBytes = recv(sock, @chunk(0), CHUNK_SIZE, 0)
		'nothing reveiced?
		if nBytes = 0 then
			if dSize < maxSize then return ERROR_DISCONNECTED
			'exit do
			return dSize 'we are done
		end if

		if nBytes < 0 then return ERROR_GET

		'add reveived chunk to data buffer
		pData = reallocate(pData, dSize + nBytes)
		dim as ubyte ptr pWrite = pData + dSize
		memcpy pWrite, @chunk(0), nBytes
		dSize += nBytes

		'more data received then was asked for?
		if maxSize > 0 andalso dSize >= maxSize then exit do

		dim as integer _timeout = 200
		sleep 10
		while CanGet() <> 1 andalso _timeout > 0
			sleep 10 : _timeout -= 10
		wend

		if _timeout <= 0 then return ERROR_DISCONNECTED
		
	loop
	return dSize
end function

'-------------------------------------------------------------------------------

' constructing NetworkConnection pointers
type ConnectionFactoy extends object
	public:
	declare constructor
	declare virtual destructor
	' return a connection If it returns NULL, there is no connection available.
	declare abstract function GetConnection() as NetworkConnection ptr
	declare function GetLastError as NETWORK_ERROR

	protected:
	as SNC_SOCKET sock
	as fd_set read_fd
	as sockaddr_in addr
	as NETWORK_ERROR lastError
end type

constructor ConnectionFactoy
	  sock = opensocket(AF_INET, SOCK_STREAM, 0)
	  if sock = SNC_SOCK_ERROR then lasterror = ERROR_SOCKET
end constructor

destructor ConnectionFactoy
	if sock <> SNC_SOCK_ERROR then
		closesocket(sock)
		sock = SNC_SOCK_ERROR
	end if
end destructor

function ConnectionFactoy.GetLastError as NETWORK_ERROR
	return lasterror
end function

'-------------------------------------------------------------------------------

' Constructs connection to server
type NetworkClient extends ConnectionFactoy
	public:
	' Initialized with the server address and the destination port
	declare constructor (address as string, byval port as ushort)
	' Returns a connection to the server
	declare function GetConnection() as NetworkConnection ptr
end type

' connection_maker(port)
constructor NetworkClient(address as string,byval port as ushort)
	base()
	if port=SNC_SOCK_ERROR then 
		LastError = ERROR_SOCKET
		return
	end if
	' server address
	dim as hostent ptr he = gethostbyname(strptr(address))
	if (he = 0) then 
		LastError = ERROR_RESOLVE
		return
	end if
	addr.sin_family = AF_INET
	addr.sin_port = htons(port)
	addr.sin_addr = *cptr(in_addr ptr, he->h_addr_list[0])
	if connect(sock, cptr(sockaddr ptr, @addr), sizeof(sockaddr)) = SNC_SOCK_ERROR then
		LastError = ERROR_CONNECT
	end if
end constructor

function NetworkClient.GetConnection() as NetworkConnection ptr
	return new NetworkConnection(sock)
end function

'-------------------------------------------------------------------------------

' Constructs connections to clients
type NetworkServer extends ConnectionFactoy
	public:
	' Opens connection possibility on port for maxConnections clients
	declare constructor (byval port as ushort,byval maxConnections as long=64)
	' Returns a connection to a connecting client
	declare function GetConnection() as NetworkConnection ptr
	dim as string ClientIP
	dim as ushort ClientPort
	private:
	as timeval timeout
end type

constructor NetworkServer(byval port as ushort,byval maxConnections as long)
	base()
	if sock=SNC_SOCK_ERROR then 
		LastError = ERROR_SOCKET
		return
	end if
	addr.sin_family = AF_INET
	addr.sin_port = htons(port)
	addr.sin_addr.s_addr = INADDR_ANY
	if bind(sock, cptr(sockaddr ptr,@addr), sizeof(sockaddr)) = SNC_SOCK_ERROR then
		lasterror = ERROR_BIND
	elseif listen(sock, maxConnections) = SNC_SOCK_ERROR then
		lasterror = ERROR_LISTEN
	end if
end constructor

function NetworkServer.GetConnection() as NetworkConnection ptr
	FD_ZERO(@read_fd)
	FD_SET_(sock, @read_fd)
	if select_(sock + 1, @read_fd, 0, 0, @timeout) = SNC_SOCK_ERROR then
		lasterror=ERROR_SELECT
		return 0
	end if

	if FD_ISSET(sock, @read_fd) = 0 then return 0

	dim as sockaddr_in ClientAddress
	dim as long size = sizeof(sockaddr_in)
	var clientsock = accept(sock, cptr(sockaddr ptr,@ClientAddress), @size)
	if clientsock=SNC_SOCK_ERROR then
		lasterror = ERROR_ACCEPT
		return 0
	end if
	dim as zstring ptr pIP = inet_ntoa(ClientAddress.sin_addr)
	if pIP then 
		ClientIP   = *pIP
		ClientPort = ntohs(ClientAddress.sin_port)
	else
		ClientIP   = ""
		ClientPort = 0
	end if
	return new NetworkConnection(clientsock)
end function

#endif '__SNC_BI__
