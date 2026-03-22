import { useRef, useCallback } from 'react'
import CanvasWorld from './CanvasWorld'

export default function CanvasStage({ pan, setPan, zoom, active, viewportRef }) {
  const dragStart = useRef(null)

  const onWheel = useCallback((e) => {
    e.preventDefault()
    // Ctrl+wheel or pinch = zoom; plain scroll = pan
    if (e.ctrlKey || e.metaKey) return // let parent zoomBy handle if wired
    setPan(p => ({ x: p.x - e.deltaX, y: p.y - e.deltaY }))
  }, [setPan])

  const onPointerDown = useCallback((e) => {
    dragStart.current = { mx: e.clientX, my: e.clientY, px: pan.x, py: pan.y }
    e.currentTarget.setPointerCapture(e.pointerId)
  }, [pan])

  const onPointerMove = useCallback((e) => {
    if (!dragStart.current) return
    const dx = e.clientX - dragStart.current.mx
    const dy = e.clientY - dragStart.current.my
    setPan({ x: dragStart.current.px + dx, y: dragStart.current.py + dy })
  }, [setPan])

  const onPointerUp = useCallback(() => {
    dragStart.current = null
  }, [])

  return (
    <div
      ref={viewportRef}
      onWheel={onWheel}
      onPointerDown={onPointerDown}
      onPointerMove={onPointerMove}
      onPointerUp={onPointerUp}
      style={{
        flex: 1,
        overflow: 'hidden',
        position: 'relative',
        cursor: 'grab',
        userSelect: 'none',
      }}
    >
      <CanvasWorld pan={pan} zoom={zoom} active={active} />
    </div>
  )
}
