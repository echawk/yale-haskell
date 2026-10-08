-- Empty needs Eq (Int -> Int), which does not exist: rejected.
module Main where
import Dialogue (stdout, appendChan, done, abort)

data (Eq a) => Box a = Empty | Full a

f :: Box (Int -> Int)
f = Empty

main = appendChan stdout "unreachable" abort done
