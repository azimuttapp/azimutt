module Models.Project.LayoutTest exposing (..)

import Libs.Tailwind as Tw
import Libs.Time as Time
import Models.Position as Position
import Models.Project.Group exposing (Group)
import Models.Project.Layout as Layout exposing (Layout)
import Models.Project.TableProps exposing (TableProps)
import Models.Size as Size
import PagesComponents.Organization_.Project_.Models.Memo exposing (Memo)
import Test exposing (Test, describe)
import TestHelpers.Helpers exposing (testEncode)


suite : Test
suite =
    describe "Layout"
        [ describe "serde"
            [ testEncode "empty" Layout.encode (Layout [] [] [] Time.zero Time.zero) """{"tables":[],"createdAt":0,"updatedAt":0}"""
            , testEncode "empty table"
                Layout.encode
                (Layout [ TableProps ( "", "users" ) Position.zeroGrid Size.zeroCanvas Tw.gray [] False False False ] [] [] Time.zero Time.zero)
                """{"tables":[{"id":".users","position":{"left":0,"top":0},"size":{"width":0,"height":0},"color":"gray","columns":[]}],"createdAt":0,"updatedAt":0}"""
            , testEncode "empty group"
                Layout.encode
                (Layout [] [ Group "group 1" [ ( "", "users" ) ] Tw.gray False ] [] Time.zero Time.zero)
                """{"tables":[],"groups":[{"name":"group 1","tables":[".users"],"color":"gray"}],"createdAt":0,"updatedAt":0}"""
            , testEncode "empty memo"
                Layout.encode
                (Layout [] [] [ Memo 1 "hey" Position.zeroGrid Size.zeroCanvas Nothing ] Time.zero Time.zero)
                """{"tables":[],"memos":[{"id":1,"content":"hey","position":{"left":0,"top":0},"size":{"width":0,"height":0}}],"createdAt":0,"updatedAt":0}"""
            ]
        ]
