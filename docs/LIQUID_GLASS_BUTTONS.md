# 🧪 Liquid Glass Button System

## Концепция

Кнопки в batmGAMES используют **Liquid Glass** — систему, имитирующую прозрачное цветное стекло с физикой вязкой жидкости.

### Что это НЕ:
- ❌ Обычная кнопка с `border-radius` и градиентом
- ❌ Простая blob-анимация на hover
- ❌ Непрозрачная цветная заливка

### Что это:
- ✅ Многослойный оптический материал
- ✅ Spring physics для всех параметров
- ✅ Реакция на pointer с инерцией
- ✅ Ощущение прозрачного стекла с цветом внутри

---

## Визуальная структура

```
       ☀️ виртуальный свет (следует за pointer)
        │
        ├─ Specular highlight (яркое пятно)
        │
    ┌───▼──────────────────────┐
    │   Layer 5: Edge light    │ ← светлая кромка
    │  ┌────────────────────┐  │
    │  │ Layer 4: Diffuse   │  │ ← мягкое свечение
    │  │ ┌────────────────┐ │  │
    │  │ │ Layer 3: Color │ │  │ ← полупрозрачный цвет
    │  │ │ ┌────────────┐ │ │  │
    │  │ │ │ Layer 2:   │ │ │  │ ← внутренняя глубина
    │  │ │ │  Depth     │ │ │  │
    │  │ │ └────────────┘ │ │  │
    │  │ └────────────────┘ │  │
    │  └────────────────────┘  │
    └──────────────────────────┘
             ↓
    Layer 1: backdrop (фон за кнопкой)
```

---

## Оптические слои

### Layer 0: Colored Backdrop (подложка)
```html
<div class="btn-base btn-base--orange">
  <button class="liquid-glass-btn">ИГРАТЬ</button>
</div>
```
```css
.btn-base {
  position: relative;
  display: inline-block;
  padding: 3px; /* толщина стекла */
  border-radius: 21px; /* 18px + 3px */
}
.btn-base--orange { background: linear-gradient(135deg, #ff7820, #ff4500); }
.btn-base--blue   { background: linear-gradient(135deg, #3b9eff, #1a6fc4); }
.btn-base--green  { background: linear-gradient(135deg, #22e77c, #16a34a); }
```
**Ключевая идея**: цвет — это не в самой кнопке, а в подложке под стеклом.

### Layer 1: Backdrop blur
```css
backdrop-filter: blur(8px) saturate(1.2);
```
Размывает фон → создаёт ощущение прозрачности.

### Layer 2: Clear Glass (само стекло)
```css
background:
  radial-gradient(
    circle at var(--light-x) var(--light-y),
    rgba(255,255,255,0.35),
    transparent 50%
  ),
  rgba(255,255,255,0.12);
```
**Важно**: стекло всегда белое полупрозрачное (alpha 0.12–0.35). Цвет берётся от подложки снизу.

### Layer 3: Inner Depth
```css
box-shadow:
  inset 0 1px 3px rgba(255,255,255,0.6),   /* верхний свет */
  inset 0 -10px 20px rgba(0,0,0,0.15);     /* нижняя глубина */
```
Создаёт ощущение толщины материала. Тень нейтральная (чёрная), не зависит от цвета подложки.

### Layer 4: Edge Light
```css
border: 1px solid rgba(255,255,255,0.35);
```
Или через `::before`:
```css
.btn::before {
  content: '';
  position: absolute;
  inset: 0;
  border-radius: inherit;
  border: 1.5px solid rgba(255,255,255,0.4);
  mask: linear-gradient(135deg, #000 30%, transparent 70%);
}
```
Светлая кромка только сверху-слева.

### Layer 5: Specular Highlight
```css
.btn::after {
  content: '';
  position: absolute;
  top: 8%;
  left: 15%;
  width: 40%;
  height: 25%;
  background: radial-gradient(
    ellipse,
    rgba(255,255,255,0.5),
    transparent 70%
  );
  transform: translate(
    var(--light-offset-x),
    var(--light-offset-y)
  );
  transition: transform 0.6s cubic-bezier(0.25, 0.46, 0.45, 0.94);
}
```

---

## Spring Physics

### Базовая модель
```javascript
class SpringValue {
  constructor(initial, stiffness = 0.08, damping = 0.82) {
    this.current = initial;
    this.target = initial;
    this.velocity = 0;
    this.stiffness = stiffness;
    this.damping = damping;
  }

  update() {
    this.velocity += (this.target - this.current) * this.stiffness;
    this.velocity *= this.damping;
    this.current += this.velocity;
  }

  set(newTarget) {
    this.target = newTarget;
  }
}
```

### Применяемые параметры
```javascript
const btn = {
  lightX: new SpringValue(0.5, 0.08, 0.82),    // положение света
  lightY: new SpringValue(0.5, 0.08, 0.82),
  scale: new SpringValue(1.0, 0.15, 0.75),     // масштаб при нажатии
  deform: new SpringValue(0, 0.06, 0.85),      // деформация формы
  rotation: new SpringValue(0, 0.05, 0.88),    // лёгкий наклон
};

function gameLoop() {
  btn.lightX.update();
  btn.lightY.update();
  btn.scale.update();
  btn.deform.update();
  btn.rotation.update();

  // Применяем к CSS variables
  el.style.setProperty('--light-x', `${btn.lightX.current * 100}%`);
  el.style.setProperty('--light-y', `${btn.lightY.current * 100}%`);
  el.style.setProperty('--scale', btn.scale.current);

  requestAnimationFrame(gameLoop);
}
```

---

## Pointer Interaction

### 1. Idle (покой)
```javascript
// Очень медленное "дыхание"
scale: 1.000 → 1.001 → 1.000 → 0.999 → 1.000
period: ~4 seconds
```

### 2. Hover (наведение)
```javascript
canvas.addEventListener('pointermove', (e) => {
  const rect = btn.getBoundingClientRect();
  const x = (e.clientX - rect.left) / rect.width;
  const y = (e.clientY - rect.top) / rect.height;

  // Свет следует за pointer с инерцией
  btn.lightX.set(x);
  btn.lightY.set(y);

  // Лёгкая деформация в сторону pointer
  const dx = x - 0.5;
  const dy = y - 0.5;
  const dist = Math.hypot(dx, dy);
  btn.deform.set(dist * 0.05);  // макс 5% деформация
});
```

### 3. Press (нажатие)
```javascript
btn.addEventListener('pointerdown', () => {
  btn.scale.set(0.965);              // сжатие
  btn.brightness.set(0.85);          // затемнение
  btn.innerShadow.set(1.5);          // глубже тень
  btn.deform.set(btn.deform.current * 1.3);  // усиление деформации
});
```

### 4. Release (отпускание)
```javascript
btn.addEventListener('pointerup', () => {
  btn.scale.set(1.01);   // overshoot
  setTimeout(() => {
    btn.scale.set(1.0);  // settle
  }, 50);
});
```

---

## Деформация формы (Blob)

### НЕ делать:
```css
/* ❌ Бесконечная анимация */
animation: blob 3s infinite;
```

### Делать:
```javascript
// Форма деформируется только при взаимодействии
const baseBorderRadius = 18;

function updateBorderRadius() {
  const deformAmount = btn.deform.current;
  const angle = Math.atan2(pointerY - 0.5, pointerX - 0.5);

  // 4 угла деформируются по-разному
  const tl = baseBorderRadius + Math.cos(angle) * deformAmount * 10;
  const tr = baseBorderRadius + Math.cos(angle + Math.PI/2) * deformAmount * 10;
  const br = baseBorderRadius + Math.cos(angle + Math.PI) * deformAmount * 10;
  const bl = baseBorderRadius + Math.cos(angle + 3*Math.PI/2) * deformAmount * 10;

  el.style.borderRadius = `${tl}px ${tr}px ${br}px ${bl}px`;
}
```

**Результат**: форма слегка вытягивается к pointer, как вязкая жидкость.

---

## Gooey Filter (опционально)

```html
<svg style="position:absolute;width:0;height:0">
  <defs>
    <filter id="gooey">
      <feGaussianBlur in="SourceGraphic" stdDeviation="8" result="blur"/>
      <feColorMatrix in="blur" mode="matrix"
        values="1 0 0 0 0  0 1 0 0 0  0 0 1 0 0  0 0 0 20 -10"/>
      <feComposite in="SourceGraphic" in2="goo" operator="atop"/>
    </filter>
  </defs>
</svg>
```

```css
.btn:hover {
  filter: url(#gooey);
}
```

**Когда использовать**: только при очень сильной деформации (deform > 0.3). Иначе оставить чистую форму.

---

## Performance

### Desktop
- Полная физика: ✅
- Backdrop-filter: ✅
- SVG filter: ✅
- 60 FPS

### Mobile
```javascript
const isMobile = /Android|iPhone|iPad/i.test(navigator.userAgent);

if (isMobile) {
  // Упрощённая модель
  stiffness *= 1.5;    // быстрее реакция
  damping *= 0.95;     // меньше колебаний
  maxDeform *= 0.5;    // слабее blob

  // Отключить backdrop-filter на слабых устройствах
  if (performance.memory?.jsHeapSizeLimit < 1e9) {
    el.style.backdropFilter = 'none';
  }
}
```

---

## Accessibility

```css
@media (prefers-reduced-motion: reduce) {
  .btn {
    /* Отключить spring physics */
    --stiffness: 1;
    --damping: 1;

    /* Простой transition */
    transition: transform 0.2s, opacity 0.2s;
  }

  .btn:hover {
    transform: scale(1.02);
  }

  .btn:active {
    transform: scale(0.98);
  }

  /* Убрать деформацию */
  .btn {
    border-radius: 18px !important;
  }
}
```

---

## Цветовые варианты

Само стекло **всегда одинаковое** (белое полупрозрачное). Цвет задаётся только через подложку:

### Orange (accent)
```css
.btn-base--orange {
  background: linear-gradient(135deg, #ff7820, #ff4500);
}
```

### Blue
```css
.btn-base--blue {
  background: linear-gradient(135deg, #3b9eff, #1a6fc4);
}
```

### Green
```css
.btn-base--green {
  background: linear-gradient(135deg, #22e77c, #16a34a);
}
```

### Использование
```html
<!-- Оранжевая кнопка -->
<div class="btn-base btn-base--orange">
  <button class="liquid-glass-btn">ИГРАТЬ</button>
</div>

<!-- Синяя кнопка -->
<div class="btn-base btn-base--blue">
  <button class="liquid-glass-btn">НАЧАТЬ</button>
</div>
```

---

## Примеры использования

### Обычная кнопка
```html
<div class="btn-base btn-base--orange">
  <button class="liquid-glass-btn">ИГРАТЬ</button>
</div>
```

### Большая кнопка (game over)
```html
<div class="btn-base btn-base--orange">
  <button class="liquid-glass-btn liquid-glass-btn--large">ЕЩЁ РАЗ</button>
</div>
```

### Кнопка с иконкой
```html
<div class="btn-base btn-base--blue">
  <button class="liquid-glass-btn">
    <span class="icon">🎮</span>
    НАЧАТЬ
  </button>
</div>
```

### Принцип работы
Кнопка всегда выглядит как **прозрачное белое стекло**. Меняя цвет подложки `.btn-base--*`, меняется видимый цвет капли — точно как на референсе с зелёной подложкой.

---

## Чек-лист реализации

- [ ] Многослойный background (цвет полупрозрачный)
- [ ] Backdrop-filter для размытия фона
- [ ] Inner shadows (глубина)
- [ ] Edge light (::before)
- [ ] Specular highlight (::after, следует за pointer)
- [ ] Spring physics для всех параметров
- [ ] Pointer tracking с инерцией
- [ ] Деформация формы при hover/press
- [ ] Overshoot при release
- [ ] Очень слабое "дыхание" в idle
- [ ] Gooey filter только при сильной деформации
- [ ] Mobile optimization
- [ ] prefers-reduced-motion support

---

## Референсы

### Apple Design
- iOS notification buttons
- Apple Watch complications
- macOS Big Sur controls

### Реальное стекло
- Frosted glass with color inside
- Venetian glass art
- Liquid-filled capsules

### Физика
- Spring-damper system
- Viscous fluid simulation
- Soft-body deformation

---

## Авторы

Разработано для **batmGAMES** платформы.
Вдохновлено Apple Design Language и liquid glass art.

**Технологии**:
- CSS custom properties
- Pointer Events API
- RequestAnimationFrame
- Spring physics
- SVG filters
- Backdrop-filter

**Версия**: 2.0
**Дата**: 2026-08-15
