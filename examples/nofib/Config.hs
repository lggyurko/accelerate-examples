{-# LANGUAGE PatternGuards   #-}
{-# LANGUAGE TemplateHaskell #-}
{-# LANGUAGE TypeOperators   #-}
{-# LANGUAGE ViewPatterns    #-}

module Config where

import ParseArgs
import Data.Label
import Data.Maybe


data Config
  = Config
  {
    -- Standard options
    _configBackend      :: Backend
  , _configHelp         :: Bool
  , _configBenchmark    :: Bool
  , _configQuickCheck   :: Bool

    -- Which QuickCheck test types to enable?
  , _configDouble       :: Bool
  , _configFloat        :: Bool
  , _configInt64        :: Bool
  , _configInt32        :: Bool
  , _configInt16        :: Bool
  , _configInt8         :: Bool
  , _configWord64       :: Bool
  , _configWord32       :: Bool
  , _configWord16       :: Bool
  , _configWord8        :: Bool
  }
  deriving Show

$(mkLabels [''Config])


defaults :: Config
defaults = Config
  {
    _configBackend      = maxBound
  , _configHelp         = False
  , _configBenchmark    = True
  , _configQuickCheck   = True

  , _configDouble       = False
  , _configFloat        = False
  , _configInt64        = True
  , _configInt32        = True
  , _configInt16        = False
  , _configInt8         = False
  , _configWord64       = False
  , _configWord32       = False
  , _configWord16       = False
  , _configWord8        = False
  }

options :: [OptDescr (Config -> Config)]
options =
  [ Option  [] ["no-quickcheck"]
            (NoArg (set configQuickCheck False))
            "disable QuickCheck tests"

  , Option  [] ["no-benchmark"]
            (NoArg (set configBenchmark False))
            "disable Criterion benchmarks"

  , Option  [] ["double"]
            (OptArg (set configDouble . read . fromMaybe "True") "BOOL")
            (describe configDouble "enable double-precision tests")

  , Option  [] ["float"]
            (OptArg (set configFloat . read . fromMaybe "True") "BOOL")
            (describe configDouble "enable single-precision tests")

  , Option  [] ["int64"]
            (OptArg (set configInt64 . read . fromMaybe "True") "BOOL")
            (describe configInt64 "enable 64-bit integer tests")

  , Option  [] ["int32"]
            (OptArg (set configInt32 . read . fromMaybe "True") "BOOL")
            (describe configInt32 "enable 32-bit integer tests")

  , Option  [] ["int16"]
            (OptArg (set configInt16 . read . fromMaybe "True") "BOOL")
            (describe configInt16 "enable 16-bit integer tests")

  , Option  [] ["int8"]
            (OptArg (set configInt8 . read . fromMaybe "True") "BOOL")
            (describe configInt8 "enable 8-bit integer tests")

  , Option  [] ["word64"]
            (OptArg (set configWord64 . read . fromMaybe "True") "BOOL")
            (describe configWord64 "enable 64-bit unsigned integer tests")

  , Option  [] ["word32"]
            (OptArg (set configWord32 . read . fromMaybe "True") "BOOL")
            (describe configWord32 "enable 32-bit unsigned integer tests")

  , Option  [] ["word16"]
            (OptArg (set configWord16 . read . fromMaybe "True") "BOOL")
            (describe configWord16 "enable 16-bit unsigned integer tests")

  , Option  [] ["word8"]
            (OptArg (set configWord8 . read . fromMaybe "True") "BOOL")
            (describe configWord8 "enable 8-bit unsigned integer tests")

  , Option  ['h', '?'] ["help"]
            (NoArg (set configHelp True))
            "show this help message"
  ]
  where
    describe f msg
      = msg ++ " (" ++ show (get f defaults) ++ ")"

header :: [String]
header =
  [ "accelerate-nofib (c) [2013] The Accelerate Team"
  , ""
  , "Usage: accelerate-nofib [OPTIONS]"
  , ""
  ]

footer :: [String]
footer = []

