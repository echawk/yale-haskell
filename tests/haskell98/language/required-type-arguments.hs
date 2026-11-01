{-# LANGUAGE ExplicitNamespaces, RequiredTypeArguments, ScopedTypeVariables #-}
size :: forall a -> (Bounded a, Enum a) => Int
size a = fromEnum (maxBound :: a) - fromEnum (minBound :: a) + 1

describe :: forall a b -> (Show a, Show b) => a -> b -> String
describe a b x y = show x ++ "/" ++ show y

main :: IO ()
main = do
  print (size Bool, size (type Ordering))
  putStrLn (describe Int Char 3 'c')
