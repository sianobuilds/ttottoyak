# Tto-Tto-Yak (또또약)

> **Contactless AI Senior Vital Monitoring & Medication Adherence Platform**  
> 전면 RGB 카메라 피드만으로 안면 미세 혈류(rPPG)와 468개 랜드마크 기반 안면 단차·비대칭을 분석하고, 처방전 비전 OCR을 통해 복약 순응도를 관리하는 AI 디지털 헬스케어 플랫폼

---

## 📌 프로젝트 개요 & 시스템 정의
고가의 웨어러블 하드웨어 센서 도입 없이, 표준 스마트폰/태블릿 RGB 카메라 피드만으로 안면 미세 혈류(rPPG)를 감지하여 심박·호흡수를 비접촉 측정하고, 안면 468개 랜드마크 기반 눈/코/입 3D 단차 및 비대칭을 검진하여 뇌졸중·안면신경 전조 증상을 포착하며, 약물 패키지 및 처방전 OCR 대조를 통해 복약 순응도를 완성하는 AI 디지털 헬스케어 OS입니다.

- **대상 사용자**: 다제약물(Polypharmacy) 복용 고령 시니어, 만성·중증 질환자, 독거노인 돌봄 사회복지사 및 보호자
- **아키텍처**: Edge-Client 전처리 (MediaPipe 468) + FastAPI C-Level NumPy/SciPy 신호처리 파이프라인

---

## ✨ 핵심 기능 (Core Features)

1. **생체 데이터 사전 동의 게이트 (Consent Gate)**
   - 안면 영상 및 랜드마크 분석 전 법적·윤리적 동의 핸들 제공
   - 원본 영상 비저장 원칙(Privacy-by-Design): 랜드마크 추출 즉시 메모리 파기

2. **AI 건강체크 (안면 3D 단차·비대칭 + rPPG 생체 신호)**
   - **안면 비대칭/단차 분석**: MediaPipe 468개 랜드마크 기반 눈꼬리 수평 편차(Eye Tilt), 입꼬리 비대칭률(Mouth Corner Delta), 코 중심 3D 깊이 단차(Depth Delta) 실시간 추적 (뇌졸중/구안와사 전조 감지)
   - **rPPG 심박수 복원**: CHROM(색차 투영) + 5차 버터워스 필터(0.75~3.5Hz) + Welch FFT 피크 검출

3. **인터랙티브 복약 스케줄러 (월간 ↔ 주간)**
   - 월간(1~31일) / 주간 달력 뷰 전환 지원
   - 사용자 직접 터치형 '복약하기' 토글 버튼 및 실시간 주간 순응도(Compliance Score) 반영

4. **실시간 처방전 카메라 촬영 & 비전 OCR**
   - 카메라로 실물 처방전/약봉지 촬영 시 병원명, 처방약(Amodipine 등), 복용법 자동 추출 및 복약 DB 적재

5. **돌봄 연계망 (Care Community) & 비상 SOS**
   - 사회복지사, 보호자 긴급 연락망 및 이상 징후 감지 시 자동 알림 라우팅

---

## 🛠 Tech Stack
- **Frontend**: Flutter (Mobile Web/PWA Responsive), Custom Vector Canvas
- **Backend**: Python 3.11, FastAPI, Uvicorn, WebSockets, Pydantic v2
- **AI & DSP**: NumPy, SciPy (CHROM rPPG DSP), MediaPipe Face Mesh, PyTesseract
