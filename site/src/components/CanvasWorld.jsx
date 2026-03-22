import { motion } from 'framer-motion'
import { SECTIONS } from '../constants/sections'
import CanvasNode from './CanvasNode'

export default function CanvasWorld({ pan, zoom, active }) {
  return (
    <motion.div
      animate={{ x: pan.x, y: pan.y, scale: zoom }}
      transition={{ type: 'spring', stiffness: 180, damping: 28 }}
      style={{
        position: 'absolute',
        top: 0,
        left: 0,
        transformOrigin: '0 0',
        willChange: 'transform',
      }}
    >
      {SECTIONS.map((section, i) => (
        <CanvasNode
          key={section.id}
          section={section}
          isActive={active === i}
        />
      ))}
    </motion.div>
  )
}
