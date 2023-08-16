module Models.Project.LayoutTest exposing (..)

import Libs.Nel exposing (Nel)
import Libs.Tailwind as Tw
import Libs.Time as Time
import Models.DbValue exposing (DbValue(..))
import Models.Position as Position
import Models.Project.Group exposing (Group)
import Models.Project.Layout as Layout exposing (Layout)
import Models.Project.SourceId as SourceId
import Models.Project.TableProps exposing (TableProps)
import Models.Project.TableRow as TableRow exposing (TableRow)
import Models.Size as Size
import PagesComponents.Organization_.Project_.Models.Memo exposing (Memo)
import Services.QueryBuilder exposing (ColumnMatch, RowQuery)
import Set
import Test exposing (Test, describe)
import TestHelpers.Helpers exposing (testEncode)


suite : Test
suite =
    describe "Layout"
        [ describe "serde"
            [ testEncode "empty" Layout.encode (Layout [] [] [] [] Time.zero Time.zero) """{"tables":[],"createdAt":0,"updatedAt":0}"""
            , testEncode "empty table"
                Layout.encode
                (Layout [ TableProps ( "", "users" ) Position.zeroGrid Size.zeroCanvas Tw.gray [] False False False ] [] [] [] Time.zero Time.zero)
                """{"tables":[{"id":".users","position":{"left":0,"top":0},"size":{"width":0,"height":0},"color":"gray","columns":[]}],"createdAt":0,"updatedAt":0}"""
            , testEncode "empty table row"
                Layout.encode
                (Layout [] [ TableRow 1 Nothing Position.zeroGrid Size.zeroCanvas SourceId.zero (RowQuery ( "", "users" ) (Nel (ColumnMatch (Nel "id" []) DbNull) [])) (TableRow.StateSuccess (TableRow.SuccessState [] Set.empty Set.empty False Time.zero Time.zero)) False False ] [] [] Time.zero Time.zero)
                """{"tables":[],"tableRows":[{"id":1,"position":{"left":0,"top":0},"size":{"width":0,"height":0},"source":"00000000-0000-0000-0000-000000000000","query":{"table":".users","primaryKey":[{"column":"id","value":null}]},"state":{"values":[],"startedAt":0,"loadedAt":0}}],"createdAt":0,"updatedAt":0}"""
            , testEncode "empty group"
                Layout.encode
                (Layout [] [] [ Group "group 1" [ ( "", "users" ) ] Tw.gray False ] [] Time.zero Time.zero)
                """{"tables":[],"groups":[{"name":"group 1","tables":[".users"],"color":"gray"}],"createdAt":0,"updatedAt":0}"""
            , testEncode "empty memo"
                Layout.encode
                (Layout [] [] [] [ Memo 1 "hey" Position.zeroGrid Size.zeroCanvas Nothing False ] Time.zero Time.zero)
                """{"tables":[],"memos":[{"id":1,"content":"hey","position":{"left":0,"top":0},"size":{"width":0,"height":0}}],"createdAt":0,"updatedAt":0}"""
            ]
        ]
