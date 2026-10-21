-- Text.Show.Functions (base): an orphan Show instance for functions.
module Text.Show.Functions () where

instance Show (a -> b) where
  showsPrec _ _ = showString "<function>"
