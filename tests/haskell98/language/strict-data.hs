-- StrictData: fields are strict but those marked ~; a newtype's is not.
{-# LANGUAGE StrictData #-}
import Control.Exception
data P = P Int Int
data L = L Int ~Int
newtype N = N Int
probe :: a -> IO String
probe x = fmap (either (\e -> const "strict" (e :: SomeException)) (const "lazy")) (try (evaluate x))
main = do
  probe (P 1 undefined `seq` ()) >>= putStrLn
  probe (L 1 undefined `seq` ()) >>= putStrLn
  probe (N undefined `seq` ()) >>= putStrLn
