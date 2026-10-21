{-# LANGUAGE ConstraintKinds, TypeFamilies, TypeOperators, DataKinds, FlexibleContexts #-}
type family Check a :: () where Check a = '()
type Ok a = (Check a ~ '())
type ShowOk a = (Show a, Check a ~ '())

f :: Ok a => a -> Int
f _ = 1
g :: ShowOk a => a -> String
g = show

main :: IO ()
main = print (f 'x', g True)
