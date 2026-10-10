-- Data.Foldable (base): the class is PreludeModern's, where (under
-- --modern-prelude) it also replaces the Prelude's list functions.
module Data.Foldable (
    Foldable(foldMap, foldr, foldl, foldr', foldl', foldr1, foldl1, toList,
             null, length, elem, maximum, minimum, sum, product),
    foldrM, foldlM, traverse_, for_, sequenceA_, asum, mapM_, forM_,
    sequence_, msum, concat, concatMap, and, or, any, all, maximumBy,
    minimumBy, notElem, find
  ) where

import Prelude hiding (foldr, foldl, foldr1, foldl1, null, length, elem, notElem, maximum, minimum, sum, product, concat, concatMap, and, or, any, all, mapM_, sequence_, mapM, sequence)
import PreludeModern
import Monad (MonadPlus(mzero, mplus))

foldrM :: (Foldable t, Monad m) => (a -> b -> m b) -> b -> t a -> m b
foldrM f z0 xs = foldl (\k x z -> f x z >>= k) return xs z0

foldlM :: (Foldable t, Monad m) => (b -> a -> m b) -> b -> t a -> m b
foldlM f z0 xs = foldr (\x k z -> f z x >>= k) return xs z0

traverse_ :: (Foldable t, Applicative f) => (a -> f b) -> t a -> f ()
traverse_ f t = foldr (\x k -> f x *> k) (pure ()) t

for_ :: (Foldable t, Applicative f) => t a -> (a -> f b) -> f ()
for_ t f = traverse_ f t

sequenceA_ :: (Foldable t, Applicative f) => t (f a) -> f ()
sequenceA_ t = foldr (\m k -> m *> k) (pure ()) t

asum :: (Foldable t, Alternative f) => t (f a) -> f a
asum t = foldr (<|>) empty t

forM_ :: (Foldable t, Monad m) => t a -> (a -> m b) -> m ()
forM_ t f = mapM_ f t

msum :: (Foldable t, MonadPlus m) => t (m a) -> m a
msum t = foldr mplus mzero t
