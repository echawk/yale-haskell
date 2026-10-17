import Control.Monad.Trans.Accum
import Control.Monad.Trans.Identity
import Control.Monad.Trans.Class (lift)

counter :: Accum [String] Int
counter = do
  add ["a"]
  xs <- look
  add ["b"]
  ys <- looks length
  return (length xs + ys)

main = do
  print (runAccum counter ["start"])
  r <- runIdentityT (lift (putStrLn "inside") >> return (5 :: Int))
  print r
  print (evalAccum (add "xy" >> look) "z")
