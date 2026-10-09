-- Foreign.Marshal.Error: the Haskell 2010 library module (Report 2010,
-- chapter 35), for Yale Haskell's Haskell 98 dialect.
module Foreign.Marshal.Error (
    throwIf, throwIf_, throwIfNeg, throwIfNeg_, throwIfNull, void
  ) where

import Foreign.Ptr

throwIf :: (a -> Bool) -> (a -> String) -> IO a -> IO a
throwIf pred msgfct act = do
  res <- act
  if pred res then ioError (userError (msgfct res)) else return res

throwIf_ :: (a -> Bool) -> (a -> String) -> IO a -> IO ()
throwIf_ pred msgfct act = throwIf pred msgfct act >> return ()

throwIfNeg :: (Ord a, Num a) => (a -> String) -> IO a -> IO a
throwIfNeg = throwIf (< 0)

throwIfNeg_ :: (Ord a, Num a) => (a -> String) -> IO a -> IO ()
throwIfNeg_ = throwIf_ (< 0)

throwIfNull :: String -> IO (Ptr a) -> IO (Ptr a)
throwIfNull msg = throwIf (== nullPtr) (const msg)

void :: IO a -> IO ()
void act = act >> return ()
