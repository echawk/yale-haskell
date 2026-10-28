-- div/mod/quot/rem by zero passed as a lazy argument is not evaluated
-- before the call: the callee's catch sees the ArithException
import Control.Exception

t :: Int -> IO ()
t v = print v `catch` \e -> putStrLn ("caught " ++ show (e :: ArithException))

main :: IO ()
main = do
  t (1 `div` length "")
  t (1 `mod` length "")
  t (7 `quot` 2)
  t (7 `rem` length "")
