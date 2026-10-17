-- Helper for explicit-prelude-list.hs (utility-ht's Data.Monoid.HT).
module MonoidHT ((<>), twice) where
import Prelude (Monoid, mappend, (.))
(<>) :: Monoid m => m -> m -> m
(<>) = mappend
twice :: Monoid m => m -> m
twice x = x <> x
