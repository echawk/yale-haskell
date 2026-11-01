{-# LANGUAGE NoFieldSelectors, DuplicateRecordFields, OverloadedRecordDot #-}
data P = P { name :: String, age :: Int } deriving Show

-- the field name is free for an ordinary definition
name :: Int
name = 7

main :: IO ()
main = do
  let p = P { name = "a", age = 3 }
  print (name, case p of P { age = a } -> a)
  putStrLn p.name
  print (p { age = 4 })
