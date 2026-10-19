{-# LANGUAGE TemplateHaskell #-}
-- Declaration splices: $(e), and an expression alone at the top level;
-- a generated instance from reify of this module's type.
import DeclGen

data Shape = Circle Double | Rect Double Double | Dot deriving Show

$(mkConst "answer" 42)

mkConst "seven" 7

deriveDescribe ''Shape

main :: IO ()
main = do
  print (answer + seven)
  mapM_ (putStrLn . describeIt) [Circle 1, Rect 2 3, Dot]
