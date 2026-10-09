module Main where
import CMath
main = print (c_cos 0, c_hypot 3 4, map c_cos [0])
