-- StandaloneDeriving of types declared in another module, including a
-- newtype-derived class with a context.
{-# LANGUAGE StandaloneDeriving, GeneralizedNewtypeDeriving #-}
import StandaloneTypes
class Describe a where describe :: a -> String
instance Describe a => Describe (Maybe a) where
  describe Nothing = "none"
  describe (Just x) = "just " ++ describe x
instance Describe Int where describe n = "int " ++ show n
deriving instance Eq Color
deriving instance Ord Color
deriving instance Show a => Show (Wrap a)
deriving instance Eq a => Eq (Pair a)
deriving instance Show a => Show (Pair a)
deriving instance Describe a => Describe (Wrap a)
main = do
  print (Red == Red, Red < Green, Wrap (Just 3), Pair 1 2 == Pair 1 (2 :: Int), Pair 'a' 'b')
  putStrLn (describe (Wrap (Just (4 :: Int))))
