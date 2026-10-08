-- A record construction that omits a strict field is a compile error
-- (H98 Report 3.15.2).
data T = T { a :: Int, b :: !Int }

main = print (a (T { a = 1 }))
