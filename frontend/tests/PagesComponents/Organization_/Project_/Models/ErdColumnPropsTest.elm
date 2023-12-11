module PagesComponents.Organization_.Project_.Models.ErdColumnPropsTest exposing (..)

import Expect
import Models.Project.ColumnPath as ColumnPath exposing (ColumnPath)
import PagesComponents.Organization_.Project_.Models.ErdColumnProps as ErdColumnProps exposing (ErdColumnProps, ErdColumnPropsNested(..))
import Test exposing (Test, describe, test)


suite : Test
suite =
    describe "PagesComponents.Organization_.Project_.Models.ErdColumnProps"
        [ test "flat and nest" (\_ -> props |> ErdColumnProps.flatten |> ErdColumnProps.nest |> Expect.equal props)
        , describe "removeWithIndex"
            [ test "not found"
                (\_ ->
                    [ prop "id" [], prop "name" [] ]
                        |> ErdColumnProps.removeWithIndex (path "slug")
                        |> Expect.equal ( [ prop "id" [], prop "name" [] ], Nothing )
                )
            , test "found at root"
                (\_ ->
                    [ prop "id" [], prop "name" [] ]
                        |> ErdColumnProps.removeWithIndex (path "name")
                        |> Expect.equal ( [ prop "id" [] ], Just 1 )
                )
            , test "found nested"
                (\_ ->
                    [ prop "id" [], prop "name" [ prop "first" [], prop "last" [] ] ]
                        |> ErdColumnProps.removeWithIndex (path "name.first")
                        |> Expect.equal ( [ prop "id" [], prop "name" [ prop "last" [] ] ], Just 0 )
                )
            , test "not found nested"
                (\_ ->
                    [ prop "id" [], prop "name" [ prop "first" [], prop "last" [] ] ]
                        |> ErdColumnProps.removeWithIndex (path "name.middle")
                        |> Expect.equal ( [ prop "id" [], prop "name" [ prop "first" [], prop "last" [] ] ], Nothing )
                )
            ]
        ]


props : List ErdColumnProps
props =
    [ buildProps "id" [] False, buildProps "settings" [ buildProps "colors" [] True ] True ]


buildProps : String -> List ErdColumnProps -> Bool -> ErdColumnProps
buildProps name children highlighted =
    { name = name
    , children = ErdColumnPropsNested children
    , highlighted = highlighted
    }


prop : String -> List ErdColumnProps -> ErdColumnProps
prop name children =
    { name = name
    , children = ErdColumnPropsNested children
    , highlighted = False
    }


path : String -> ColumnPath
path value =
    value |> String.replace "." ColumnPath.separator |> ColumnPath.fromString
