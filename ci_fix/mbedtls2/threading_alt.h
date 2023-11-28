#ifndef _MBEDTLS_THERADING_ALT_H_
#define _MBEDTLS_THERADING_ALT_H_

#if defined(_MSC_VER)

#include <windows.h>

typedef struct
{
    CRITICAL_SECTION cs;
    char is_valid;
} mbedtls_threading_mutex_t;

#endif /* _MBEDTLS_THERADING_ALT_H_ */
