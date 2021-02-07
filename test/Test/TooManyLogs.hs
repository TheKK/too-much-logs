{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE TemplateHaskell #-}

module Test.TooManyLogs (tests) where

import Hedgehog
  ( Property,
    checkParallel,
    cover,
    discover,
    forAll,
    property,
    (===),
  )
import qualified Test.Constants as C
import Test.Gen (genUTCTime)
import TooManyLogs
  ( FilterType (FilterInRange),
    Log (timestamp),
    logIsInTimeRange,
    logMatchFilter,
  )

prop_filterInRange :: Property
prop_filterInRange = property $ do
  ta <- forAll genUTCTime
  tb <- forAll genUTCTime
  logTimeStamp <- forAll genUTCTime

  -- Select begin & end ourselve to increase the coverage of "in range
  let begin = min ta tb
      end = max ta tb
      isInRange = begin <= logTimeStamp && logTimeStamp <= end

  cover 10 "in range" isInRange
  cover 10 "out of range" $ not isInRange

  let log = C.log {timestamp = logTimeStamp}

  logIsInTimeRange (begin, end) log
    === isInRange

prop_filterInRange_alwayOutOfRange :: Property
prop_filterInRange_alwayOutOfRange = property $ do
  ta <- forAll genUTCTime
  tb <- forAll genUTCTime
  logTimeStamp <- forAll genUTCTime

  let begin = max ta tb
      end = min ta tb
      isInRange = begin <= logTimeStamp && logTimeStamp <= end

  cover 100 "out of range" $ not isInRange

prop_logMatchFilter_isoToFilterInRange :: Property
prop_logMatchFilter_isoToFilterInRange = property $ do
  begin <- forAll genUTCTime
  end <- forAll genUTCTime
  logTimeStamp <- forAll genUTCTime

  let log = C.log {timestamp = logTimeStamp}

  logMatchFilter (FilterInRange (begin, end)) log
    === logIsInTimeRange (begin, end) log

tests :: IO Bool
tests = checkParallel $$(discover)
