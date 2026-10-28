{-# LANGUAGE CPP #-}
-- F() of a one-parameter macro is one empty argument, as in C (GHC's
-- CodeGen.Platform.hs has REG() in a comment).
#define REG(x) [x]
-- the REG() macro
main = print (length "REG()", REG(1))
