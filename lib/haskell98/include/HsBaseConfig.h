/* HsBaseConfig.h -- Yale Haskell's stand-in for base's configuration
   header, which packages #include for the machine types' sizes and
   alignments (primitive's Data.Primitive.Types): MachDeps.h's.  The
   HTYPE_* macros of Foreign.C.Types' types are defined, their
   representations as there (generic-deriving's Enum instances use them
   unconditionally); those behind System.Posix.Types (HTYPE_DEV_T, ...)
   are not, so a package leaves out its instances for those types. */

#ifndef HSBASECONFIG_H
#define HSBASECONFIG_H
#include "MachDeps.h"

#define HTYPE_CHAR Int8
#define HTYPE_SIGNED_CHAR Int8
#define HTYPE_UNSIGNED_CHAR Word8
#define HTYPE_SHORT Int16
#define HTYPE_UNSIGNED_SHORT Word16
#define HTYPE_INT Int32
#define HTYPE_UNSIGNED_INT Word32
#define HTYPE_LONG Int64
#define HTYPE_UNSIGNED_LONG Word64
#define HTYPE_PTRDIFF_T Int64
#define HTYPE_SIZE_T Word64
#define HTYPE_WCHAR_T Int32
#define HTYPE_SIG_ATOMIC_T Int32
#define HTYPE_LONG_LONG Int64
#define HTYPE_UNSIGNED_LONG_LONG Word64
#define HTYPE_BOOL Word8
#define HTYPE_INTPTR_T Int64
#define HTYPE_UINTPTR_T Word64
#define HTYPE_INTMAX_T Int64
#define HTYPE_UINTMAX_T Word64
#define HTYPE_CLOCK_T Int64
#define HTYPE_TIME_T Int64
#define HTYPE_USECONDS_T Word32
#define HTYPE_SUSECONDS_T Int64
#define HTYPE_FLOAT Float
#define HTYPE_DOUBLE Double
#endif
