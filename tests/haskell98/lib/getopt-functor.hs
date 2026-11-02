import System.Console.GetOpt

data Flag = Verbose | Level Int deriving Show

options :: [OptDescr String]
options = [ Option "v" ["verbose"] (NoArg "verbose") "verbose"
          , Option "l" ["level"] (ReqArg ("level " ++) "N") "level" ]

main :: IO ()
main = do
  let opts = map (fmap length) options
      (flags, rest, errs) = getOpt Permute opts ["-v", "--level=3", "file"]
  print (flags, rest, errs)
