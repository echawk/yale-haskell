{-# LANGUAGE TemplateHaskell #-}
-- reifyRoles (phantom when no field mentions the parameter) and
-- reifyConStrictness (a banged field is strict).
module Main where

import RolesGen

data P a b = P a Int
data S = S !Int String
newtype N a b = N [a]

main :: IO ()
main = do
  putStrLn $(rolesOf ''P)
  putStrLn $(rolesOf ''N)
  putStrLn $(rolesOf ''Maybe)
  putStrLn $(strictnessOf 'S)
  putStrLn $(strictnessOf 'Just)
