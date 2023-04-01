#ifndef __STDINT_H__
#define __STDINT_H__

// N.B.
// char is unsigned on GCC for BBC B
// size_t is 16 bits

typedef unsigned char uint8_t;
typedef signed char int8_t;
typedef unsigned int uint16_t;
typedef signed int int16_t;
typedef unsigned long uint32_t;
typedef signed long int32_t;
typedef unsigned long long uint64_t;
typedef signed long long int64_t;

#endif // !__STDINT_H__
