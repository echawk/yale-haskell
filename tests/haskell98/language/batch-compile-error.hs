-- A program that does not type check: the diagnostics go to stderr, stdout
-- stays empty, and the exit status is 1.
main = appendChan stdout (show (1 + True)) abort done
