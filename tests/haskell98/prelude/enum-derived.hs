-- toEnum, fromEnum and pred on a derived Enum instance.
module Main where
import Dialogue (stdout, appendChan, done, abort)

data Day = Mon | Tue | Wed | Thu | Fri deriving (Eq, Ord, Enum)

main = appendChan stdout (unlines [
  show (map fromEnum [Mon, Wed, Fri]),
  show (fromEnum (toEnum 3 :: Day), fromEnum (pred Wed), fromEnum (succ Mon))
  ]) abort done
