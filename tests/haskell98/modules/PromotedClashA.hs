-- A type PmLit, exported for another module's constructor of that name.
module PromotedClashA (PmLit(..)) where
data PmLit = PmSLit String deriving Show
