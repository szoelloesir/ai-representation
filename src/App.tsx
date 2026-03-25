import { useCallback, useEffect, useLayoutEffect, useMemo, useRef, useState } from 'react'
import './App.css'
import deckMarkdown from './content/example-deck.md?raw'
import { compileDeck } from './presentation/compiler'
import { parseDeck } from './presentation/parser'
import type { SceneNode } from './presentation/types'
import img1 from './content/example-deck-images/1.png'
import img2 from './content/example-deck-images/2.png'
import img3 from './content/example-deck-images/3.png'
import img4 from './content/example-deck-images/4.png'
import img5 from './content/example-deck-images/5.png'
import img6 from './content/example-deck-images/6.png'

const IMAGE_REGISTRY: Record<string, string> = {
  '1.png': img1,
  '2.png': img2,
  '3.png': img3,
  '4.png': img4,
  '5.png': img5,
  '6.png': img6,
}

function renderDiagram(node: SceneNode, isActive: boolean) {
  const diagram = node.diagram
  if (!diagram) {
    return <pre>{node.content}</pre>
  }

  if (diagram.kind === 'image' && diagram.imageSrc) {
    const src = IMAGE_REGISTRY[diagram.imageSrc]
    const alt = diagram.imageAlt ?? diagram.title ?? ''
    if (!src) {
      return (
        <div className="diagram-flow">
          <h3>{diagram.title ?? 'Image'}</h3>
          <pre>{`Missing image asset: ${diagram.imageSrc}`}</pre>
        </div>
      )
    }
    return (
      <div className="diagram-image">
        <img src={src} alt={alt} />
      </div>
    )
  }

  if (diagram.kind === 'chart' && diagram.points.length > 0) {
    const maxValue = Math.max(...diagram.points.map((point) => point.value), 1)
    const animateGrow = diagram.animation === 'grow' && isActive
    const animatePulse = diagram.animation === 'pulse' && isActive

    return (
      <div className="diagram-chart">
        {diagram.title ? <h3>{diagram.title}</h3> : null}
        <ul>
          {diagram.points.map((point) => {
            const width = `${Math.max((point.value / maxValue) * 100, 4)}%`
            return (
              <li key={point.label}>
                <span className="chart-label">{point.label}</span>
                <div className="chart-track">
                  <div
                    className={`chart-bar ${animateGrow ? 'animate-grow' : ''} ${
                      animatePulse ? 'animate-pulse' : ''
                    }`}
                    style={{ width }}
                  />
                </div>
                <span className="chart-value">{point.value}</span>
              </li>
            )
          })}
        </ul>
      </div>
    )
  }

  return (
    <div className="diagram-flow">
      {diagram.title ? <h3>{diagram.title}</h3> : null}
      <pre>{diagram.lines.join('\n')}</pre>
    </div>
  )
}

function App() {
  const [activeIndex, setActiveIndex] = useState(0)
  const [viewSize, setViewSize] = useState({ width: 0, height: 0 })
  const [renderedSizeById, setRenderedSizeById] = useState<Record<string, { width: number; height: number }>>({})
  const viewportRef = useRef<HTMLElement | null>(null)
  const nodeElementsRef = useRef<Record<string, HTMLElement | null>>({})
  const [overlapWarnings, setOverlapWarnings] = useState<string[]>([])
  const compiled = useMemo(() => compileDeck(parseDeck(deckMarkdown)), [])
  const camera = compiled.cameraPath[activeIndex]
  const activeFrameNodes = useMemo(
    () => compiled.nodes.filter((node) => node.frameId === camera.frameId),
    [compiled.nodes, camera.frameId],
  )

  const frameBounds = useMemo(() => {
    if (activeFrameNodes.length === 0) {
      return { minX: camera.x, minY: camera.y, maxX: camera.x + 600, maxY: camera.y + 320 }
    }
    const minX = Math.min(...activeFrameNodes.map((node) => node.x))
    const minY = Math.min(...activeFrameNodes.map((node) => node.y))
    const maxX = Math.max(
      ...activeFrameNodes.map((node) => node.x + (renderedSizeById[node.id]?.width ?? node.width)),
    )
    const maxY = Math.max(
      ...activeFrameNodes.map((node) => node.y + (renderedSizeById[node.id]?.height ?? node.height)),
    )
    return { minX, minY, maxX, maxY }
  }, [activeFrameNodes, camera.x, camera.y, renderedSizeById])

  const viewportPadding = 48
  const contentWidth = Math.max(frameBounds.maxX - frameBounds.minX, 1)
  const contentHeight = Math.max(frameBounds.maxY - frameBounds.minY, 1)
  const availableWidth = Math.max(viewSize.width - viewportPadding * 2, 1)
  const availableHeight = Math.max(viewSize.height - viewportPadding * 2, 1)
  const fitScale = Math.min(availableWidth / contentWidth, availableHeight / contentHeight)
  const desiredScale = camera.scale * fitScale
  // Hard guarantee: never exceed the scale that would clip active content.
  const resolvedScale = Math.max(0.25, Math.min(2.4, Math.min(desiredScale, fitScale)))
  const centeredOffsetX = (availableWidth - contentWidth * resolvedScale) / 2
  const centeredOffsetY = (availableHeight - contentHeight * resolvedScale) / 2
  const translateX = viewportPadding + centeredOffsetX - frameBounds.minX * resolvedScale
  const translateY = viewportPadding + centeredOffsetY - frameBounds.minY * resolvedScale
  const transform = `translate(${translateX}px, ${translateY}px) scale(${resolvedScale})`
  const transition = `transform ${camera.transition.durationMs}ms ${camera.transition.easing}`
  const isTinyViewport = viewSize.width < 720 || viewSize.height < 420

  // Static-ish validation: detect if frame bounding rectangles overlap in world space.
  // This approximates the layout used by the compiler and helps catch bad `layout.x/y`.
  useEffect(() => {
    const byFrameId = new Map<string, { minX: number; minY: number; maxX: number; maxY: number }>()
    for (const node of compiled.nodes) {
      const existing = byFrameId.get(node.frameId)
      const nodeMinX = node.x
      const nodeMinY = node.y
      const nodeMaxX = node.x + node.width
      const nodeMaxY = node.y + node.height
      if (!existing) {
        byFrameId.set(node.frameId, {
          minX: nodeMinX,
          minY: nodeMinY,
          maxX: nodeMaxX,
          maxY: nodeMaxY,
        })
      } else {
        existing.minX = Math.min(existing.minX, nodeMinX)
        existing.minY = Math.min(existing.minY, nodeMinY)
        existing.maxX = Math.max(existing.maxX, nodeMaxX)
        existing.maxY = Math.max(existing.maxY, nodeMaxY)
      }
    }

    const entries = Array.from(byFrameId.entries())
      .map(([frameId, rect]) => ({ frameId, rect }))
      .sort((a, b) => a.frameId.localeCompare(b.frameId))

    const SAFE_MARGIN_PX = 40
    const warnings: string[] = []

    for (let i = 0; i < entries.length; i += 1) {
      for (let j = i + 1; j < entries.length; j += 1) {
        const a = entries[i]
        const b = entries[j]
        const aMinX = a.rect.minX - SAFE_MARGIN_PX
        const aMinY = a.rect.minY - SAFE_MARGIN_PX
        const aMaxX = a.rect.maxX + SAFE_MARGIN_PX
        const aMaxY = a.rect.maxY + SAFE_MARGIN_PX

        const bMinX = b.rect.minX - SAFE_MARGIN_PX
        const bMinY = b.rect.minY - SAFE_MARGIN_PX
        const bMaxX = b.rect.maxX + SAFE_MARGIN_PX
        const bMaxY = b.rect.maxY + SAFE_MARGIN_PX

        const overlapX = aMinX < bMaxX && aMaxX > bMinX
        const overlapY = aMinY < bMaxY && aMaxY > bMinY
        if (overlapX && overlapY) {
          const rawOverlapX =
            Math.min(a.rect.maxX, b.rect.maxX) - Math.max(a.rect.minX, b.rect.minX)
          const rawOverlapY =
            Math.min(a.rect.maxY, b.rect.maxY) - Math.max(a.rect.minY, b.rect.minY)

          const aCenterX = (a.rect.minX + a.rect.maxX) / 2
          const bCenterX = (b.rect.minX + b.rect.maxX) / 2
          const aCenterY = (a.rect.minY + a.rect.maxY) / 2
          const bCenterY = (b.rect.minY + b.rect.maxY) / 2

          const suggestMoveX = rawOverlapX >= rawOverlapY
          const suggestedDelta = Math.ceil((Math.max(rawOverlapX, rawOverlapY) + SAFE_MARGIN_PX) * 1.05)

          let suggestion = ''
          if (suggestMoveX) {
            const dir = aCenterX < bCenterX ? 1 : -1
            suggestion = `Suggestion: move "${b.frameId}" by at least ~${suggestedDelta}px in x (dir=${dir}).`
          } else {
            const dir = aCenterY < bCenterY ? 1 : -1
            suggestion = `Suggestion: move "${b.frameId}" by at least ~${suggestedDelta}px in y (dir=${dir}).`
          }

          const warning = `World overlap (approx) between "${a.frameId}" and "${b.frameId}". ` +
            `Overlaps: x~${Math.max(0, Math.round(rawOverlapX))}px, y~${Math.max(0, Math.round(rawOverlapY))}px ` +
            `(SAFE_MARGIN=${SAFE_MARGIN_PX}px). ${suggestion}`

          warnings.push(warning)
          console.warn(warning)
        }
      }
    }

    // De-duplicate warnings
    setOverlapWarnings(Array.from(new Set(warnings)))
  }, [compiled.nodes])

  const goPrevious = useCallback(() => {
    setActiveIndex((current) => Math.max(current - 1, 0))
  }, [])

  const goNext = useCallback(() => {
    setActiveIndex((current) => Math.min(current + 1, compiled.cameraPath.length - 1))
  }, [compiled.cameraPath.length])

  const updateRealViewportSize = useCallback(() => {
    const viewport = viewportRef.current
    if (!viewport) {
      return
    }

    const rect = viewport.getBoundingClientRect()
    const visualWidth = window.visualViewport?.width ?? rect.width
    const visualHeight = window.visualViewport?.height ?? rect.height
    const width = Math.max(1, Math.floor(Math.min(rect.width, visualWidth)))
    const height = Math.max(1, Math.floor(Math.min(rect.height, visualHeight)))

    setViewSize((previous) => {
      if (previous.width === width && previous.height === height) {
        return previous
      }
      return { width, height }
    })
  }, [])

  useEffect(() => {
    const viewport = viewportRef.current
    if (!viewport) {
      return
    }
    const observer = new ResizeObserver((entries) => {
      const entry = entries[0]
      if (!entry) {
        return
      }
      setViewSize({
        width: Math.max(1, Math.floor(entry.contentRect.width)),
        height: Math.max(1, Math.floor(entry.contentRect.height)),
      })
      updateRealViewportSize()
    })
    observer.observe(viewport)
    updateRealViewportSize()

    function onViewportChange() {
      updateRealViewportSize()
    }

    window.addEventListener('resize', onViewportChange)
    window.visualViewport?.addEventListener('resize', onViewportChange)
    window.visualViewport?.addEventListener('scroll', onViewportChange)

    return () => {
      observer.disconnect()
      window.removeEventListener('resize', onViewportChange)
      window.visualViewport?.removeEventListener('resize', onViewportChange)
      window.visualViewport?.removeEventListener('scroll', onViewportChange)
    }
  }, [updateRealViewportSize])

  const measureActiveFrameNodes = useCallback(() => {
    setRenderedSizeById((previous) => {
      let changed = false
      const next = { ...previous }
      for (const node of activeFrameNodes) {
        const element = nodeElementsRef.current[node.id]
        if (!element) {
          continue
        }
        const width = Math.ceil(element.offsetWidth)
        const height = Math.ceil(element.offsetHeight)
        const prev = previous[node.id]
        if (!prev || prev.width !== width || prev.height !== height) {
          next[node.id] = { width, height }
          changed = true
        }
      }
      return changed ? next : previous
    })
  }, [activeFrameNodes])

  useLayoutEffect(() => {
    measureActiveFrameNodes()
  }, [measureActiveFrameNodes, activeIndex, viewSize.width, viewSize.height])

  useEffect(() => {
    function onKeyDown(event: KeyboardEvent) {
      if (event.key === 'ArrowLeft') {
        event.preventDefault()
        goPrevious()
      } else if (event.key === 'ArrowRight' || event.key === ' ') {
        event.preventDefault()
        goNext()
      }
    }
    window.addEventListener('keydown', onKeyDown)
    return () => window.removeEventListener('keydown', onKeyDown)
  }, [goNext, goPrevious])

  return (
    <main className="deck-shell">
      <header className="topbar">
        <h1>{compiled.title}</h1>
        <p>
          Frame {activeIndex + 1}/{compiled.cameraPath.length}
        </p>
      </header>

      {overlapWarnings.length > 0 ? (
        <>
          <section className="overlap-banner">
            <strong>Layout validation:</strong> detected {overlapWarnings.length} overlap(s) (approx). Details are shown below (and logged to console).
          </section>
          <section className="overlap-details">
            <pre>{overlapWarnings.join('\n')}</pre>
          </section>
        </>
      ) : null}

      <section
        ref={viewportRef}
        className={`viewport ${isTinyViewport ? 'viewport-tiny' : ''}`}
      >
        <div className="camera" style={{ transform, transition }}>
          <div className="canvas">
            {compiled.nodes.map((node) => (
              <article
                key={node.id}
                ref={(element) => {
                  nodeElementsRef.current[node.id] = element
                }}
                className={`node node-${node.type} ${
                  node.frameId === camera.frameId ? 'node-active' : ''
                }`}
                style={{
                  left: `${node.x}px`,
                  top: `${node.y}px`,
                  width: `${node.width}px`,
                  minHeight: `${node.height}px`,
                }}
              >
                {node.type === 'title' ? <h2>{node.content}</h2> : null}
                {node.type === 'text' ? <pre>{node.content}</pre> : null}
                {node.type === 'diagram' ? renderDiagram(node, node.frameId === camera.frameId) : null}
              </article>
            ))}
          </div>
        </div>
      </section>

      <footer className="controls">
        <button type="button" onClick={goPrevious} disabled={activeIndex === 0}>
          Previous
        </button>
        <button
          type="button"
          onClick={goNext}
          disabled={activeIndex === compiled.cameraPath.length - 1}
        >
          Next
        </button>
      </footer>
    </main>
  )
}

export default App
