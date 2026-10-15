-- Two constructors named Success (hiding-constructor.hs).
module HideConA (R(..)) where
data R = Success Int | Failure String deriving Show
