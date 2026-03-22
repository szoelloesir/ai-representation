import { useState, useCallback, useEffect } from 'react'
import { SECTIONS, NODE_WIDTH, NODE_HEIGHT } from '../constants/sections'

const DEFAULT_ZOOM = 0.6

function targetForIndex(index, viewportW, viewportH, zoom) {
  const section = SECTIONS[index]
  const x = -(section.x * zoom) + viewportW / 2 - (NODE_WIDTH * zoom) / 2
  const y = -(section.y * zoom) + viewportH / 2 - (NODE_HEIGHT * zoom) / 2
  return { x, y }
}

export function useCanvas(viewportRef) {
  const [zoom, setZoom]   = useState(DEFAULT_ZOOM)
  const [pan,  setPan]    = useState({ x: 0, y: 0 })
  const [active, setActive] = useState(0)

  // Center on the initial node after mount
  useEffect(() => {
    const el = viewportRef.current
    if (!el) return
    const { offsetWidth: w, offsetHeight: h } = el
    setPan(targetForIndex(0, w, h, DEFAULT_ZOOM))
  }, [viewportRef])

  const navigateTo = useCallback((index) => {
    const el = viewportRef.current
    if (!el) return
    const { offsetWidth: w, offsetHeight: h } = el
    setActive(index)
    setPan(targetForIndex(index, w, h, zoom))
  }, [viewportRef, zoom])

  const zoomBy = useCallback((delta) => {
    setZoom(z => {
      const next = Math.min(2, Math.max(0.1, z + delta))
      const el = viewportRef.current
      if (el) {
        const { offsetWidth: w, offsetHeight: h } = el
        const section = SECTIONS[active]
        setPan({
          x: -(section.x * next) + w / 2 - (NODE_WIDTH  * next) / 2,
          y: -(section.y * next) + h / 2 - (NODE_HEIGHT * next) / 2,
        })
      }
      return next
    })
  }, [active, viewportRef])

  const resetZoom = useCallback(() => {
    const el = viewportRef.current
    if (!el) return
    setZoom(DEFAULT_ZOOM)
    const { offsetWidth: w, offsetHeight: h } = el
    setPan(targetForIndex(active, w, h, DEFAULT_ZOOM))
  }, [active, viewportRef])

  const fitAll = useCallback(() => {
    const el = viewportRef.current
    if (!el) return
    const { offsetWidth: w, offsetHeight: h } = el
    const totalWidth  = SECTIONS[SECTIONS.length - 1].x + NODE_WIDTH
    const totalHeight = NODE_HEIGHT
    const fitZoom = Math.min(
      w / (totalWidth  + 400),
      h / (totalHeight + 200),
      1
    )
    setZoom(fitZoom)
    setPan({
      x: w / 2 - (totalWidth  / 2) * fitZoom,
      y: h / 2 - (totalHeight / 2) * fitZoom,
    })
    setActive(-1)
  }, [viewportRef])

  // Keyboard navigation
  useEffect(() => {
    function onKey(e) {
      if (e.key === 'ArrowRight') navigateTo(Math.min(active + 1, SECTIONS.length - 1))
      if (e.key === 'ArrowLeft')  navigateTo(Math.max(active - 1, 0))
    }
    window.addEventListener('keydown', onKey)
    return () => window.removeEventListener('keydown', onKey)
  }, [active, navigateTo])

  return { zoom, pan, setPan, active, navigateTo, zoomBy, resetZoom, fitAll }
}
