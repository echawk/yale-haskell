-- Matching a tuple (or any single-constructor) pattern evaluates the
-- value (Report 3.17.2): only ~ patterns and pattern bindings are lazy.
import Control.Exception

data P = P Int Int

check :: String -> Int -> IO ()
check what x = do
  r <- try (evaluate x)
  putStrLn (what ++ ": " ++ either (\e -> "undefined" `const` (e :: SomeException)) show r)

lam :: (Int, Int) -> Int
lam = \(a, b) -> 0

fun :: (Int, Int) -> Int
fun (a, b) = 1

con :: P -> Int
con (P _ _) = 2

lazyPat :: (Int, Int) -> Int
lazyPat ~(a, b) = 3

main :: IO ()
main = do
  check "case" (case (undefined :: (Int, Int)) of (a, b) -> 4)
  check "lambda" (lam undefined)
  check "function" (fun undefined)
  check "constructor" (con undefined)
  check "lazy pattern" (lazyPat undefined)
  check "pattern binding" (let (a, b) = (undefined :: (Int, Int)) in 5)
  check "evaluated" (fun (undefined, undefined))
