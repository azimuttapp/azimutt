// see https://github.com/cujojs/jiff
declare module 'jiff' {
    type Value = object | array | string | number | null
    type Change = object
    type Patch = Change[]

    export function diff(a: Value, b: Value): Patch

    export function patch(changes: Patch, x: Value): Value
}
