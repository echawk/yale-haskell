/* HsFFI.h for packages' C sources built by MicroCabal's Yale Haskell
   backend (tools/microcabal/Yale.hs): the Haskell 2010 FFI's C types as
   Yale Haskell passes them (Int as a C long, Char as a 32-bit code
   point).  hs_init and the like are not provided: the runtime is SBCL's,
   started before any C code runs. */
#ifndef HSFFI_H
#define HSFFI_H
#include <stdint.h>
#include <stddef.h>
typedef long          HsInt;
typedef unsigned long HsWord;
typedef int8_t        HsInt8;
typedef int16_t       HsInt16;
typedef int32_t       HsInt32;
typedef int64_t       HsInt64;
typedef uint8_t       HsWord8;
typedef uint16_t      HsWord16;
typedef uint32_t      HsWord32;
typedef uint64_t      HsWord64;
typedef int32_t       HsChar;
typedef int           HsBool;
typedef float         HsFloat;
typedef double        HsDouble;
typedef void         *HsPtr;
typedef void        (*HsFunPtr)(void);
typedef void         *HsStablePtr;
#define HS_BOOL_FALSE 0
#define HS_BOOL_TRUE  1
#endif
