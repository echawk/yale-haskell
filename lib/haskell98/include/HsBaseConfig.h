/* HsBaseConfig.h -- Yale Haskell's stand-in for base's configuration
   header, which packages #include for the machine types' sizes and
   alignments (primitive's Data.Primitive.Types): MachDeps.h's.  The
   HTYPE_* macros (the C types behind System.Posix.Types) are not defined,
   so a package leaves out its instances for those types. */

#ifndef HSBASECONFIG_H
#define HSBASECONFIG_H
#include "MachDeps.h"
#endif
