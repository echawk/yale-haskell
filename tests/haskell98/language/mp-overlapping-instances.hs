{-# LANGUAGE MultiParamTypeClasses, FlexibleInstances, FunctionalDependencies #-}
module Main (main) where
class Describe a r | a -> r where describe :: a -> r
instance {-# OVERLAPPING #-} Describe [Char] String where describe s = "string " ++ s
instance Describe [a] String where describe xs = "list of " ++ show (length xs)
instance {-# OVERLAPPING #-} Describe (Maybe Int) String where describe _ = "maybe int"
instance Describe (Maybe a) String where describe _ = "maybe"
main :: IO ()
main = mapM_ putStrLn [describe "hi", describe [True, False], describe (Just (3 :: Int)), describe (Just 'c')]
