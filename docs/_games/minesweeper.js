/**
 * Minesweeper - Classic
 * ══════════════════════════════════════════════════════════════
 * Классический Сапёр для batmGAMES Platform
 * ══════════════════════════════════════════════════════════════
 */

export default {
  // ══════════════════════════════════════════════════════════════
  // Game Metadata
  // ══════════════════════════════════════════════════════════════
  meta: {
    slug: 'minesweeper',
    title: 'Сапёр',
    description: 'Открывай клетки, избегай мин. Классика или бесконечное поле!',
    category: 'puzzle',
  },

  // ══════════════════════════════════════════════════════════════
  // Game State
  // ══════════════════════════════════════════════════════════════
  canvas: null,
  ctx: null,
  platform: null,
  isPlaying: false,

  cols: 10,
  rows: 10,
  mines: 15,
  cellSize: 40,

  grid: [],
  revealed: [],
  flagged: [],

  firstClick: true,
  gameWon: false,
  score: 0,
  startTime: 0,
  elapsedTime: 0,

  // Colors
  numberColors: [
    null,
    '#0000ff',
    '#008000',
    '#ff0000',
    '#000080',
    '#800000',
    '#008080',
    '#000000',
    '#808080',
  ],

  // ══════════════════════════════════════════════════════════════
  // Lifecycle: Init
  // ══════════════════════════════════════════════════════════════
  init(canvas, platform) {
    console.log('💣 Minesweeper: init');

    this.canvas = canvas;
    this.ctx = canvas.getContext('2d');
    this.platform = platform;

    this.calculateSizes();
    this.setupInput();
  },

  // ══════════════════════════════════════════════════════════════
  // Lifecycle: Start
  // ══════════════════════════════════════════════════════════════
  start() {
    console.log('▶️ Minesweeper: start');

    this.isPlaying = true;
    this.firstClick = true;
    this.gameWon = false;
    this.score = 0;
    this.startTime = Date.now();
    this.elapsedTime = 0;

    this.initGrid();
    this.gameLoop();
  },

  // ══════════════════════════════════════════════════════════════
  // Lifecycle: Stop
  // ══════════════════════════════════════════════════════════════
  stop() {
    console.log('⏸️ Minesweeper: stop');
    this.isPlaying = false;
  },

  // ══════════════════════════════════════════════════════════════
  // Lifecycle: Cleanup
  // ══════════════════════════════════════════════════════════════
  cleanup() {
    console.log('🧹 Minesweeper: cleanup');
    this.stop();
  },

  // ══════════════════════════════════════════════════════════════
  // Game Loop
  // ══════════════════════════════════════════════════════════════
  gameLoop() {
    if (!this.isPlaying) return;

    if (!this.gameWon && !this.firstClick) {
      this.elapsedTime = Math.floor((Date.now() - this.startTime) / 1000);
    }

    this.render();
    requestAnimationFrame(() => this.gameLoop());
  },

  // ══════════════════════════════════════════════════════════════
  // Render
  // ══════════════════════════════════════════════════════════════
  render() {
    const { ctx, canvas } = this;

    // Clear
    ctx.fillStyle = '#0a0d12';
    ctx.fillRect(0, 0, canvas.width, canvas.height);

    const boardWidth = this.cols * this.cellSize;
    const boardHeight = this.rows * this.cellSize;
    const offsetX = (canvas.width - boardWidth) / 2;
    const offsetY = (canvas.height - boardHeight) / 2 + 40;

    // Draw stats
    ctx.fillStyle = '#f2f4ff';
    ctx.font = 'bold 18px sans-serif';
    ctx.textAlign = 'center';

    const flagsLeft = this.mines - this.flagged.filter(f => f).length;
    ctx.fillText(`💣 ${flagsLeft}`, offsetX + 60, offsetY - 20);
    ctx.fillText(`⏱️ ${this.elapsedTime}s`, canvas.width - offsetX - 60, offsetY - 20);

    // Draw grid
    for (let row = 0; row < this.rows; row++) {
      for (let col = 0; col < this.cols; col++) {
        const x = offsetX + col * this.cellSize;
        const y = offsetY + row * this.cellSize;
        const idx = row * this.cols + col;

        if (this.revealed[idx]) {
          // Revealed cell
          ctx.fillStyle = '#1a1f2e';
          ctx.fillRect(x, y, this.cellSize, this.cellSize);

          if (this.grid[idx] === -1) {
            // Mine
            ctx.fillStyle = '#ff0000';
            ctx.font = 'bold 24px sans-serif';
            ctx.textAlign = 'center';
            ctx.textBaseline = 'middle';
            ctx.fillText('💣', x + this.cellSize / 2, y + this.cellSize / 2);
          } else if (this.grid[idx] > 0) {
            // Number
            ctx.fillStyle = this.numberColors[this.grid[idx]];
            ctx.font = 'bold 20px sans-serif';
            ctx.textAlign = 'center';
            ctx.textBaseline = 'middle';
            ctx.fillText(this.grid[idx].toString(), x + this.cellSize / 2, y + this.cellSize / 2);
          }
        } else {
          // Hidden cell
          ctx.fillStyle = '#2a3142';
          ctx.fillRect(x + 1, y + 1, this.cellSize - 2, this.cellSize - 2);

          // Highlight
          ctx.fillStyle = 'rgba(255, 255, 255, 0.1)';
          ctx.fillRect(x + 1, y + 1, this.cellSize - 2, 3);

          // Flag
          if (this.flagged[idx]) {
            ctx.fillStyle = '#ff7000';
            ctx.font = 'bold 20px sans-serif';
            ctx.textAlign = 'center';
            ctx.textBaseline = 'middle';
            ctx.fillText('🚩', x + this.cellSize / 2, y + this.cellSize / 2);
          }
        }

        // Border
        ctx.strokeStyle = '#0a0d12';
        ctx.lineWidth = 1;
        ctx.strokeRect(x, y, this.cellSize, this.cellSize);
      }
    }

    ctx.textAlign = 'start';
    ctx.textBaseline = 'alphabetic';
  },

  // ══════════════════════════════════════════════════════════════
  // Game Logic
  // ══════════════════════════════════════════════════════════════
  initGrid() {
    const total = this.cols * this.rows;

    this.grid = Array(total).fill(0);
    this.revealed = Array(total).fill(false);
    this.flagged = Array(total).fill(false);
  },

  placeMines(safeIdx) {
    // Place mines avoiding first click
    let placed = 0;
    const total = this.cols * this.rows;

    while (placed < this.mines) {
      const idx = Math.floor(Math.random() * total);

      if (idx !== safeIdx && this.grid[idx] !== -1) {
        this.grid[idx] = -1;
        placed++;
      }
    }

    // Calculate numbers
    for (let row = 0; row < this.rows; row++) {
      for (let col = 0; col < this.cols; col++) {
        const idx = row * this.cols + col;

        if (this.grid[idx] !== -1) {
          let count = 0;

          for (let dr = -1; dr <= 1; dr++) {
            for (let dc = -1; dc <= 1; dc++) {
              if (dr === 0 && dc === 0) continue;

              const nr = row + dr;
              const nc = col + dc;

              if (nr >= 0 && nr < this.rows && nc >= 0 && nc < this.cols) {
                const nidx = nr * this.cols + nc;
                if (this.grid[nidx] === -1) count++;
              }
            }
          }

          this.grid[idx] = count;
        }
      }
    }
  },

  revealCell(row, col) {
    if (row < 0 || row >= this.rows || col < 0 || col >= this.cols) return;

    const idx = row * this.cols + col;

    if (this.revealed[idx] || this.flagged[idx]) return;

    // First click - place mines
    if (this.firstClick) {
      this.placeMines(idx);
      this.firstClick = false;
      this.startTime = Date.now();
    }

    this.revealed[idx] = true;
    this.score += 10;

    // Hit mine
    if (this.grid[idx] === -1) {
      this.revealAllMines();
      this.gameOver();
      return;
    }

    // Empty cell - flood fill
    if (this.grid[idx] === 0) {
      for (let dr = -1; dr <= 1; dr++) {
        for (let dc = -1; dc <= 1; dc++) {
          if (dr === 0 && dc === 0) continue;
          this.revealCell(row + dr, col + dc);
        }
      }
    }

    this.platform.updateScore(this.score);
    this.platform.haptic('light');

    // Check win
    this.checkWin();
  },

  toggleFlag(row, col) {
    if (row < 0 || row >= this.rows || col < 0 || col >= this.cols) return;

    const idx = row * this.cols + col;

    if (this.revealed[idx]) return;

    this.flagged[idx] = !this.flagged[idx];
    this.platform.haptic('light');

    this.checkWin();
  },

  revealAllMines() {
    for (let i = 0; i < this.grid.length; i++) {
      if (this.grid[i] === -1) {
        this.revealed[i] = true;
      }
    }
  },

  checkWin() {
    let unrevealedSafe = 0;

    for (let i = 0; i < this.grid.length; i++) {
      if (!this.revealed[i] && this.grid[i] !== -1) {
        unrevealedSafe++;
      }
    }

    if (unrevealedSafe === 0) {
      this.gameWon = true;
      this.score += 1000;
      this.platform.updateScore(this.score);
      this.platform.haptic('success');
      setTimeout(() => this.gameOver(), 500);
    }
  },

  gameOver() {
    this.platform.haptic(this.gameWon ? 'success' : 'error');
    this.platform.gameOver(this.score);
  },

  // ══════════════════════════════════════════════════════════════
  // Input
  // ══════════════════════════════════════════════════════════════
  setupInput() {
    // Mouse click
    this.canvas.addEventListener('click', (e) => {
      if (!this.isPlaying || this.gameWon) return;

      const rect = this.canvas.getBoundingClientRect();
      const x = e.clientX - rect.left;
      const y = e.clientY - rect.top;

      const { col, row } = this.getCellFromPos(x, y);
      if (col !== -1) {
        this.revealCell(row, col);
      }
    });

    // Right click for flag
    this.canvas.addEventListener('contextmenu', (e) => {
      e.preventDefault();

      if (!this.isPlaying || this.gameWon) return;

      const rect = this.canvas.getBoundingClientRect();
      const x = e.clientX - rect.left;
      const y = e.clientY - rect.top;

      const { col, row } = this.getCellFromPos(x, y);
      if (col !== -1) {
        this.toggleFlag(row, col);
      }
    });

    // Touch
    let touchTimeout = null;

    this.canvas.addEventListener('touchstart', (e) => {
      if (!this.isPlaying || this.gameWon) return;

      const rect = this.canvas.getBoundingClientRect();
      const x = e.touches[0].clientX - rect.left;
      const y = e.touches[0].clientY - rect.top;

      const { col, row } = this.getCellFromPos(x, y);
      if (col === -1) return;

      // Long press = flag
      touchTimeout = setTimeout(() => {
        this.toggleFlag(row, col);
        touchTimeout = null;
      }, 500);
    });

    this.canvas.addEventListener('touchend', (e) => {
      if (!this.isPlaying || this.gameWon) return;

      if (touchTimeout) {
        clearTimeout(touchTimeout);

        const rect = this.canvas.getBoundingClientRect();
        const x = e.changedTouches[0].clientX - rect.left;
        const y = e.changedTouches[0].clientY - rect.top;

        const { col, row } = this.getCellFromPos(x, y);
        if (col !== -1) {
          this.revealCell(row, col);
        }
      }

      touchTimeout = null;
    });
  },

  getCellFromPos(x, y) {
    const boardWidth = this.cols * this.cellSize;
    const boardHeight = this.rows * this.cellSize;
    const offsetX = (this.canvas.width - boardWidth) / 2;
    const offsetY = (this.canvas.height - boardHeight) / 2 + 40;

    const col = Math.floor((x - offsetX) / this.cellSize);
    const row = Math.floor((y - offsetY) / this.cellSize);

    if (col >= 0 && col < this.cols && row >= 0 && row < this.rows) {
      return { col, row };
    }

    return { col: -1, row: -1 };
  },

  // ══════════════════════════════════════════════════════════════
  // Helpers
  // ══════════════════════════════════════════════════════════════
  calculateSizes() {
    const maxSize = Math.min(this.canvas.width, this.canvas.height) - 100;
    this.cellSize = Math.floor(maxSize / Math.max(this.cols, this.rows));
    this.cellSize = Math.min(40, this.cellSize);
  },

  onResize(width, height) {
    this.calculateSizes();
  },
};
