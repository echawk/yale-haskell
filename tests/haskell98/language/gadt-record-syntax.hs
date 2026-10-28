-- GADT record syntax: C :: { f :: t, .. } -> T i (GHC's CmmCondBranch); its
-- fields' selectors, construction, update and patterns.
{-# LANGUAGE GADTs #-}
data O
data C

data Node e x where
  Label :: Int -> Node C O
  CondBranch :: {                 -- conditional branch
      pred :: Bool,
      onTrue, onFalse :: Int,
      likely :: Maybe Bool
  } -> Node O C
  Point :: { px, py :: Int } -> Node O O

describe :: Node e x -> String
describe (Label n) = "label " ++ show n
describe c@CondBranch{} = "branch " ++ show (onTrue c, onFalse c, likely c)
describe (Point { px = x }) = "point " ++ show x

main :: IO ()
main = do
  putStrLn (describe (CondBranch { pred = True, onTrue = 1, onFalse = 2, likely = Nothing }))
  putStrLn (describe (Point 3 4))
  putStrLn (describe (Label 7))
  print (py ((Point 3 4) { py = 9 }))
