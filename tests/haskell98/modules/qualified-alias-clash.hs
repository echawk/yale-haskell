-- Two modules imported qualified as the same name, both exporting gets:
-- only a use of L.gets would be an error (Haskell 98 5.5.2).
import qualified QAliasA as L
import qualified QAliasB as L

main :: IO ()
main = print (L.a + L.b)
