-- Lowercase GHC pragmas ({-# inline f #-}, noinline), names ending in #.
{-# LANGUAGE MagicHash #-}
f :: Int -> Int
f x = x
f# :: Int -> Int
f# x = x
{-# noinline f #-}
main = print (f 1, f# 2)
