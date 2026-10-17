/* MachDeps.h -- Yale Haskell's stand-in for the header GHC installs,
   which packages #include for the sizes of the machine types (primitive,
   vector, hashable).  The sizes are those of a 64-bit GHC; Yale Haskell's
   Int is the 63-bit fixnum (doc/plans/GHC-EXTENSIONS.md), but code that
   asks is sizing a memory layout or a word's bits, which follow the
   64-bit machine. */

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

#define SIZEOF_HSCHAR 4
#define SIZEOF_HSINT 8
#define SIZEOF_HSWORD 8
#define SIZEOF_HSFLOAT 4
#define SIZEOF_HSDOUBLE 8
#define SIZEOF_HSPTR 8
#define SIZEOF_HSFUNPTR 8
#define SIZEOF_HSSTABLEPTR 8

#define SIZEOF_INT8 1
#define SIZEOF_WORD8 1
#define SIZEOF_INT16 2
#define SIZEOF_WORD16 2
#define SIZEOF_INT32 4
#define SIZEOF_WORD32 4
#define SIZEOF_INT64 8
#define SIZEOF_WORD64 8

#define ALIGNMENT_HSCHAR 4
#define ALIGNMENT_HSINT 8
#define ALIGNMENT_HSWORD 8
#define ALIGNMENT_HSFLOAT 4
#define ALIGNMENT_HSDOUBLE 8
#define ALIGNMENT_HSPTR 8
#define ALIGNMENT_HSFUNPTR 8
#define ALIGNMENT_HSSTABLEPTR 8
#define ALIGNMENT_INT8 1
#define ALIGNMENT_WORD8 1
#define ALIGNMENT_INT16 2
#define ALIGNMENT_WORD16 2
#define ALIGNMENT_INT32 4
#define ALIGNMENT_WORD32 4
#define ALIGNMENT_INT64 8
#define ALIGNMENT_WORD64 8

#define WORD_SIZE_IN_BITS 64
#define WORD_SIZE_IN_BITS_FLOAT 64.0
#define TAG_BITS 3
#define TAG_MASK ((1 << TAG_BITS) - 1)

#endif
