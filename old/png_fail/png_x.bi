#include once "png16.bi"
#include once "fbgfx.bi"
'#include once "crt/errno.bi"
#include once "crt/string.bi"

private sub libpng_error_callback cdecl(byval png as png_structp, byval p as png_const_charp)
	print "libpng failed to load the image (" & *p & ")"
end sub

'From freeBASIC examples, a bit modified
function imageread_png(byref filename as string, byval bpp as integer) as FB.IMAGE ptr
	
	dim as ubyte header(0 to 7)
	
	dim as FILE ptr fp = fopen(filename, "rb")
	if fp = 0 then
		print "could not open image file"
		return 0
	end if
	
	if fread(@header(0), 1, 8, fp) <> 8 then
		print "couldn't read header"
		fclose(fp)
		return 0
	end if
	
	if(png_sig_cmp(@header(0), 0, 8)) then
		print "png_sig_cmp() failed"
		fclose(fp)
		return 0
	end if
	
	dim as png_structp png = png_create_read_struct(PNG_LIBPNG_VER_STRING, NULL, @libpng_error_callback, NULL)
	if png = 0 then
		print "png_create_read_struct() failed"
		fclose(fp)
		return 0
	end if
	
	dim as png_infop info = png_create_info_struct(png)
	if info = 0 then
		print "png_create_info_struct() failed"
		fclose(fp)
		return 0
	end if
	
	png_init_io(png, fp)
	png_set_sig_bytes(png, 8)
	png_read_info(png, info)

	dim as integer w, h, bitdepth, channels, pixdepth, colortype, rowbytes
	w = png_get_image_width(png, info)
	h = png_get_image_height(png, info)
	bitdepth = png_get_bit_depth(png, info)
	channels = png_get_channels(png, info)
	pixdepth = bitdepth * channels
	colortype = png_get_color_type(png, info)

	dim as FB.IMAGE ptr pImg = imagecreate(w, h)
	dim as ubyte ptr pDst = cptr(ubyte ptr, pImg + 1)

	png_set_interlace_handling(png)
	png_read_update_info(png, info)

	rowbytes = png_get_rowbytes(png, info)
	dim as ubyte ptr pSrc = callocate(rowbytes)

	for y as integer = 0 to h-1
		png_read_row(png, pSrc, NULL)

		select case(colortype)
		case PNG_COLOR_TYPE_RGB
			imageconvertrow(pSrc, 24, pDst, bpp, w)
			pDst += pImg->pitch
		
		case PNG_COLOR_TYPE_RGB_ALPHA
			select case(bpp)
			case 24, 32
				for i as integer = 0 to rowbytes-1 step 4
					'' FB wants: &hAARRGGBB, that is &hBB &hGG &hRR &hAA (little endian)
					'' libpng provides &hAABBGGRR, that is &hRR &hGG &hBB &hAA (little endian)
					'' so we need to copy AA/GG as-is, and swap RR/BB
					pDst[0] = pSrc[i+2]
					pDst[1] = pSrc[i+1]
					pDst[2] = pSrc[i+0]
					pDst[3] = pSrc[i+3]
					pDst += 4
				next
			case 15, 16
				'' No alpha supported, only RGB will be used
				imageconvertrow(pSrc, 32, pDst, bpp, w )
				pDst += pImg->pitch
			end select
		
		case PNG_COLOR_TYPE_GRAY
			select case(bpp)
			case 24, 32
				for i as integer = 0 to rowbytes-1
					*cptr(ulong ptr, pDst) = rgb( pSrc[i], pSrc[i], pSrc[i] )
					pDst += 4
				next
			case 15, 16
				for i as integer = 0 to rowbytes-1
					pset pImg, (i, y), rgb( pSrc[i], pSrc[i], pSrc[i] )
				next
			case else
				'' 8 bpp and less require a proper global palette,
				'' which contains the colors used in the image
				'for i as integer = 0 to rowbytes-1
				'	pset pImg, (i, jinfo.output_scanline-1), pSrc[i]
				'next
				memcpy(pDst, pSrc, rowbytes )
				pDst += pImg->pitch
			end select
		end select
	next
	
	deallocate(pSrc)
	
	png_read_end(png, info)
	png_destroy_read_struct(@png, @info, 0)
	fclose(fp)
	
	return pImg
end function
