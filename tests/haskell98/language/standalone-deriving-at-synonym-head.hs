-- Standalone newtype deriving at a synonym for one application
-- (pandoc-types' deriving instance Semigroup Blocks, Blocks = Many Block)
-- beside an instance of the class at another (Semigroup Inlines).
{-# LANGUAGE FlexibleInstances, GeneralizedNewtypeDeriving, StandaloneDeriving #-}
newtype Many a = Many [a] deriving (Show, Eq)
data Inline = Str String | Space deriving (Show, Eq)
data Block = Para [Inline] deriving (Show, Eq)
type Inlines = Many Inline
type Blocks = Many Block
deriving instance Semigroup Blocks
deriving instance Monoid Blocks
instance Semigroup Inlines where
  Many xs <> Many ys = Many (xs ++ [Space] ++ ys)
instance Monoid Inlines where
  mempty = Many []
main = do
  print (Many [Str "a"] <> Many [Str "b"] :: Inlines)
  print (Many [Para []] <> mempty <> Many [Para [Space]] :: Blocks)
