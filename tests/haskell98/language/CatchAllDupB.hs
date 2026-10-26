{-# LANGUAGE FlexibleInstances, UndecidableInstances #-}
-- A catch-all instance of CatchAllDupA's class (as uniplate's
-- Data.Generics.Uniplate.Data).
module CatchAllDupB (bShow) where
import CatchAllDupA
instance Show a => U a where
  u = show
bShow :: Int -> String
bShow = u
