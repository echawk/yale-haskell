-- A data instance of a family named qualified (bitvec's data instance
-- U.Vector Bit), its constructor exported with the family.
{-# LANGUAGE TypeFamilies #-}
module DataFamQualB (Bit(..), A.Vec(BitVec)) where
import qualified DataFamQualA as A
newtype Bit = Bit Bool
data instance A.Vec Bit = BitVec !Int !Int
