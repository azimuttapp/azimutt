import {
    Color,
    EntityId,
    LegacyColumnId,
    LegacyProject,
    LegacyProjectRelation,
    LegacyProjectTable,
    Px
} from "@azimutt/models";
import {ElmApp} from "./elm";
import {Logger} from "./logger";

export class AzimuttApi {
    constructor(private app: ElmApp,
                private logger: Logger,
                public project: LegacyProject | undefined = undefined) {
    }

    getAllTables = (): LegacyProjectTable[] => {
        const removedTables = (this.project?.settings?.removedTables || '').split(',').map(t => t.trim()).filter(t => t.length > 0)
        return this.project?.sources
            .filter(s => s.enabled !== false)
            .flatMap(s => s.tables)
            .filter(t => !removedTables.find(r => t.table === r || new RegExp(r).test(t.table))) || []
    }
    getAllRelations = (): LegacyProjectRelation[] => this.project?.sources.filter(s => s.enabled !== false).flatMap(s => s.relations) || []
    showTable = (id: EntityId, left?: Px, top?: Px): void => this.app.showTable(id, typeof left === 'number' && typeof top === 'number' ? {left, top} : undefined)
    hideTable = (id: EntityId): void => this.app.hideTable(id)
    toggleTableColumns = (id: EntityId): void => this.app.toggleTableColumns(id)
    moveTableTo = (id: EntityId, left: Px, top: Px): void => this.app.setTablePosition(id, {left, top})
    moveTable = (id: EntityId, dx: Px, dy: Px): void => this.app.moveTable(id, {dx, dy})
    selectTable = (id: EntityId): void => this.app.selectTable(id)
    setTableColor = (id: EntityId, color: Color): void => this.app.setTableColor(id, color)
    showColumn = (id: LegacyColumnId): void => this.app.showColumn(id)
    hideColumn = (id: LegacyColumnId): void => this.app.hideColumn(id)
    moveColumn = (id: LegacyColumnId, index: number): void => this.app.moveColumn(id, index)
    fitToScreen = (): void => this.app.fitToScreen()
    help = (): void => this.logger.info('Hi! Welcome in the hackable world! 💻️🤓\n' +
        'We are just trying out this, so if you use it and it\'s helpful, please let us know. Also, if you need more feature like this, don\'t hesitate to ask.\n\n' +
        'Here are a few tips:\n' +
        ' - `tableId` is the "schema.table" of a table, but if schema is "public", you can omit it. Basically, what you see in table header.\n' +
        ' - `columnRef` is similar to `tableId` but with the column name appended. For example "users.id" or "audit.logs.time".\n\n' +
        '⚠️ This is not a stable interface, just a toy to experiment. If you start using it heavily, let us know so we can define something more stable.')
}
