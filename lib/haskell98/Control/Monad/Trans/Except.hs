-- Control.Monad.Trans.Except (transformers)
module Control.Monad.Trans.Except (
    ExceptT(ExceptT), Except, except, runExcept, runExceptT, mapExceptT,
    withExceptT, withExcept, mapExcept, throwE, catchE, handleE, tryE,
    finallyE,
    liftCallCC, liftListen, liftPass
  ) where

import Data.Functor.Contravariant (Contravariant(contramap))
import Control.Monad.Signatures
import PreludeModern
import Monad (MonadPlus(mzero, mplus))
import Control.Monad.Trans.Class
import Control.Monad.IO.Class
import Data.Functor.Identity

newtype ExceptT e m a = ExceptT (m (Either e a))

type Except e = ExceptT e Identity

runExceptT :: ExceptT e m a -> m (Either e a)
runExceptT (ExceptT m) = m

except :: Monad m => Either e a -> ExceptT e m a
except m = ExceptT (return m)

runExcept :: Except e a -> Either e a
runExcept m = runIdentity (runExceptT m)

mapExceptT :: (m (Either e a) -> n (Either e' b)) -> ExceptT e m a -> ExceptT e' n b
mapExceptT f m = ExceptT (f (runExceptT m))

withExceptT :: Monad m => (e -> e') -> ExceptT e m a -> ExceptT e' m a
withExceptT f m = ExceptT (runExceptT m >>= \v -> return (either (Left . f) Right v))

instance Functor m => Functor (ExceptT e m) where
  fmap f m = ExceptT (fmap (\v -> fmap f v) (runExceptT m))

instance Monad m => Applicative (ExceptT e m) where
  pure a = ExceptT (return (Right a))
  mf <*> mx = ExceptT (runExceptT mf >>= \f -> case f of
                         Left e -> return (Left e)
                         Right g -> runExceptT mx >>= \x -> return (fmap g x))

instance Monad m => Monad (ExceptT e m) where
  return a = ExceptT (return (Right a))
  m >>= k = ExceptT (runExceptT m >>= \v -> case v of
                       Left e -> return (Left e)
                       Right a -> runExceptT (k a))

instance MonadFail m => MonadFail (ExceptT e m) where
  fail msg = ExceptT (fail msg)

-- the errors of failed alternatives are combined, as in transformers
instance (Monad m, Monoid e) => Alternative (ExceptT e m) where
  empty = ExceptT (return (Left mempty))
  m <|> n = ExceptT (runExceptT m >>= \v -> case v of
                       Left e -> runExceptT n >>= \w -> return (case w of
                                   Left e' -> Left (e `mappend` e')
                                   Right a -> Right a)
                       Right a -> return (Right a))

instance (Monad m, Monoid e) => MonadPlus (ExceptT e m) where
  mzero = empty
  mplus = (<|>)

instance MonadTrans (ExceptT e) where
  lift m = ExceptT (m >>= \a -> return (Right a))

instance MonadIO m => MonadIO (ExceptT e m) where
  liftIO io = lift (liftIO io)

throwE :: Monad m => e -> ExceptT e m a
throwE e = ExceptT (return (Left e))

catchE :: Monad m => ExceptT e m a -> (e -> ExceptT e' m a) -> ExceptT e' m a
catchE m h = ExceptT (runExceptT m >>= \v -> case v of
                        Left e -> runExceptT (h e)
                        Right a -> return (Right a))

withExcept :: (e -> e') -> Except e a -> Except e' a
withExcept = withExceptT

mapExcept :: (Either e a -> Either e' b) -> Except e a -> Except e' b
mapExcept f = mapExceptT (Identity . f . runIdentity)

handleE :: Monad m => (e -> ExceptT e' m a) -> ExceptT e m a -> ExceptT e' m a
handleE = flip catchE

tryE :: Monad m => ExceptT e m a -> ExceptT e m (Either e a)
tryE m = catchE (fmap Right m) (return . Left)

finallyE :: Monad m => ExceptT e m a -> ExceptT e m () -> ExceptT e m a
finallyE m closer = ExceptT (runExceptT m >>= \res -> runExceptT closer >>= \c ->
                      return (case c of
                                Left e -> Left e
                                Right () -> res))

-- Lifting other operations through ExceptT (transformers)
liftCallCC :: CallCC m (Either e a) (Either e b) -> CallCC (ExceptT e m) a b
liftCallCC callCC f = ExceptT $ callCC $ \c ->
  runExceptT (f (\a -> ExceptT $ c (Right a)))

liftListen :: Monad m => Listen w m (Either e a) -> Listen w (ExceptT e m) a
liftListen listen = mapExceptT $ \m -> do
  (a, w) <- listen m
  return $! fmap (\r -> (r, w)) a

liftPass :: Monad m => Pass w m (Either e a) -> Pass w (ExceptT e m) a
liftPass pass = mapExceptT $ \m -> pass $ do
  a <- m
  return $! case a of
    Left l -> (Left l, id)
    Right (r, f) -> (Right r, f)

-- transformers' (the transformed monad contravariant)
instance Contravariant m => Contravariant (ExceptT e m) where
  contramap f = ExceptT . contramap (fmap f) . runExceptT

-- transformers' Foldable and Traversable
instance Foldable f => Foldable (ExceptT e f) where
  foldMap f (ExceptT a) = foldMap (either (const mempty) f) a
instance Traversable f => Traversable (ExceptT e f) where
  traverse f (ExceptT a) =
    fmap ExceptT (traverse (either (pure . Left) (fmap Right . f)) a)
