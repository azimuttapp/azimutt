module PagesComponents.Organization_.Project_.Models.ErdColumnPropsTest exposing (..)

import Expect
import PagesComponents.Organization_.Project_.Models.ErdColumnProps as ErdColumnProps exposing (ErdColumnProps, ErdColumnPropsNested(..))
import Test exposing (Test, describe, test)


suite : Test
suite =
    describe "PagesComponents.Organization_.Project_.Models.ErdColumnProps"
        [ test "flat and nest" (\_ -> props |> ErdColumnProps.flatten |> ErdColumnProps.nest |> Expect.equal props)
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
