-- DocLike ShowS (String -> String) and DocLike (m a): at an undecided t -> t
-- neither is chosen early; at G String -> G String the (m a) instance, through
-- the reader monad (JHC's text "sizeof" <> parens).
{-# LANGUAGE FlexibleInstances, UndecidableInstances, OverlappingInstances #-}
module Main where
import Prelude hiding ((<>))
class TextLike a where text :: String -> a
class TextLike a => DocLike a where
  (<>) :: a -> a -> a
  parens :: a -> a
  parens x = text "(" <> x <> text ")"
instance TextLike String where text = id
instance DocLike String where (<>) = (++)
instance TextLike ShowS where text = showString
instance DocLike ShowS where (<>) = (.)
instance (TextLike a, Monad m) => TextLike (m a) where text = return . text
instance (DocLike a, Monad m) => DocLike (m a) where a <> b = do { x <- a; y <- b; return (x <> y) }

newtype G a = G (Maybe a)
instance Functor G where fmap f (G m) = G (fmap f m)
instance Applicative G where pure = G . Just; G f <*> G a = G (f <*> a)
instance Monad G where G m >>= k = G (m >>= \a -> case k a of G r -> r)

sizeof :: G String -> G String
sizeof t = (text "sizeof" <> parens) t

main = case sizeof (return "int") of G r -> print r
