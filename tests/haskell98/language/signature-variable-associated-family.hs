{-# LANGUAGE TypeFamilies #-}
module Main where
data Pattern' e = VarP Int | DotP e | Two (Pattern' e) (Pattern' e) deriving Show
class APatternLike p where
  type ADotT p
  mapAP :: (Pattern' (ADotT p) -> Pattern' (ADotT p)) -> p -> p
instance APatternLike (Pattern' a) where
  type ADotT (Pattern' a) = a
  mapAP f p = case f p of
    Two a b -> Two (mapAP f a) (mapAP f b)
    q -> q
subst :: (e -> e) -> [(Int, Pattern' e)] -> Pattern' e -> Pattern' e
subst subE s = mapAP $ \ p -> case p of
  VarP x -> maybe p id (lookup x s)
  DotP e -> DotP (subE e)
  _ -> p
main = print (subst (+1) [(1, DotP 10)] (Two (VarP 1) (DotP (5 :: Int))))
