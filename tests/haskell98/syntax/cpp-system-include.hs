{-# LANGUAGE CPP #-}
#include <sys/types.h>
#include <stdint.h>
#include "MachDeps.h"
main = print WORD_SIZE_IN_BITS
