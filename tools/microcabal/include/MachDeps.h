/* MachDeps.h for packages' C sources built by MicroCabal's Yale Haskell
   backend (tools/microcabal/Yale.hs), as GHC's for a 64-bit target: the
   C types' sizes.  It is not on Yale Haskell's own CPP path: there Int has
   63 bits, and a module testing WORD_SIZE_IN_BITS for 64 would assume a
   64-bit Int. */
#ifndef MACHDEPS_H
#define MACHDEPS_H
#define SIZEOF_CHAR 1
#define SIZEOF_SHORT 2
#define SIZEOF_INT 4
#define SIZEOF_LONG 8
#define SIZEOF_LONG_LONG 8
#define SIZEOF_VOID_P 8
#define SIZEOF_FLOAT 4
#define SIZEOF_DOUBLE 8
#define SIZEOF_HSINT 8
#define SIZEOF_HSWORD 8
#define SIZEOF_HSPTR 8
#define SIZEOF_HSFUNPTR 8
#define SIZEOF_HSSTABLEPTR 8
#define SIZEOF_HSCHAR 4
#define SIZEOF_HSFLOAT 4
#define SIZEOF_HSDOUBLE 8
#define SIZEOF_INT8 1
#define SIZEOF_INT16 2
#define SIZEOF_INT32 4
#define SIZEOF_INT64 8
#define SIZEOF_WORD8 1
#define SIZEOF_WORD16 2
#define SIZEOF_WORD32 4
#define SIZEOF_WORD64 8
#define WORD_SIZE_IN_BITS 64
#define TAG_BITS 3
#endif
