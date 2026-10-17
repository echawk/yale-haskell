-- Q.T(..) in an export list exports T and the constructors in scope as Q.C.
import QTypeB

main :: IO ()
main = print [A, B]
