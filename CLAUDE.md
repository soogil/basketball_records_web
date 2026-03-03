# Project Architecture Guide: MVP Pattern

## 1. Overview
이 프로젝트는 소규모 확장을 고려한 MVP(Model-View-Presenter) 패턴을 사용합니다. 모든 코드는 철저하게 역할이 분리되어야 하며, View는 비즈니스 로직을 가지지 않고 오직 Presenter의 명령만 수행합니다.

## 2. Directory Structure
프로젝트 루트 아래의 `lib/` 폴더 구조는 다음과 같이 유지합니다.

```text
lib/
 ┣ core/               # 앱 전반에서 쓰이는 공통 모듈 (상수, 테마, 유틸리티)
 ┃ ┣ constants.dart
 ┃ ┗ utils.dart
 ┣ models/             # 데이터 구조체 및 비즈니스 데이터 모델
 ┃ ┗ user_model.dart
 ┣ repositories/       # API 서버나 DB와 통신하여 데이터를 가져오는 계층
 ┃ ┗ auth_repository.dart
 ┣ presenters/         # 비즈니스 로직 처리 및 View 업데이트 명령
 ┃ ┣ contracts/        # View와 Presenter가 통신하기 위한 Interface(abstract class) 모음
 ┃ ┃ ┗ login_contract.dart
 ┃ ┗ login_presenter.dart
 ┗ views/              # 화면 UI (Stateless/Stateful Widgets)
   ┣ screens/          # 전체 화면 단위
   ┃ ┗ login_screen.dart
   ┗ widgets/          # 재사용 가능한 UI 컴포넌트