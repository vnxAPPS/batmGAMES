/**
 * Territory Battle - Coming Soon
 * ══════════════════════════════════════════════════════════════
 * Стратегическая игра: завоёвывай регионы карты
 * ══════════════════════════════════════════════════════════════
 */

export default {
  // ══════════════════════════════════════════════════════════════
  // Game Metadata
  // ══════════════════════════════════════════════════════════════
  meta: {
    slug: 'territory',
    title: 'Битва за территорию',
    description: 'Завоюй все регионы карты! Атакуй соседей, укрепляй оборону, побеждай ИИ.',
    category: 'strategy',
  },

  // ══════════════════════════════════════════════════════════════
  // Game State
  // ══════════════════════════════════════════════════════════════
  canvas: null,
  ctx: null,
  platform: null,
  isPlaying: false,

  // ══════════════════════════════════════════════════════════════
  // Lifecycle: Init
  // ══════════════════════════════════════════════════════════════
  init(canvas, platform) {
    console.log('⚔️ Territory: init');

    this.canvas = canvas;
    this.ctx = canvas.getContext('2d');
    this.platform = platform;
  },

  // ══════════════════════════════════════════════════════════════
  // Lifecycle: Start
  // ══════════════════════════════════════════════════════════════
  start() {
    console.log('▶️ Territory: start');

    this.isPlaying = true;
    this.render();
  },

  // ══════════════════════════════════════════════════════════════
  // Lifecycle: Stop
  // ══════════════════════════════════════════════════════════════
  stop() {
    console.log('⏸️ Territory: stop');
    this.isPlaying = false;
  },

  // ══════════════════════════════════════════════════════════════
  // Lifecycle: Cleanup
  // ══════════════════════════════════════════════════════════════
  cleanup() {
    console.log('🧹 Territory: cleanup');
    this.stop();
  },

  // ══════════════════════════════════════════════════════════════
  // Render
  // ══════════════════════════════════════════════════════════════
  render() {
    const { ctx, canvas } = this;

    // Clear
    ctx.fillStyle = '#0a0d12';
    ctx.fillRect(0, 0, canvas.width, canvas.height);

    // Coming Soon message
    ctx.fillStyle = '#f2f4ff';
    ctx.font = 'bold 32px sans-serif';
    ctx.textAlign = 'center';
    ctx.textBaseline = 'middle';
    ctx.fillText('⚔️', canvas.width / 2, canvas.height / 2 - 60);

    ctx.font = 'bold 24px sans-serif';
    ctx.fillText('Coming Soon', canvas.width / 2, canvas.height / 2);

    ctx.font = '16px sans-serif';
    ctx.fillStyle = '#8b92b0';
    ctx.fillText('Игра в разработке', canvas.width / 2, canvas.height / 2 + 40);
    ctx.fillText('Завоевай карту! Атакуй, защищайся, побеждай ИИ.', canvas.width / 2, canvas.height / 2 + 65);

    ctx.textAlign = 'start';
    ctx.textBaseline = 'alphabetic';
  },

  // ══════════════════════════════════════════════════════════════
  // Resize Handler
  // ══════════════════════════════════════════════════════════════
  onResize(width, height) {
    if (this.isPlaying) {
      this.render();
    }
  },
};
