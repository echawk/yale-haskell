-- Naming a field the constructor does not have is a compile error.
data T = A { x :: Int } | B { y :: Int }

main = print (x (A { y = 1 }))
