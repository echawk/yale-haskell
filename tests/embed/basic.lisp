;;;; basic.lisp -- #@hs{ ... }# blocks (doc/EMBEDDING.md): expressions,
;;;; definitions, imports, splices, values in both directions, IO, errors.

(in-package :cl-user)

(eval-when (:compile-toplevel :load-toplevel :execute)
  (setf *readtable* (yale-haskell:enable-haskell-syntax (copy-readtable))))

(defun show (x) (format t "~s~%" x))

#@hs{ import qualified Data.Map as M }#

#@hs{
  fib :: Int -> Int
  fib n = if n < 2 then n else fib (n - 1) + fib (n - 2)
}#

#@hs{
  data Shape = Circle Double | Square Double deriving Show
  area :: Shape -> Double
  area (Circle r) = pi * r * r
  area (Square s) = s * s
}#

(show (+ 1 #@hs{ 2 * 3 }#))
(show #@hs{ fib 20 }#)
(defun fib-of (n) #@hs{ fib ($n :: Int) }#)
(show (fib-of 25))
(defun adder (k) #@hs{ \x -> x + ($k :: Int) }#)
(show (funcall (adder 10) 32))
(show #@hs{ map (\x -> x * x) $(list 1 2 3) }#)
(show #@hs{ M.toList (M.fromList (zip "abc" [1 :: Int ..])) }#)
(show #@hs{ words "hello lisp world" -- a comment with }# in it
          }#)
(show #@hs{ (1 :: Int, "two }#", 'c', True, Just 3.5 :: Maybe Double, Nothing :: Maybe Int) }#)
(show #@hs{ fmap sum $ Just [1..10 :: Integer] }#)
(show #@hs{ map area [Circle 1, Square 2] }#)
(defparameter *shape* #@hs{ Circle 2 }#)
(show #@hs{ show ($*shape* :: Shape) }#)
(show #@hs{ map $(lambda (x) (* x 10)) [1, 2, 3 :: Int] }#)
(show #@hs{ (\f -> f 3 4) $(lambda (a b) (expt a b)) :: Integer }#)
(show #@hs{ length (show (product [1..50 :: Integer])) }#)
#@hs{ putStrLn "from Haskell's IO" }#
(funcall #@hs{ \s -> putStrLn ("hello " ++ s) }# "Lisp")
(show (handler-case #@hs{ head ([] :: [Int]) }#
        (yale-haskell:haskell-error (e) (list :haskell-error (yale-haskell:haskell-error-message e)))))
(show (handler-case (yale-haskell:eval-haskell "1 + True")
        (yale-haskell:haskell-compile-error () :compile-error)))
(show (yale-haskell:eval-haskell "M.size (M.fromList [(1, 'a'), (2, 'b')])"))
