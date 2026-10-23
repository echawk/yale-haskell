{-# LANGUAGE PatternSynonyms, TypeFamilies #-}
module PatConExportA (Mode, pattern ScopeCheck, pattern TypeCheck, ToC(..)) where
data Mode = ScopeCheck | TypeCheck deriving (Eq, Show)

class ToC a where
  type ConOf a
  toC :: a -> ConOf a

instance ToC Bool where
  type ConOf Bool = String
  toC = show
