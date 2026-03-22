import { NODE_WIDTH, NODE_HEIGHT } from '../constants/sections'

export default function CanvasNode({ section, isActive }) {
  return (
    <div
      style={{
        position: 'absolute',
        left: section.x,
        top:  section.y,
        width:  NODE_WIDTH,
        height: NODE_HEIGHT,
        border: isActive
          ? '2px solid rgba(139,92,246,0.9)'
          : '1px solid rgba(255,255,255,0.1)',
        borderRadius: 12,
        background: isActive
          ? 'rgba(139,92,246,0.07)'
          : 'rgba(255,255,255,0.03)',
        display: 'flex',
        flexDirection: 'column',
        alignItems: 'center',
        justifyContent: 'center',
        gap: 24,
        transition: 'border-color 0.3s, background 0.3s',
      }}
    >
      <span
        style={{
          fontSize: 14,
          textTransform: 'uppercase',
          letterSpacing: '0.15em',
          color: 'rgba(139,92,246,0.8)',
          fontWeight: 600,
        }}
      >
        {section.id}
      </span>
      <h2
        style={{
          fontSize: 64,
          fontWeight: 700,
          color: '#f1f5f9',
          textAlign: 'center',
          maxWidth: '80%',
          lineHeight: 1.1,
          letterSpacing: '-1px',
        }}
      >
        {section.title}
      </h2>
      <p style={{ color: 'rgba(226,232,240,0.35)', fontSize: 20 }}>
        — placeholder —
      </p>
    </div>
  )
}
