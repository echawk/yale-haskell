{-# LANGUAGE MultiParamTypeClasses, FunctionalDependencies, FlexibleInstances, FlexibleContexts, UndecidableInstances #-}
-- an instance context variable determined by a functional dependency
class Stream s t | s -> t where
  uncons :: s -> Maybe (t, s)
instance Stream [a] a where
  uncons [] = Nothing
  uncons (x : xs) = Just (x, xs)

newtype P s a = P (s -> Maybe (a, s))

class Parsing p where
  describe :: p -> String

instance (Stream s t, Show t) => Parsing (P s u) where
  describe _ = "a parser"

firstShown :: (Stream s t, Show t) => s -> String
firstShown s = maybe "empty" (show . fst) (uncons s)

main :: IO ()
main = do
  putStrLn (describe (P (\s -> Just ((), s)) :: P String ()))
  putStrLn (firstShown "xyz")
