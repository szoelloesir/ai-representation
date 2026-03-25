import { getTransitionForPreset } from './presets'
import type { CameraFrame, CompiledDeck, DeckSpec, SceneNode } from './types'

const FRAME_SPACING_X = 900
const FRAME_SPACING_Y = 450
const CARD_GAP_Y = 18

function estimateWrappedLines(lines: string[], cardWidth: number, charsPerLine = 54): number {
  const contentWidthRatio = Math.max(Math.floor((cardWidth - 32) / 10), 20)
  const effectiveCharsPerLine = Math.max(Math.min(charsPerLine, contentWidthRatio), 20)
  return lines.reduce((sum, line) => {
    const lineLength = Math.max(line.length, 1)
    return sum + Math.max(1, Math.ceil(lineLength / effectiveCharsPerLine))
  }, 0)
}

function createTitleNode(frameId: string, title: string, x: number, y: number): SceneNode {
  return {
    id: `${frameId}-title`,
    frameId,
    type: 'title',
    x,
    y,
    width: 540,
    height: 96,
    content: title,
  }
}

function createTextNode(frameId: string, body: string[], x: number, y: number): SceneNode {
  const width = 760
  const lineCount = Math.max(estimateWrappedLines(body, width), 1)
  return {
    id: `${frameId}-text`,
    frameId,
    type: 'text',
    x,
    y,
    width,
    height: 56 + lineCount * 40,
    content: body.join('\n'),
  }
}

function createDiagramNode(
  frameId: string,
  diagram: NonNullable<DeckSpec['frames'][number]['diagram']>,
  x: number,
  y: number,
): SceneNode {
  const kind =
    diagram.kind ??
    (diagram.imageSrc
      ? 'image'
      : diagram.points && diagram.points.length > 0
        ? 'chart'
        : 'flow')

  const width = kind === 'image' ? 920 : 860

  const lineCount =
    kind === 'image'
      ? 1
      : Math.max(
          estimateWrappedLines(
            diagram.title ? [diagram.title, ...diagram.lines] : diagram.lines,
            width,
            58,
          ),
          1,
        )

  const chartPointCount = diagram.points?.length ?? 0
  const estimatedHeight =
    kind === 'image'
      ? 520
      : kind === 'chart' && chartPointCount > 0
        ? 120 + chartPointCount * 34
        : 72 + lineCount * 34

  const content = [diagram.title ?? '', ...diagram.lines].filter(Boolean).join('\n')
  return {
    id: `${frameId}-diagram`,
    frameId,
    type: 'diagram',
    x,
    y,
    width,
    height: estimatedHeight,
    content,
    diagram: {
      title: diagram.title,
      kind,
      animation: diagram.animation ?? 'none',
      chartType: diagram.chartType,
      lines: diagram.lines,
      points: diagram.points ?? [],
      imageSrc: diagram.imageSrc,
      imageAlt: diagram.imageAlt,
    },
  }
}

export function compileDeck(deck: DeckSpec): CompiledDeck {
  const nodes: SceneNode[] = []
  const cameraPath: CameraFrame[] = []

  deck.frames.forEach((frame, index) => {
    const gridX = (index % 3) * FRAME_SPACING_X
    const gridY = Math.floor(index / 3) * FRAME_SPACING_Y
    const baseX = frame.layout?.x ?? gridX
    const baseY = frame.layout?.y ?? gridY
    let nextY = baseY

    const titleNode = createTitleNode(frame.id, frame.title, baseX, nextY)
    nodes.push(titleNode)
    nextY += titleNode.height + CARD_GAP_Y

    if (frame.body.length > 0) {
      const textNode = createTextNode(frame.id, frame.body, baseX, nextY)
      nodes.push(textNode)
      nextY += textNode.height + CARD_GAP_Y
    }

    if (frame.diagram) {
      const diagramNode = createDiagramNode(frame.id, frame.diagram, baseX, nextY)
      nodes.push(diagramNode)
    }

    const motionPreset = frame.motion?.preset ?? 'panTo'
    cameraPath.push({
      frameId: frame.id,
      x: baseX,
      y: baseY,
      scale: frame.layout?.scale ?? 1,
      rotation: frame.layout?.rotation ?? 0,
      transition: getTransitionForPreset(motionPreset, frame.motion?.durationMs),
    })
  })

  return {
    title: deck.title,
    nodes,
    cameraPath,
  }
}
