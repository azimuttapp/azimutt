import {ISqlType} from "mssql";

// Write missing types in @types/mssql (8.1.2 instead of 9.1.1 :/)

export type ColumnMetadata = {
    index: number;
    name: string;
    length: number;
    type: (() => ISqlType) | ISqlType;
    udt?: any;
    scale?: number | undefined;
    precision?: number | undefined;
    nullable: boolean;
    caseSensitive: boolean;
    identity: boolean;
    readOnly: boolean;
}
