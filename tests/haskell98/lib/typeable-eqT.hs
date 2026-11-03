{-# LANGUAGE TypeOperators, GADTs, ScopedTypeVariables #-}
-- Data.Typeable's eqT, and its (:~:) re-export (lens' Data.Data.Lens)
import qualified Data.Typeable as X

conv :: forall a b. (X.Typeable a, X.Typeable b) => a -> Maybe b
conv x = case X.eqT :: Maybe (a X.:~: b) of
  Just X.Refl -> Just x
  Nothing -> Nothing

main :: IO ()
main = do
  print (conv (3 :: Int) :: Maybe Int)
  print (conv (3 :: Int) :: Maybe Bool)
  print (fmap (const ()) (X.eqT :: Maybe (Char X.:~: Char)))
