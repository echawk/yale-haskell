import FlexibleGivenA
instance SL T where { toS (T s) = s; fromS = T }
instance SL [a] where { toS _ = "list"; fromS _ = [] }
main = putStrLn (toS (fromT (T "hi") :: T))
