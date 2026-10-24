-- PackageImports: import "pkg" M, the package ignored.
{-# LANGUAGE PackageImports #-}
import "base" Data.List (sort)
main = print (sort [3,1,2::Int])
