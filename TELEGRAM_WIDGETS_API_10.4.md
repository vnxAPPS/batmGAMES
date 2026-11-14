# Telegram Bot API 10.4 — HTML Widgets
**Дата выхода:** 9 ноября 2026  
**Источник:** https://core.telegram.org/bots/api-changelog#november-9-2026  
**Документация виджетов:** https://core.telegram.org/bots/widgets

---

## Что это такое

Виджеты — это HTML/CSS/JS, встроенные **прямо в сообщение бота** в чате. Не WebApp, который открывается в отдельном окне. Виджет живёт внутри пузыря сообщения — как карточка с интерактивом.

**Текущие ограничения (production):**
- Только приватные чаты
- Нельзя переслать
- Protected content автоматически

---

## Новые методы Bot API

### `sendWidget` — отправить виджет
```python
await bot.send_widget(
    chat_id=user_id,
    html="<h2>Привет!</h2><button onclick=\"TelegramWidget.request('tap')\">Нажми</button>",
    width=300,          # 200–600 px (опционально)
    height=150,         # 50–600 px (опционально)
    public_data="{}",   # Общие данные (до 1024 байт)
    chat_data="{}",     # Данные для этого сообщения (до 1024 байт)
    allow_queries=True, # Разрешить виджету отправлять запросы боту
    is_shared=False,    # Создать shared виджет (один для всех сообщений)
)
```

### `sendSharedWidget` — повторно отправить shared виджет
```python
await bot.send_shared_widget(
    chat_id=user_id,
    widget_id="WIDGET_ID_FROM_PREV",
    chat_data="{}"  # Уникальные данные для этого сообщения
)
```

### `editMessageWidgetData` — обновить данные виджета
```python
await bot.edit_message_widget_data(
    chat_id=user_id,
    message_id=msg_id,
    public_data='{"score": 42}',
    chat_data='{"level": 3}'
)
```

### `editSharedWidgetData` — обновить public_data для всех копий
```python
await bot.edit_shared_widget_data(
    widget_id="WIDGET_ID",
    public_data='{"leaderboard": [...]}'
)
```

### `answerWidgetQuery` — ответить на запрос от виджета
```python
@dp.widget_query()
async def handle_widget_query(query: WidgetQuery):
    # Обработать запрос
    result = process(query.data)
    
    await query.answer(data=json.dumps(result))  # до 1024 байт
    
    # Опционально обновить данные:
    await bot.edit_message_widget_data(
        chat_id=query.chat.id,
        message_id=query.message_id,
        chat_data=json.dumps(new_state)
    )
```

---

## Объект Widget (что приходит в Message)

```python
class Widget:
    id: str | None          # Только для shared виджетов
    width: int | None
    height: int | None
    html: str               # Код виджета
    public_data: str | None # Общие данные
    chat_data: str | None   # Данные этого сообщения
```

---

## WidgetQuery — запрос от виджета к боту

```python
class WidgetQuery:
    id: str                 # Уникальный ID запроса
    from_user: User         # Кто нажал
    data: str               # Данные от виджета (1–64 байт!)
    type: WidgetQueryType   # Тип запроса
    # + контекст: chat+message_id ИЛИ inline_message_id ИЛИ widget_id
```

**Типы запросов:**
- `WidgetQueryTypeData` — обычный запрос с данными
- `WidgetQueryTypeSignData` — с подписью TON кошелька
- `WidgetQueryTypeSentTransaction` — уведомление о транзакции TON

---

## JavaScript API внутри виджета

```javascript
// Доступный объект TelegramWidget
TelegramWidget.profile          // 1 (версия профиля)
TelegramWidget.colorScheme      // 'light' | 'dark'
TelegramWidget.themeParams      // { bg_color, text_color, ... }
TelegramWidget.isActive         // bool (виджет виден?)
TelegramWidget.isPreview        // bool
TelegramWidget.isForward        // bool
TelegramWidget.chatType         // 'private'|'group'|'supergroup'|null
TelegramWidget.viewer           // { id, first_name, username?, is_premium? }
TelegramWidget.chatData         // string | null
TelegramWidget.publicData       // string | null
TelegramWidget.wallet           // WidgetWallet | null (TON)

// Методы
TelegramWidget.request(data)              // → Promise<{result}>  ГЛАВНЫЙ МЕТОД
TelegramWidget.copyText(text)             // Копировать в буфер
TelegramWidget.openLink(url)              // Открыть https:// ссылку
TelegramWidget.openTelegramLink(url)      // Открыть t.me ссылку
TelegramWidget.watchPublicData()          // Следить за обновлениями
TelegramWidget.ready()                    // Сообщить о готовности
TelegramWidget.setResizeAnchor('top'|'bottom')

// Haptic
TelegramWidget.HapticFeedback.impactOccurred('light'|'medium'|'heavy')
TelegramWidget.HapticFeedback.notificationOccurred('success'|'error'|'warning')

// События
TelegramWidget.onEvent('activated', fn)
TelegramWidget.onEvent('deactivated', fn)
TelegramWidget.onEvent('themeChanged', fn)
TelegramWidget.onEvent('chatDataChanged', fn)
TelegramWidget.onEvent('publicDataChanged', fn)
```

---

## Что можно использовать в HTML

### Разрешённые теги
- Структура: `div`, `span`, `p`, `h1-h6`, `header`, `footer`, `section`, `article`
- Текст: `b`, `i`, `u`, `em`, `strong`, `code`, `pre`
- Таблицы: `table`, `tr`, `td`, `th` (с `colspan`/`rowspan`)
- Медиа: `<img>` только `data:` PNG/JPEG/GIF/WebP, `<canvas>`, `<button>`, `<a>`
- SVG: shapes, paths, gradients, `text/tspan`

### Запрещено
- `<form>`, `<input>`, `<select>`, `<textarea>` — стриппируются вместе с контентом
- `<iframe>`, `<video>`, `<audio>`, `<script src="...">`
- Внешние изображения (только `data:`)

### CSS
✅ Flex, Grid, position, z-index, overflow:hidden  
✅ Transitions, `@keyframes`, Web Animations API  
✅ `blur()`, `brightness()`, `drop-shadow()` через filter  
✅ 2D transforms  
✅ CSS variables  
✅ `@media (prefers-color-scheme)`, `@media (width)`  
✅ `--tg-theme-*` переменные темы автоматически  

❌ `vh` единицы  
❌ `overflow: scroll/auto`  
❌ `position: sticky`  
❌ 3D transforms  
❌ `@font-face`, `@import`  
❌ `:has()`  

### JavaScript рантайм
- **QuickJS** (ES2023, без JIT) — быстрый, безопасный
- ✅ Promises, async/await, setTimeout, requestAnimationFrame
- ✅ DOM полный: createElement, querySelector, innerHTML, classList
- ✅ Canvas 2D: paths, gradients, fillText, drawImage
- ✅ localStorage (4 KB), sessionStorage
- ✅ Intl, crypto.getRandomValues, TextEncoder, URL
- ❌ **fetch, XMLHttpRequest, WebSocket** → `NetworkDisabledError`
- ❌ alert, confirm, navigator.clipboard, Blob

---

## Лимиты (важно!)

| Параметр | Лимит |
|----------|-------|
| HTML размер | 32 768 байт |
| **HTML после zlib сжатия** | **4 096 байт** ← ГЛАВНЫЙ ЛИМИТ |
| public_data / chat_data | 1 024 байт каждый |
| Запрос от виджета (data) | 1–64 байт |
| Ответ бота (data) | 1 024 байт |
| localStorage | 4 KB |
| Размер виджета | 200–600 × 50–600 px |
| DOM узлы | 2 000 |
| Canvas пиксели | 2048×2048 всего |
| Изображения data: | 1024×1024 px |
| Память | 8 MB |
| Таймеры | 64 одновременно |

**Проверить размер:**
```bash
python3 -c 'import sys,zlib; print(len(zlib.compress(sys.stdin.buffer.read(), 9)))' < widget.html
```

---

## Другие новинки API 10.4

### Ephemeral Messages (временные сообщения)
Ответ на callback_query видят только нажавший кнопку — работает в группах:
```python
await query.answer(
    text="Только ты видишь это!",
    ephemeral_message_parameters=EphemeralMessageParameters(
        # receiver_user_id теперь опционален
    )
)
```

### TON Wallet интеграция
- `ton_wallet_card` в `ChatFullInfo` — посмотреть кошелёк пользователя
- `TonWalletTransfer` в сообщениях — сервисные сообщения о переводах
- `ton_address` — новый тип entity для адресов TON
- Виджет может запросить подпись транзакции через `WidgetQueryTypeSignData`

### getUniqueGift
```python
gift = await bot.get_unique_gift(name="gift_name")
```

### Цитаты из Rich Messages
```python
await bot.send_message(
    chat_id=chat_id,
    text="Ответ",
    reply_parameters=ReplyParameters(
        message_id=orig_msg_id,
        quote_rich_texts=[...]  # Цитировать форматированный контент
    )
)
```

### Username суффиксы для Premium
Пользователи Premium могут давать ботам дополнительные имена:  
`@batmGAMES_agent`, `@batmGAMES_ai`, `@batmGAMES_app`, `@batmGAMES_game`

---

## Поддержка в aiogram 3.x

На момент написания aiogram 3.16 ещё не поддерживает Bot API 10.4 нативно.  
Нужно следить за обновлениями: https://github.com/aiogram/aiogram/releases  
Временно можно использовать raw API calls через `bot.session`.

---

# batmGAMES: Что применяем прямо сейчас

## 🔥 Приоритет 1: Игровые виджеты вместо WebApp

Вместо открытия отдельного окна WebApp — игра прямо в чате!

### Мини-игры в пузыре (Snake, 2048, Minesweeper)
Идеально подходят потому что:
- Небольшой canvas (600×600 px максимум)
- Простое управление кнопками/свайпом
- Результат виден сразу в чате

```html
<!-- snake_widget.html (~2KB сжатый) -->
<canvas id="c" width="300" height="300" style="..."></canvas>
<div style="display:flex;gap:8px;justify-content:center;margin-top:8px">
  <button onclick="dir={x:0,y:-1}">▲</button>
  <button onclick="dir={x:-1,y:0}">◀</button>
  <button onclick="dir={x:0,y:1}">▼</button>
  <button onclick="dir={x:1,y:0}">▶</button>
</div>
<script>
  // Вся логика Snake в <4KB
  // При game over: TelegramWidget.request(JSON.stringify({score: points}))
</script>
```

Бот получает результат и:
1. Обновляет рейтинг через `editMessageWidgetData`
2. Трекает в CRM через `update_client_profile`

---

## 🔥 Приоритет 2: Интерактивный профиль игрока

Виджет вместо скучного текстового профиля:

```python
profile_html = f"""
<div style="background:var(--tg-theme-bg-color);padding:12px;border-radius:12px">
  <h3 style="color:var(--tg-theme-text-color)">{user.first_name}</h3>
  <p>🏆 Рекорд Snake: <strong>{records.snake}</strong></p>
  <p>🎮 Игр сыграно: <strong>{stats.games_played}</strong></p>
  <canvas id="chart" width="280" height="80"></canvas>
  <button onclick="TelegramWidget.request('open_game:snake')">Играть</button>
</div>
<script>
  // Нарисовать chart активности за 7 дней
  drawActivityChart(JSON.parse(TelegramWidget.chatData));
</script>
"""

await bot.send_widget(
    chat_id=user_id,
    html=profile_html,
    height=200,
    chat_data=json.dumps(stats.last_7_days),
    allow_queries=True
)
```

---

## 🔥 Приоритет 3: Shared Leaderboard

Один виджет лидерборда, который обновляется для всех автоматически:

```python
# Создать shared виджет один раз
leaderboard_msg = await bot.send_widget(
    chat_id=CHANNEL_ID,
    html=leaderboard_html,
    is_shared=True,
    public_data=json.dumps(top10_data),
    allow_queries=True
)
widget_id = leaderboard_msg.widget.id

# Позже: отправить в личку пользователю
await bot.send_shared_widget(
    chat_id=user_id,
    widget_id=widget_id,
    chat_data=json.dumps({"user_rank": user_rank})
)

# Обновлять автоматически каждый час
await bot.edit_shared_widget_data(
    widget_id=widget_id,
    public_data=json.dumps(new_top10)
)
```

Все видят актуальный рейтинг — без перезагрузки!

---

## 🔥 Приоритет 4: Выбор персонажа в виджете

Создать персонажа прямо в чате, без перехода в отдельный WebApp:

```python
character_html = """
<canvas id="c" width="80" height="100" style="margin:0 auto;display:block"></canvas>
<div style="display:grid;grid-template-columns:repeat(4,1fr);gap:4px;margin-top:8px">
  <button data-part="torso" data-color="#22c55e" onclick="setColor(this)">🟢</button>
  <button data-part="torso" data-color="#3b82f6" onclick="setColor(this)">🔵</button>
  ...
</div>
<button onclick="save()" style="width:100%;margin-top:8px">Сохранить</button>
<script>
  let char = JSON.parse(TelegramWidget.chatData || '{}');
  
  function setColor(btn) {
    char[btn.dataset.part] = btn.dataset.color;
    drawCharacter();
  }
  
  async function save() {
    await TelegramWidget.request(JSON.stringify({action:'save', char}));
  }
  
  drawCharacter(); // рисует из char данных
</script>
"""
```

---

## Временная шкала внедрения

### Сейчас (ждём aiogram поддержку)
- [ ] Изучить changelog aiogram → Bot API 10.4 поддержка
- [ ] Написать прототип Snake виджета (HTML + JS)
- [ ] Проверить размер через python zlib (должно быть <4096 байт)
- [ ] Тестировать через raw API call

### После появления aiogram поддержки
1. **Мини Snake виджет** — самая простая реализация (~1 день)
2. **Профиль игрока** — с canvas chart (~2 дня)
3. **Shared Leaderboard** — обновляемый рейтинг (~2 дня)
4. **Character creator** — в виджете (~3 дня)

### Долгосрочно
5. TON интеграция (платные функции, NFT стикеры)
6. 2048 и Minesweeper в виджете
7. Турниры с live обновлением через shared виджет

---

## Архитектурное решение: WebApp vs Widget

| | WebApp | Widget |
|--|--------|--------|
| Открытие | Отдельное окно | Прямо в чате |
| UX | Выход из чата | Не выходя из чата |
| Размер | Нет лимита | 4KB сжатый HTML |
| JS возможности | Полный браузер | Ограниченный QuickJS |
| Canvas | Любой размер | До 2048×2048 px |
| Сеть | fetch, WebSocket | ❌ Нет сети |
| Идеально для | Сложные игры, большие UI | Мини-игры, статистика, профили |
| **Решение batmGAMES** | Roblox Runner, FNF, Territory | Snake, 2048, Minesweeper, Leaderboard |

**Итог:** Используем оба подхода. Сложные игры → WebApp. Простые и статистика → Widget.

---

## Пример минимального Snake виджета

```html
<!DOCTYPE html>
<html>
<head>
<style>
* { margin:0; padding:0; box-sizing:border-box; }
body { background:var(--tg-theme-bg-color); display:flex; flex-direction:column; align-items:center; padding:8px; }
canvas { border:1px solid var(--tg-theme-hint-color); border-radius:4px; }
.controls { display:grid; grid-template-areas:'. u .' 'l . r' '. d .'; gap:4px; margin-top:8px; }
button { width:40px; height:40px; border:none; border-radius:8px; background:var(--tg-theme-button-color); color:var(--tg-theme-button-text-color); font-size:18px; cursor:pointer; touch-action:none; }
#score { color:var(--tg-theme-text-color); margin-top:4px; font-weight:bold; }
</style>
</head>
<body>
<canvas id="c" width="200" height="200"></canvas>
<div id="score">Score: 0</div>
<div class="controls">
  <button style="grid-area:u" onclick="setDir(0,-1)">▲</button>
  <button style="grid-area:l" onclick="setDir(-1,0)">◀</button>
  <button style="grid-area:r" onclick="setDir(1,0)">▶</button>
  <button style="grid-area:d" onclick="setDir(0,1)">▼</button>
</div>
<script>
const G=10, S=200/G;
let snake=[{x:5,y:5}], food={x:7,y:7}, dir={x:1,y:0}, score=0, alive=true;
const ctx=document.getElementById('c').getContext('2d');

function setDir(x,y){ if(x!=-dir.x||y!=-dir.y) dir={x,y}; }

function step(){
  if(!alive) return;
  const h={x:snake[0].x+dir.x, y:snake[0].y+dir.y};
  if(h.x<0||h.x>=G||h.y<0||h.y>=G||snake.some(s=>s.x==h.x&&s.y==h.y)){
    alive=false;
    TelegramWidget.request(String(score));  // Отправить счёт боту
    return;
  }
  snake.unshift(h);
  if(h.x==food.x&&h.y==food.y){
    score+=10;
    document.getElementById('score').textContent='Score: '+score;
    food={x:Math.floor(Math.random()*G), y:Math.floor(Math.random()*G)};
  } else { snake.pop(); }
}

function draw(){
  ctx.fillStyle='#1a1a2e'; ctx.fillRect(0,0,200,200);
  ctx.fillStyle='#e74c3c'; ctx.fillRect(food.x*S+1,food.y*S+1,S-2,S-2);
  snake.forEach((s,i)=>{
    ctx.fillStyle=i==0?'#2ecc71':'#27ae60';
    ctx.fillRect(s.x*S+1,s.y*S+1,S-2,S-2);
  });
  if(!alive){ ctx.fillStyle='rgba(0,0,0,.7)'; ctx.fillRect(0,0,200,200); ctx.fillStyle='#fff'; ctx.font='20px sans-serif'; ctx.textAlign='center'; ctx.fillText('Game Over',100,100); }
}

setInterval(()=>{ step(); draw(); }, 150);
</script>
</body>
</html>
```

---

*Документ создан: 2026-11-14*  
*Следить за: https://github.com/aiogram/aiogram/releases*  
*Telegram Widgets docs: https://core.telegram.org/bots/widgets*
