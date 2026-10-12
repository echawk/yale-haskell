-- Control.Monad.Fix (base).  RecursiveDo's rec and mdo use mfix
-- (parser/exp-parser.mumble).
module Control.Monad.Fix (MonadFix(mfix), fix) where

import Data.IORef
import System.IO.Unsafe (unsafeInterleaveIO)
import Data.Functor.Identity (Identity(..))

fix :: (a -> a) -> a
fix f = let x = f x in x

class Monad m => MonadFix m where
  mfix :: (a -> m a) -> m a

instance MonadFix Maybe where
  mfix f = let a = f (unJust a) in a
    where unJust (Just x) = x
          unJust Nothing = error "mfix Maybe: Nothing"

instance MonadFix [] where
  mfix f = case fix (f . head) of
             [] -> []
             (x : _) -> x : mfix (drop 1 . f)

-- the result is read lazily from a reference filled in afterwards
instance MonadFix IO where
  mfix k = do
    ref <- newIORef (error "mfix IO: value used before it is defined")
    ans <- unsafeInterleaveIO (readIORef ref)
    result <- k ans
    writeIORef ref result
    return result

instance MonadFix Identity where
  mfix f = Identity (fix (runIdentity . f))

instance MonadFix ((->) r) where
  mfix f = \r -> let a = f a r in a
