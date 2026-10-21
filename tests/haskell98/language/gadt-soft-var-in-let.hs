{-# LANGUAGE GADTs #-}
data Args a where
  NoArgs :: Args ()
  OneArg :: (a -> String) -> Args a

newtype Field = Field Int deriving Show

render :: Args a -> Field -> String
render args@(OneArg f) fld =
  let key = show fld
  in key ++ "!"
render NoArgs fld = show fld

main :: IO ()
main = putStrLn (render (OneArg show :: Args Int) (Field 3)) >> putStrLn (render NoArgs (Field 4))
