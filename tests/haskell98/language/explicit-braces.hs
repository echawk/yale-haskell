-- A module body written entirely with explicit braces and semicolons,
-- with no layout (Haskell 98 section 2.7).
module Main where {
  f :: Int -> Int;
  f x = case x of { 0 -> 1; n -> n * f (n - 1) };

  g :: Int -> Int;
  g x = let { a = x + 1; b = a * 2 } in b where { };

  out :: String;
  out = unlines [show (f 5), show (g 3)];

main = appendChan stdout out abort done
}
