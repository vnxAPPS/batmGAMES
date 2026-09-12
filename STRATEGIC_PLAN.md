# batmGAMES - Стратегический план развития

## 📊 Текущее состояние (2026-09-12)

### Завершено ✅
- **Unified Platform v3.0** — одна точка входа, SDK, UI система
- **5 рабочих игр** — Runner, Snake, Tetris, 2048, Minesweeper
- **3 заглушки** — FNF Beat, Slide9, Territory (Coming Soon)
- **Документация** — 4 полных гайда для команды
- **Фикс путей** — GitHub Pages теперь работает корректно

### Платформа: 95% готова
- Core SDK ✅
- Liquid Glass UI ✅
- Unified screens ✅
- Character rendering ✅
- Haptic feedback ✅
- Audio system 🔜
- Leaderboard 🔜
- Achievements 🔜

---

## 🎯 Стратегические приоритеты

### Фаза 1: Production Ready (1-2 недели)
**Цель:** Запустить в production с 5 играми и полноценной интеграцией

#### 1.1 Критические таски
- [ ] **Deploy на MATRIXde-n1** (порт 80 занят nginx, см. PORT_REGISTRY.md)
  - Добавить server-блок в `/etc/nginx/sites-available/`
  - Настроить статику: `/var/www/games.helloneo.uk`
  - SPA-фоллбэк: `try_files $uri /index.html`
  - Тест через curl с маркером в теле (не только код 200)
  
- [ ] **CRM интеграция**
  - Дать Service Account доступ к Google Sheets
  - Запустить миграции БД (001, 002)
  - Протестировать sheets_sync.py
  - Первая полная синхронизация
  - Настроить автоматическую синхронизацию (cron)

- [ ] **Telegram bot интеграция**
  - Подключить игры к системе scoring в боте
  - Трекинг игровых сессий в CRM
  - Сохранение high scores per user
  - Начисление очков за игры

#### 1.2 Тестирование
- [ ] Тесты на реальных устройствах
  - iOS (Safari)
  - Android (Chrome)
  - Desktop (Chrome, Firefox)
  - Telegram WebApp на всех платформах

- [ ] Performance audit
  - Проверка на слабых устройствах
  - Оптимизация canvas rendering
  - Lazy loading для тяжёлых ресурсов

---

### Фаза 2: Feature Complete (2-3 недели)
**Цель:** Реализовать 3 оставшиеся игры + расширить платформу

#### 2.1 Реализация placeholder игр

**FNF Beat Battle Solo** (приоритет: HIGH)
- 4-lane ритм-геймплей (D-F-J-K)
- Система спавна нот с BPM sync
- Perfect/Good/Miss тайминг (±50ms / ±100ms / miss)
- Combo counter + multiplier
- Touch controls (4 зоны)
- Минимум 3 трека разной сложности
- **Оценка:** 20-25 часов

**Territory Battle** (приоритет: MEDIUM)
- Карта с 15-20 регионами
- Пошаговая механика (attack/defense dice)
- 3 AI противника (easy/medium/hard)
- Система юнитов и подкреплений
- Визуализация боевых результатов
- **Оценка:** 30-35 часов

**FNF Slidenotefication 9** (приоритет: LOW)
- Multi-lane ритм (A-Z клавиши)
- Shaped notes (круги, квадраты, треугольники)
- Bot opponent с AI паттернами
- Health bar система
- Более сложная система тайминга
- **Оценка:** 25-30 часов

**Итого:** 75-90 часов работы (2-3 недели для одного разработчика)

#### 2.2 Platform enhancements

**Audio System**
```javascript
platform.playMusic(trackName, loop = true)
platform.stopMusic()
platform.playSFX(soundName, volume = 1.0)
platform.setMusicVolume(0-1)
platform.setSFXVolume(0-1)
```

**Leaderboard**
- Backend API для submit/fetch scores
- Интеграция с CRM (clients.games_stats)
- UI компонент для топ-10
- Фильтры: today/week/all-time
- Персональная позиция в рейтинге

**Achievements**
- Система достижений в platform.js
- Badge UI (popup при разблокировке)
- Интеграция с CRM (JSON поле в clients)
- Примеры: "First Win", "Speed Demon", "Combo Master"

---

### Фаза 3: Growth & Optimization (1-2 месяца)
**Цель:** Расширение контента + улучшение метрик

#### 3.1 Новые игры из GAME_CONCEPTS.md

Приоритетный список (от простого к сложному):

1. **Memory Palace** (puzzle, ~10 часов)
   - Матрица карточек
   - Flip механика
   - Прогрессия уровней
   - Минимальный арт

2. **Signal Chain** (logic, ~15 часов)
   - Соединение точек
   - Головоломки с возрастающей сложностью
   - Визуализация цепочек

3. **Orbital Mechanics** (physics, ~20 часов)
   - Запуск спутников
   - Физика орбит (упрощённая)
   - Puzzle + sandbox режимы

4. **AI Wars** (strategy, ~30 часов)
   - Программирование AI юнитов
   - Арена для боёв
   - Система апгрейдов

5. **Dyson Sphere Builder** (incremental, ~40 часов)
   - Idle/incremental механика
   - Визуализация строительства
   - Многоуровневая прогрессия

#### 3.2 Аналитика и метрики

**Tracking**
- Game plays (начало/завершение сессий)
- Average session length per game
- Completion rate (% игроков, завершивших игру)
- Retention: day-1, day-7, day-30
- High scores distribution

**Tools**
- Простой analytics.js модуль
- События в Telegram Analytics
- Dashboard в CRM (Google Sheets)

**Метрики успеха:**
- 100+ активных игроков в день
- 70%+ retention день-1
- 10+ минут средняя сессия
- 5+ игр в топ-3 по популярности

---

### Фаза 4: Ecosystem (долгосрочно)

#### 4.1 Social features
- Челленджи между друзьями
- Шаринг рекордов в Telegram
- Daily challenges (одна игра/день на очки)
- Сезонные турниры

#### 4.2 Monetization (опционально)
- Премиум персонажи (косметика)
- Дополнительные уровни для игр
- Ad-free опция
- Battle pass / сезонные награды

#### 4.3 Technical improvements
- Progressive Web App (offline support)
- Service Worker для кеширования
- WebGL для требовательных игр
- Multi-language support (EN, ES, etc.)

---

## 📅 Timeline Summary

```
Week 1-2:   Production deployment + CRM + Testing
Week 3-4:   FNF Beat Battle + Territory Battle
Week 5-6:   Slidenotefication 9 + Audio System + Leaderboard
Month 2:    3 новые игры + Achievements
Month 3+:   Growth features + Optimization
```

---

## 👥 Распределение работы (команда 3 чел)

### Developer 1 (Backend/Integration)
- CRM синхронизация
- Backend API для leaderboard
- Telegram bot интеграция
- Аналитика и метрики
- Deploy и DevOps

### Developer 2 (Games/Gameplay)
- Реализация 3 placeholder игр
- Новые игры из concepts
- Game balancing и тестирование
- Sound design и audio integration

### Developer 3 (Platform/UI)
- Platform enhancements (audio, achievements)
- UI/UX improvements
- Performance optimization
- Mobile testing и fixes

---

## 🎲 Risk Management

### Технические риски

**Проблема:** Пути на GitHub Pages ломаются при изменениях структуры  
**Митигация:** Всегда использовать относительные пути, тестировать локально + на GH Pages

**Проблема:** Canvas performance на слабых устройствах  
**Митигация:** FPS throttling, упрощение рендера для мобильных, feature detection

**Проблема:** Audio sync в ритм-играх нестабилен  
**Митигация:** Web Audio API с AudioContext.currentTime, калибровка задержки

### Процессные риски

**Проблема:** Конфликты в Git при работе втроём  
**Митигация:** Git Flow (feature branches), code review, чёткое разделение зон ответственности

**Проблема:** Deploy ломает production (инцидент 12.09 с nginx)  
**Митигация:** Staging environment, проверка body content (не только HTTP 200), rollback plan

---

## 📈 Success Metrics

### MVP (через 2 недели)
- ✅ 5 игр работают в production
- ✅ CRM tracks game sessions
- ✅ <100ms average load time
- ✅ 0 critical bugs на production

### V1.0 (через 6 недель)
- ✅ 8 игр полностью реализованы
- ✅ Audio system working
- ✅ Leaderboard live
- ✅ 50+ daily active users
- ✅ 70%+ day-1 retention

### V2.0 (через 3 месяца)
- ✅ 12+ игр
- ✅ Achievements system
- ✅ Social features
- ✅ 200+ daily active users
- ✅ 80%+ day-7 retention

---

## 🔗 Dependencies

### External
- GitHub Pages (hosting)
- Telegram WebApp SDK
- Google Sheets API (CRM)
- MATRIXde-n1 server (nginx на порту 80)

### Internal
- Character creator (`character/`) должен синхронизировать с platform
- Telegram bot должен поддерживать game scoring API
- CRM schema migrations (001, 002) должны быть выполнены

---

## 📝 Next Action Items

### Сегодня/завтра
1. [ ] Тестировать фикс путей на GitHub Pages (live)
2. [ ] Проверить все 5 игр на реальном устройстве
3. [ ] Создать server-блок для games.helloneo.uk

### Эта неделя
1. [ ] Deploy на production
2. [ ] Запустить CRM синхронизацию
3. [ ] Начать FNF Beat Battle (дизайн механики)

### Следующий месяц
1. [ ] Реализовать 3 placeholder игры
2. [ ] Добавить audio system
3. [ ] Запустить leaderboard

---

*План составлен: 2026-09-12*  
*Следующая ревизия: после завершения Фазы 1*  
*Ответственный: команда из 3 разработчиков*
