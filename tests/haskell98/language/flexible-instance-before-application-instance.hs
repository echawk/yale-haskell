-- A flexible instance (DocLike String) chosen once its type is decided, not
-- the application instance (DocLike (m a)) while the element is undecided
-- (JHC's FrontEnd.Class: pprint .. <+> pprint .. ++ " ").
{-# LANGUAGE FlexibleInstances, UndecidableInstances, OverlappingInstances #-}
module Main where
import Prelude hiding ((<>))
class TextLike a where text :: String -> a
class TextLike a => DocLike a where (<+>) :: a -> a -> a
instance TextLike String where text = id
instance DocLike String where a <+> b = a ++ " " ++ b
instance (TextLike a, Monad m) => TextLike (m a) where text = return . text
instance (DocLike a, Monad m) => DocLike (m a) where a <+> b = do { x <- a; y <- b; return (x <+> y) }

g :: Monad m => Int -> m String
g n = if n > 0 then return "ok" else error $ "bad: " ++ (text "x" <+> text "y") ++ " " ++ show n

main = g 1 >>= putStrLn
