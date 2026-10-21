{-# LANGUAGE ConstraintKinds, TypeFamilies, TypeOperators, DataKinds, FlexibleContexts, FlexibleInstances, UndecidableInstances, UndecidableSuperClasses, MultiParamTypeClasses #-}
type family Check a :: () where Check a = '()
type Fine a = (Check a ~ '())
type ShowEq a = (Show a, Eq a)

class Fine a => Good a
instance Fine a => Good a
class ShowEq a => Both a
instance ShowEq a => Both a

f :: (Good a, Both a) => a -> a -> String
f x y = show (x == y) ++ show x

main :: IO ()
main = putStrLn (f 'a' 'a')
