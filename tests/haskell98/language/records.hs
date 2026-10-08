-- Records (Haskell 98 section 3.15): construction with labels in any
-- order, selector functions, update of one and several fields, field
-- patterns, and positional construction of a record type.
module Main where
import Dialogue (stdout, appendChan, done, abort)

data Person = Person { name :: String, age :: Int, city :: String }

describe :: Person -> String
describe p = name p ++ " (" ++ show (age p) ++ ", " ++ city p ++ ")"

isAdult :: Person -> Bool
isAdult Person { age = a } = a >= 18

alice, bob :: Person
alice = Person { age = 30, name = "Alice", city = "Paris" }
bob   = Person "Bob" 12 "Rome"

out :: String
out = unlines [ describe alice
              , describe (alice { city = "Oslo" })
              , describe (bob { age = 13, city = "Turin" })
              , unwords (map (show . isAdult) [alice, bob])
              , unwords (map name [alice, bob]) ]

main = appendChan stdout out abort done
