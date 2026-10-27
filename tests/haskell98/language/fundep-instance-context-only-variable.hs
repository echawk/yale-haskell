-- Top's (Helium's constraint solver) instance HasBasic (St s m) info, whose
-- context has a variable t only (Embedded ClassBasic (s ..) (t ..), HasBasic
-- (SelectFix t ..) info): a method using itself at its own type decides t
-- from the given Embedded before the other constraints are looked for.
{-# LANGUAGE MultiParamTypeClasses, FunctionalDependencies, FlexibleInstances, FlexibleContexts, UndecidableInstances, KindSignatures #-}
module Main where

newtype St s m a = St (s -> m (a, s))
data SelectFix (t :: (* -> *) -> *) (m :: * -> *) a = SelectFix (m a)

class Embedded label s t | label s -> t, t -> label where
  getE :: label -> s -> t

data ClassBasic = ClassBasic

instance Monad m => Monad (St s m) where
  return a = St (\s -> return (a, s))
  St f >>= g = St (\s -> f s >>= \(a, s') -> case g a of St h -> h s')

instance Monad m => Monad (SelectFix t m) where
  return a = SelectFix (return a)
  SelectFix f >>= g = SelectFix (f >>= \x -> case g x of SelectFix h -> h)

deBasic :: (Embedded ClassBasic (s (St s m)) (t (St s m)), Monad m) => SelectFix t (St s m) a -> St s m a
deBasic (SelectFix m) = m

class Monad m => HasBasic m info | m -> info where
  discard :: m ()
  getInfo :: m [info]
  getChecks :: m [m Bool]

instance ( Monad m
         , Embedded ClassBasic (s (St s m)) (t (St s m))
         , HasBasic (SelectFix t (St s m)) info
         ) => HasBasic (St s m) info where
  discard = deBasic discard
  getInfo = deBasic getInfo
  getChecks = deBasic (SelectFix getChecks)

main = print 1

instance Embedded c s2 t => Embedded c (s1, s2) t where
  getE c (_, s2) = getE c s2
