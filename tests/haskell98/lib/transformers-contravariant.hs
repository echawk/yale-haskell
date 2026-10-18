-- transformers' Contravariant instances (ReaderT, MaybeT, ...)
import Data.Functor.Contravariant
import Control.Monad.Trans.Reader
import Control.Monad.Trans.Writer
import Control.Monad.Trans.Maybe
newtype Pr a = Pr (a -> Bool)
instance Contravariant Pr where contramap f (Pr p) = Pr (p . f)
run :: Pr a -> a -> Bool
run (Pr p) = p
main :: IO ()
main = do
  print (run (runReaderT (contramap length (ReaderT (\n -> Pr even))) ()) "abcd")
  print (run (runMaybeT (contramap show (MaybeT (Pr (maybe False ((> 1) . length)))))) (Just (42 :: Int)))
