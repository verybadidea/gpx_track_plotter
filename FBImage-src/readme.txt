        SOIL

	Jonathan Dummer
	2007-07-26-10.36

	Simple OpenGL Image Library

	A tiny c library for uploading images as
	textures into OpenGL.  Also saving and
	loading of images is supported.

	I'm using Sean's Tool Box image loader as a base:
	http://www.nothings.org/

	I'm upgrading it to load TGA and DDS files, and a direct
	path for loading DDS files straight into OpenGL textures,
	when applicable.

	Image Formats:
	- BMP		load & save
	- TGA		load & save
	- DDS		load & save
	- PNG		load
	- JPG		load

	OpenGL Texture Features:
	- resample to power-of-two sizes
	- MIPmap generation
	- compressed texture S3TC formats (if supported)
	- can pre-multiply alpha for you, for better compositing
	- can flip image about the y-axis (except pre-compressed DDS files)

	Thanks to:
	* Sean Barret - for the awesome stb_image
	* Dan Venkitachalam - for finding some non-compliant DDS files, and patching some explicit casts
	* everybody at gamedev.net
