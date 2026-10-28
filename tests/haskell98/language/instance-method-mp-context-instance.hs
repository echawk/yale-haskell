-- An instance's method using the class at a type whose instance has a
-- multi-parameter context (PPrint d (a, b) in PPrint d Env's pprint: JHC's
-- KindEnv): the method's variables are its signature's, not kept monomorphic.
{-# LANGUAGE MultiParamTypeClasses, FlexibleInstances, FlexibleContexts, UndecidableInstances #-}
module Main where
import qualified Data.Map as Map

class DocLike d where
  text :: String -> d
  (<+>) :: d -> d -> d
  vcat :: [d] -> d
instance DocLike String where
  text = id
  a <+> b = a ++ " " ++ b
  vcat = unlines

class DocLike d => PPrint d a where
  pprint :: a -> d
instance DocLike d => PPrint d Int where
  pprint = text . show

instance (PPrint d a, PPrint d b) => PPrint d (a, b) where
  pprint (a, b) = pprint a <+> pprint b

data Env = Env { envMap :: Map.Map Int (Int, Int) }

instance DocLike d => PPrint d Env where
  pprint Env { envMap = m } = vcat $
      [ pprint x <+> text "=>" <+> pprint y | (x, y) <- Map.toList m ] ++ [text "end"]

main = putStr (pprint (Env (Map.fromList [(1, (2, 3))])) :: String)
