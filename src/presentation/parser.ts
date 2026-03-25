import type {
  DeckSpec,
  DiagramAnimation,
  DiagramBlock,
  DiagramChartPoint,
  DiagramKind,
  FrameSpec,
  LayoutBlock,
  MotionBlock,
  MotionPreset,
} from './types'

const MOTION_PRESETS: MotionPreset[] = ['focusIn', 'panTo', 'zoomOut', 'revealGroup']

function slugify(input: string): string {
  return input
    .toLowerCase()
    .replace(/[^a-z0-9]+/g, '-')
    .replace(/^-+|-+$/g, '')
}

function parseKeyValue(lines: string[]): Record<string, string> {
  const values: Record<string, string> = {}
  for (const line of lines) {
    const idx = line.indexOf(':')
    if (idx < 0) {
      continue
    }
    const key = line.slice(0, idx).trim()
    const value = line.slice(idx + 1).trim()
    if (key.length > 0) {
      values[key] = value
    }
  }
  return values
}

function parseLayout(lines: string[]): LayoutBlock {
  const data = parseKeyValue(lines)
  return {
    x: data.x ? Number(data.x) : undefined,
    y: data.y ? Number(data.y) : undefined,
    scale: data.scale ? Number(data.scale) : undefined,
    rotation: data.rotation ? Number(data.rotation) : undefined,
  }
}

function parseMotion(lines: string[]): MotionBlock {
  const data = parseKeyValue(lines)
  const preset = data.preset as MotionPreset | undefined
  if (!preset || !MOTION_PRESETS.includes(preset)) {
    return { preset: 'panTo' }
  }
  return {
    preset,
    durationMs: data.durationMs ? Number(data.durationMs) : undefined,
  }
}

function parseDiagram(lines: string[]): DiagramBlock {
  const nonEmpty = lines.filter((line) => line.trim().length > 0)
  const metadata: Record<string, string> = {}
  let contentStart = 0

  for (let idx = 0; idx < nonEmpty.length; idx += 1) {
    const raw = nonEmpty[idx]
    const keyIdx = raw.indexOf(':')
    if (keyIdx < 0) {
      break
    }
    const key = raw.slice(0, keyIdx).trim()
    const value = raw.slice(keyIdx + 1).trim()
    if (!['title', 'type', 'chart', 'animation', 'src', 'image', 'alt'].includes(key)) {
      break
    }
    metadata[key] = value
    contentStart = idx + 1
  }

  const contentLines = nonEmpty.slice(contentStart)
  const kind = (metadata.type as DiagramKind | undefined) ?? undefined
  const chartType = metadata.chart === 'bar' ? 'bar' : undefined
  const imageSrc = metadata.src ?? metadata.image
  const imageAlt = metadata.alt
  const animation =
    (metadata.animation as DiagramAnimation | undefined) && ['none', 'grow', 'pulse'].includes(metadata.animation)
      ? (metadata.animation as DiagramAnimation)
      : undefined

  let points: DiagramChartPoint[] | undefined
  const shouldParseChart = kind === 'chart' || chartType === 'bar'
  if (shouldParseChart) {
    points = contentLines
      .map((line) => {
        const match = line.match(/^(.+?)\s*\|\s*.*?(-?\d+(?:\.\d+)?)\s*$/)
        if (!match) {
          return null
        }
        return {
          label: match[1].trim(),
          value: Number(match[2]),
        }
      })
      .filter((point): point is DiagramChartPoint => point !== null)
  }

  return {
    title: metadata.title,
    lines: contentLines,
    kind,
    animation,
    chartType,
    points,
    imageSrc,
    imageAlt,
  }
}

export function parseDeck(markdown: string): DeckSpec {
  const lines = markdown.split(/\r?\n/)
  const frames: FrameSpec[] = []
  let deckTitle = 'Untitled deck'
  let currentFrame: FrameSpec | null = null

  let idx = 0
  while (idx < lines.length) {
    const line = lines[idx].trim()

    if (line.startsWith('# ') && !line.startsWith('## ')) {
      deckTitle = line.slice(2).trim()
      idx += 1
      continue
    }

    if (line.startsWith('## ')) {
      const title = line.slice(3).trim()
      currentFrame = {
        id: slugify(title),
        title,
        body: [],
      }
      frames.push(currentFrame)
      idx += 1
      continue
    }

    if (!currentFrame) {
      idx += 1
      continue
    }

    if (line.startsWith('```')) {
      const blockType = line.slice(3).trim()
      const blockLines: string[] = []
      idx += 1
      while (idx < lines.length && !lines[idx].trim().startsWith('```')) {
        blockLines.push(lines[idx])
        idx += 1
      }

      if (blockType === 'layout') {
        currentFrame.layout = parseLayout(blockLines)
      } else if (blockType === 'motion') {
        currentFrame.motion = parseMotion(blockLines)
      } else if (blockType === 'diagram') {
        currentFrame.diagram = parseDiagram(blockLines)
      }

      idx += 1
      continue
    }

    if (line.length > 0) {
      currentFrame.body.push(line)
    }
    idx += 1
  }

  return { title: deckTitle, frames }
}
