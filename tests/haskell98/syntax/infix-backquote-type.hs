-- A type constructor in backquotes is an infix type: f `Product` g (barbies').
data Product f g a = Pair (f a) (g a)
type PM = (Maybe `Product` []) Int
x :: PM
x = Pair (Just 1) [2, 3]
f :: Int `Either` Bool -> Int
f = either id fromEnum
main = case x of Pair a b -> print (a, b, f (Right True))
