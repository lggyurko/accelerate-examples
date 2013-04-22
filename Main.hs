
module Main where

import MD5
import Digest
import Config

import Numeric
import Data.List
import Data.Label
import Data.Maybe
import Text.Printf
import Control.Monad
import Criterion.Measurement
import System.IO
import System.Environment
import Data.Array.Accelerate                    ( Z(..), (:.)(..) )
import qualified Data.Array.Accelerate          as A
import qualified Data.ByteString.Lazy.Char8     as L


main :: IO ()
main = do
  (conf, _cconf, _nops) <- parseArgs =<< getArgs

  -- Read the plain text word lists. This creates a vector of MD5 chunks ready
  -- for hashing.
  --
  putStr "reading wordlist... " >> hFlush stdout
  (tdict, dict) <- time $ runDigest =<< digestFile conf (fromJust $ get configWordlist conf)

  let (Z :. _ :. entries) = A.arrayShape dict
  putStrLn $ printf "%d words in %s\n" entries (secs tdict)

  -- Attempt to recover one hash at a time by comparing it to entries in the
  -- database. This rehashes the entire word list every time, rather than
  -- pre-computing the hashes and performing a lookup. That approach, known as a
  -- rainbow table, while much faster when multiple iterations of the hashing
  -- function are applied, but is defeated by salting passwords. This is true
  -- even if the salt is known, so long as it is unique for each password.
  --
  let recover hash =
        let abcd = readMD5 hash
            idx  = run1 conf (hashcat (A.use dict)) (A.fromList Z [abcd])
        --
        in case idx `A.indexArray` Z of
             -1 -> Nothing
             n  -> Just (extract dict n)

      recoverAll :: [L.ByteString] -> IO (Int,Int)
      recoverAll =
        foldM (\(i,n) h -> maybe (return (i,n+1)) (\t -> showText h t >> return (i+1,n+1)) (recover h)) (0,0)

      showText hash text = do
        L.putStr hash >> putStr " = \"" >> L.putStr text >> putStrLn "\""

  digests <- case get configDigests conf of
               Right s  -> return [L.pack s]
               Left fs  -> concat `fmap` mapM (\f -> L.lines `fmap` L.readFile f) fs

  -- Run the lookup for each unknown hash against the given wordlists.
  --
  putStrLn "beginning recovery..."
  (trec, (r, t)) <- time (recoverAll digests)

  -- And print a summary of results
  --
  let percent = fromIntegral r / fromIntegral t * 100.0 :: Double
      persec  = fromIntegral (t * entries) / trec
  putStrLn $ printf "\nrecovered %d/%d (%f %%) digests in %s, %s"
                      r t percent (secs trec)
                      (showFFloatSIBase (Just 2) 1000 persec "Hash/sec")

  when (r == t) $ putStrLn "All hashes recovered (:"


showFFloatSIBase :: RealFloat a => Maybe Int -> a -> a -> ShowS
showFFloatSIBase p b n
  = showString
  . nubBy (\x y -> x == ' ' && y == ' ')
  $ showFFloat p n' [ ' ', si_unit ]
  where
    n'          = n / (b ^^ (pow-4))
    pow         = max 0 . min 8 . (+) 4 . floor $ logBase b n
    si_unit     = "pnµm kMGT" !! pow

