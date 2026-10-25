-- A method with its own constraint, in an instance whose context is a
-- multi-parameter class with a one-parameter superclass (regex-base's
-- RegexContext a b (AllTextSubmatches [] b), from RegexLike a b, whose
-- superclass is Extract b): the superclass is the instance's, so the
-- dictionary's entry takes only the method's own (MonadFail m).  It took
-- both, and matchM r s :: Maybe t was a function.
{-# LANGUAGE MultiParamTypeClasses, FlexibleInstances #-}
class Ex s where
  len :: s -> Int
class Ex s => RL r s where
  once :: r -> s -> Maybe Int
class RL r s => RC r s t where
  mat :: r -> s -> t
  matM :: MonadFail m => r -> s -> m t
newtype Sub = Sub Char
instance Ex [a] where len = length
instance RL Sub String where
  once (Sub c) s = lookup c (zip s [0 ..])
newtype All b = All [b]
instance RL a b => RC a b (All b) where
  mat r s = maybe (All []) id (matM r s)
  matM r s = case once r s of
    Nothing -> fail "no match"
    Just i -> return (All (replicate (len s - i) s))
main :: IO ()
main = do
  case matM (Sub 'c') "abcd" :: Maybe (All String) of
    Just (All xs) -> print xs
    Nothing -> putStrLn "none"
  case matM (Sub 'z') "abcd" :: Maybe (All String) of
    Just (All xs) -> print xs
    Nothing -> putStrLn "none"
  let All ys = mat (Sub 'a') "ab" :: All String in print ys
