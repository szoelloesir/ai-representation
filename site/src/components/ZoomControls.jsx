export default function ZoomControls({ zoom, zoomBy, resetZoom, fitAll }) {
  return (
    <div
      style={{
        position: 'absolute',
        bottom: 24,
        right: 24,
        display: 'flex',
        flexDirection: 'column',
        gap: 6,
        zIndex: 10,
      }}
    >
      <Btn onClick={() => zoomBy(+0.1)} title="Zoom in">+</Btn>
      <Btn onClick={() => zoomBy(-0.1)} title="Zoom out">−</Btn>
      <Btn onClick={resetZoom} title="Reset zoom" style={{ fontSize: 11 }}>
        {Math.round(zoom * 100)}%
      </Btn>
      <Btn onClick={fitAll} title="Fit all nodes" style={{ fontSize: 10 }}>
        FIT
      </Btn>
    </div>
  )
}

function Btn({ onClick, title, children, style }) {
  return (
    <button
      onClick={onClick}
      title={title}
      style={{
        width: 36,
        height: 36,
        borderRadius: 8,
        border: '1px solid rgba(255,255,255,0.12)',
        background: 'rgba(10,10,15,0.85)',
        color: '#e2e8f0',
        cursor: 'pointer',
        fontSize: 18,
        display: 'flex',
        alignItems: 'center',
        justifyContent: 'center',
        backdropFilter: 'blur(8px)',
        transition: 'background 0.15s',
        ...style,
      }}
    >
      {children}
    </button>
  )
}
