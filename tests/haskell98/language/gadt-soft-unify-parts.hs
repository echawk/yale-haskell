{-# LANGUAGE GADTs #-}
data U = U deriving Show
data T a where
  ULeaf :: T U
  IntLeaf :: Int -> T Int

run :: T a -> Maybe a
run ULeaf = pure U
run (IntLeaf n) = Just n

main :: IO ()
main = print (run ULeaf, run (IntLeaf 4))
