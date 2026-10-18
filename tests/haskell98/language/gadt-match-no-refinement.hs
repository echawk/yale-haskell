{-# LANGUAGE MultiParamTypeClasses, FlexibleInstances, KindSignatures, GADTs, ScopedTypeVariables #-}
-- A GADT match whose right-hand side needs no type refinement gets its
-- type from the signature (transformers-compat's GRead1Con instances)
import Data.Functor.Classes
import Data.Coerce
import Text.ParserCombinators.ReadPrec
import Text.Read (readPrec_to_S, readS_to_Prec, readPrec, readListPrec)

newtype Rec1 f p = Rec1 (f p)
data NonV4
data V4
data Read1Args v a where
  V4Read1Args :: Read a => Read1Args V4 a
  NonV4Read1Args :: ReadPrec a -> ReadPrec [a] -> Read1Args NonV4 a

class GRead1Con v f where
  gread :: Int -> Read1Args v a -> ReadPrec (f a)

coerceRec1 :: ReadPrec (f a) -> ReadPrec (Rec1 f a)
coerceRec1 = coerce

instance Read1 f => GRead1Con NonV4 (Rec1 f) where
  gread _ (NonV4Read1Args rp rl) = coerceRec1 $ readS_to_Prec $
      liftReadsPrec (readPrec_to_S rp) (readPrec_to_S rl 0)

main :: IO ()
main = case gread 0 (NonV4Read1Args (readPrec :: ReadPrec Int) readListPrec :: Read1Args NonV4 Int) :: ReadPrec (Rec1 Maybe Int) of
  r -> print (map (\(Rec1 m, s) -> (m, s)) (readPrec_to_S r 0 "Just 5"))
