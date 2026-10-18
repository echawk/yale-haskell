-- Control.Arrow (base)
module Control.Arrow (
    Arrow(arr, first, second, (***), (&&&)), Kleisli(Kleisli, runKleisli),
    returnA, (^>>), (>>^), (<<^), (^<<), (>>>), (<<<),
    ArrowZero(zeroArrow), ArrowPlus((<+>)),
    ArrowChoice(left, right, (+++), (|||)), ArrowApply(app),
    ArrowLoop(loop), Category,
    ArrowMonad(ArrowMonad), leftApp
  ) where

import Prelude hiding (id, (.))
import qualified Prelude as P
import Control.Category
import Monad (MonadPlus(mzero, mplus))
import PreludeModern (Applicative(pure, (<*>)), Alternative(empty, (<|>)))

infixr 5 <+>
infixr 3 ***
infixr 3 &&&
infixr 2 +++
infixr 2 |||
infixr 1 ^>>, >>^
infixr 1 ^<<, <<^

class Category a => Arrow a where
  arr :: (b -> c) -> a b c
  first :: a b c -> a (b, d) (c, d)
  first = (*** id)
  second :: a b c -> a (d, b) (d, c)
  second = (id ***)
  (***) :: a b c -> a b' c' -> a (b, b') (c, c')
  f *** g = first f >>> arr swap >>> first g >>> arr swap
    where swap ~(x, y) = (y, x)
  (&&&) :: a b c -> a b c' -> a b (c, c')
  f &&& g = arr (\b -> (b, b)) >>> f *** g

instance Arrow (->) where
  arr f = f
  first f (x, y) = (f x, y)
  second f (x, y) = (x, f y)
  (f *** g) ~(x, y) = (f x, g y)
  (f &&& g) x = (f x, g x)

newtype Kleisli m a b = Kleisli { runKleisli :: a -> m b }

instance Monad m => Category (Kleisli m) where
  id = Kleisli return
  Kleisli f . Kleisli g = Kleisli (\b -> g b >>= f)

instance Monad m => Arrow (Kleisli m) where
  arr f = Kleisli (return P.. f)
  first (Kleisli f) = Kleisli (\ ~(b, d) -> f b >>= \c -> return (c, d))
  second (Kleisli f) = Kleisli (\ ~(d, b) -> f b >>= \c -> return (d, c))

instance Monad m => Functor (Kleisli m a) where
  fmap f (Kleisli g) = Kleisli (\x -> g x >>= (return P.. f))

instance Monad m => Applicative (Kleisli m a) where
  pure x = Kleisli (\_ -> return x)
  Kleisli f <*> Kleisli g = Kleisli (\x -> f x >>= \h -> g x >>= (return P.. h))

instance MonadPlus m => Alternative (Kleisli m a) where
  empty = Kleisli (\_ -> mzero)
  Kleisli f <|> Kleisli g = Kleisli (\x -> f x `mplus` g x)

instance Monad m => Monad (Kleisli m a) where
  Kleisli f >>= k = Kleisli (\x -> f x >>= \a -> runKleisli (k a) x)

instance MonadPlus m => MonadPlus (Kleisli m a)

returnA :: Arrow a => a b b
returnA = id

(^>>) :: Arrow a => (b -> c) -> a c d -> a b d
f ^>> a = arr f >>> a

(>>^) :: Arrow a => a b c -> (c -> d) -> a b d
a >>^ f = a >>> arr f

(<<^) :: Arrow a => a c d -> (b -> c) -> a b d
a <<^ f = a <<< arr f

(^<<) :: Arrow a => (c -> d) -> a b c -> a b d
f ^<< a = arr f <<< a

class Arrow a => ArrowZero a where
  zeroArrow :: a b c

instance MonadPlus m => ArrowZero (Kleisli m) where
  zeroArrow = Kleisli (\_ -> mzero)

class ArrowZero a => ArrowPlus a where
  (<+>) :: a b c -> a b c -> a b c

instance MonadPlus m => ArrowPlus (Kleisli m) where
  Kleisli f <+> Kleisli g = Kleisli (\x -> f x `mplus` g x)

class Arrow a => ArrowChoice a where
  left :: a b c -> a (Either b d) (Either c d)
  left = (+++ id)
  right :: a b c -> a (Either d b) (Either d c)
  right = (id +++)
  (+++) :: a b c -> a b' c' -> a (Either b b') (Either c c')
  f +++ g = left f >>> arr mirror >>> left g >>> arr mirror
    where mirror :: Either x y -> Either y x
          mirror (Left x) = Right x
          mirror (Right y) = Left y
  (|||) :: a b d -> a c d -> a (Either b c) d
  f ||| g = f +++ g >>> arr untag
    where untag (Left x) = x
          untag (Right y) = y

instance ArrowChoice (->) where
  left f = f +++ P.id
  right f = P.id +++ f
  f +++ g = either (Left P.. f) (Right P.. g)
  (|||) = either

instance Monad m => ArrowChoice (Kleisli m) where
  left f = f +++ arr P.id
  right f = arr P.id +++ f
  f +++ g = (f >>> arr Left) ||| (g >>> arr Right)
  Kleisli f ||| Kleisli g = Kleisli (either f g)

class Arrow a => ArrowApply a where
  app :: a (a b c, b) c

instance ArrowApply (->) where
  app (f, x) = f x

instance Monad m => ArrowApply (Kleisli m) where
  app = Kleisli (\(Kleisli f, x) -> f x)

class Arrow a => ArrowLoop a where
  loop :: a (b, d) (c, d) -> a b c

instance ArrowLoop (->) where
  loop f b = let (c, d) = f (b, d) in c

-- The monad of an arrow with application
newtype ArrowMonad a b = ArrowMonad (a () b)

instance Arrow a => Functor (ArrowMonad a) where
  fmap f (ArrowMonad m) = ArrowMonad (m >>^ f)

instance Arrow a => Applicative (ArrowMonad a) where
  pure x = ArrowMonad (arr (const x))
  ArrowMonad f <*> ArrowMonad x = ArrowMonad (f &&& x >>> arr (uncurry P.id))

instance ArrowApply a => Monad (ArrowMonad a) where
  ArrowMonad m >>= f =
    ArrowMonad (m >>> arr (\x -> let ArrowMonad h = f x in (h, ())) >>> app)

instance ArrowPlus a => Alternative (ArrowMonad a) where
  empty = ArrowMonad zeroArrow
  ArrowMonad x <|> ArrowMonad y = ArrowMonad (x <+> y)

instance (ArrowApply a, ArrowPlus a) => MonadPlus (ArrowMonad a)

-- left for any arrow with application
leftApp :: ArrowApply a => a b c -> a (Either b d) (Either c d)
leftApp f = arr ((\b -> (arr (\() -> b) >>> f >>> arr Left, ())) |||
                 (\d -> (arr (\() -> d) >>> arr Right, ()))) >>> app
