{-# LANGUAGE ImplicitParams #-}
module Main where
import ImplicitParamsA
g :: (?cutoff :: Cut) => Int
g = f 1 * 2
main = print (let ?cutoff = Cut 4 in g)
