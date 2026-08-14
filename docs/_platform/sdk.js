/**
 * batmGAMES Platform SDK v2
 * ─────────────────────────────────────────────────────────────────
 * Единая точка доступа к возможностям платформы.
 * Импорт: import Platform from '/_platform/sdk.js';
 *
 * Platform.user()             → данные игрока
 * Platform.save(key, val)     → сохранить значение
 * Platform.load(key, def)     → загрузить значение
 * Platform.saveRecord(slug, score) → сохранить рекорд
 * Platform.getRecord(slug)    → лучший рекорд
 * Platform.haptic(type)       → вибрация
 * Platform.toast(msg, type)   → всплывающее уведомление
 * Platform.expand()           → раскрыть Telegram окно
 * ─────────────────────────────────────────────────────────────────
 */

const TG = window.Telegram?.WebApp;

// ── Init ────────────────────────────────────────────────────────
if (TG) { TG.ready(); }

// ── User ────────────────────────────────────────────────────────
function user() {
  const u = TG?.initDataUnsafe?.user || {};
  const character = JSON.parse(localStorage.getItem('batm_character') || 'null') || {
    name:         u.first_name || 'Игрок',
    legs_color:   '#2d4fd6',
    torso_color:  '#22c55e',
    arms_color:   '#ffd23e',
    head_color:   '#ffd23e',
    hair_style:   'default',
    face_emotion: 'smile',
  };
  return {
    id:         u.id || 0,
    username:   u.username   || 'guest',
    first_name: u.first_name || 'Игрок',
    character,
  };
}

// ── Storage ─────────────────────────────────────────────────────
function save(key, value) {
  localStorage.setItem(`batm_${key}`, JSON.stringify(value));
}

function load(key, defaultValue = null) {
  const raw = localStorage.getItem(`batm_${key}`);
  try { return raw !== null ? JSON.parse(raw) : defaultValue; }
  catch { return defaultValue; }
}

// ── Records ─────────────────────────────────────────────────────
function saveRecord(gameSlug, score, meta = {}) {
  const u   = user();
  const key = `record_${gameSlug}_${u.id}`;
  const cur = load(key, { score: 0 });
  if (score > cur.score) {
    save(key, { score, meta, date: new Date().toISOString() });
    haptic('success');
    return true; // новый рекорд
  }
  return false;
}

function getRecord(gameSlug) {
  const u = user();
  return load(`record_${gameSlug}_${u.id}`, null);
}

// ── Haptics ─────────────────────────────────────────────────────
/**
 * @param {'light'|'medium'|'heavy'|'error'|'success'|'warning'} type
 */
function haptic(type = 'light') {
  const hf = TG?.HapticFeedback;
  if (!hf) return;
  if (type === 'error' || type === 'success' || type === 'warning') {
    hf.notificationOccurred(type);
  } else {
    hf.impactOccurred(type);
  }
}

// ── Toast ────────────────────────────────────────────────────────
let _toastEl = null;
let _toastTimer = null;

/**
 * @param {string} message
 * @param {'info'|'success'|'error'|'warning'} type
 * @param {number} duration ms
 */
function toast(message, type = 'info', duration = 2500) {
  if (!_toastEl) {
    _toastEl = document.createElement('div');
    _toastEl.style.cssText = `
      position: fixed;
      bottom: 80px;
      left: 50%;
      transform: translateX(-50%) translateY(20px);
      padding: 10px 22px;
      border-radius: 999px;
      font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", sans-serif;
      font-size: 14px;
      font-weight: 700;
      pointer-events: none;
      z-index: 9999;
      opacity: 0;
      transition: opacity 0.2s, transform 0.2s;
      white-space: nowrap;
    `;
    document.body.appendChild(_toastEl);
  }

  const styles = {
    info:    { bg: 'rgba(255,112,0,0.95)',  color: '#fff' },
    success: { bg: 'rgba(34,231,124,0.95)',  color: '#05070c' },
    error:   { bg: 'rgba(255,77,109,0.95)',  color: '#fff' },
    warning: { bg: 'rgba(255,185,56,0.95)',  color: '#05070c' },
  };
  const s = styles[type] || styles.info;
  _toastEl.style.background = s.bg;
  _toastEl.style.color      = s.color;
  _toastEl.textContent      = message;

  clearTimeout(_toastTimer);
  _toastEl.style.opacity   = '1';
  _toastEl.style.transform = 'translateX(-50%) translateY(0)';

  _toastTimer = setTimeout(() => {
    _toastEl.style.opacity   = '0';
    _toastEl.style.transform = 'translateX(-50%) translateY(20px)';
  }, duration);
}

// ── Expand ───────────────────────────────────────────────────────
function expand() {
  if (TG) TG.expand();
}

// ── Back button ─────────────────────────────────────────────────
/**
 * Рендерит неоновую кнопку "назад" внутри переданного контейнера.
 * @param {HTMLElement} container  — куда вставить кнопку
 * @param {string} href            — URL для перехода (default '../')
 * @returns {HTMLAnchorElement}
 */
function createBackButton(container, href = '../') {
  const a = document.createElement('a');
  a.href = href;
  a.className = 'batm-back-btn';
  a.innerHTML = '<span class="batm-back-arrow"></span>';

  // Inject styles once
  if (!document.getElementById('batm-back-style')) {
    const style = document.createElement('style');
    style.id = 'batm-back-style';
    style.textContent = `
      .batm-back-btn {
        display: flex;
        align-items: center;
        justify-content: center;
        width: 36px; height: 36px;
        text-decoration: none;
        border-radius: 10px;
        background: rgba(255,112,0,0.12);
        border: 1px solid rgba(255,112,0,0.35);
        box-shadow: 0 0 10px rgba(255,112,0,0.25),inset 0 0 8px rgba(255,112,0,0.08);
        transition: all 0.15s;
        flex-shrink: 0;
      }
      .batm-back-btn:active {
        transform: scale(0.92);
        box-shadow: 0 0 18px rgba(255,112,0,0.5),inset 0 0 12px rgba(255,112,0,0.15);
      }
      .batm-back-arrow {
        display: block;
        width: 14px; height: 14px;
        border-left: 2.5px solid #ff7000;
        border-bottom: 2.5px solid #ff7000;
        transform: rotate(45deg) translateX(2px);
        filter: drop-shadow(0 0 4px #ff7000);
      }
    `;
    document.head.appendChild(style);
  }

  if (container) container.prepend(a);
  return a;
}

// ── Input: unified swipe + key handler ──────────────────────────
/**
 * Подписаться на направленные входы (стрелки + свайпы).
 * @param {HTMLElement} el    — элемент для touch-событий
 * @param {function} handler  — handler(dir: 'up'|'down'|'left'|'right')
 * @returns {function}        — вызови чтобы отписаться
 */
function onDirection(el, handler) {
  let tx = 0, ty = 0;

  const touchStart = e => { tx = e.touches[0].clientX; ty = e.touches[0].clientY; };
  const touchEnd   = e => {
    const dx = e.changedTouches[0].clientX - tx;
    const dy = e.changedTouches[0].clientY - ty;
    if (Math.abs(dx) < 12 && Math.abs(dy) < 12) return;
    if (Math.abs(dy) > Math.abs(dx)) handler(dy > 0 ? 'down' : 'up');
    else                              handler(dx > 0 ? 'right' : 'left');
  };
  const keyDown = e => {
    const map = { ArrowUp:'up', ArrowDown:'down', ArrowLeft:'left', ArrowRight:'right' };
    if (map[e.key]) { handler(map[e.key]); e.preventDefault(); }
  };

  el.addEventListener('touchstart', touchStart, { passive: true });
  el.addEventListener('touchend',   touchEnd,   { passive: true });
  document.addEventListener('keydown', keyDown);

  return () => {
    el.removeEventListener('touchstart', touchStart);
    el.removeEventListener('touchend',   touchEnd);
    document.removeEventListener('keydown', keyDown);
  };
}

// ── Export (ESM + global) ────────────────────────────────────────
const Platform = {
  user, save, load,
  saveRecord, getRecord,
  haptic, toast, expand,
  createBackButton, onDirection,
};

export default Platform;

// Also expose globally for non-module scripts
window.Platform = Platform;
