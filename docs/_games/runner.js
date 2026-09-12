/**
 * Simple Runner Game - Example
 * ══════════════════════════════════════════════════════════════
 * Демонстрирует базовый Game API для batmGAMES Platform
 * ══════════════════════════════════════════════════════════════
 */

export default {
  // ══════════════════════════════════════════════════════════════
  // Game Metadata
  // ══════════════════════════════════════════════════════════════
  meta: {
    slug: 'runner',
    title: 'Roblox Runner',
    description: 'Беги и перепрыгивай кубики! Чем дальше — тем быстрее.',
    category: 'arcade',
  },

  // ══════════════════════════════════════════════════════════════
  // Game State
  // ══════════════════════════════════════════════════════════════
  canvas: null,
  ctx: null,
  platform: null,
  isPlaying: false,
  score: 0,
  speed: 3,

  player: {
    x: 100,
    y: 0,
    width: 40,
    height: 40,
    velocityY: 0,
    jumping: false,
  },

  obstacles: [],
  obstacleTimer: 0,
  obstacleInterval: 120, // frames

  ground: 300,
  gravity: 0.6,
  jumpForce: -12,

  // ══════════════════════════════════════════════════════════════
  // Lifecycle: Init
  // ══════════════════════════════════════════════════════════════
  init(canvas, platform) {
    console.log('🎮 Runner: init');

    this.canvas = canvas;
    this.ctx = canvas.getContext('2d');
    this.platform = platform;

    // Setup input
    this.setupInput();

    // Position player on ground
    this.player.y = this.ground - this.player.height;
  },

  // ══════════════════════════════════════════════════════════════
  // Lifecycle: Start
  // ══════════════════════════════════════════════════════════════
  start() {
    console.log('▶️ Runner: start');

    this.isPlaying = true;
    this.score = 0;
    this.speed = 3;
    this.obstacles = [];
    this.obstacleTimer = 0;

    this.player.y = this.ground - this.player.height;
    this.player.velocityY = 0;
    this.player.jumping = false;

    this.gameLoop();
  },

  // ══════════════════════════════════════════════════════════════
  // Lifecycle: Stop
  // ══════════════════════════════════════════════════════════════
  stop() {
    console.log('⏸️ Runner: stop');
    this.isPlaying = false;
  },

  // ══════════════════════════════════════════════════════════════
  // Lifecycle: Cleanup
  // ══════════════════════════════════════════════════════════════
  cleanup() {
    console.log('🧹 Runner: cleanup');
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
    // Update score
    this.score += 1;
    this.platform.updateScore(Math.floor(this.score / 10));

    // Increase speed gradually
    this.speed += 0.001;

    // Player physics
    this.player.velocityY += this.gravity;
    this.player.y += this.player.velocityY;

    // Ground collision
    if (this.player.y >= this.ground - this.player.height) {
      this.player.y = this.ground - this.player.height;
      this.player.velocityY = 0;
      this.player.jumping = false;
    }

    // Spawn obstacles
    this.obstacleTimer++;
    if (this.obstacleTimer >= this.obstacleInterval) {
      this.spawnObstacle();
      this.obstacleTimer = 0;
      // Decrease interval (spawn faster)
      this.obstacleInterval = Math.max(60, this.obstacleInterval - 1);
    }

    // Update obstacles
    for (let i = this.obstacles.length - 1; i >= 0; i--) {
      const obs = this.obstacles[i];
      obs.x -= this.speed;

      // Remove off-screen obstacles
      if (obs.x + obs.width < 0) {
        this.obstacles.splice(i, 1);
        continue;
      }

      // Collision detection
      if (this.checkCollision(this.player, obs)) {
        this.gameOver();
      }
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

    // Ground line
    ctx.strokeStyle = '#ff7000';
    ctx.lineWidth = 2;
    ctx.beginPath();
    ctx.moveTo(0, this.ground);
    ctx.lineTo(canvas.width, this.ground);
    ctx.stroke();

    // Player (use platform character renderer)
    this.platform.renderCharacter(
      ctx,
      this.player.x + this.player.width / 2,
      this.player.y + this.player.height / 2,
      this.player.width
    );

    // Obstacles
    ctx.fillStyle = '#ff4500';
    for (const obs of this.obstacles) {
      ctx.fillRect(obs.x, obs.y, obs.width, obs.height);
    }
  },

  // ══════════════════════════════════════════════════════════════
  // Helpers
  // ══════════════════════════════════════════════════════════════
  spawnObstacle() {
    this.obstacles.push({
      x: this.canvas.width,
      y: this.ground - 40,
      width: 30,
      height: 40,
    });
  },

  checkCollision(a, b) {
    return (
      a.x < b.x + b.width &&
      a.x + a.width > b.x &&
      a.y < b.y + b.height &&
      a.y + a.height > b.y
    );
  },

  gameOver() {
    const finalScore = Math.floor(this.score / 10);
    this.platform.gameOver(finalScore);
  },

  // ══════════════════════════════════════════════════════════════
  // Input
  // ══════════════════════════════════════════════════════════════
  setupInput() {
    // Jump on tap/click/space
    const jump = () => {
      if (!this.isPlaying) return;
      if (!this.player.jumping) {
        this.player.velocityY = this.jumpForce;
        this.player.jumping = true;
        this.platform.haptic('light');
      }
    };

    this.canvas.addEventListener('pointerdown', jump);

    document.addEventListener('keydown', (e) => {
      if (e.key === ' ' || e.key === 'ArrowUp') {
        e.preventDefault();
        jump();
      }
    });
  },

  // ══════════════════════════════════════════════════════════════
  // Resize Handler (optional)
  // ══════════════════════════════════════════════════════════════
  onResize(width, height) {
    // Adjust ground position for new canvas size
    this.ground = height * 0.7;
  },
};
