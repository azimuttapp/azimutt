import {z} from "zod";
import {Position, Size} from "@azimutt/models";

export type Brand<K, T> = K & { __brand: T } // cf https://michalzalecki.com/nominal-typing-in-typescript

export const Slug = z.string()
export type Slug = z.infer<typeof Slug>
export const Email = z.string()
export type Email = z.infer<typeof Email>
export const Username = z.string()
export type Username = z.infer<typeof Username>
export const HtmlId = z.string()
export type HtmlId = z.infer<typeof HtmlId>
export const FileUrl = z.string()
export type FileUrl = z.infer<typeof FileUrl>
export const FileName = z.string()
export type FileName = z.infer<typeof FileName>
export const FileContent = z.string()
export type FileContent = z.infer<typeof FileContent>
export const FileObject = z.instanceof(window.File)
export type FileObject = z.infer<typeof FileObject> // export type FileObject = File
export const ViewPosition = z.enum(['start', 'end'])
export type ViewPosition = z.infer<typeof ViewPosition>
export const ToastLevel = z.enum(['info', 'success', 'warning', 'error'])
export type ToastLevel = z.infer<typeof ToastLevel>
export const Platform = z.enum(['mac', 'pc'])
export type Platform = z.infer<typeof Platform>
export const UserRole = z.enum(['owner', 'writer', 'reader'])
export type UserRole = z.infer<typeof UserRole>
export const Dialect = z.enum(['AML', 'PostgreSQL', 'MySQL', 'JSON'])
export type Dialect = z.infer<typeof Dialect>

export interface PositionViewport {
    clientX: number
    clientY: number
}

export const PositionViewport = z.object({
    clientX: z.number(),
    clientY: z.number()
}).strict()

export const AutoLayoutMethod = z.enum(['dagre', 'cytoscape/random', 'cytoscape/grid', 'cytoscape/circle', 'cytoscape/avsdf', 'cytoscape/breadthfirst', 'cytoscape/cose', 'cytoscape/dagre', 'cytoscape/fcose'])
export type AutoLayoutMethod = z.infer<typeof AutoLayoutMethod>
export const DiagramNode = z.object({id: z.string(), size: Size, pos: Position}).strict()
export type DiagramNode = z.infer<typeof DiagramNode>
export const DiagramEdge = z.object({src: z.string(), ref: z.string()}).strict()
export type DiagramEdge = z.infer<typeof DiagramEdge>
