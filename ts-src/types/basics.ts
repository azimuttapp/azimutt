import {z} from "zod";

export type Timestamp = number // date in numerical format (1663007946750)
export const Timestamp = z.number()
export type DateTime = string // date in iso format ("2022-09-12T11:13:02.611616Z")
export const DateTime = z.string()
export type Px = number // number of pixels
export type Slug = string
export const Slug = z.string()
export type Email = string
export type Username = string
export type HtmlId = string
export const HtmlId = z.string()
export type FileUrl = string
export type FileName = string
export const FileName = z.string()
export type FileContent = string
export const FileContent = z.string()
export type FileObject = File
export const FileObject = z.instanceof(window.File)
export type ViewPosition = 'start' | 'end'
export const ViewPosition = z.enum(['start', 'end'])
export type ToastLevel = 'info' | 'success' | 'warning' | 'error'
export const ToastLevel = z.enum(['info', 'success', 'warning', 'error'])
export type Platform = 'mac' | 'pc'
export const Platform = z.enum(['mac', 'pc'])

export interface Position {
    left: number
    top: number
}

export const Position = z.object({
    left: z.number(),
    top: z.number()
}).strict()

export interface PositionViewport {
    clientX: number
    clientY: number
}

export const PositionViewport = z.object({
    clientX: z.number(),
    clientY: z.number()
}).strict()

export interface Size {
    width: number
    height: number
}

export const Size = z.object({
    width: z.number(),
    height: z.number()
}).strict()

export interface Delta {
    dx: number
    dy: number
}

export const Delta = z.object({
    dx: z.number(),
    dy: z.number()
}).strict()

export type Color =
    'indigo'
    | 'violet'
    | 'purple'
    | 'fuchsia'
    | 'pink'
    | 'rose'
    | 'red'
    | 'orange'
    | 'amber'
    | 'yellow'
    | 'lime'
    | 'green'
    | 'emerald'
    | 'teal'
    | 'cyan'
    | 'sky'
    | 'blue'
    | 'gray'

export const Color = z.enum(['indigo', 'violet', 'purple', 'fuchsia', 'pink', 'rose', 'red', 'orange', 'amber', 'yellow', 'lime', 'green', 'emerald', 'teal', 'cyan', 'sky', 'blue', 'gray'])
