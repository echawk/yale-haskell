-- MultilineStrings (GHC 9.12): """...""" with its common indentation removed.
{-# LANGUAGE MultilineStrings #-}
main = do
  putStr """
    hello
      world\tx
    end
    """
  print """a
         b"""
  print "plain"
