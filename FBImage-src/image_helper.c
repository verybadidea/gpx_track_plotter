/*
    Jonathan Dummer

    image helper functions

    MIT license
*/

#include "config.h"

#include "image_helper.h"

#include <stdlib.h>
#include <math.h>



unsigned char clamp_byte( int x ) {
  return ( (x) < 0 ? (0) : ( (x) > 255 ? 255 : (x) ) );
}


/*
	This function takes the YCoCg components of the image
	and converts them into RGB.  See above.
*/
int
	convert_YCoCg_to_RGB
	(
		unsigned char* orig,
		int width, int height, int channels
	)
{
	int i;
	/*	error check	*/
	if( (width < 1) || (height < 1) ||
		(channels < 3) || (channels > 4) ||
		(orig == NULL) )
	{
		/*	nothing to do	*/
		return -1;
	}
	/*	do the conversion	*/
	if( channels == 3 )
	{
		for( i = 0; i < width*height*3; i += 3 )
		{
			int co = orig[i+0] - 128;
			int y  = orig[i+1];
			int cg = orig[i+2] - 128;
			/*	R	*/
			orig[i+0] = clamp_byte( y + co - cg );
			/*	G	*/
			orig[i+1] = clamp_byte( y + cg );
			/*	B	*/
			orig[i+2] = clamp_byte( y - co - cg );
		}
	} else
	{
		for( i = 0; i < width*height*4; i += 4 )
		{
			int co = orig[i+0] - 128;
			int cg = orig[i+1] - 128;
			unsigned char a  = orig[i+2];
			int y  = orig[i+3];
			/*	R	*/
			orig[i+0] = clamp_byte( y + co - cg );
			/*	G	*/
			orig[i+1] = clamp_byte( y + cg );
			/*	B	*/
			orig[i+2] = clamp_byte( y - co - cg );
			/*	A	*/
			orig[i+3] = a;
		}
	}
	/*	done	*/
	return 0;
}

float find_max_RGBE (unsigned char *image, int width, int height) {
	float max_val = 0.0f;
	unsigned char *img = image;
	int i, j;
	for( i = width * height; i > 0; --i )
	{
		/* float scale = powf( 2.0f, img[3] - 128.0f ) / 255.0f; */
		float scale = ldexp( 1.0f / 255.0f, (int)(img[3]) - 128 );
		for( j = 0; j < 3; ++j )
		{
			if( img[j] * scale > max_val )
			{
				max_val = img[j] * scale;
			}
		}
		/* next pixel */
		img += 4;
	}
	return max_val;
}

int RGBE_to_RGBdivA(unsigned char *image,
                    int width, int height,
                    int rescale_to_max) {
	/* local variables */
	int i, iv;
	unsigned char *img = image;
	float scale = 1.0f;
	/* error check */
	if( (!image) || (width < 1) || (height < 1) )
	{
		return 0;
	}
	/* convert (note: no negative numbers, but 0.0 is possible) */
	if( rescale_to_max )
	{
		scale = 255.0f / find_max_RGBE( image, width, height );
	}
	for( i = width * height; i > 0; --i )
	{
		/* decode this pixel, and find the max */
		float r,g,b,e, m;
		/* e = scale * powf( 2.0f, img[3] - 128.0f ) / 255.0f; */
		e = scale * ldexp( 1.0f / 255.0f, (int)(img[3]) - 128 );
		r = e * img[0];
		g = e * img[1];
		b = e * img[2];
		m = (r > g) ? r : g;
		m = (b > m) ? b : m;
		/* and encode it into RGBdivA */
		iv = (m != 0.0f) ? (int)(255.0f / m) : 1.0f;
		iv = (iv < 1) ? 1 : iv;
		img[3] = (iv > 255) ? 255 : iv;
		iv = (int)(img[3] * r + 0.5f);
		img[0] = (iv > 255) ? 255 : iv;
		iv = (int)(img[3] * g + 0.5f);
		img[1] = (iv > 255) ? 255 : iv;
		iv = (int)(img[3] * b + 0.5f);
		img[2] = (iv > 255) ? 255 : iv;
		/* and on to the next pixel */
		img += 4;
	}
	return 1;
}

int RGBE_to_RGBdivA2 (unsigned char *image,
                      int width, int height,
                      int rescale_to_max) {
	/* local variables */
	int i, iv;
	unsigned char *img = image;
	float scale = 1.0f;
	/* error check */
	if( (!image) || (width < 1) || (height < 1) )
	{
		return 0;
	}
	/* convert (note: no negative numbers, but 0.0 is possible) */
	if( rescale_to_max )
	{
		scale = 255.0f * 255.0f / find_max_RGBE( image, width, height );
	}
	for( i = width * height; i > 0; --i )
	{
		/* decode this pixel, and find the max */
		float r,g,b,e, m;
		/* e = scale * powf( 2.0f, img[3] - 128.0f ) / 255.0f; */
		e = scale * ldexp( 1.0f / 255.0f, (int)(img[3]) - 128 );
		r = e * img[0];
		g = e * img[1];
		b = e * img[2];
		m = (r > g) ? r : g;
		m = (b > m) ? b : m;
		/* and encode it into RGBdivA */
		iv = (m != 0.0f) ? (int)sqrtf( 255.0f * 255.0f / m ) : 1.0f;
		iv = (iv < 1) ? 1 : iv;
		img[3] = (iv > 255) ? 255 : iv;
		iv = (int)(img[3] * img[3] * r / 255.0f + 0.5f);
		img[0] = (iv > 255) ? 255 : iv;
		iv = (int)(img[3] * img[3] * g / 255.0f + 0.5f);
		img[1] = (iv > 255) ? 255 : iv;
		iv = (int)(img[3] * img[3] * b / 255.0f + 0.5f);
		img[2] = (iv > 255) ? 255 : iv;
		/* and on to the next pixel */
		img += 4;
	}
	return 1;
}
