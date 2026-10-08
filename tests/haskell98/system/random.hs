-- Random: StdGen, the Random instances and the global generator.
-- The expected values come from an independent transliteration of the
-- L'Ecuyer generator and Hugs's randomIvalInteger.
module Main where
import Dialogue (stdout, appendChan, done, abort, thenIO, thenIO_)

import Random

put :: String -> IO ()
put s = appendChan stdout s abort done

showInts :: [Int] -> String
showInts xs = unwords (map show xs)

nexts :: Int -> StdGen -> [Int]
nexts 0 _ = []
nexts n g = let (x, g') = next g in x : nexts (n - 1) g'

g42 :: StdGen
g42 = mkStdGen 42

main :: IO ()
main =
  put ("mkStdGen 42: " ++ show g42 ++ "\n") `thenIO_`
  put ("mkStdGen (-42): " ++ show (mkStdGen (-42)) ++ "\n") `thenIO_`
  put ("mkStdGen 3000000000: " ++ show (mkStdGen 3000000000) ++ "\n") `thenIO_`
  put ("next: " ++ showInts (nexts 5 g42) ++ "\n") `thenIO_`
  put ("genRange: " ++ show (genRange g42) ++ "\n") `thenIO_`
  put ("dice: " ++ showInts (take 12 (randomRs (1, 6) g42)) ++ "\n") `thenIO_`
  put ("reversed range: " ++ showInts (take 5 (randomRs (6, 1) g42)) ++ "\n") `thenIO_`
  put ("chars: " ++ take 20 (randomRs ('a', 'z') g42) ++ "\n") `thenIO_`
  put ("bools: " ++ concat [ if b then "T" else "F" | b <- take 20 (randoms g42) ] ++ "\n") `thenIO_`
  put ("big: " ++ unwords (map show (take 3 (randomRs (0, 10^(30::Int) :: Integer) g42))) ++ "\n") `thenIO_`
  let (l, r) = split g42 in
  put ("split: " ++ show l ++ " / " ++ show r ++ "\n") `thenIO_`
  put ("read . show: " ++ show (read (show g42) :: StdGen) ++ "\n") `thenIO_`
  put ("read junk: " ++ show (read "hello" :: StdGen) ++ "\n") `thenIO_`
  put ("doubles in [0,1): " ++ show (all (\d -> d >= 0 && d < 1)
                                         (take 100 (randoms g42 :: [Double]))) ++ "\n") `thenIO_`
  put ("floats in [2,3]: " ++ show (all (\d -> d >= 2 && d <= 3)
                                        (take 100 (randomRs (2, 3) g42 :: [Float]))) ++ "\n") `thenIO_`
  randomIO `thenIO` \x ->
  put ("unseeded randomIO is an Int: " ++ show (x == (x :: Int)) ++ "\n") `thenIO_`
  setStdGen (mkStdGen 7) `thenIO_`
  randomRIO (1, 100) `thenIO` \a ->
  randomRIO (1, 100) `thenIO` \b ->
  randomRIO (1, 100) `thenIO` \c ->
  put ("seeded randomRIO: " ++ showInts [a, b, c] ++ "\n") `thenIO_`
  getStdGen `thenIO` \g ->
  put ("getStdGen: " ++ show g ++ "\n") `thenIO_`
  newStdGen `thenIO` \n1 ->
  getStdGen `thenIO` \g' ->
  put ("newStdGen: " ++ show n1 ++ " / " ++ show g' ++ "\n") `thenIO_`
  getStdRandom (randomR (1, 6)) `thenIO` \d ->
  put ("getStdRandom: " ++ show (d :: Int) ++ "\n")
