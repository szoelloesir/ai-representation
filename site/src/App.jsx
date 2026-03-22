import { useRef } from 'react'
import { useCanvas } from './hooks/useCanvas'
import NavBar       from './components/NavBar'
import CanvasStage  from './components/CanvasStage'
import ZoomControls from './components/ZoomControls'

export default function App() {
  const viewportRef = useRef(null)
  const { zoom, pan, setPan, active, navigateTo, zoomBy, resetZoom, fitAll } =
    useCanvas(viewportRef)

  return (
    <div style={{ display: 'flex', flexDirection: 'column', width: '100%', height: '100%' }}>
      <NavBar active={active} navigateTo={navigateTo} />

      <div style={{ flex: 1, position: 'relative', overflow: 'hidden' }}>
        <CanvasStage
          viewportRef={viewportRef}
          pan={pan}
          setPan={setPan}
          zoom={zoom}
          active={active}
        />
        <ZoomControls
          zoom={zoom}
          zoomBy={zoomBy}
          resetZoom={resetZoom}
          fitAll={fitAll}
        />
      </div>
    </div>
  )
}
