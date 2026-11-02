{-# LANGUAGE KindSignatures, FlexibleInstances, MultiParamTypeClasses #-}
-- infix class and instance heads ((f `Compose` g) x, sop-core's)
class (f `Pair` g) a where
  pairName :: f a -> g a -> String
instance (Maybe `Pair` []) Int where
  pairName _ _ = "Maybe and [] at Int"
instance (Either String `Pair` Maybe) Bool where
  pairName _ _ = "Either String and Maybe at Bool"

main :: IO ()
main = do
  putStrLn (pairName (Just (1 :: Int)) [2])
  putStrLn (pairName (Right True :: Either String Bool) Nothing)
