-- The other Success (hiding-constructor.hs).
module HideConB (P(..)) where
data P = Success Bool deriving Show
