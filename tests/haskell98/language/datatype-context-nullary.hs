-- The datatype context applies to every constructor, including the
-- nullary one, so `Empty` below needs Eq a.
module Main where
import Dialogue (stdout, appendChan, done, abort)

data (Eq a) => Box a = Empty | Full a

describe :: (Eq a) => Box a -> Box a -> String
describe Empty Empty = "both empty"
describe (Full x) (Full y) | x == y = "same"
describe _ _ = "different"

main = appendChan stdout (unlines [describe (Empty :: Box Int) Empty,
                                   describe (Full 'a') (Full 'a'),
                                   describe Empty (Full 'b')]) abort done
