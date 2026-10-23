module Main where
import Control.Exception.Base (IOException, try)
main :: IO ()
main = do
  r <- try (readFile "/nonexistent/file") :: IO (Either IOException String)
  putStrLn (either (const "caught") id r)
