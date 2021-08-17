#ifndef __snc_utility_bi__
#define __snc_utility_bi__

const as string LINEEND   = chr(13,10)
const as string HEADEREND = chr(13,10,13,10)

const as string MIME_HTM = "text/html"
const as string MIME_TXT = "text/plain"

const as string MIME_BMP = "image/bmp"
const as string MIME_GIF = "image/gif"
const as string MIME_JPG = "image/jpg"
const as string MIME_JPEG = "image/jpeg"
const as string MIME_PNG = "image/png"
const as string MIME_TIIF = "image/tiff"

const as string MIME_WAV = "audio/wav"
const as string MIME_MP3 = "audio/mpeg"
const as string MIME_OGG = "audio/ogg"

const as string MIME_MP4 = "video/mp4"

const as string MIME_PDF = "application/pdf"
const as string MIME_ZIP = "application/x-compressed"
const as string MIME_GZ  = "application/gzip"
const as string MIME_JSON = "application/json"
' ...

' url en/de-coding
function URLEncode(url as string) as string
  static as string * 63 an = "abcdefghijklmnopqrstuvwxyz" & _
                             "ABCDEFGHIJKLMNOPQRSTUVWXYZ" & _
                             "0123456789/"
  url=trim(url)
  dim as integer nChars = len(url)
  if nChars<1 then return ""
  dim as string encoded
  for i as integer = 1 to nChars
    dim as string char = mid(url,i,1)
    if instr(an,char)>0 then
      encoded &= char
    else
      encoded &= "%" & lcase(hex(asc(char),2))
    end if
  next
  return encoded
end function

function URLDecode(url as string) as string
  url=trim(url)
  dim as integer nChars = len(url)+1
  if nChars<2 then return ""
  dim as string decoded
  dim as integer i=1
  while i<nChars
    dim as string char = mid(url,i,1)
    if char="%" then
      decoded &= chr(val("&H" & mid(url,i+1,2))):i+=3
    else
      decoded &= char : i+=1
    end if
  wend
  return decoded
end function

' build an HTTP GET request: e.g. ("domain.com", "/test.txt", "text/plain")
' Requests a representation of the specified resource.
function HTTPGet(byref host as string, byref pathfile as string, byval mime as string="") as string
  dim as string msg
  msg  = "GET "   & pathfile & " HTTP/1.1" & LINEEND
  msg &= "Host: " & host                   & LINEEND
  if len(mime)>0 then
  msg &= "mime: " & mime                   & LINEEND
  end if
  msg &= "User-Agent: GetHTTP 0.0"         & LINEEND 
  msg &= "Connection: close"               & HEADEREND
  return msg
end function

' build an HTTP HEAD request: e.g. ("domain.com", "/test.jpg", "image/jpg")
' Asks for the response identical to the one that would correspond to a GET request, but without the response body. 
' (you can extract the content length and mime type from it)
function HTTPHead(byref host as string, byref pathfile as string, byval mime as string="") as string
  dim as string msg
  msg  = "HEAD "  & pathfile & " HTTP/1.1" & LINEEND
  msg &= "Host: " & host                   & LINEEND
  if len(mime)>0 then
  msg &= "mime: " & mime                   & LINEEND
  end if
  msg &= "Connection: close"               & HEADEREND
  return msg
end function

' build an HTTP POST request: e.g. ("domain.com", "/script.php", "key1=value&key2=value")
' Requests that the server accept the entity enclosed in the request as a new subordinate of the web resource identified by the URI.
function HTTPPost(byref host as string, byref pathfile as string, byref query as string, byval UseReferer as boolean=true) as string
  dim as string msg
  msg  = "POST "  & pathfile & " HTTP/1.1"                 & LINEEND
  msg &= "Host: " & host                                   & LINEEND
  if UseReferer then
  msg &= "Referer: http://" & host & pathfile & "?"        & LINEEND
  end if
  msg &= "Content-type: application/x-www-form-urlencoded" & LINEEND
  msg &= "Content-length: " & len(query) & LINEEND
  msg &= "Connection: close" & HEADEREND
  msg &= query
  return msg
end function 

' build an HTTP PUT request: e.g. ("domain.com", "/test.txt", "This is the content.")
' Requests that the enclosed entity be stored under the supplied URI.
function HTTPPut(byref host as string, byref pathfile as string, byval content as string) as string
  dim as string msg
  msg  = "PUT "   & pathfile & " HTTP/1.1" & LINEEND
  msg &= "Host: " & host                   & LINEEND
  msg &= content
  return msg
end function



#endif ' __snc_utility_bi__
