{-# LANGUAGE TypeFamilies #-}
-- module Reexport of import qualified GHC.Exts as Reexport (toList): toList,
-- also in scope unqualified (report 5.2)
module QualifiedReexportA (module QualifiedReexportA, module Reexport) where
import GHC.Exts (IsList(..))
import qualified GHC.Exts as Reexport (toList)
data P = P Int Int
instance IsList P where
  type Item P = Int
  fromList [a, b] = P a b
  toList (P a b) = [a, b]
