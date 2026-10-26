-- A context at an application of the instance's variable (free's
-- Read (w (CofreeF f a (CofreeT f w a)))), wanted while the arguments
-- are still being unified (the last argument first).
{-# LANGUAGE FlexibleContexts, UndecidableInstances #-}
data CofreeF f a b = a :< f b deriving (Show, Read)
newtype CofreeT f w a = CofreeT { runCofreeT :: w (CofreeF f a (CofreeT f w a)) }

instance Show (w (CofreeF f a (CofreeT f w a))) => Show (CofreeT f w a) where
  showsPrec d (CofreeT w) = showParen (d > 10) $
    showString "CofreeT " . showsPrec 11 w

instance Read (w (CofreeF f a (CofreeT f w a))) => Read (CofreeT f w a) where
  readsPrec d = readParen (d > 10) $ \r ->
     [(CofreeT w, t) | ("CofreeT", s) <- lex r, (w, t) <- readsPrec 11 s]


main = putStrLn "ok"
