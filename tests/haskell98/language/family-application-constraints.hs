{-# LANGUAGE TypeFamilies, FlexibleContexts, MultiParamTypeClasses, FunctionalDependencies #-}
-- Constraints at type family applications (megaparsec's): a local
-- binding's Ord (Token s) from an instance's context is generalized,
-- and a multi-parameter constraint's superclass's family superclasses
-- (MonadParsec e s m, Stream s, Ord (Token s)) are given.
class Ord (Tok s) => St s where
  type Tok s
  first :: s -> Tok s
instance Ord a => St [a] where
  type Tok [a] = a
  first = head
newtype H t = H [t] deriving Show
instance Ord t => Semigroup (H t) where H a <> H b = H (a ++ b)
instance Ord t => Monoid (H t) where mempty = H []
data R s a = R s (H (Tok s)) a
use :: St s => s -> a -> R s a
use s0 a = pk s0 a
  where pk s x = R s mempty x
main1 = case use "abc" 'z' of R s (H h) a -> print (s, h, a)

class (Ord (Tk s), Ord (Tks s)) => St2 s where
  type Tk s
  type Tks s
instance Ord a => St2 [a] where
  type Tk [a] = a
  type Tks [a] = [a]
class (Monad m, St2 s) => MP e s m | m -> e s where
  toks :: (Tks s -> Tks s -> Bool) -> Tks s -> m (Tks s)
  sat :: (Tk s -> Bool) -> m (Tk s)
chunk :: MP e s m => Tks s -> m (Tks s)
chunk = toks (==)
noneOf :: (Foldable f, MP e s m) => f (Tk s) -> m (Tk s)
noneOf cs = sat (\x -> notElem x cs)
newtype P a = P (Maybe a)
instance Functor P where fmap f (P m) = P (fmap f m)
instance Applicative P where { pure = P . Just; P f <*> P x = P (f <*> x) }
instance Monad P where P m >>= f = P (m >>= \x -> case f x of P y -> y)
instance MP () String P where
  toks eq s = P (if eq s "ab" then Just s else Nothing)
  sat p = P (if p 'a' then Just 'a' else Nothing)
main = do
  main1
  case chunk "ab" :: P String of P r -> print r
  case noneOf "xyz" :: P Char of P r -> print r
