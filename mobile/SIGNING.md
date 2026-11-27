# Ключ загрузки для мобильных игр batmGAMES

Один ключ на все игры из `mobile/`: Google Play разрешает подписывать им
сколько угодно приложений, а Play App Signing всё равно подпишет каждое своим
ключом Google. Создаётся в Google Cloud Shell (Java там уже стоит):
<https://shell.cloud.google.com>

## 1. Создать ключ

Вставь блок целиком. Он сам проверяет, что ключ открывается паролем, и кладёт
пароль и ключ в файлы, откуда их надёжно копировать:

```bash
mkdir -p ~/batmgames-key && cd ~/batmgames-key
rm -f upload.jks password.txt upload.jks.b64
P=$(openssl rand -hex 16)
keytool -genkeypair -v -keystore upload.jks -storetype PKCS12 \
  -alias batmgames -keyalg RSA -keysize 4096 -validity 10000 \
  -storepass "$P" -keypass "$P" \
  -dname "CN=batmGAMES, OU=vnxAPPS, O=vnxAPPS, C=RU"
printf '%s' "$P" > password.txt
base64 -w0 upload.jks > upload.jks.b64
echo
if keytool -list -keystore upload.jks -storepass "$(cat password.txt)" | grep -q batmgames; then
  echo "ПРОВЕРКА ПРОЙДЕНА: ключ открывается паролем (длина ${#P})"
else
  echo "ОШИБКА: ключ не открывается, дальше не иди"
fi
cloudshell download upload.jks
cloudshell download password.txt
```

Должна появиться строка **«ПРОВЕРКА ПРОЙДЕНА … (длина 32)»**, и браузер
скачает два файла. **Сохрани оба минимум в два места** (менеджер паролей,
флешка): ключ без пароля бесполезен, пароль без ключа тоже.

## 2. Четыре секрета в GitHub — по одному

`github.com/vnxAPPS/batmGAMES` → **Settings → Secrets and variables →
Actions → New repository secret**. Каждый секрет отдельно: имя, значение,
**Add secret**.

Значения копируй из файлов, а не из окна терминала: в Cloud Shell нажми
**Open Editor** (справа сверху), открой файл слева в папке `batmgames-key`,
`Ctrl+A`, `Ctrl+C`.

| № | Имя | Значение |
|---|---|---|
| 1 | `ANDROID_KEYSTORE` | всё содержимое `upload.jks.b64` |
| 2 | `ANDROID_KEY_ALIAS` | `batmgames` |
| 3 | `ANDROID_STORE_PASSWORD` | содержимое `password.txt` (32 символа) |
| 4 | `ANDROID_KEY_PASSWORD` | то же, что в № 3 |

После четвёртого секрета запусти сборку: **Actions → vnxmind-android → Run
workflow**. В сводке запуска строка «Подпись» должна быть `CN=batmGAMES…`, а
не `Android Debug`.
