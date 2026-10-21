{-# LANGUAGE ConstraintKinds, MultiParamTypeClasses, FlexibleInstances, FlexibleContexts #-}
module ConstraintSynEta (GS(..), GS0, gs) where
data P a = P
class GS p f where gshow :: p () -> f -> String
instance GS P Int where gshow _ n = "int " ++ show n
type GS0 = GS P
gs :: GS0 f => f -> String
gs = gshow (P :: P ())
