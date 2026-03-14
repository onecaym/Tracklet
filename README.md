# Test Tracker Mac — нативное Swift-приложение

Учёт тестов по брендам: отчёты, бренды, аналитика, недавние отчёты. Светлая тема, только Swift/SwiftUI.

## Как собрать проект

**Через Xcode:**
1. Откройте `TestTrackerMac.xcodeproj` в Xcode (из папки `TestTrackerMac/`).
2. Выберите схему **TestTrackerMac** и цель **My Mac**.
3. Сборка: **Product → Build** (⌘B). Запуск: **Product → Run** (⌘R).

**Через терминал:**
```bash
cd test_tracker_mac/TestTrackerMac
xcodebuild -project TestTrackerMac.xcodeproj -scheme TestTrackerMac -configuration Release build
```
Готовый `.app` будет в `~/Library/Developer/Xcode/DerivedData/TestTrackerMac-.../Build/Products/Release/TestTrackerMac.app`.

**Скопировать .app в папку проекта:**
```bash
cd test_tracker_mac/TestTrackerMac
./build_app.sh
```
Скрипт соберёт Release и положит **TestTrackerMac.app** в папку **Release/**.

## Как сделать отдельное приложение для macOS

Чтобы получить **отдельное приложение** (один файл .app), которое можно запускать без Xcode и переносить на другой Mac:

### Как сделать в Xcode по шагам

1. Откройте проект **TestTrackerMac.xcodeproj** в Xcode.
2. В верхней панели выберите схему **TestTrackerMac** и цель **My Mac**.
3. Переключите сборку на **Release**: меню **Product → Scheme → Edit Scheme…** (или ⌘<). В списке слева выберите **Run**. В поле **Build Configuration** выберите **Release**. Нажмите **Close**.
4. Соберите проект: **Product → Build** (⌘B).
5. Откройте папку с результатом: **Product → Show Build Folder in Finder**. В открывшемся окне зайдите в **Release** — там будет **TestTrackerMac.app**.
6. Перетащите **TestTrackerMac.app** в папку **Программы** (или в любое место) — это и есть готовое отдельное приложение для macOS.

Дальше можно снова переключить схему на **Debug** (Edit Scheme → Run → Build Configuration → Debug), чтобы удобно разрабатывать.

---

1. **Соберите в конфигурации Release** (не Debug):
   - В Xcode: **Product → Scheme → Edit Scheme…** → в разделе **Run** выберите **Release**, закройте. Затем **Product → Build** (⌘B).  
   - Или в терминале:  
     `xcodebuild -project TestTrackerMac.xcodeproj -scheme TestTrackerMac -configuration Release build`

2. **Найдите готовый .app:**
   - В Xcode: **Product → Show Build Folder in Finder** → откройте папку **Release** → там лежит **TestTrackerMac.app**.
   - Или в Finder: **Переход → Переход к папке** и вставьте:  
     `~/Library/Developer/Xcode/DerivedData/`  
     Найдите папку **TestTrackerMac-…** (с уникальным суффиксом), откройте **Build/Products/Release/** — там **TestTrackerMac.app**.

3. **Сделайте из него отдельное приложение:**
   - Перетащите **TestTrackerMac.app** в папку **Программы** (/Applications) — тогда оно будет в списке программ и запускается двойным щелчком как любое приложение macOS.
   - Либо скопируйте .app в любое место (Рабочий стол, флешка) — он будет работать и оттуда. Всё необходимое уже внутри .app.

Такой **TestTrackerMac.app** — это и есть отдельное приложение для macOS: не нужен Xcode, не нужны исходники. Данные при первом запуске сохраняются в `~/Library/Application Support/TestTrackerMac/`.

**Удобный вариант:** выполните в терминале из папки проекта `./build_app.sh` — скрипт сам соберёт Release и скопирует **TestTrackerMac.app** в папку **Release/** внутри проекта; оттуда его можно перетащить в «Программы» или куда угодно.

---

## Запуск из Xcode

1. Откройте в Xcode проект:
   ```
   test_tracker_mac/TestTrackerMac/TestTrackerMac.xcodeproj
   ```
2. Выберите схему **TestTrackerMac** и целевое устройство **My Mac**.
3. Нажмите **Run** (⌘R).

Приложение соберётся и запустится. База SQLite создаётся в `~/Library/Application Support/TestTrackerMac/test_tracker.db`.

## Сборка приложения для Mac (готовый .app)

### Вариант 1: через Xcode

1. Откройте **TestTrackerMac.xcodeproj** в Xcode.
2. В меню выберите **Product → Scheme → TestTrackerMac** и **My Mac**.
3. Соберите в Release: **Product → Build** (или ⌘B).  
   Либо создайте архив: **Product → Archive** — в Organizer появится архив, из него можно экспортировать .app.
4. Готовое приложение лежит в папке сборки Xcode:
   - **Product → Show Build Folder in Finder** (или в меню **Product**).
   - Путь вида:  
     `~/Library/Developer/Xcode/DerivedData/TestTrackerMac-…/Build/Products/Release/TestTrackerMac.app`

Скопируйте **TestTrackerMac.app** в «Программы» или в любое место — это и есть приложение для Mac. Запуск двойным щелчком.

### Вариант 2: из терминала

Из папки с проектом выполните:

```bash
cd TestTrackerMac
xcodebuild -project TestTrackerMac.xcodeproj -scheme TestTrackerMac -configuration Release build
```

После успешной сборки .app будет здесь:

```
~/Library/Developer/Xcode/DerivedData/TestTrackerMac-<hash>/Build/Products/Release/TestTrackerMac.app
```

Скопируйте этот **TestTrackerMac.app** куда нужно — это и есть приложение для Mac.

### Копирование .app в папку проекта

Чтобы сразу получить .app рядом с проектом, можно выполнить скрипт из корня репозитория:

```bash
cd test_tracker_mac/TestTrackerMac
./build_app.sh
```

Скрипт соберёт Release и скопирует **TestTrackerMac.app** в подпапку **Release** рядом с проектом.

## Требования

- macOS 13.0+
- Xcode 15+ (для Swift Charts)

## Функционал

- **Создать отчёт** — дата, бренд, V1 / V2 / V1 Reject / V2 Reject, несколько брендов в одном отчёте, копирование в буфер.
- **Бренды** — добавление и удаление (с каскадным удалением отчётов).
- **Аналитика** — линейный график по месяцам, выбор бренда и периода (3/6/12/24 мес.), цель по умолчанию 1 тест/мес.
- **Недавние отчёты** — таблица последних 20 отчётов.

Схема БД совместима с Python-версией: один и тот же файл `test_tracker.db` можно использовать в обеих версиях (при необходимости скопируйте его в нужную папку).
