import GHC.ResponseFile

main :: IO ()
main = do
  let args = ["plain", "with space", "quote'd", "back\\slash", ""]
  putStr (escapeArgs args)
  print (unescapeArgs (escapeArgs args))
  print (unescapeArgs "a 'b c' \"d e\" f\\ g")
