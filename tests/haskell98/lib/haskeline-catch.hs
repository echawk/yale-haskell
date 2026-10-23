module Main where
import qualified System.Console.Haskeline as Haskeline
import Control.Exception (SomeException, ErrorCall(..), throwIO)
import Control.Monad.Trans.Class (lift)

act :: Haskeline.InputT IO String
act = (lift (throwIO (ErrorCall "boom")) >> return "no")
        `Haskeline.catch` \e -> return (show (e :: SomeException))

main :: IO ()
main = Haskeline.runInputT Haskeline.defaultSettings act >>= putStrLn
