{-# LANGUAGE MultiParamTypeClasses, FlexibleInstances, FlexibleContexts, TypeFamilies #-}
-- MonoLocalBinds (TypeFamilies): recurse, mentioning the method's pre, is
-- not generalized; the list instance's dictionary passes its context
-- before the method's own Monad m (Agda's PatternLike)
module Main (main) where

data Pat a = Var a | Con [Pat a] deriving Show

class PatternLike a b where
  traverseP :: Monad m => (Pat a -> m (Pat a)) -> b -> m b

instance PatternLike a (Pat a) where
  traverseP pre p = pre p >>= recurse
    where
    recurse p = case p of
      Con ps -> fmap Con (traverseP pre ps)
      _ -> return p

instance PatternLike a b => PatternLike a [b] where
  traverseP pre = mapM (traverseP pre)

main :: IO ()
main = print (traverseP (\p -> Just (p :: Pat Char)) (Con [Var (head "x"), Con []]))
