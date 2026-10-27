-- JHC's DocLike: TextLike ShowS (String -> String) and TextLike (m a): at
-- Int -> D, where ShowS's head does not match, the (m a) instance.
{-# LANGUAGE FlexibleInstances, UndecidableInstances, OverlappingInstances #-}
module Main where
import Prelude hiding ((<>))

class TextLike a where
  text :: String -> a

instance TextLike String where text = id
instance TextLike ShowS where text = showString
instance (TextLike a, Monad m) => TextLike (m a) where text = return . text

newtype D = D String deriving Show
instance TextLike D where text = D

f :: Int -> D
f = text "hi"

main = print (f 3, text "x" "y" :: String)
