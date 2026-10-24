{-# LANGUAGE GADTs, TypeFamilies, OverloadedStrings, FlexibleInstances, FlexibleContexts #-}
module Main where
import Data.List.NonEmpty (NonEmpty(..))
import Data.String (IsString(..))
import Data.Functor.Identity

newtype Doc = Doc String deriving Show
instance IsString Doc where fromString = Doc
newtype M a = M { runM :: a } deriving Show
instance Functor M where fmap f (M a) = M (f a)
instance Applicative M where { pure = M; M f <*> M a = M (f a) }
instance Monad M where M a >>= k = k a
instance IsString a => IsString (M a) where
  fromString = M . fromString

class Sized a where
  size :: a -> Int
instance Sized [a] where
  size = length
instance Sized (NonEmpty a) where
  size (_ :| xs) = 1 + length xs

pluralS :: (Functor m, Sized a) => a -> m Doc -> m Doc
pluralS xs = fmap (\(Doc s) -> Doc (if size xs == 1 then s else s ++ "s"))

report :: (Monad m, IsString (m Doc)) => [String] -> NonEmpty String -> [m Doc]
report missing xs = concat
    [ fields xs
    , if null missing then [] else fields missing ]
  where
    fields ys = [ pluralS ys "field" ]

main :: IO ()
main = print (map runM (report ["a", "b"] ("x" :| [])))
