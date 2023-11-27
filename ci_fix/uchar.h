#ifndef _STEAMRT_UCHAR_H_
#define _STEAMRT_UCHAR_H_

#ifndef __cplusplus

/* 
 * This file is used only for old GCC platforms that do not support
 * uchar.h, e.g. GCC 4.8.4 on SteamRT
 */

#ifdef _FAKE_UCHAR_

#include <stdint.h>

typedef uint16_t char16_t;
typedef uint32_t char32_t;

#endif /* _FAKE_UCHAR_ */

#endif /* __cplusplus */
#endif /* _STREAMRT_UCHAR_H_ */
