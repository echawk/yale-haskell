{-# LANGUAGE CPP #-}
#define __YALE_HSC__ 1
#include "cpp-hsc-header.h"
main = print (HSC_LIMIT :: Int)
