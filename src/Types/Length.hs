module Types.Length
	( Length(..)
	, convertUnit
	) where

import Data.Functor ((<$>))
import Data.Monoid ((<>))

{-
https://developer.mozilla.org/en-US/docs/Web/CSS/length
https://developer.mozilla.org/en-US/docs/Web/CSS/percentage
https://developer.mozilla.org/en-US/docs/Web/CSS/angle
https://developer.mozilla.org/en-US/docs/Web/CSS/timing-function
https://developer.mozilla.org/en-US/docs/Web/CSS/time

A length is an algebraic data type consisting of a number value and a unit

* 12px
* 1.1em
-}

{----------------------------------------------------------------------------------------------------{
                                                                      | Type
}----------------------------------------------------------------------------------------------------}

-- TODO: figure out what to do with missing units
data Length = Length
	{ value :: Double
	, unit :: String
	} deriving (Show, Eq)

lengthArithemetic :: (Double -> Double -> Double) -> Length -> Length -> Length
lengthArithemetic op (Length v1 u1) (Length v2 u2)
	| u1 == "" || u1 == u2 = Length (op v1 v2) u2
	| u2 == "" = Length (op v1 v2) u1
	| otherwise = case convertUnit v2 u2 u1 of
		-- is an exception a good idea here?
		Nothing -> error $ "Cannot convert " <> u1 <> " to " <> u2
		Just v2' -> Length (op v1 v2') u1

instance Num Length where
	n1 + n2 = lengthArithemetic (+) n1 n2
	n1 * n2 = lengthArithemetic (*) n1 n2
	negate (Length f u) = Length (negate f) u
	abs (Length f u) = Length (abs f) u
	signum (Length f u) = Length (signum f) u
	fromInteger f = Length (fromInteger f) []

instance Fractional Length where
	--  TODO: fix division here so that we can remove units
	n1 / n2 = lengthArithemetic (/) n1 n2
	fromRational n = Length (fromRational n) []

--------------------------------------------------------------------- | Unit Conversion

{-
https://www.w3.org/TR/css3-values/

Some values can be converted from one to another, which would allow arithmetic operations between them:

* cm <-> in <-> mm <-> pt <-> pc
* deg <-> grad <-> turn <-> rad
* s <-> ms

It should be possible to perform certain types of arithmetic:

* `100px * 2` is equal to 200px
* `100px / 1px` is equal to 100
* `100 * 1px` is equal to 100px
* `100px + 100px` is equal to 200px

Which unit should be displayed when performing arithmetic between compatible unit types?
Does `1in + 2.54cm` output as 2in or 5.08cm?
-}

-- we're going to generate our entire conversion chart off of this list
simpleConversionChart :: [[(String, Double)]]
simpleConversionChart =
	[
		-- distance
		[ ("in",  1)    -- inches
		, ("cm",  2.54) -- centemeters
		, ( "q", 10.16) -- quarter centemeters (2.54 * 4)
		, ("mm", 25.4)  -- millimeters
		, ("px", 96)    -- pixels
		, ("pt", 72)    -- points
		, ("pc",  6)    -- picas
		]
	,
		-- time
		[ ("s", 1)
		, ("ms", 1000)
		]
	,
		-- angle
		[ ("turn",   1)
		, ("deg" , 360)
		, ("grad", 400)
		, ("rad" , 2 * pi)
		]
	,
		-- frequency
		[ ("Hz" ,    1)
		, ("kHz", 1000)
		]

		-- TODO: resolution
	]

createConversionChart :: [(String, Double)] -> [((String, String), Double)]
createConversionChart (x : []) = []
createConversionChart (x : xs) = concatMap multipliers xs ++ createConversionChart xs
	where
		multipliers y = [((fst x, fst y), snd y / snd x), ((fst y, fst x), snd x / snd y)]

conversionChart :: [((String, String), Double)]
conversionChart = concatMap createConversionChart simpleConversionChart

convertUnit :: Double -> String -> String -> Maybe Double
convertUnit n from to = (* n) <$> lookup (from, to) conversionChart

{----------------------------------------------------------------------------------------------------{
                                                                      | Functions
}----------------------------------------------------------------------------------------------------}

