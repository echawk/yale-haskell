-- Traditional cpp: a comment in a macro's body joins what is on its sides
-- (reflection's CAT(a,b) a/**/b).
{-# LANGUAGE CPP #-}
#define CAT(a,b) a/**/b
#define GO(n) newtype CAT(T,n) = CAT(T,n) Int; \
  instance Show CAT(T,n) where { show _ = "T" ++ show n };
GO(1)
GO(2)
main = print (T1 0) >> print (T2 0)
