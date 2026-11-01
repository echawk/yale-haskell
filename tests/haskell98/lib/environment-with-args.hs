import System.Environment

main :: IO ()
main = do
  withArgs ["x", "y"] (getArgs >>= print)
  getArgs >>= print
  withProgName "prog" (getProgName >>= putStrLn)
  _ <- getExecutablePath
  return ()
