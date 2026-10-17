-- Equality constraints in instance contexts (prettyprinter's
-- instance ann ~ Void => Pretty (Doc ann)).
{-# LANGUAGE GADTs, FlexibleInstances #-}
import Data.Void
import Data.String
class Pretty a where pretty :: a -> String
newtype Doc ann = Doc String
instance ann ~ Void => Pretty (Doc ann) where
  pretty (Doc s) = "doc:" ++ s
newtype Name = Name String deriving Show
instance a ~ Char => IsString (Wrap [a]) where fromString = Wrap
newtype Wrap a = Wrap a deriving Show
main = do
  putStrLn (pretty (Doc "x" :: Doc Void))
  print (fromString "hi" :: Wrap String)
