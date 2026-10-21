{-# LANGUAGE MultiParamTypeClasses, FunctionalDependencies, FlexibleInstances, FlexibleContexts #-}
import qualified Data.Foldable as F
class LL full item | full -> item where
  lmap :: LL full' item' => (item -> item') -> full -> full'
  ltoList :: full -> [item]
  lfromList :: [item] -> full

instance LL [a] a where
  lmap f = lfromList . map f . ltoList
  ltoList = id
  lfromList = id

class SL s where
  unl :: LL full s => full -> s

newtype Box = Box [Char] deriving Show
newtype FM a = FM [a]
instance Foldable FM where foldr f z (FM xs) = foldr f z xs
toS :: Box -> String
toS (Box cs) = cs

instance SL (FM Char) where
  unl = FM . unl0 . lmap F.toList
    where unl0 :: [String] -> String
          unl0 = foldr (++) []

main :: IO ()
main = case unl [FM "ab", FM "c"] of FM s -> print s
