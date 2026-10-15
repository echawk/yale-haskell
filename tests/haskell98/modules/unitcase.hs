-- A program foo.hs beside a unit file Foo.hu (another module) on a
-- case-insensitive file system: foo.hs is its own unit, not Foo.hu.
import Unitcase
main = putStrLn unitcase
