export function filterValues(obj: object, p: (v: any) => boolean): object {
    return Object.fromEntries(Object.entries(obj).filter(([, v]) => p(v)))
}
