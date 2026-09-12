/**
 * Tetris - Classic
 * ══════════════════════════════════════════════════════════════
 * Классический тетрис для batmGAMES Platform
 * ══════════════════════════════════════════════════════════════
 */

export default {
  // ══════════════════════════════════════════════════════════════
  // Game Metadata
  // ══════════════════════════════════════════════════════════════
  meta: {
    slug: 'tetris',
    title: 'Tetris',
    description: 'Классика! Складывай фигуры, убирай линии, не дай столбику дорасти до верха.',
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
  rows: 20,
  blockSize: 30,
  board: [],

  currentPiece: null,
  currentX: 0,
  currentY: 0,

  nextPiece: null,
  score: 0,
  lines: 0,
  level: 1,

  dropInterval: 1000,
  lastDrop: 0,
  fastDrop: false,

  // Tetromino shapes
  pieces: {
    I: [[1,1,1,1]],
    O: [[1,1],[1,1]],
    T: [[0,1,0],[1,1,1]],
    S: [[0,1,1],[1,1,0]],
    Z: [[1,1,0],[0,1,1]],
    J: [[1,0,0],[1,1,1]],
    L: [[0,0,1],[1,1,1]],
  },

  colors: {
    I: '#00f0f0',
    O: '#f0f000',
    T: '#a000f0',
    S: '#00f000',
    Z: '#f00000',
    J: '#0000f0',
    L: '#f0a000',
  },

  // ══════════════════════════════════════════════════════════════
  // Lifecycle: Init
  // ══════════════════════════════════════════════════════════════
  init(canvas, platform) {
    console.log('🟪 Tetris: init');

    this.canvas = canvas;
    this.ctx = canvas.getContext('2d');
    this.platform = platform;

    // Adjust canvas size for tetris
    this.blockSize = Math.floor(Math.min(
      canvas.width / (this.cols + 6),
      canvas.height / this.rows
    ));

    this.setupInput();
  },

  // ══════════════════════════════════════════════════════════════
  // Lifecycle: Start
  // ══════════════════════════════════════════════════════════════
  start() {
    console.log('▶️ Tetris: start');

    this.isPlaying = true;
    this.score = 0;
    this.lines = 0;
    this.level = 1;
    this.dropInterval = 1000;
    this.lastDrop = Date.now();
    this.fastDrop = false;

    // Initialize board
    this.board = Array.from({ length: this.rows }, () =>
      Array(this.cols).fill(0)
    );

    // Spawn first pieces
    this.nextPiece = this.randomPiece();
    this.spawnPiece();

    this.gameLoop();
  },

  // ══════════════════════════════════════════════════════════════
  // Lifecycle: Stop
  // ══════════════════════════════════════════════════════════════
  stop() {
    console.log('⏸️ Tetris: stop');
    this.isPlaying = false;
  },

  // ══════════════════════════════════════════════════════════════
  // Lifecycle: Cleanup
  // ══════════════════════════════════════════════════════════════
  cleanup() {
    console.log('🧹 Tetris: cleanup');
    this.stop();
  },

  // ══════════════════════════════════════════════════════════════
  // Game Loop
  // ══════════════════════════════════════════════════════════════
  gameLoop() {
    if (!this.isPlaying) return;

    this.update();
    this.render();
    requestAnimationFrame(() => this.gameLoop());
  },

  // ══════════════════════════════════════════════════════════════
  // Update Logic
  // ══════════════════════════════════════════════════════════════
  update() {
    const now = Date.now();
    const interval = this.fastDrop ? 50 : this.dropInterval;

    if (now - this.lastDrop > interval) {
      if (!this.move(0, 1)) {
        this.lockPiece();
        this.clearLines();
        this.spawnPiece();

        // Check game over
        if (this.collision(this.currentPiece.shape, this.currentX, this.currentY)) {
          this.gameOver();
          return;
        }
      }
      this.lastDrop = now;
    }
  },

  // ══════════════════════════════════════════════════════════════
  // Render
  // ══════════════════════════════════════════════════════════════
  render() {
    const { ctx, canvas } = this;

    // Clear
    ctx.fillStyle = '#0a0d12';
    ctx.fillRect(0, 0, canvas.width, canvas.height);

    const boardX = Math.floor((canvas.width - this.cols * this.blockSize) / 2);
    const boardY = Math.floor((canvas.height - this.rows * this.blockSize) / 2);

    // Draw board background
    ctx.fillStyle = '#161d2b';
    ctx.fillRect(boardX, boardY, this.cols * this.blockSize, this.rows * this.blockSize);

    // Draw grid
    ctx.strokeStyle = 'rgba(255, 255, 255, 0.05)';
    ctx.lineWidth = 1;
    for (let row = 0; row <= this.rows; row++) {
      ctx.beginPath();
      ctx.moveTo(boardX, boardY + row * this.blockSize);
      ctx.lineTo(boardX + this.cols * this.blockSize, boardY + row * this.blockSize);
      ctx.stroke();
    }
    for (let col = 0; col <= this.cols; col++) {
      ctx.beginPath();
      ctx.moveTo(boardX + col * this.blockSize, boardY);
      ctx.lineTo(boardX + col * this.blockSize, boardY + this.rows * this.blockSize);
      ctx.stroke();
    }

    // Draw locked blocks
    for (let row = 0; row < this.rows; row++) {
      for (let col = 0; col < this.cols; col++) {
        if (this.board[row][col]) {
          this.drawBlock(
            boardX + col * this.blockSize,
            boardY + row * this.blockSize,
            this.board[row][col]
          );
        }
      }
    }

    // Draw current piece
    if (this.currentPiece) {
      const shape = this.currentPiece.shape;
      const color = this.currentPiece.color;

      for (let row = 0; row < shape.length; row++) {
        for (let col = 0; col < shape[row].length; col++) {
          if (shape[row][col]) {
            this.drawBlock(
              boardX + (this.currentX + col) * this.blockSize,
              boardY + (this.currentY + row) * this.blockSize,
              color
            );
          }
        }
      }
    }

    // Draw next piece preview
    this.drawNextPiece(boardX, boardY);

    // Draw stats
    this.drawStats(boardX, boardY);
  },

  drawBlock(x, y, color) {
    const { ctx } = this;
    const size = this.blockSize;

    ctx.fillStyle = color;
    ctx.fillRect(x + 1, y + 1, size - 2, size - 2);

    // Highlight
    ctx.fillStyle = 'rgba(255, 255, 255, 0.2)';
    ctx.fillRect(x + 1, y + 1, size - 2, 4);
  },

  drawNextPiece(boardX, boardY) {
    if (!this.nextPiece) return;

    const { ctx } = this;
    const previewX = boardX + this.cols * this.blockSize + 20;
    const previewY = boardY;

    ctx.fillStyle = '#f2f4ff';
    ctx.font = '14px sans-serif';
    ctx.fillText('NEXT', previewX, previewY + 14);

    const shape = this.nextPiece.shape;
    const color = this.nextPiece.color;

    for (let row = 0; row < shape.length; row++) {
      for (let col = 0; col < shape[row].length; col++) {
        if (shape[row][col]) {
          this.drawBlock(
            previewX + col * this.blockSize,
            previewY + 30 + row * this.blockSize,
            color
          );
        }
      }
    }
  },

  drawStats(boardX, boardY) {
    const { ctx } = this;
    const statsX = boardX - 100;
    const statsY = boardY;

    ctx.fillStyle = '#f2f4ff';
    ctx.font = '14px sans-serif';
    ctx.textAlign = 'left';

    ctx.fillText(`SCORE`, statsX, statsY + 14);
    ctx.fillText(`${this.score}`, statsX, statsY + 36);

    ctx.fillText(`LINES`, statsX, statsY + 70);
    ctx.fillText(`${this.lines}`, statsX, statsY + 92);

    ctx.fillText(`LEVEL`, statsX, statsY + 126);
    ctx.fillText(`${this.level}`, statsX, statsY + 148);

    ctx.textAlign = 'start';
  },

  // ══════════════════════════════════════════════════════════════
  // Game Logic
  // ══════════════════════════════════════════════════════════════
  randomPiece() {
    const types = Object.keys(this.pieces);
    const type = types[Math.floor(Math.random() * types.length)];
    return {
      type,
      shape: this.pieces[type],
      color: this.colors[type],
    };
  },

  spawnPiece() {
    this.currentPiece = this.nextPiece;
    this.nextPiece = this.randomPiece();

    this.currentX = Math.floor((this.cols - this.currentPiece.shape[0].length) / 2);
    this.currentY = 0;
  },

  move(dx, dy) {
    if (!this.collision(this.currentPiece.shape, this.currentX + dx, this.currentY + dy)) {
      this.currentX += dx;
      this.currentY += dy;
      return true;
    }
    return false;
  },

  rotate() {
    const rotated = this.currentPiece.shape[0].map((_, i) =>
      this.currentPiece.shape.map(row => row[i]).reverse()
    );

    if (!this.collision(rotated, this.currentX, this.currentY)) {
      this.currentPiece.shape = rotated;
      this.platform.haptic('light');
    }
  },

  collision(shape, x, y) {
    for (let row = 0; row < shape.length; row++) {
      for (let col = 0; col < shape[row].length; col++) {
        if (shape[row][col]) {
          const newX = x + col;
          const newY = y + row;

          if (newX < 0 || newX >= this.cols || newY >= this.rows) {
            return true;
          }

          if (newY >= 0 && this.board[newY][newX]) {
            return true;
          }
        }
      }
    }
    return false;
  },

  lockPiece() {
    const shape = this.currentPiece.shape;
    const color = this.currentPiece.color;

    for (let row = 0; row < shape.length; row++) {
      for (let col = 0; col < shape[row].length; col++) {
        if (shape[row][col]) {
          const boardY = this.currentY + row;
          const boardX = this.currentX + col;
          if (boardY >= 0) {
            this.board[boardY][boardX] = color;
          }
        }
      }
    }

    this.platform.haptic('medium');
  },

  clearLines() {
    let cleared = 0;

    for (let row = this.rows - 1; row >= 0; row--) {
      if (this.board[row].every(cell => cell !== 0)) {
        this.board.splice(row, 1);
        this.board.unshift(Array(this.cols).fill(0));
        cleared++;
        row++; // Check same row again
      }
    }

    if (cleared > 0) {
      this.lines += cleared;

      // Scoring
      const points = [0, 100, 300, 500, 800];
      this.score += points[cleared] * this.level;

      this.platform.updateScore(this.score);
      this.platform.haptic('success');

      // Level up every 10 lines
      const newLevel = Math.floor(this.lines / 10) + 1;
      if (newLevel > this.level) {
        this.level = newLevel;
        this.dropInterval = Math.max(100, 1000 - (this.level - 1) * 100);
      }
    }
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
        this.move(-1, 0);
        e.preventDefault();
      } else if (e.key === 'ArrowRight') {
        this.move(1, 0);
        e.preventDefault();
      } else if (e.key === 'ArrowDown') {
        this.fastDrop = true;
        e.preventDefault();
      } else if (e.key === 'ArrowUp' || e.key === ' ') {
        this.rotate();
        e.preventDefault();
      }
    });

    document.addEventListener('keyup', (e) => {
      if (e.key === 'ArrowDown') {
        this.fastDrop = false;
      }
    });

    // Touch controls
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

      if (Math.abs(dx) > Math.abs(dy)) {
        // Horizontal swipe
        if (dx > 30) {
          this.move(1, 0);
        } else if (dx < -30) {
          this.move(-1, 0);
        }
      } else {
        // Vertical swipe or tap
        if (dy > 50) {
          this.move(0, 1);
        } else if (Math.abs(dx) < 30 && Math.abs(dy) < 30) {
          // Tap = rotate
          this.rotate();
        }
      }
    });
  },

  // ══════════════════════════════════════════════════════════════
  // Resize Handler
  // ══════════════════════════════════════════════════════════════
  onResize(width, height) {
    this.blockSize = Math.floor(Math.min(
      width / (this.cols + 6),
      height / this.rows
    ));
  },
};
