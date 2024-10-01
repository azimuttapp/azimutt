export const relative = (l: Location): string => l.pathname + l.search + l.hash
export const hash = (hash: string): string => hash.slice(1)
export const queryParams = (search: string): { [p: string]: string } =>
    Object.fromEntries(search.slice(1).split('&').filter(v => v.includes('=')).map(v => v.split('=')).map(([k, ...v]) => [k, v.join('=')]))

export function uriComponentEncoded(text: string): boolean {
    return !text.match(/^[a-zA-Z0-9-_.!~*'()]+$/g)
}
