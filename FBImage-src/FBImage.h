#ifndef __ImageLoad_h__
#define __ImageLoad_h__

#include "config.h"


#ifdef WIN32
 #ifdef BUILD_DLL
  #define DLL_EXPORT __declspec(dllexport)
 #else
  //#define DLL_EXPORT __declspec(dllimport)
  #define DLL_EXPORT
 #endif
#else
 #define DLL_EXPORT
#endif

#ifdef __cplusplus
extern "C" {
#endif
enum {
  _LOAD_RGB = 3,
  _LOAD_RGBA = 4
};

/**
  Passed in as reuse_texture_ID, will cause SOIL to
  register a new texture ID using glGenTextures().
  If the value passed into reuse_texture_ID > 0 then
  SOIL will just re-use that texture ID (great for
  reloading image assets in-game!)
**/



enum
{
  _FLAG_POWER_OF_TWO = 1,
  _FLAG_MIPMAPS = 2,
  _FLAG_TEXTURE_REPEATS = 4,
  _FLAG_MULTIPLY_ALPHA = 8,
  _FLAG_INVERT_Y = 16,
  _FLAG_COMPRESS_TO_DXT = 32,
  _FLAG_DDS_LOAD_DIRECT = 64,
  _FLAG_NTSC_SAFE_RGB = 128,
  _FLAG_CoCg_Y = 256,
  _FLAG_TEXTURE_RECTANGLE = 512
};


typedef struct {
  int image_hdr;
  int image_bpp;
  int image_w;
  int image_h;
  int image_p;
  int reserved1;
  int reserved2;
  int reserved3;
} FBImage;

FBImage* DLL_EXPORT LoadRGBAFile(const char * filename);
FBImage* DLL_EXPORT LoadRGBAMemory(const void * buffer,int buffersize);
const char* DLL_EXPORT GetLastResult(void);
unsigned char DLL_EXPORT SaveRGBAFile(FBImage* img,const char * filename);

#ifdef __cplusplus
}
#endif

#endif // __ImageLoad_h__
