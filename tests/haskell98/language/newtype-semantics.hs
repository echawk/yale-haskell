-- Matching a newtype constructor does not force the value (Haskell 98
-- section 4.2.3), unlike a data constructor with one field.
module Main where
import Dialogue (stdout, appendChan, done, abort)

newtype N = N Int
data    D = D Int

matchN :: N -> String
matchN (N _) = "newtype: no evaluation"

matchD :: D -> String
matchD (D _) = "data: forced"

out :: String
out = unlines [ matchN (error "not forced")
              , case error "not forced" of N _ -> "case on newtype: ok"
              , matchD (D (error "the field is not forced")) ]

main = appendChan stdout out abort done
