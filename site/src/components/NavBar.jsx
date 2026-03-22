import { SECTIONS } from '../constants/sections'

export default function NavBar({ active, navigateTo }) {
  const canPrev = active > 0
  const canNext = active < SECTIONS.length - 1
  const progress = active >= 0
    ? ((active + 1) / SECTIONS.length) * 100
    : 0

  return (
    <nav
      style={{
        height: 56,
        display: 'flex',
        alignItems: 'center',
        gap: 12,
        padding: '0 20px',
        background: 'rgba(10,10,15,0.85)',
        borderBottom: '1px solid rgba(255,255,255,0.08)',
        backdropFilter: 'blur(8px)',
        flexShrink: 0,
        position: 'relative',
        zIndex: 10,
      }}
    >
      {/* Prev */}
      <button
        onClick={() => canPrev && navigateTo(active - 1)}
        disabled={!canPrev}
        style={btnStyle(!canPrev)}
        aria-label="Previous section"
      >
        ←
      </button>

      {/* Section titles */}
      <div style={{ display: 'flex', gap: 4, flex: 1, justifyContent: 'center' }}>
        {SECTIONS.map((s, i) => (
          <button
            key={s.id}
            onClick={() => navigateTo(i)}
            style={{
              padding: '4px 12px',
              borderRadius: 6,
              border: 'none',
              cursor: 'pointer',
              fontSize: 13,
              fontWeight: active === i ? 600 : 400,
              background: active === i ? 'rgba(139,92,246,0.25)' : 'transparent',
              color: active === i ? '#c4b5fd' : 'rgba(226,232,240,0.55)',
              transition: 'all 0.2s',
            }}
          >
            {i + 1}. {s.title}
          </button>
        ))}
      </div>

      {/* Next */}
      <button
        onClick={() => canNext && navigateTo(active + 1)}
        disabled={!canNext}
        style={btnStyle(!canNext)}
        aria-label="Next section"
      >
        →
      </button>

      {/* Progress bar */}
      <div
        style={{
          position: 'absolute',
          bottom: 0,
          left: 0,
          height: 2,
          width: `${progress}%`,
          background: 'linear-gradient(90deg, #7c3aed, #a78bfa)',
          transition: 'width 0.4s ease',
        }}
      />
    </nav>
  )
}

function btnStyle(disabled) {
  return {
    width: 32,
    height: 32,
    borderRadius: 6,
    border: '1px solid rgba(255,255,255,0.12)',
    background: 'rgba(255,255,255,0.05)',
    color: disabled ? 'rgba(226,232,240,0.2)' : '#e2e8f0',
    cursor: disabled ? 'default' : 'pointer',
    fontSize: 16,
    display: 'flex',
    alignItems: 'center',
    justifyContent: 'center',
    flexShrink: 0,
    transition: 'opacity 0.2s',
  }
}
