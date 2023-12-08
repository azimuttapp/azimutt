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
import NoUnused.Dependencies
import NoUnused.Parameters
import NoUnused.Patterns
import Review.Rule as Rule exposing (Rule)


config : List Rule
config =
    [ NoDebug.Log.rule |> Rule.ignoreErrorsForFiles [ "src/Libs/Debug.elm" ]
    , NoDebug.TodoOrToString.rule |> Rule.ignoreErrorsForFiles [ "src/Libs/Debug.elm" ]
    , NoExposingEverything.rule |> Rule.ignoreErrorsForDirectories [ "tests" ]
    , NoMissingSubscriptionsCall.rule
    , NoRecursiveUpdate.rule |> Rule.ignoreErrorsForFiles [ "src/PagesComponents/Organization_/Project_/Updates.elm" ]
    , NoMissingTypeAnnotation.rule |> Rule.ignoreErrorsForDirectories [ ".elm-spa" ]
    , NoMissingTypeAnnotationInLetIn.rule
    , NoMissingTypeExpose.rule |> Rule.ignoreErrorsForDirectories [ ".elm-spa" ]

    -- problem: some used constructors are reported as error :(
    -- , NoUnused.CustomTypeConstructors.rule [] |> Rule.ignoreErrorsForDirectories [ ".elm-spa", "src/Libs" ] |> Rule.ignoreErrorsForFiles [ "src/Components/Atoms/Icon.elm" ]
    , NoUnused.Dependencies.rule
    , NoUnused.Parameters.rule |> Rule.ignoreErrorsForDirectories [ ".elm-spa" ]
    , NoUnused.Patterns.rule

    -- problem: used modules in unused functions are reported as error :(
    -- , NoUnused.Variables.rule |> Rule.ignoreErrorsForDirectories [ ".elm-spa", "src/Libs", "tests/Libs" ]
    ]
