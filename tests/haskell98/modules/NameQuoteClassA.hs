module NameQuoteClassA (Inv(..)) where
class Inv f where inv :: f a -> f a
