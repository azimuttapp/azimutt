import {z} from "zod";

export type Brand<K, T> = K & { __brand: T } // cf https://michalzalecki.com/nominal-typing-in-typescript

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
export type UserRole = 'owner' | 'writer' | 'reader'
export const UserRole = z.enum(['owner', 'writer', 'reader'])

export interface PositionViewport {
    clientX: number
    clientY: number
}

export const PositionViewport = z.object({
    clientX: z.number(),
    clientY: z.number()
}).strict()
