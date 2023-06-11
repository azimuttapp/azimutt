import {AzimuttSchema} from "@azimutt/database-types";
import {formatSchema, parseSchema} from "./prisma";

export const prisma = {
    name: 'Prisma',
    parse: (content: string): Promise<AzimuttSchema> => parseSchema(content).then(formatSchema)
}
