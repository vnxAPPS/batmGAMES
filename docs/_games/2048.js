/**
 * 2048 - Classic
 * ══════════════════════════════════════════════════════════════
 * Классическая игра 2048 для batmGAMES Platform
 * ══════════════════════════════════════════════════════════════
 */

export default {
  // ══════════════════════════════════════════════════════════════
  // Game Metadata
  // ══════════════════════════════════════════════════════════════
  meta: {
    slug: '2048',
    title: '2048',
    description: 'Сдвигай плитки, складывай числа. Дойди до 2048!',
    category: 'puzzle',
  },

  // ══════════════════════════════════════════════════════════════
  // Game State
  // ══════════════════════════════════════════════════════════════
  canvas: null,
  ctx: null,
  platform: null,
  isPlaying: false,

  size: 4,
  grid: [],
  score: 0,
  bestScore: 0,

  tileSize: 100,
  gap: 10,

  colors: {
    0: '#1a1f2e',
    2: '#eee4da',
    4: '#ede0c8',
    8: '#f2b179',
    16: '#f59563',
    32: '#f67c5f',
    64: '#f65e3b',
    128: '#edcf72',
    256: '#edcc61',
    512: '#edc850',
    1024: '#edc53f',
    2048: '#edc22e',
    4096: '#3c3a32',
    8192: '#3c3a32',
  },

  textColors: {
    2: '#776e65',
    4: '#776e65',
    8: '#f9f6f2',
    16: '#f9f6f2',
    32: '#f9f6f2',
    64: '#f9f6f2',
    128: '#f9f6f2',
    256: '#f9f6f2',
    512: '#f9f6f2',
    1024: '#f9f6f2',
    2048: '#f9f6f2',
    4096: '#f9f6f2',
    8192: '#f9f6f2',
  },

  // Animation
  animating: false,
  mergedCells: [],

  // ══════════════════════════════════════════════════════════════
  // Lifecycle: Init
  // ══════════════════════════════════════════════════════════════
  init(canvas, platform) {
    console.log('🔢 2048: init');

    this.canvas = canvas;
    this.ctx = canvas.getContext('2d');
    this.platform = platform;

    // Load best score
    this.bestScore = parseInt(localStorage.getItem('batmGAMES_2048_best') || '0');

    this.calculateSizes();
    this.setupInput();
  },

  // ══════════════════════════════════════════════════════════════
  // Lifecycle: Start
  // ══════════════════════════════════════════════════════════════
  start() {
    console.log('▶️ 2048: start');

    this.isPlaying = true;
    this.score = 0;
    this.animating = false;
    this.mergedCells = [];

    // Initialize grid
    this.grid = Array.from({ length: this.size }, () =>
      Array(this.size).fill(0)
    );

    // Add initial tiles
    this.addRandomTile();
    this.addRandomTile();

    this.gameLoop();
  },

  // ══════════════════════════════════════════════════════════════
  // Lifecycle: Stop
  // ══════════════════════════════════════════════════════════════
  stop() {
    console.log('⏸️ 2048: stop');
    this.isPlaying = false;
  },

  // ══════════════════════════════════════════════════════════════
  // Lifecycle: Cleanup
  // ══════════════════════════════════════════════════════════════
  cleanup() {
    console.log('🧹 2048: cleanup');
    this.stop();
  },

  // ══════════════════════════════════════════════════════════════
  // Game Loop
  // ══════════════════════════════════════════════════════════════
  gameLoop() {
    if (!this.isPlaying) return;

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

    const boardSize = this.size * this.tileSize + (this.size + 1) * this.gap;
    const offsetX = (canvas.width - boardSize) / 2;
    const offsetY = (canvas.height - boardSize) / 2 + 40;

    // Draw score
    ctx.fillStyle = '#f2f4ff';
    ctx.font = 'bold 24px sans-serif';
    ctx.textAlign = 'center';
    ctx.fillText(`SCORE: ${this.score}`, canvas.width / 2, offsetY - 50);

    ctx.font = '14px sans-serif';
    ctx.fillStyle = '#8b92b0';
    ctx.fillText(`BEST: ${this.bestScore}`, canvas.width / 2, offsetY - 25);

    // Draw board background
    ctx.fillStyle = '#161d2b';
    ctx.fillRect(offsetX, offsetY, boardSize, boardSize);

    // Draw tiles
    for (let row = 0; row < this.size; row++) {
      for (let col = 0; col < this.size; col++) {
        const value = this.grid[row][col];
        const x = offsetX + this.gap + col * (this.tileSize + this.gap);
        const y = offsetY + this.gap + row * (this.tileSize + this.gap);

        // Empty cell
        if (value === 0) {
          ctx.fillStyle = '#1a1f2e';
          ctx.fillRect(x, y, this.tileSize, this.tileSize);
        } else {
          // Tile
          const color = this.colors[value] || this.colors[8192];
          ctx.fillStyle = color;
          ctx.fillRect(x, y, this.tileSize, this.tileSize);

          // Value
          const textColor = this.textColors[value] || '#f9f6f2';
          ctx.fillStyle = textColor;

          const fontSize = value < 100 ? 48 : value < 1000 ? 40 : 32;
          ctx.font = `bold ${fontSize}px sans-serif`;
          ctx.textAlign = 'center';
          ctx.textBaseline = 'middle';
          ctx.fillText(value.toString(), x + this.tileSize / 2, y + this.tileSize / 2);
        }
      }
    }

    ctx.textAlign = 'start';
    ctx.textBaseline = 'alphabetic';
  },

  // ══════════════════════════════════════════════════════════════
  // Game Logic
  // ══════════════════════════════════════════════════════════════
  move(direction) {
    if (this.animating) return;

    const oldGrid = this.grid.map(row => [...row]);
    let moved = false;

    if (direction === 'left') {
      moved = this.moveLeft();
    } else if (direction === 'right') {
      moved = this.moveRight();
    } else if (direction === 'up') {
      moved = this.moveUp();
    } else if (direction === 'down') {
      moved = this.moveDown();
    }

    if (moved) {
      this.addRandomTile();
      this.platform.updateScore(this.score);

      if (this.score > this.bestScore) {
        this.bestScore = this.score;
        localStorage.setItem('batmGAMES_2048_best', this.bestScore.toString());
      }

      // Check game over
      if (!this.canMove()) {
        setTimeout(() => this.gameOver(), 300);
      }
    }
  },

  moveLeft() {
    let moved = false;
    for (let row = 0; row < this.size; row++) {
      const line = this.grid[row].filter(x => x !== 0);
      const merged = this.mergeLine(line);

      while (merged.length < this.size) {
        merged.push(0);
      }

      for (let col = 0; col < this.size; col++) {
        if (this.grid[row][col] !== merged[col]) {
          moved = true;
        }
        this.grid[row][col] = merged[col];
      }
    }
    return moved;
  },

  moveRight() {
    let moved = false;
    for (let row = 0; row < this.size; row++) {
      const line = this.grid[row].filter(x => x !== 0);
      const merged = this.mergeLine(line);

      while (merged.length < this.size) {
        merged.unshift(0);
      }

      for (let col = 0; col < this.size; col++) {
        if (this.grid[row][col] !== merged[col]) {
          moved = true;
        }
        this.grid[row][col] = merged[col];
      }
    }
    return moved;
  },

  moveUp() {
    let moved = false;
    for (let col = 0; col < this.size; col++) {
      const line = [];
      for (let row = 0; row < this.size; row++) {
        if (this.grid[row][col] !== 0) {
          line.push(this.grid[row][col]);
        }
      }

      const merged = this.mergeLine(line);

      while (merged.length < this.size) {
        merged.push(0);
      }

      for (let row = 0; row < this.size; row++) {
        if (this.grid[row][col] !== merged[row]) {
          moved = true;
        }
        this.grid[row][col] = merged[row];
      }
    }
    return moved;
  },

  moveDown() {
    let moved = false;
    for (let col = 0; col < this.size; col++) {
      const line = [];
      for (let row = 0; row < this.size; row++) {
        if (this.grid[row][col] !== 0) {
          line.push(this.grid[row][col]);
        }
      }

      const merged = this.mergeLine(line);

      while (merged.length < this.size) {
        merged.unshift(0);
      }

      for (let row = 0; row < this.size; row++) {
        if (this.grid[row][col] !== merged[row]) {
          moved = true;
        }
        this.grid[row][col] = merged[row];
      }
    }
    return moved;
  },

  mergeLine(line) {
    const result = [];
    let i = 0;

    while (i < line.length) {
      if (i + 1 < line.length && line[i] === line[i + 1]) {
        const merged = line[i] * 2;
        result.push(merged);
        this.score += merged;
        this.platform.haptic('light');
        i += 2;
      } else {
        result.push(line[i]);
        i++;
      }
    }

    return result;
  },

  addRandomTile() {
    const emptyCells = [];
    for (let row = 0; row < this.size; row++) {
      for (let col = 0; col < this.size; col++) {
        if (this.grid[row][col] === 0) {
          emptyCells.push({ row, col });
        }
      }
    }

    if (emptyCells.length > 0) {
      const { row, col } = emptyCells[Math.floor(Math.random() * emptyCells.length)];
      this.grid[row][col] = Math.random() < 0.9 ? 2 : 4;
    }
  },

  canMove() {
    // Check for empty cells
    for (let row = 0; row < this.size; row++) {
      for (let col = 0; col < this.size; col++) {
        if (this.grid[row][col] === 0) return true;
      }
    }

    // Check for possible merges
    for (let row = 0; row < this.size; row++) {
      for (let col = 0; col < this.size; col++) {
        const value = this.grid[row][col];

        // Check right
        if (col < this.size - 1 && this.grid[row][col + 1] === value) {
          return true;
        }

        // Check down
        if (row < this.size - 1 && this.grid[row + 1][col] === value) {
          return true;
        }
      }
    }

    return false;
  },

  gameOver() {
    this.platform.haptic('error');
    this.platform.gameOver(this.score);
  },

  // ══════════════════════════════════════════════════════════════
  // Input
  // ══════════════════════════════════════════════════════════════
  setupInput() {
    // Keyboard
    document.addEventListener('keydown', (e) => {
      if (!this.isPlaying) return;

      if (e.key === 'ArrowLeft') {
        this.move('left');
        e.preventDefault();
      } else if (e.key === 'ArrowRight') {
        this.move('right');
        e.preventDefault();
      } else if (e.key === 'ArrowUp') {
        this.move('up');
        e.preventDefault();
      } else if (e.key === 'ArrowDown') {
        this.move('down');
        e.preventDefault();
      }
    });

    // Touch swipe
    let touchStartX = 0;
    let touchStartY = 0;

    this.canvas.addEventListener('touchstart', (e) => {
      touchStartX = e.touches[0].clientX;
      touchStartY = e.touches[0].clientY;
    });

    this.canvas.addEventListener('touchend', (e) => {
      if (!this.isPlaying) return;

      const touchEndX = e.changedTouches[0].clientX;
      const touchEndY = e.changedTouches[0].clientY;

      const dx = touchEndX - touchStartX;
      const dy = touchEndY - touchStartY;

      const minSwipe = 30;

      if (Math.abs(dx) > Math.abs(dy) && Math.abs(dx) > minSwipe) {
        this.move(dx > 0 ? 'right' : 'left');
      } else if (Math.abs(dy) > minSwipe) {
        this.move(dy > 0 ? 'down' : 'up');
      }
    });
  },

  // ══════════════════════════════════════════════════════════════
  // Helpers
  // ══════════════════════════════════════════════════════════════
  calculateSizes() {
    const maxSize = Math.min(this.canvas.width, this.canvas.height) - 120;
    this.tileSize = Math.floor((maxSize - (this.size + 1) * this.gap) / this.size);
  },

  onResize(width, height) {
    this.calculateSizes();
  },
};
