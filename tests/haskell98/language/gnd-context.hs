-- GeneralizedNewtypeDeriving of a class whose underlying instance has a
-- context (Describe (Maybe a) needs Describe a).
{-# LANGUAGE GeneralizedNewtypeDeriving #-}
class Describe a where describe :: a -> String
instance Describe a => Describe (Maybe a) where
  describe Nothing = "none"
  describe (Just x) = "just " ++ describe x
instance Describe Int where describe n = "int " ++ show n
newtype Wrap a = Wrap (Maybe a) deriving Describe
main = putStrLn (describe (Wrap (Just (4 :: Int))))
