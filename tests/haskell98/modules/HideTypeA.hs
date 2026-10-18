module HideTypeA (Color(..), Shape(..)) where
data Color = Red | Green deriving Show
data Shape = Circle Double | Shape deriving Show
