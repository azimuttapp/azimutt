import {AzimuttApi} from "./types/api";
import {Color, ColumnId, Project, Relation, Table, TableId} from "./types/project";
import {Px} from "./types/basics";
import {ElmApp} from "./elm";

export class AzimuttApiImpl implements AzimuttApi {
    constructor(private app: ElmApp,
                public project: Project | undefined = undefined,
                public projects: {[id: string]: Project} | undefined = undefined) {
    }

    getAllTables = (): Table[] => {
        const removedTables = (this.project?.settings?.removedTables || '').split(',').map(t => t.trim()).filter(t => t.length > 0)
        return this.project?.sources
            .filter(s => s.enabled !== false)
            .flatMap(s => s.tables)
            .filter(t => !removedTables.find(r => t.table === r || new RegExp(r).test(t.table))) || []
    }
    getAllRelations = (): Relation[] => this.project?.sources.filter(s => s.enabled !== false).flatMap(s => s.relations) || []
    getVisibleTables = (): Table[] => {
        const tables: { [id: TableId]: Table } = this.getAllTables().reduce((acc, t) => ({...acc, [`${t.schema}.${t.table}`]: t}), {})
        return this.project?.layout.tables.map(t => tables[t.id]).filter(t => t !== undefined) as Table[]
    }
    showTable = (id: TableId, left?: Px, top?: Px): void => this.app.send({kind: 'GotTableShow', id, position: typeof left === 'number' && typeof top === 'number' ? {left, top} : undefined})
    hideTable = (id: TableId): void => this.app.send({kind: 'GotTableHide', id})
    toggleTableColumns = (id: TableId): void => this.app.send({kind: 'GotTableToggleColumns', id})
    moveTableTo = (id: TableId, left: Px, top: Px): void => this.app.send({kind: 'GotTablePosition', id, position: {left, top}})
    moveTable = (id: TableId, dx: Px, dy: Px): void => this.app.send({kind: 'GotTableMove', id, delta: {dx, dy}})
    selectTable = (id: TableId): void => this.app.send({kind: 'GotTableSelect', id})
    setTableColor = (id: TableId, color: Color): void => this.app.send({kind: 'GotTableColor', id, color})
    showColumn = (id: ColumnId): void => this.app.send({kind: 'GotColumnShow', ref: id})
    hideColumn = (id: ColumnId): void => this.app.send({kind: 'GotColumnHide', ref: id})
    moveColumn = (id: ColumnId, index: number): void => this.app.send({kind: 'GotColumnMove', ref: id, index})
    fitToScreen = (): void => this.app.send({kind: 'GotFitToScreen'})
    resetCanvas = (): void => this.app.send({kind: 'GotResetCanvas'})
    help = (): void => console.info('Hi! Welcome in the hackable world! 💻️🤓\n' +
        'We are just trying out this, so if you use it and it\'s helpful, please let us know. Also, if you need more feature like this, don\'t hesitate to ask.\n\n' +
        'Here are a few tips:\n' +
        ' - `tableId` is the "schema.table" of a table, but if schema is "public", you can omit it. Basically, what you see in table header.\n' +
        ' - `columnRef` is similar to `tableId` but with the column name appended. For example "users.id" or "audit.logs.time".\n\n' +
        '⚠️ This is not a stable interface, just a toy to experiment. If you start using it heavily, let us know so we can define something more stable.')
}
