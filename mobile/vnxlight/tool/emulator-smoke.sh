#!/usr/bin/env bash
# Прогон vnxLIGHT на эмуляторе: ставит APK, включает свет кнопкой, протягивает
# яркость пальцем по полоске, выключает. По дороге снимает скриншоты — они же
# годятся для страницы в Google Play.
#
# У эмулятора нет вспышки: приложение светит экраном (лучом), а нативная
# часть ничего не включает. Стенд проверяет интерфейс и что приложение не
# падает без вспышки; реальный светодиод проверяется на телефоне.
#
# Запуск: bash mobile/vnxlight/tool/emulator-smoke.sh <путь к APK>
set -u

APK=${1:?нужен путь к APK}
OUT=smoke
PKG=com.vnxapps.light
ACTIVITY=com.vnxapps.vnxlight.MainActivity
mkdir -p "$OUT"
fail=0
n=0

summary() { printf '%s\n' "$*" >> "${GITHUB_STEP_SUMMARY:-/dev/null}"; echo "$*"; }

shot() {
  n=$((n + 1))
  adb exec-out screencap -p > "$OUT/$(printf '%02d' "$n")-$1.png" 2>/dev/null
}

dump() {
  adb shell uiautomator dump /sdcard/ui.xml > /dev/null 2>&1
  adb shell cat /sdcard/ui.xml > "$OUT/ui.xml" 2>/dev/null
}

# Нажать элемент, у которого text или content-desc подходит под регулярное
# выражение $1: целиком, если $2 = exact, иначе где угодно в подписи.
# Кликабельные элементы — в первую очередь: иначе можно попасть в текст с тем
# же словом, а не в кнопку. Flutter отдаёт подписи кнопок в content-desc.
tap() {
  local pattern=$1 mode=${2:-part} xy
  for _ in 1 2 3 4 5; do
    dump
    xy=$(python3 - "$OUT/ui.xml" "$pattern" "$mode" <<'PY'
import re, sys
xml, pattern, mode = sys.argv[1], sys.argv[2], sys.argv[3]
xml = open(xml, encoding="utf-8", errors="replace").read()
rx = re.compile(rf"(?:{pattern})")
hit = (lambda s: rx.fullmatch(s)) if mode == "exact" else (lambda s: rx.search(s))
found = []
for node in re.findall(r"<node [^>]*>", xml):
    a = dict(re.findall(r'([\w-]+)="([^"]*)"', node))
    names = [a.get("text", "").strip(), a.get("content-desc", "").strip()]
    if any(n and hit(n) for n in names) and a.get("enabled") != "false":
        x1, y1, x2, y2 = map(int, re.findall(r"\d+", a["bounds"]))
        found.append((a.get("clickable") != "true", (x1 + x2) // 2, (y1 + y2) // 2))
if found:
    _, x, y = sorted(found, key=lambda f: f[0])[0]
    print(x, y)
PY
)
    if [ -n "$xy" ]; then
      # shellcheck disable=SC2086
      adb shell input tap $xy
      sleep 1
      return 0
    fi
    sleep 2
  done
  echo "::error::Не нашёл на экране: $pattern"
  cp "$OUT/ui.xml" "$OUT/ui-missing-$n.xml" 2>/dev/null
  shot "missing"
  fail=1
  return 1
}

seen() {
  dump
  grep -qE "(text|content-desc)=\"[^\"]*($1)" "$OUT/ui.xml"
}

summary "## vnxLIGHT на эмуляторе"
summary ""
if ! adb install -r "$APK" > "$OUT/install.txt" 2>&1; then
  cat "$OUT/install.txt"
  echo "::error::APK не установился."
  exit 1
fi
summary "- установка: ок"

adb shell settings put system screen_off_timeout 600000
adb shell cmd locale set-app-locales "$PKG" --locales ru-RU > /dev/null 2>&1 || true
adb logcat -c
adb shell am start -W -n "$PKG/$ACTIVITY" > "$OUT/start.txt" 2>&1
sleep 8
shot off

if tap 'Включить фонарик|Turn on flashlight'; then
  sleep 4
  shot on-full
  summary "- свет включён кнопкой"
fi

# Полоска яркости: провести пальцем от верха до середины.
dump
read -r x1 y1 x2 y2 <<< "$(python3 - "$OUT/ui.xml" <<'PY'
import re, sys
xml = open(sys.argv[1], encoding="utf-8", errors="replace").read()
for node in re.findall(r"<node [^>]*>", xml):
    a = dict(re.findall(r'([\w-]+)="([^"]*)"', node))
    if re.search(r"Яркость|Brightness", a.get("content-desc", "") + a.get("text", "")):
        print(*map(int, re.findall(r"\d+", a["bounds"])))
        break
PY
)"
if [ -n "${x1:-}" ]; then
  cx=$(( (x1 + x2) / 2 ))
  adb shell input swipe "$cx" $(( y1 + 10 )) "$cx" $(( (y1 + y2) / 2 + (y2 - y1) / 6 )) 600
  sleep 3
  shot on-dim
  summary "- яркость уменьшена пальцем по полоске"
else
  echo "::error::Не нашёл полоску яркости."
  fail=1
fi

if tap 'Выключить фонарик|Turn off flashlight'; then
  sleep 3
  shot off-again
  summary "- свет выключен кнопкой"
fi

adb shell ps -A -o PID,NAME > "$OUT/ps.txt" 2>&1
adb logcat -d -v time > "$OUT/logcat.txt" 2>&1
if ! grep -q "$PKG" "$OUT/ps.txt"; then
  echo "::error::Процесс приложения не жив в конце прогона."
  fail=1
fi
crashes=$(grep -nE "FATAL EXCEPTION|ANR in $PKG|Fatal signal|MissingPluginException" "$OUT/logcat.txt" | head -20)
if [ -n "$crashes" ]; then
  echo "::error::В logcat есть падения."
  summary ""
  summary '```'
  summary "$crashes"
  summary '```'
  fail=1
fi

summary ""
summary "Скриншоты (1080×1920, годятся для Google Play) — в артефакте screens-…"
ls "$OUT"/*.png 2>/dev/null | sed 's#.*/#- #' >> "${GITHUB_STEP_SUMMARY:-/dev/null}"
exit $fail
