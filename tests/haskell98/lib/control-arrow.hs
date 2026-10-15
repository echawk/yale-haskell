-- Control.Arrow and Control.Category for functions and Kleisli arrows.
import Control.Arrow
import qualified Control.Category as C
main = do
  print ((first (+1) >>> second (*2)) (1, 2), ((+1) &&& (*2)) 5, ((+1) *** show) (1, 2))
  print (left (+1) (Left 3 :: Either Int Int), (show ||| reverse) (Right "ab" :: Either Int String))
  r <- runKleisli (Kleisli (\x -> print x >> return (x + 1)) >>> arr (*10)) 4
  print (r, (C.id C.. (+1)) 1, loop (\(b, d) -> (b + 1, d)) 1, app ((+2), 3))
