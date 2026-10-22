{-# LANGUAGE ImplicitParams #-}
module ImplicitParamsA (f, Cut(..)) where
newtype Cut = Cut Int
f :: (?cutoff :: Cut) => Int -> Int
f n = let Cut c = ?cutoff in n + c
