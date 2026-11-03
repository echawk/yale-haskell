-- GHC.Event's Event: a set of I/O events, a Monoid (lens' AsEmpty Event)
import GHC.Event
main :: IO ()
main = do
  print (evtRead <> evtWrite, mempty :: Event, evtRead == evtRead <> mempty)
  print evtWrite
