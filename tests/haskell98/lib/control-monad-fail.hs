-- base's Control.Monad exports MonadFail's fail (logict)
import Prelude (IO, String, putStrLn, Maybe(..), print, (>>))
import Control.Monad (Monad(..), fail)

f :: Maybe Int
f = fail "x"

main :: IO ()
main = print f >> putStrLn "ok"
