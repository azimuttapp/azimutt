import {Color, ColumnId, Project, Relation, Table, TableId} from "./project";
import {Px} from "./basics";

export interface AzimuttApi {
    project?: Project
    projects?: {[id: string]: Project}
    getAllTables: () => Table[]
    getAllRelations: () => Relation[]
    getVisibleTables: () => Table[]
    showTable: (id: TableId, left?: Px, top?: Px) => void
    hideTable: (id: TableId) => void
    toggleTableColumns: (id: TableId) => void
    moveTableTo: (id: TableId, left: Px, top: Px) => void
    moveTable: (id: TableId, dx: Px, dy: Px) => void
    selectTable: (id: TableId) => void
    setTableColor: (id: TableId, color: Color) => void
    showColumn: (id: ColumnId) => void
    hideColumn: (id: ColumnId) => void
    moveColumn: (id: ColumnId, index: number) => void
    fitToScreen: () => void
    resetCanvas: () => void
    help: () => void
}
