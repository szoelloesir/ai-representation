export type MotionPreset = 'focusIn' | 'panTo' | 'zoomOut' | 'revealGroup'

export interface TransitionSpec {
  durationMs: number
  easing: 'easeInOut' | 'easeOut' | 'linear'
}

export interface LayoutBlock {
  x?: number
  y?: number
  scale?: number
  rotation?: number
}

export interface MotionBlock {
  preset: MotionPreset
  durationMs?: number
}

export type DiagramKind = 'flow' | 'chart' | 'image'
export type DiagramAnimation = 'none' | 'grow' | 'pulse'

export interface DiagramChartPoint {
  label: string
  value: number
}

export interface DiagramBlock {
  title?: string
  lines: string[]
  kind?: DiagramKind
  animation?: DiagramAnimation
  chartType?: 'bar'
  points?: DiagramChartPoint[]
  imageSrc?: string
  imageAlt?: string
}

export interface FrameSpec {
  id: string
  title: string
  body: string[]
  layout?: LayoutBlock
  motion?: MotionBlock
  diagram?: DiagramBlock
}

export interface DeckSpec {
  title: string
  frames: FrameSpec[]
}

export interface SceneNode {
  id: string
  frameId: string
  type: 'title' | 'text' | 'diagram'
  x: number
  y: number
  width: number
  height: number
  content: string
  diagram?: {
    title?: string
    kind: DiagramKind
    animation: DiagramAnimation
    chartType?: 'bar'
    lines: string[]
    points: DiagramChartPoint[]
    imageSrc?: string
    imageAlt?: string
  }
}

export interface CameraFrame {
  frameId: string
  x: number
  y: number
  scale: number
  rotation: number
  transition: TransitionSpec
}

export interface CompiledDeck {
  title: string
  nodes: SceneNode[]
  cameraPath: CameraFrame[]
}
