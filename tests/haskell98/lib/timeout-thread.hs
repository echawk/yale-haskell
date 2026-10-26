-- System.Timeout: the action is interrupted when the bound passes (a
-- sleep, and a long computation), and not otherwise; a timeout that
-- finished leaves no exception behind.
import System.Timeout
import Control.Concurrent (threadDelay)

main :: IO ()
main = do
  timeout 20000 (return (5 :: Int)) >>= print
  timeout 20000 (threadDelay 5000000) >>= print
  timeout 20000 (mapM_ (\_ -> return ()) [1 .. 10 ^ 9 :: Integer]) >>= print
  timeout 1000000 (threadDelay 1000 >> return "in time") >>= print
  timeout (-1) (return 'x') >>= print
  timeout 0 (return 'y') >>= print
  threadDelay 50000
  putStrLn "done"
