-- A type error must be reported: there is no Num instance for String.
module Main where

main = appendChan stdout ("one" + 1) abort done
