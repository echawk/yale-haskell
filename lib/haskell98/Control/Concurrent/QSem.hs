-- Control.Concurrent.QSem (base): a quantity semaphore, over an MVar of
-- the quantity and the waiters' MVars.
module Control.Concurrent.QSem (QSem, newQSem, waitQSem, signalQSem) where

import Control.Concurrent.QSemN

newtype QSem = QSem QSemN

newQSem :: Int -> IO QSem
newQSem n
  | n < 0 = ioError (userError "newQSem: Initial quantity must be non-negative")
  | otherwise = fmap QSem (newQSemN n)

waitQSem :: QSem -> IO ()
waitQSem (QSem q) = waitQSemN q 1

signalQSem :: QSem -> IO ()
signalQSem (QSem q) = signalQSemN q 1
