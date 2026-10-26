-- An instance whose context is a multi-parameter constraint with a
-- one-parameter superclass (class Num i => C s i): at a type (C s Int)
-- and at a variable only the context has (C s i, i determined by s),
-- as utf8-string's IsString (UTF8 string); the dictionaries match.
{-# LANGUAGE MultiParamTypeClasses, FunctionalDependencies, FlexibleInstances, FlexibleContexts #-}
class Num i => C s i where
  pk :: i -> String -> s
instance C [Char] Int where
  pk _ = id
newtype W s = W s
class D a where
  d :: String -> a
instance C s Int => D (W s) where
  d x = W (pk (0 :: Int) x)
unW (W s) = s
main1 = putStrLn (unW (d "hello" :: W String))

class Num i => C2 s i | s -> i where
  pk2 :: String -> s
  sz :: s -> i
instance C2 [Char] Int where
  pk2 = id
  sz = fromIntegral . length
class D2 a where
  d2 :: String -> a
  len2 :: a -> Integer
instance C2 s i => D2 (W s) where
  d2 x = W (pk2 x)
  len2 (W s) = toInteger (sz s + 1)

main = do
  main1
  putStrLn (unW (d2 "hi" :: W String))
  print (len2 (W "abc"))
