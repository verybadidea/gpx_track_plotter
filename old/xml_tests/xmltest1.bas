#include once "libxml/xmlreader.bi"
#define NULL 0

declare function getNodeTypeDescrStr(nodeType as integer) as string

'dim as string filename = "xml_test_file.txt"
dim as string filename = "biking-Sun May 3 17:27:23 2020-23.2km.gpx"

dim as xmlTextReaderPtr pReader = xmlReaderForFile(filename, NULL, 0)

if (pReader = NULL) then
	print "Unable to open "; filename
	end 1
end if

dim as integer ret = xmlTextReaderRead(pReader)

dim as const zstring ptr pConstName, pConstValue
dim as const zstring ptr pAttrName, pAttrValue
dim as integer nodetype, move

do while (ret = 1)
	pConstName = xmlTextReaderConstName(pReader)
	pConstValue = xmlTextReaderConstValue(pReader)

	nodetype = xmlTextReaderNodeType(pReader)
	print "NAME: " & *pConstName
	print " Depth: " & xmlTextReaderDepth(pReader)
	print " NodeType: " & nodetype & " = " & getNodeTypeDescrStr(nodetype)
	print " IsEmpty: " & xmlTextReaderIsEmptyElement(pReader)
	print " HasValue: " & xmlTextReaderHasValue(pReader)
	print " Value: " & *pConstValue

	if xmlTextReaderHasAttributes(pReader) = 1 then
		move = 0
		do while xmlTextReaderMoveToAttributeNo(pReader, move)
			pAttrName = xmlTextReaderConstName(pReader)
			pAttrvalue = xmlTextReaderConstValue(pReader)
			print "  Attribute NAME: " + *pAttrName + " VALUE: " + *pAttrValue
			move += 1
		loop
	end if
	ret = xmlTextReaderRead(pReader)
	getkey()
loop
sleep

xmlFreeTextReader(pReader)

if( ret <> 0 ) then
	print "failed to parse: "; filename
end if

xmlCleanupParser()
xmlMemoryDump()


function getNodeTypeDescrStr(nodeType as integer) as string
	select case nodeType
	case 01 : return "XML_ELEMENT_NODE"
	case 02 : return "XML_ATTRIBUTE_NODE"
	case 03 : return "XML_TEXT_NODE"
	case 04 : return "XML_CDATA_SECTION_NODE"
	case 05 : return "XML_ENTITY_REF_NODE"
	case 06 : return "XML_ENTITY_NODE"
	case 07 : return "XML_PI_NODE"
	case 08 : return "XML_COMMENT_NODE"
	case 09 : return "XML_DOCUMENT_NODE"
	case 10 : return "XML_DOCUMENT_TYPE_NODE"
	case 11 : return "XML_DOCUMENT_FRAG_NODE"
	case 12 : return "XML_NOTATION_NODE"
	case 13 : return "XML_HTML_DOCUMENT_NODE"
	case 14 : return "XML_DTD_NODE"
	case 15 : return "XML_ELEMENT_DECL"
	case 16 : return "XML_ATTRIBUTE_DECL"
	case 17 : return "XML_ENTITY_DECL"
	case 18 : return "XML_NAMESPACE_DECL"
	case 19 : return "XML_XINCLUDE_START"
	case 20 : return "XML_XINCLUDE_END"
	end select
	return "XML_MODE_???"
end function

'See also:
'https://www.freebasic.net/forum/viewtopic.php?f=2&t=26187&p=240904&hilit=libxml#p240904
'http://xmlsoft.org/examples/index.html
'https://metacpan.org/pod/distribution/XML-LibXML/LibXML.pod
'https://www.codeproject.com/articles/15452/the-xmltextreader-a-beginner-s-guide

'~ /usr/lib/i386-linux-gnu/libxml2.so.2
'~ /usr/lib/i386-linux-gnu/libxml2.so.2.9.4
'~ /usr/lib/python2.7/dist-packages/drv_libxml2.py
'~ /usr/lib/python2.7/dist-packages/drv_libxml2.pyc
'~ /usr/lib/python2.7/dist-packages/libxml2.py
'~ /usr/lib/python2.7/dist-packages/libxml2.pyc
'~ /usr/lib/python2.7/dist-packages/libxml2mod.x86_64-linux-gnu.so
'~ /usr/lib/x86_64-linux-gnu/libxml2.so.2

'~ lrwxrwxrwx 1 root root      16 Feb  5 18:08 libxml2.so.2 -> libxml2.so.2.9.4
'~ -rw-r--r-- 1 root root 2011260 Feb  5 18:08 libxml2.so.2.9.4

'~ /usr/lib/i386-linux-gnu$ ls -l libxml*
'~ lrwxrwxrwx 1 root root      12 Jun 29 23:32 libxml2.so -> libxml2.so.2
'~ lrwxrwxrwx 1 root root      16 Feb  5 18:08 libxml2.so.2 -> libxml2.so.2.9.4
'~ -rw-r--r-- 1 root root 2011260 Feb  5 18:08 libxml2.so.2.9.4
