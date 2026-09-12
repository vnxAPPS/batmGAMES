/**
 * batmGAMES Platform Core v3.0
 * ══════════════════════════════════════════════════════════════
 * Единая платформа для всех игр.
 * Управляет lifecycle, UI, персонажами, рекордами.
 * ══════════════════════════════════════════════════════════════
 */

const TG = window.Telegram?.WebApp;

class BatmGamesPlatform {
  constructor() {
    this.currentGame = null;
    this.user = this.loadUser();
    this.canvas = null;
    this.ctx = null;
    this.state = 'idle'; // idle, playing, paused, gameover

    // UI elements
    this.elements = {};

    // Bind methods
    this.handlePlayClick = this.handlePlayClick.bind(this);
    this.handleRetryClick = this.handleRetryClick.bind(this);
    this.handleMenuClick = this.handleMenuClick.bind(this);
    this.handleBackClick = this.handleBackClick.bind(this);
  }

  // ══════════════════════════════════════════════════════════════
  // Initialization
  // ══════════════════════════════════════════════════════════════

  init() {
    // Get DOM elements
    this.canvas = document.getElementById('game-canvas');
    this.ctx = this.canvas?.getContext('2d');

    this.elements = {
      overlayScreen: document.getElementById('overlay-screen'),
      startScreen: document.getElementById('start-screen'),
      gameoverScreen: document.getElementById('gameover-screen'),
      gameTitle: document.getElementById('game-title'),
      gameDesc: document.getElementById('game-desc'),
      bestScore: document.getElementById('best-score'),
      scoreDisplay: document.getElementById('score-display'),
      scoreResult: document.getElementById('score-result'),
      newRecord: document.getElementById('new-record'),
      characterPreview: document.getElementById('character-preview'),
      characterResult: document.getElementById('character-result'),
      playBtn: document.getElementById('play-btn'),
      retryBtn: document.getElementById('retry-btn'),
      menuBtn: document.getElementById('menu-btn'),
      backBtn: document.getElementById('back-btn'),
    };

    // Setup event listeners
    this.setupEventListeners();

    // Init Telegram WebApp
    if (TG) {
      TG.ready();
      TG.expand();
    }

    console.log('✅ Platform initialized');
  }

  setupEventListeners() {
    this.elements.playBtn?.addEventListener('click', this.handlePlayClick);
    this.elements.retryBtn?.addEventListener('click', this.handleRetryClick);
    this.elements.menuBtn?.addEventListener('click', this.handleMenuClick);
    this.elements.backBtn?.addEventListener('click', this.handleBackClick);
  }

  // ══════════════════════════════════════════════════════════════
  // Game Lifecycle
  // ══════════════════════════════════════════════════════════════

  async loadGame(slug) {
    try {
      console.log(`🎮 Loading game: ${slug}`);

      // Dynamic import of game module
      const gameModule = await import(`../_games/${slug}.js`);
      this.currentGame = gameModule.default;

      // Validate game API
      if (!this.currentGame.meta || !this.currentGame.init) {
        throw new Error('Invalid game module: missing meta or init');
      }

      // Initialize game
      this.currentGame.init(this.canvas, this);

      // Setup canvas size
      this.resizeCanvas();
      window.addEventListener('resize', () => this.resizeCanvas());

      // Show start screen
      this.showStartScreen();

      console.log(`✅ Game loaded: ${this.currentGame.meta.title}`);
    } catch (error) {
      console.error('❌ Failed to load game:', error);
      this.showError(`Не удалось загрузить игру: ${slug}`);
    }
  }

  resizeCanvas() {
    if (!this.canvas) return;

    const container = this.canvas.parentElement;
    const rect = container.getBoundingClientRect();

    this.canvas.width = rect.width;
    this.canvas.height = rect.height;

    // Notify game about resize
    if (this.currentGame?.onResize) {
      this.currentGame.onResize(rect.width, rect.height);
    }
  }

  showStartScreen() {
    this.state = 'idle';

    // Set game info
    this.elements.gameTitle.textContent = this.currentGame.meta.title;
    this.elements.gameDesc.textContent = this.currentGame.meta.description;

    // Show best record
    const record = this.getRecord(this.currentGame.meta.slug);
    if (record) {
      this.elements.bestScore.innerHTML =
        `🏆 Лучший результат: <strong>${record.score}</strong>`;
      this.elements.bestScore.classList.remove('hidden');
    } else {
      this.elements.bestScore.classList.add('hidden');
    }

    // Render character preview
    this.renderCharacterPreview();

    // Show screens
    this.elements.startScreen.classList.remove('hidden');
    this.elements.gameoverScreen.classList.add('hidden');
    this.elements.overlayScreen.classList.remove('hidden');

    // Reset score display
    this.updateScore(0);
  }

  handlePlayClick() {
    this.startGame();
  }

  startGame() {
    if (!this.currentGame) return;

    this.state = 'playing';

    // Hide overlay
    this.elements.overlayScreen.classList.add('hidden');

    // Start game
    this.currentGame.start();

    // Haptic feedback
    this.haptic('medium');

    console.log('▶️ Game started');
  }

  gameOver(score) {
    if (this.state !== 'playing') return;

    this.state = 'gameover';

    // Stop game
    if (this.currentGame?.stop) {
      this.currentGame.stop();
    }

    // Save record
    const isNewRecord = this.saveRecord(this.currentGame.meta.slug, score);

    // Show game over screen
    this.showGameOverScreen(score, isNewRecord);

    console.log(`🏁 Game over. Score: ${score}, New record: ${isNewRecord}`);
  }

  showGameOverScreen(score, isNewRecord) {
    // Set score
    this.elements.scoreResult.innerHTML =
      `Ваш счёт: <strong>${score}</strong>`;

    // Show new record badge
    if (isNewRecord) {
      this.elements.newRecord.classList.remove('hidden');
      this.haptic('success');
    } else {
      this.elements.newRecord.classList.add('hidden');
    }

    // Render character
    this.renderCharacterResult();

    // Show screens
    this.elements.gameoverScreen.classList.remove('hidden');
    this.elements.startScreen.classList.add('hidden');
    this.elements.overlayScreen.classList.remove('hidden');
  }

  handleRetryClick() {
    this.retryGame();
  }

  retryGame() {
    // Hide game over screen
    this.elements.gameoverScreen.classList.add('hidden');
    this.elements.newRecord.classList.add('hidden');

    // Restart game
    this.startGame();
  }

  handleMenuClick() {
    this.exitToMenu();
  }

  handleBackClick() {
    if (this.state === 'playing') {
      // Pause and show confirmation?
      this.gameOver(0);
    } else {
      this.exitToMenu();
    }
  }

  exitToMenu() {
    // Cleanup game
    if (this.currentGame?.cleanup) {
      this.currentGame.cleanup();
    }

    // Go to main menu
    window.location.href = 'index.html';
  }

  showError(message) {
    alert(message);
    this.exitToMenu();
  }

  // ══════════════════════════════════════════════════════════════
  // Character Rendering
  // ══════════════════════════════════════════════════════════════

  renderCharacter(ctx, x, y, size = 40) {
    const char = this.user.character;

    // Simple block character (Roblox style)
    // Legs
    ctx.fillStyle = char.legs_color;
    ctx.fillRect(x - size * 0.25, y + size * 0.5, size * 0.5, size * 0.5);

    // Torso
    ctx.fillStyle = char.torso_color;
    ctx.fillRect(x - size * 0.33, y, size * 0.66, size * 0.5);

    // Arms
    ctx.fillStyle = char.arms_color;
    ctx.fillRect(x - size * 0.5, y + size * 0.16, size * 0.16, size * 0.33);
    ctx.fillRect(x + size * 0.33, y + size * 0.16, size * 0.16, size * 0.33);

    // Head
    ctx.fillStyle = char.head_color;
    ctx.fillRect(x - size * 0.33, y - size * 0.5, size * 0.66, size * 0.5);

    // Hair (simple)
    ctx.fillStyle = '#3d2817';
    ctx.fillRect(x - size * 0.33, y - size * 0.5 - size * 0.16, size * 0.66, size * 0.16);

    // Face (eyes)
    ctx.fillStyle = '#000';
    ctx.fillRect(x - size * 0.16, y - size * 0.33, size * 0.12, size * 0.12);
    ctx.fillRect(x + size * 0.08, y - size * 0.33, size * 0.12, size * 0.12);
  }

  renderCharacterPreview() {
    if (!this.elements.characterPreview) return;

    const canvas = document.createElement('canvas');
    canvas.width = 120;
    canvas.height = 150;
    const ctx = canvas.getContext('2d');

    this.renderCharacter(ctx, 60, 75, 60);

    this.elements.characterPreview.innerHTML = '';
    this.elements.characterPreview.appendChild(canvas);
  }

  renderCharacterResult() {
    if (!this.elements.characterResult) return;

    const canvas = document.createElement('canvas');
    canvas.width = 100;
    canvas.height = 120;
    const ctx = canvas.getContext('2d');

    this.renderCharacter(ctx, 50, 60, 50);

    this.elements.characterResult.innerHTML = '';
    this.elements.characterResult.appendChild(canvas);
  }

  // ══════════════════════════════════════════════════════════════
  // UI Updates
  // ══════════════════════════════════════════════════════════════

  updateScore(score) {
    if (this.elements.scoreDisplay) {
      this.elements.scoreDisplay.textContent = score;
    }
  }

  // ══════════════════════════════════════════════════════════════
  // User & Storage
  // ══════════════════════════════════════════════════════════════

  loadUser() {
    const u = TG?.initDataUnsafe?.user || {};
    const character = JSON.parse(localStorage.getItem('batm_character') || 'null') || {
      name: u.first_name || 'Игрок',
      legs_color: '#2d4fd6',
      torso_color: '#22c55e',
      arms_color: '#ffd23e',
      head_color: '#ffd23e',
      hair_style: 'default',
      face_emotion: 'smile',
    };

    return {
      id: u.id || 0,
      username: u.username || 'guest',
      first_name: u.first_name || 'Игрок',
      character,
    };
  }

  saveRecord(gameSlug, score) {
    const key = `record_${gameSlug}_${this.user.id}`;
    const cur = JSON.parse(localStorage.getItem(key) || '{"score":0}');

    if (score > cur.score) {
      localStorage.setItem(key, JSON.stringify({
        score,
        date: new Date().toISOString(),
      }));
      return true;
    }

    return false;
  }

  getRecord(gameSlug) {
    const key = `record_${gameSlug}_${this.user.id}`;
    return JSON.parse(localStorage.getItem(key) || 'null');
  }

  // ══════════════════════════════════════════════════════════════
  // Utilities
  // ══════════════════════════════════════════════════════════════

  haptic(type = 'light') {
    const hf = TG?.HapticFeedback;
    if (!hf) return;

    if (type === 'error' || type === 'success' || type === 'warning') {
      hf.notificationOccurred(type);
    } else {
      hf.impactOccurred(type);
    }
  }

  toast(message, type = 'info') {
    // Simple toast (можно улучшить)
    console.log(`[${type.toUpperCase()}] ${message}`);
  }
}

// ══════════════════════════════════════════════════════════════
// Export
// ══════════════════════════════════════════════════════════════

export default new BatmGamesPlatform();
