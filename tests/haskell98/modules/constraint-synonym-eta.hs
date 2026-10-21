{-# LANGUAGE ConstraintKinds, FlexibleContexts #-}
import ConstraintSynEta
newtype W a = W a
sh :: GS0 a => W a -> String
sh (W x) = gs x
main :: IO ()
main = putStrLn (sh (W (5 :: Int))) >> print (W (6 :: Int))

instance GS0 a => Show (W a) where show = sh
