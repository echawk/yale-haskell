-- an ExitCode past every handler exits with its code; finally runs first
import System.Exit
import Control.Exception
main :: IO ()
main = exitWith (ExitFailure 6) `finally` putStrLn "cleanup"
