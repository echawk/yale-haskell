{-# LANGUAGE GeneralizedNewtypeDeriving #-}
import Control.Monad.State
newtype AppT m a = AppT { unAppT :: StateT Int m a }
  deriving (Functor, Applicative, Monad)
main = runStateT (unAppT (AppT (modify (+1)) >> AppT get)) 2 >>= print
