#!/bin/bash

# 포트 정리
lsof -ti :8000 | xargs kill -9 2>/dev/null
lsof -ti :3000 | xargs kill -9 2>/dev/null

trap 'kill $(jobs -p) 2>/dev/null' EXIT

echo "=========================================="
echo " 1. 백엔드 FastAPI 서버 구동 (:8000)"
echo "=========================================="
cd backend
source venv/bin/activate
uvicorn main:app --host 127.0.0.1 --port 8000 &
cd ..

echo "=========================================="
echo " 2. 플러터 웹앱 릴리즈 빌드 갱신"
echo "=========================================="
cd frontend
flutter pub get
flutter build web --release --no-tree-shake-icons
cd ..

echo "=========================================="
echo " 3. 정적 웹앱 서버 실행 (:3000)"
echo "=========================================="
cd frontend/build/web
python3 -m http.server 3000 --bind 127.0.0.1 &

echo ""
echo ">> 준비 완료! 브라우저에서 아래 주소로 접속하세요:"
echo ">> http://localhost:3000"
echo "=========================================="

wait
