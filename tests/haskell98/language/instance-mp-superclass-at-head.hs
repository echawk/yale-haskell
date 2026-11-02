{-# LANGUAGE MultiParamTypeClasses, FunctionalDependencies, FlexibleInstances, FlexibleContexts, UndecidableInstances #-}
class Monad m => Stream s m t | s -> t where
  uncons :: s -> m (Maybe (t, s))
instance Monad m => Stream [a] m a where
  uncons [] = return Nothing
  uncons (x : xs) = return (Just (x, xs))

newtype P s m a = P (s -> m (Maybe (a, s)))
run :: P s m a -> s -> m (Maybe (a, s))
run (P f) = f
instance Functor m => Functor (P s m) where
  fmap f (P g) = P (\s -> fmap (fmap (\(a, r) -> (f a, r))) (g s))
instance Monad m => Applicative (P s m) where
  pure a = P (\s -> return (Just (a, s)))
  P f <*> P g = P (\s -> f s >>= \x -> case x of
                           Nothing -> return Nothing
                           Just (h, r) -> fmap (fmap (\(a, r') -> (h a, r'))) (g r))

-- the superclass Applicative (P s m) needs Monad m: Stream s m Char's superclass
class Applicative p => CharParsing p where
  anyC :: p Char
instance Stream s m Char => CharParsing (P s m) where
  anyC = P uncons

twoC :: CharParsing p => p (Char, Char)
twoC = (,) <$> anyC <*> anyC

main :: IO ()
main = do
  r <- run (twoC :: P String IO (Char, Char)) "abc"
  print (fmap fst r)
