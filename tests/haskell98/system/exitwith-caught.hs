-- exitWith inside catch is GHC's ExitCode exception (hiss's hooks)
import Control.Exception
import System.Exit
main :: IO ()
main = do
  r <- (exitWith (ExitFailure 3) >> return "no exception") `catch` \ex ->
         case fromException ex of
           Just c -> return ("ExitCode " ++ show (c :: ExitCode))
           Nothing -> return ("other: " ++ show (ex :: SomeException))
  putStrLn r
