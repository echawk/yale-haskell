/* Rts.h for packages' C sources built by MicroCabal's Yale Haskell
   backend: only the Stg* integer types that C helpers use (basement's
   foundation_prim.h).  There is no GHC runtime system to call. */
#ifndef RTS_H
#define RTS_H
#include "HsFFI.h"
typedef long           StgInt;
typedef unsigned long  StgWord;
typedef int8_t   StgInt8;   typedef uint8_t  StgWord8;
typedef int16_t  StgInt16;  typedef uint16_t StgWord16;
typedef int32_t  StgInt32;  typedef uint32_t StgWord32;
typedef int64_t  StgInt64;  typedef uint64_t StgWord64;
typedef float    StgFloat;
typedef double   StgDouble;
typedef void    *StgPtr;
typedef char    *StgChar_p;
#endif
