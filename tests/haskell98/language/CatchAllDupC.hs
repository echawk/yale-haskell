{-# LANGUAGE FlexibleInstances #-}
-- Another catch-all instance of the class (as uniplate's
-- Data.Generics.Uniplate.Typeable).
module CatchAllDupC (cConst) where
import CatchAllDupA
instance U a where
  u _ = "c"
cConst :: Char -> String
cConst = u
