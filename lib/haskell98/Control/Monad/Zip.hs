-- Control.Monad.Zip (base): monads that can be zipped.
module Control.Monad.Zip (MonadZip(mzip, mzipWith, munzip)) where

import PreludeModern
import Data.Functor.Identity (Identity(Identity))
import Data.List.NonEmpty (NonEmpty((:|)))
import qualified Data.List.NonEmpty as NE

class Monad m => MonadZip m where
  mzip :: m a -> m b -> m (a, b)
  mzipWith :: (a -> b -> c) -> m a -> m b -> m c
  munzip :: m (a, b) -> (m a, m b)

  mzip = mzipWith (,)
  mzipWith f ma mb = fmap (\(a, b) -> f a b) (mzip ma mb)
  munzip mab = (fmap fst mab, fmap snd mab)

instance MonadZip [] where
  mzip = zip
  mzipWith = zipWith
  munzip = unzip

instance MonadZip Maybe where
  mzipWith f (Just a) (Just b) = Just (f a b)
  mzipWith _ _ _ = Nothing

instance MonadZip Identity where
  mzipWith f (Identity a) (Identity b) = Identity (f a b)

instance MonadZip NonEmpty where
  mzipWith = NE.zipWith
