export type Timestamp = number // date in numerical format
export type Px = number // number of pixels
export type Uuid = string
export type Email = string
export type HtmlId = string
export type FileUrl = string
export type FileName = string
export type FileContent = string
export interface File {
    name: string
    mime: string
    size: number
    lastModified: Timestamp
}
export type ViewPosition = 'start' | 'end'
export type ToastLevel = 'info' | 'success' | 'warning' | 'error'
export type Env = 'dev' | 'staging' | 'prod'
