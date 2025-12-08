# Basketball Records Web

농구 동호회에서 사용할 **경기 기록 입력 웹 애플리케이션**입니다.  
경기 후에 각 선수의 출석, 경기 수, 승리 수, 승점을 빠르게 입력하면  
자동으로 누적 점수와 승률을 계산해주고, 기록을 저장/관리할 수 있습니다.

> ⚙️ Flutter Web + Firebase + Riverpod 기반으로 구현되었습니다.

## ✨ 주요 기능

- **선수 관리**
  - 선수 추가 / 삭제
  - 출석 점수, 승점, 누적 점수, 승률 등 기본 스탯 관리

- **경기 기록 입력**
  - 날짜별로 경기 기록 생성
  - 각 선수별로
    - 출석 점수
    - 총 경기 수
    - 승리 경기 수
    - 승점
  - 테이블 기반 UI로 한 화면에서 여러 선수 기록을 빠르게 입력

- **기록 관리**
  - 날짜별 기록 저장
  - 특정 날짜 기록 삭제
  - “해당 날짜에 실제 기록이 있는지” 체크하는 기능 (모두 0인 경우 필터링 등)

- **점수 계산 & 마일스톤 체크**
  - 출석 점수 + 승점 ⇒ `totalScore`, `accumulatedScore` 자동 반영
  - 누적 점수 구간별 마일스톤 달성 여부(`scoreAchieved`) 계산

## 🧱 기술 스택

- **Framework**
  - Flutter (Web)
- **State Management**
  - Riverpod
  - riverpod_annotation / riverpod_generator (codegen)
- **Firebase**
  - Firebase Core
  - Cloud Firestore – 선수 및 경기 기록 저장
