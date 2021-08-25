module ReviewConfig exposing (config)

{-| Do not rename the ReviewConfig module or the config function, because
`elm-review` will look for these.

To add packages that contain rules, add them to this review project using

    `elm install author/packagename`

when inside the directory containing this file.

-}

import NoDebug.Log
import NoDebug.TodoOrToString
import NoExposingEverything
import NoMissingSubscriptionsCall
import NoMissingTypeAnnotation
import NoMissingTypeAnnotationInLetIn
import NoMissingTypeExpose
import NoRecursiveUpdate
import NoUnused.CustomTypeConstructors
import NoUnused.Dependencies
import NoUnused.Parameters
import NoUnused.Patterns
import NoUnused.Variables
import Review.Rule as Rule exposing (Rule)


config : List Rule
config =
    [ NoDebug.Log.rule
    , NoDebug.TodoOrToString.rule
    , NoExposingEverything.rule |> Rule.ignoreErrorsForDirectories [ "tests" ]
    , NoMissingSubscriptionsCall.rule
    , NoRecursiveUpdate.rule
    , NoMissingTypeAnnotation.rule |> Rule.ignoreErrorsForDirectories [ ".elm-spa" ]
    , NoMissingTypeAnnotationInLetIn.rule
    , NoMissingTypeExpose.rule |> Rule.ignoreErrorsForDirectories [ ".elm-spa" ]
    , NoUnused.CustomTypeConstructors.rule [] |> Rule.ignoreErrorsForDirectories [ ".elm-spa", "src/Libs" ]
    , NoUnused.Dependencies.rule
    , NoUnused.Parameters.rule |> Rule.ignoreErrorsForDirectories [ ".elm-spa" ]
    , NoUnused.Patterns.rule
    , NoUnused.Variables.rule |> Rule.ignoreErrorsForDirectories [ ".elm-spa", "src/Libs", "tests/Libs" ]
    ]
