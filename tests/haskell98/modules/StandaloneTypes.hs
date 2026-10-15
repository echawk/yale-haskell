-- Types derived in another module (standalone-deriving-elsewhere.hs).
module StandaloneTypes (Color(..), Wrap(..), Pair(..)) where
data Color = Red | Green deriving Show
newtype Wrap a = Wrap (Maybe a)
data Pair a = Pair a a
