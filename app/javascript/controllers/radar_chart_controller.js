import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="radar-chart"
export default class extends Controller {
  static values = {
    labels: String,
    values: String,
    color: String,
    fillColor: String,
    margin: Number,
    topPad: Number,
  }

  connect() {
    this.draw()
  }

  draw() {
    const canvas = this.element
    if (!(canvas instanceof HTMLCanvasElement)) return

    const labels = this.labelsValue.split(",")
    const values = this.valuesValue.split(",").map(Number)
    const opts = {
      color: this.colorValue || "#1e3a5f",
      fillColor: this.fillColorValue || "rgba(30,58,95,0.14)",
      margin: this.marginValue || 58,
      topPad: this.topPadValue || 12,
    }

    this.#drawRadar(canvas, labels, values, opts)
  }

  #drawRadar(canvas, labels, values, opts = {}) {
    const ctx = canvas.getContext("2d")
    const W = canvas.width
    const H = canvas.height
    const legendH = opts.legendH || 0
    const cx = W / 2
    const cy = (H - legendH) / 2 + (opts.topPad || 12)
    const R = Math.min(W, H - legendH) / 2 - (opts.margin || 58)
    const N = labels.length
    const levels = opts.levels || 5

    ctx.clearRect(0, 0, W, H)

    // Grid rings
    for (let l = 1; l <= levels; l++) {
      const r = R * l / levels
      ctx.beginPath()
      for (let i = 0; i < N; i++) {
        const angle = (Math.PI * 2 * i / N) - Math.PI / 2
        const x = cx + r * Math.cos(angle)
        const y = cy + r * Math.sin(angle)
        i === 0 ? ctx.moveTo(x, y) : ctx.lineTo(x, y)
      }
      ctx.closePath()
      ctx.strokeStyle = "#dde3ed"
      ctx.lineWidth = 1
      ctx.stroke()

      if (l % 2 === 0 || l === levels) {
        const pct = Math.round(100 * l / levels)
        ctx.fillStyle = "#b0bfce"
        ctx.font = "9px sans-serif"
        ctx.textAlign = "center"
        ctx.textBaseline = "bottom"
        ctx.fillText(pct + "%", cx + 2, cy - r - 2)
      }
    }

    // Spokes
    for (let i = 0; i < N; i++) {
      const angle = (Math.PI * 2 * i / N) - Math.PI / 2
      ctx.beginPath()
      ctx.moveTo(cx, cy)
      ctx.lineTo(cx + R * Math.cos(angle), cy + R * Math.sin(angle))
      ctx.strokeStyle = "#dde3ed"
      ctx.lineWidth = 1
      ctx.stroke()
    }

    // Axis labels
    ctx.font = '11px "Noto Sans JP", sans-serif'
    ctx.fillStyle = "#2c3e50"
    for (let i = 0; i < N; i++) {
      const angle = (Math.PI * 2 * i / N) - Math.PI / 2
      const lx = cx + (R + 26) * Math.cos(angle)
      const ly = cy + (R + 26) * Math.sin(angle)
      const cosA = Math.cos(angle), sinA = Math.sin(angle)
      ctx.textAlign = Math.abs(cosA) < 0.15 ? "center" : (cosA > 0 ? "left" : "right")
      ctx.textBaseline = Math.abs(sinA) < 0.15 ? "middle" : (sinA > 0 ? "top" : "bottom")

      // Support \n in labels
      const labelLines = labels[i].split("\\n")
      labelLines.forEach((line, li) => {
        ctx.fillText(line, lx, ly + (li * 13) - ((labelLines.length - 1) * 6.5))
      })
    }

    // Draw data polygon
    const color = opts.color || "#1e3a5f"
    const fillColor = opts.fillColor || "rgba(30,58,95,0.14)"
    const pts = values.map((v, i) => {
      const angle = (Math.PI * 2 * i / N) - Math.PI / 2
      const r = R * Math.max(0, Math.min(1, v / 100))
      return [cx + r * Math.cos(angle), cy + r * Math.sin(angle)]
    })

    ctx.beginPath()
    pts.forEach(([x, y], i) => i === 0 ? ctx.moveTo(x, y) : ctx.lineTo(x, y))
    ctx.closePath()
    ctx.fillStyle = fillColor
    ctx.fill()
    ctx.strokeStyle = color
    ctx.lineWidth = 2.2
    ctx.stroke()

    pts.forEach(([x, y]) => {
      ctx.beginPath()
      ctx.arc(x, y, 4, 0, Math.PI * 2)
      ctx.fillStyle = color
      ctx.fill()
    })
  }
}
