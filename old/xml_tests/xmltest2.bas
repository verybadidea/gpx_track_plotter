#include once "libxml/xmlreader.bi"
#define NULL 0

dim as string filename = "biking-Sun May 3 17:27:23 2020-23.2km.gpx" '"6461.xml"

dim as xmlTextReaderPtr pReader = xmlReaderForFile( filename, NULL, 0 )

if (pReader = NULL) then
	print "Unable to open "; filename
	end 1
end if

dim as integer ret = xmlTextReaderRead(pReader)

dim as const zstring ptr pConstName, pConstValue

do while( ret = 1 )
	pConstName = xmlTextReaderConstName(pReader)
	pConstValue = xmlTextReaderConstValue(pReader)

	print xmlTextReaderDepth(pReader); _
		xmlTextReaderNodeType(pReader); _
		" "; *pConstName; _
		xmlTextReaderIsEmptyElement(pReader); _
		xmlTextReaderHasValue(pReader); _
		*pConstValue

	ret = xmlTextReaderRead(pReader)
	getkey()
loop

xmlFreeTextReader(pReader)

if (ret <> 0) then
    print "failed to parse: "; filename
end if

xmlCleanupParser()
xmlMemoryDump()
