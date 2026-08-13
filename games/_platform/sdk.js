/**
 * Platform SDK — единая точка доступа к данным игрока.
 * Импортируй в любую игру: import { getPlayer, saveRecord } from '/_platform/sdk.js';
 */

const TG = window.Telegram?.WebApp;

/**
 * Получить данные игрока (ID, username, персонаж).
 * @returns {Promise<{id: number, username: string, character: object}>}
 */
export async function getPlayer() {
  if (TG) TG.ready();

  const user = TG?.initDataUnsafe?.user || { id: 0, username: 'Guest' };

  // Загрузка персонажа из localStorage (временно, пока нет API)
  let character = JSON.parse(localStorage.getItem('batm_character') || 'null');

  // Дефолтный персонаж если не создан
  if (!character) {
    character = {
      name: user.first_name || 'Игрок',
      legs_color: '#2d4fd6',
      torso_color: '#22c55e',
      arms_color: '#ffd23e',
      head_color: '#ffd23e',
      hair_style: 'default',
      face_emotion: 'smile'
    };
  }

  return {
    id: user.id,
    username: user.username || 'guest',
    first_name: user.first_name,
    character
  };
}

/**
 * Сохранить рекорд в игре.
 * @param {string} gameSlug - ID игры ('runner', 'fnf-beat', etc.)
 * @param {number} score - Очки
 * @param {object} metadata - Доп. данные (опционально)
 */
export async function saveRecord(gameSlug, score, metadata = {}) {
  const player = await getPlayer();

  // Сохранение в localStorage (временно)
  const key = `batm_record_${gameSlug}_${player.id}`;
  const existing = JSON.parse(localStorage.getItem(key) || '{"score":0}');

  if (score > existing.score) {
    localStorage.setItem(key, JSON.stringify({
      score,
      metadata,
      date: new Date().toISOString()
    }));
    return true; // новый рекорд
  }

  return false;
}

/**
 * Получить лучший рекорд игрока в игре.
 * @param {string} gameSlug
 * @returns {Promise<{score: number, metadata: object, date: string}|null>}
 */
export async function getRecord(gameSlug) {
  const player = await getPlayer();
  const key = `batm_record_${gameSlug}_${player.id}`;
  return JSON.parse(localStorage.getItem(key) || 'null');
}

/**
 * Вибрация (если доступна).
 * @param {'light'|'medium'|'heavy'|'error'|'success'} type
 */
export function haptic(type = 'light') {
  if (TG?.HapticFeedback) {
    if (type === 'error' || type === 'success') {
      TG.HapticFeedback.notificationOccurred(type);
    } else {
      TG.HapticFeedback.impactOccurred(type);
    }
  }
}
