module SfA where
import SfB (greeting)
infixl 6 <+>
(<+>) :: String -> String -> String
a <+> b = a ++ " " ++ b
greet :: String
greet = greeting ++ "!"
