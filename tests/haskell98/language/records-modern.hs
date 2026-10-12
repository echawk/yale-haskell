-- DuplicateRecordFields with OverloadedRecordDot, NamedFieldPuns and
-- RecordWildCards; record patterns and construction of both types.
{-# LANGUAGE DuplicateRecordFields, OverloadedRecordDot, NamedFieldPuns, RecordWildCards #-}

data Person = Person { name :: String, age :: Int } deriving (Show, Eq)
data Pet = Pet { name :: String, owner :: Person } deriving Show
data Point = Point { px :: Double, py :: Double } deriving Show

greeting :: Person -> String
greeting Person { name, age } = name ++ " (" ++ show age ++ ")"

petInfo :: Pet -> String
petInfo Pet {..} = name ++ " owned by " ++ owner.name

norm :: Point -> Double
norm p = sqrt (p.px * p.px + p.py * p.py)

main :: IO ()
main = do
  let ann = Person { name = "Ann", age = 31 }
      rex = Pet { name = "Rex", owner = ann }
  putStrLn (greeting ann)
  putStrLn (petInfo rex)
  print (rex.owner.age, map (.name) [ann, Person "Bo" 2])
  print (norm (Point 3 4), rex)
  print (ann == ann { age = 31 } , (ann { age = 32 }).age)
