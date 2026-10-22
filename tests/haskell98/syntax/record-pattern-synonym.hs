{-# LANGUAGE PatternSynonyms #-}
-- A record pattern synonym, pattern P{f, g} = ..: P f g, and the fields'
-- selectors (Agda's EqualityType{..})
module Main (main) where

data Data = Data Int String
newtype View = View Data

pattern Rec{ count, label } = View (Data count label)

main :: IO ()
main = do
  let v = Rec 3 "x"
  case v of
    Rec n l -> print (n, l)
  print (count v, label v)
  print (case v of Rec{} -> True)
