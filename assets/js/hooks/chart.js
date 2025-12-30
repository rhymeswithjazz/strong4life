// Chart.js hook for LiveView
// Uses Chart.js loaded from CDN

const Chart = {
  mounted() {
    this.initChart()
  },

  updated() {
    if (this.chart) {
      this.chart.destroy()
    }
    this.initChart()
  },

  destroyed() {
    if (this.chart) {
      this.chart.destroy()
    }
  },

  async initChart() {
    // Load Chart.js from CDN if not already loaded
    if (!window.Chart) {
      await this.loadChartJS()
    }

    const data = JSON.parse(this.el.dataset.chartData)
    const type = this.el.dataset.chartType || 'line'

    // Clear existing content
    this.el.innerHTML = '<canvas></canvas>'
    const canvas = this.el.querySelector('canvas')
    const ctx = canvas.getContext('2d')

    this.chart = new window.Chart(ctx, {
      type: type,
      data: data,
      options: {
        responsive: true,
        maintainAspectRatio: false,
        plugins: {
          legend: {
            display: false
          }
        },
        scales: {
          x: {
            grid: {
              color: 'rgba(255, 255, 255, 0.1)'
            },
            ticks: {
              color: '#94a3b8'
            }
          },
          y: {
            beginAtZero: false,
            grid: {
              color: 'rgba(255, 255, 255, 0.1)'
            },
            ticks: {
              color: '#94a3b8'
            }
          }
        }
      }
    })
  },

  loadChartJS() {
    return new Promise((resolve, reject) => {
      if (window.Chart) {
        resolve()
        return
      }

      const script = document.createElement('script')
      script.src = 'https://cdn.jsdelivr.net/npm/chart.js@4.4.1/dist/chart.umd.js'
      script.onload = resolve
      script.onerror = reject
      document.head.appendChild(script)
    })
  }
}

export default Chart

