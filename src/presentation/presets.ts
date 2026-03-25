import type { MotionPreset, TransitionSpec } from './types'

const PRESET_TRANSITIONS: Record<MotionPreset, TransitionSpec> = {
  focusIn: { durationMs: 1400, easing: 'easeOut' },
  panTo: { durationMs: 1200, easing: 'easeInOut' },
  zoomOut: { durationMs: 1600, easing: 'easeInOut' },
  revealGroup: { durationMs: 1000, easing: 'linear' },
}

export function getTransitionForPreset(
  preset: MotionPreset,
  durationMs?: number,
): TransitionSpec {
  const base = PRESET_TRANSITIONS[preset]
  return { ...base, durationMs: durationMs ?? base.durationMs }
}
