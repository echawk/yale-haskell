{-# LANGUAGE DeriveGeneric #-}
import Control.Monad.Zip
import Data.Monoid
import GHC.Generics (Generic, Generic1)
newtype Tag s b = Tag b deriving (Show, Generic, Generic1)
main = do
  print (mzip [1, 2, 3 :: Int] "ab", munzip (Just (1 :: Int, 'x')))
  print (getAlt (Alt Nothing <> Alt (Just 1) <> Alt (Just (2 :: Int))), getAlt (mconcat [Alt [1], Alt [2 :: Int]]))
  print (getAp (Ap (Just [1]) <> Ap (Just [2 :: Int])), Tag 'c' :: Tag () Char)
