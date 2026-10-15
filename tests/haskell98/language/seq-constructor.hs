-- optimize.mumble's seq-constructor, let-name-constructor-fields and
-- let-float-strict-*: seq of a constructor with lazy fields does not
-- evaluate them, one with a strict field does, and a pair built only to
-- be taken apart gives the same results.
import Control.Exception
import Control.Monad
import Control.Monad.State.Strict

data P = P !Int

step :: Int -> (Int, Int)
step s = let p = (s * 3, s + 1) in fst p `seq` (fst p + 1, snd p)

counter :: State (Int, Int) ()
counter = do
  (a, b) <- get
  let a' = a + b
  a' `seq` put (a', b + 1)

main :: IO ()
main = do
  putStrLn ((undefined :: Int, 1 :: Int) `seq` "lazy fields: not evaluated")
  r <- try (evaluate (P undefined `seq` "no")) :: IO (Either ErrorCall String)
  putStrLn (either (const "strict field: evaluated") id r)
  print (step 5)
  print (execState (replicateM_ 10 counter) (0, 1))
