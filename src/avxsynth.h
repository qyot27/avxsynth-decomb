#ifndef __AVXSYNTH_H__
#define __AVXSYNTH_H__

#include "avxsynth/avxplugin.h"
#include "avxsynth/windowsPorts/basicDataTypeConversions.h"
#include <stdlib.h>
#include <malloc.h>

using namespace avxsynth;

#define OutputDebugString(s, ...) fprintf(stderr, s)
#define _aligned_malloc(size, boundary) memalign(boundary, size)
#define _aligned_free free

#endif // __AVXSYNTH_H__