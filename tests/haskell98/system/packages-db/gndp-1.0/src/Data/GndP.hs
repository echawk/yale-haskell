-- A newtype-derived Enum, for gnd-superclass-imported.hs.
module Data.GndP where
newtype P = P Int deriving (Show, Eq, Ord, Enum, Num)
