{-# LANGUAGE FlexibleInstances, UndecidableInstances, UndecidableSuperClasses #-}
class Show t => Pretty t where
  pretty :: t -> String
  pretty x = "<" ++ show x ++ ">"

class Pretty t => Pretty2 t
instance Pretty t => Pretty2 t

instance Pretty Int
instance Pretty Bool where pretty b = if b then "yes" else "no"

both :: Pretty2 t => t -> String
both x = pretty x ++ "/" ++ show x

main :: IO ()
main = putStrLn (both (3 :: Int)) >> putStrLn (both True)
