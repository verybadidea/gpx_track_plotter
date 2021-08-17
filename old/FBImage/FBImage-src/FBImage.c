/*
  Jonathan Dummer
  2007-07-26-10.36

  Simple OpenGL Image Library

  Public Domain
  using Sean Barret's stb_image as a base

  Thanks to:
  * Sean Barret - for the awesome stb_image
  * Dan Venkitachalam - for finding some non-compliant DDS files, and patching some explicit casts
  * everybody at gamedev.net
*/

#include "config.h"

#ifdef WIN32
  #define WIN32_LEAN_AND_MEAN
  #include <windows.h>
  #include <wingdi.h>
#endif

#include "FBImage.h"

#include "stb_image_aug.h"
#include "image_helper.h"
#include "image_DXT.h"

#include "stb_image_write.h"

#include <stdint.h>
#include <stdlib.h>
#include <string.h>

/*  error reporting  */
char *result_string_pointer = "LoadImage initialized";

/*  for loading cube maps  */
enum{
  SOIL_CAPABILITY_UNKNOWN = -1,
  SOIL_CAPABILITY_NONE    = 0,
  SOIL_CAPABILITY_PRESENT = 1
};

void _free_image_data(unsigned char *img_data) {
  free( (void*)img_data );
}

#ifdef __cplusplus
extern "C" {
#endif

const char* DLL_EXPORT GetLastResult(void) {
  return result_string_pointer;
}


void doimg(unsigned char*d, unsigned char* s,int dpitch,int spitch, int w,int h) {
  int x,y,x4;
  for (y=0;y<h;y++){
    x4=0;
    for (x=0;x<w;x++){
      d[x4+0]=s[x4+2];
      d[x4+1]=s[x4+1];
      d[x4+2]=s[x4+0];
      d[x4+3]=s[x4+3];
      x4+=4;
    }
    d+=dpitch;
    s+=spitch;
  }
}

FBImage* DLL_EXPORT LoadRGBAFile(const char * filename){
  int w,h,c,dpitch,spitch;

  FBImage* img=NULL;
  if (filename==NULL) {
    result_string_pointer="Image load failed no filename !";
    return NULL;
  }
  unsigned char* p = stbi_load(filename,&w,&h,&c,4);
  if (p==NULL){
    result_string_pointer = stbi_failure_reason();
    return img;
  }
  spitch = w*4;
  dpitch = spitch+15;
  dpitch = dpitch & 0xFFFF0;

  int p_size = (sizeof(void *) + 0xF) & 0xF;
  void *tmp = malloc(32 + h*dpitch + p_size + 0xF);

  if (tmp == NULL) {
    free(p);
    result_string_pointer="Image load failed out of memory !";
    return NULL;
  }

  img = (FBImage*)(((intptr_t)tmp + p_size + 0xF) & ~0xF);
  ((void **)img)[-1] = tmp;

  img->image_hdr = 7;
  img->image_bpp = 4;
  img->image_w   = w;
  img->image_h   = h;
  img->image_p   = dpitch;
  unsigned char * s = p;
  unsigned char * d = (unsigned char*)img;
  d+=32;
  doimg(d,s,dpitch,spitch,w,h);
  free(p);
  return img;
}

FBImage* DLL_EXPORT LoadRGBAMemory(const void * buffer,int buffersize){
  int w,h,c,dpitch,spitch;
  FBImage* img=NULL;
  if (buffer==NULL) {
    result_string_pointer="Image load failed no buffer !";
    return img;
  }
  if (buffersize<10) {
    result_string_pointer="Image load failed wrong buffersize !";
    return img;
  }
  unsigned char* p = stbi_load_from_memory(buffer,buffersize,&w,&h,&c,4);
  if (p==NULL){
    result_string_pointer = stbi_failure_reason();
    return img;
  }

  spitch = w*4;
  dpitch = spitch+15;
  dpitch = dpitch & 0xFFFF0;

  int p_size = (sizeof(void *) + 0xF) & 0xF;
  void *tmp = malloc(32 + h*dpitch + p_size + 0xF);

  if (tmp == NULL) {
    free(p);
    result_string_pointer="Image load failed out of memory !";
    return NULL;
  }

  img = (FBImage*)(((intptr_t)tmp + p_size + 0xF) & ~0xF);
  ((void **)img)[-1] = tmp;

  img->image_hdr = 7;
  img->image_bpp = 4;
  img->image_w   = w;
  img->image_h   = h;
  img->image_p   = dpitch;
  unsigned char * s =p;
  unsigned char * d = (unsigned char*)img;
  d+=32;
  doimg(d,s,dpitch,spitch,w,h);
  free(p);
  return img;
}

unsigned char DLL_EXPORT SavePNGFile(FBImage* img,const char * filename,unsigned char saveAlpha){
  int x,y,w,h,dpitch,spitch,res=0;

  if (img==NULL)
    return 0;

  if(img->image_hdr != 7)
    return 0;

  w = img->image_w;
  if (w<1)
    return 0;

  h = img->image_h;
  if (h<1)
    return 0;

  unsigned char * s = (unsigned char*)img;
  s+=32;
  spitch=img->image_p;

  unsigned char * d=NULL;
  unsigned char * dm=NULL;
  if (img->image_bpp==1){
    dpitch=w;
    dm = malloc(dpitch*h);
    if (!dm) return 0;
    d=dm;
    for (y=0;y<h;y++){
      for (x=0;x<w;x++){
        d[x]=s[x];
      }
      d+=dpitch;
      s+=spitch;
    }
    res = stbi_write_png(filename, w, h, 1, dm, 0);
  }
  else if (img->image_bpp==2){
    dpitch=w*2;
    dm = malloc(dpitch*h);
    if (!dm) return 0;
    d=dm;
    for (y=0;y<h;y++){
      for (x=0;x<w;x++){
        d[x*2+0]=s[x*2+0];
        d[x*2+1]=s[x*2+1];
      }
      d+=dpitch;
      s+=spitch;
    }
    res = stbi_write_png(filename, w, h, 2, dm, 0);
  }
  else if (img->image_bpp==4){
    if (saveAlpha!=0){
      dpitch=w*4;
      dm = malloc(dpitch*h);
      if (!dm) return 0;
      d=dm;
      for (y=0;y<h;y++){
        for (x=0;x<w;x++){
          d[x*4+0]=s[x*4+2];
          d[x*4+1]=s[x*4+1];
          d[x*4+2]=s[x*4+0];
          d[x*4+3]=s[x*4+3];
        }
        d+=dpitch;
        s+=spitch;
      }
      res = stbi_write_png(filename, w, h, 4, dm, 0);
    }
    else
    {
      dpitch=w*3;
      dm = malloc(dpitch*h);
      if (!dm) return 0;
      d=dm;
      for (y=0;y<h;y++){
        for (x=0;x<w;x++){
          d[x*3+0]=s[x*4+2];
          d[x*3+1]=s[x*4+1];
          d[x*3+2]=s[x*4+0];
        }
        d+=dpitch;
        s+=spitch;
      }
      res = stbi_write_png(filename, w, h, 3, dm,0);
    }
  }
  free(dm);
  if (res!=0)
    return 1;
  else
    return 0;
}
#ifdef __cplusplus
}
#endif
