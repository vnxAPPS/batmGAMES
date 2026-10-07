#!/bin/bash
# batmGAMES Quick Test Script
# Быстрая проверка всех игр на GitHub Pages

echo "🎮 batmGAMES - Quick Test"
echo "========================="
echo ""

BASE_URL="https://vnxapps.github.io/batmGAMES"

# Цвета для вывода
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Функция проверки URL
check_url() {
    local url=$1
    local marker=$2
    local name=$3

    echo -n "Testing $name... "

    response=$(curl -s -o /dev/null -w "%{http_code}" "$url")

    if [ "$response" -eq 200 ]; then
        body=$(curl -s "$url")
        if echo "$body" | grep -q "$marker"; then
            echo -e "${GREEN}✅ OK${NC} (HTTP $response, marker found)"
            return 0
        else
            echo -e "${RED}❌ FAIL${NC} (HTTP $response, marker NOT found)"
            echo "   Expected marker: $marker"
            return 1
        fi
    else
        echo -e "${RED}❌ FAIL${NC} (HTTP $response)"
        return 1
    fi
}

echo "📱 Testing Main Pages"
echo "---------------------"
check_url "$BASE_URL/" "batmGAMES" "Main Menu"
check_url "$BASE_URL/character/" "Character Creator" "Character Creator"
echo ""

echo "🕹️ Testing Games"
echo "----------------"
check_url "$BASE_URL/play.html?game=runner" "BatmGames Platform" "Runner"
check_url "$BASE_URL/play.html?game=snake" "BatmGames Platform" "Snake"
check_url "$BASE_URL/play.html?game=tetris" "BatmGames Platform" "Tetris"
check_url "$BASE_URL/play.html?game=2048" "BatmGames Platform" "2048"
check_url "$BASE_URL/play.html?game=minesweeper" "BatmGames Platform" "Minesweeper"
echo ""

echo "🔜 Testing Placeholders"
echo "----------------------"
check_url "$BASE_URL/play.html?game=fnf-beat" "Coming Soon" "FNF Beat"
check_url "$BASE_URL/play.html?game=slide9" "Coming Soon" "Slide9"
check_url "$BASE_URL/play.html?game=territory" "Coming Soon" "Territory"
echo ""

echo "📦 Testing Static Assets"
echo "------------------------"
check_url "$BASE_URL/_platform/platform.js" "BatmGamesPlatform" "Platform SDK"
check_url "$BASE_URL/_platform/styles.css" "Liquid Glass" "Platform Styles"
check_url "$BASE_URL/_games/runner.js" "export default" "Runner Module"
check_url "$BASE_URL/_games/snake.js" "export default" "Snake Module"
echo ""

echo "========================="
echo "✅ Test Complete"
echo ""
echo "📋 Next steps:"
echo "  1. Open $BASE_URL in browser"
echo "  2. Test each game manually on mobile device"
echo "  3. Report any bugs in ISSUES.md"
echo ""
echo "🔗 Quick links:"
echo "  Main: $BASE_URL"
echo "  Runner: $BASE_URL/play.html?game=runner"
echo "  Snake: $BASE_URL/play.html?game=snake"
