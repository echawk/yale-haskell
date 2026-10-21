{-# LANGUAGE RankNTypes #-}
newtype Id m a = Id { unId :: m a }
newtype W m a = W { unW :: Id m a }
type RunI = forall n b. Monad n => Id n b -> n b
type RunW = forall n b. Monad n => W n b -> n b

liftI :: Monad m => (RunI -> m a) -> m a
liftI f = f unId

dflt :: Monad m => (forall o b. W o b -> Id o b) -> (RunW -> m a) -> m a
dflt unT f = liftI $ \run -> f (run . unT)

dflt2 :: Monad m => (forall o b. W o b -> Id o b) -> (RunW -> m a) -> m a
dflt2 unT = \f -> liftI $ \run -> f (run . unT)

main :: IO ()
main = do
  dflt unW (\run -> return (run (W (Id (Just 3))))) >>= print
  dflt2 unW (\run -> return (run (W (Id [4])))) >>= print
