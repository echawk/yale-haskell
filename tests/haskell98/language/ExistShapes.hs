{-# LANGUAGE ExistentialQuantification #-}
module ExistShapes (Shape(..), AnyShape(..), Showy(..), area', describe) where

class Shape s where
  area :: s -> Double
  name :: s -> String

data AnyShape = forall s. Shape s => AnyShape s

data Showy t = forall a. (Show a, Eq a) => Showy t a a | Plain t

area' :: AnyShape -> Double
area' (AnyShape s) = area s

describe :: AnyShape -> String
describe sh = case sh of
  AnyShape s -> name s ++ " " ++ show (area s)
