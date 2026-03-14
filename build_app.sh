#!/bin/bash
# Сборка TestTrackerMac в готовое приложение для Mac.
# Результат: папка Release/TestTrackerMac.app

set -e
cd "$(dirname "$0")"

echo "Сборка TestTrackerMac (Release)..."
xcodebuild -project TestTrackerMac.xcodeproj -scheme TestTrackerMac -configuration Release build -quiet

# Найти путь к .app в DerivedData
APP_PATH=$(find ~/Library/Developer/Xcode/DerivedData -name "TestTrackerMac.app" -path "*/Release/*" -type d 2>/dev/null | head -1)
if [ -z "$APP_PATH" ]; then
  echo "Ошибка: TestTrackerMac.app не найден в DerivedData."
  exit 1
fi

mkdir -p Release
rm -rf Release/TestTrackerMac.app
cp -R "$APP_PATH" Release/
echo "Готово: Release/TestTrackerMac.app"
