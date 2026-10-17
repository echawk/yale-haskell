-- An explicit Prelude import list limits what base's Prelude names
-- (PreludeModern) bring in, so a module may define its own <>.
import qualified MonoidHT as H
main = putStrLn (H.twice "ab" H.<> "!")
