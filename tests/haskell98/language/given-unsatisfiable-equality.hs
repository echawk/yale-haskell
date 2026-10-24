{-# LANGUAGE TypeFamilies, FlexibleContexts #-}
module Main where

data Term = Var Int deriving Show
data Ty = Ty deriving Show
data Sort = Sort deriving Show

class CheckI a where
  type TypeOf a
  checkI' :: a -> TypeOf a -> IO a
  inferI' :: (TypeOf a ~ ()) => a -> IO a
  inferI' v = checkI' v ()

type instance TypeOf Term = Ty
type instance TypeOf Sort = ()

instance CheckI Term where
  checkI' v _ = return v

instance CheckI Sort where
  checkI' v () = return v

main :: IO ()
main = do
  checkI' (Var 1) Ty >>= print
  inferI' Sort >>= print
