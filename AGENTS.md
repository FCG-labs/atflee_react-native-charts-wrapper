# AGENTS.md — atflee_react-native-charts-wrapper

> Scope: 이 모듈은 `react-native-charts-wrapper` 포크이며, 앱(`app/`)에서 `github:FCG-labs/atflee_react-native-charts-wrapper#<tag>` 형태로 참조합니다.

---

## 릴리스 프로세스 [MUST]

이 모듈을 수정한 뒤에는 반드시 아래 과정을 **한 세트**로 완료해야 합니다. 하나라도 빠지면 앱 빌드에 반영되지 않습니다.

### 1. 커밋 & 푸시

```bash
cd rn_module/atflee_react-native-charts-wrapper
git add -A
git commit -m "<변경 요약>"
git push origin main
```

### 2. 태그 생성 & 푸시

현재 최신 태그에서 patch 버전을 +1 합니다.

```bash
# 최신 태그 확인
git tag --sort=-v:refname | head -1   # e.g. v2.5.43

# 새 태그 생성
git tag v2.5.<N+1>
git push origin v2.5.<N+1>
```

### 3. 앱 package.json 업데이트

```bash
cd ../../app
# package.json의 react-native-charts-wrapper 버전을 새 태그로 변경
# "react-native-charts-wrapper": "github:FCG-labs/atflee_react-native-charts-wrapper#v2.5.<N+1>"
yarn install
```

### 4. 앱 네이티브 재빌드

native 코드(Java/Swift)를 수정한 경우 Metro HMR만으로는 반영되지 않습니다.

```bash
# Android
cd android && ./gradlew clean && cd .. && npx react-native run-android

# iOS
cd ios && pod install && cd .. && npx react-native run-ios
```

---

## 주의사항

- **태그 없이 push만 하면 앱에서 변경이 반영되지 않습니다** (package.json이 태그 기준 참조).
- 태그 네이밍: `v2.5.XX` (semver patch). major/minor 변경은 팀 합의 필요.
- iOS 변경 시 `pod install` 필수.
