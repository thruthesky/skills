---
description: "Cloudflare WAF로 보호된 사이트에 PHP PEST + ChromeDriver(Remote Debugging Port) 방식으로 접속하여 브라우저 자동화 작업을 수행하는 스킬. Cloudflare WAF, 브라우저 자동화, 웹 스크래핑, ChromeDriver, PHP PEST 관련 작업 시 사용."
---

# Cloudflare WAF 통과 브라우저 자동화 스킬

## 개요

Cloudflare WAF(Web Application Firewall)로 보호된 웹사이트에 자동으로 접속하여 데이터를 추출하거나 브라우저 자동화 작업을 수행합니다. PHP PEST 테스트 프레임워크와 ChromeDriver의 Remote Debugging Port 연결 방식을 사용합니다.

## 핵심 원리 (CoT 분석)

### 문제 정의
Cloudflare WAF는 자동화 도구의 접속을 차단합니다. 일반적인 HTTP 클라이언트(cURL, Guzzle)나 ChromeDriver가 직접 시작한 Chrome은 모두 차단됩니다.

### 실패하는 방법들과 이유

#### 1. cURL/Guzzle → 403 Forbidden
- Cloudflare는 JavaScript 챌린지를 요구
- HTTP 클라이언트는 JavaScript를 실행할 수 없음

#### 2. ChromeDriver가 Chrome을 직접 시작 → "Just a moment..." 무한 대기
- ChromeDriver가 Chrome을 시작하면 자동화 관련 플래그가 주입됨
- `--disable-blink-features=AutomationControlled` 옵션을 추가해도 Cloudflare가 감지
- Cloudflare가 검사하는 시그널들:
  - `navigator.webdriver` === `true`
  - `window.cdc_` 변수 존재
  - Chrome 자동화 플래그 (`--enable-automation` 등)
  - WebDriver 프로토콜 흔적

#### 3. Playwright MCP / Chrome DevTools MCP → Cloudflare 감지
- 이 도구들도 Chrome을 시작할 때 자동화 플래그를 주입
- `--disable-features=AutomationControlled` 등을 포함하지만 불충분

### 성공하는 방법: Remote Debugging Port 연결 방식 (ToT 분석)

```
[사고 트리 - Tree of Thoughts]

목표: Cloudflare WAF 통과
├── 방법 A: HTTP 클라이언트 → ❌ JS 실행 불가
├── 방법 B: ChromeDriver 직접 시작 → ❌ 자동화 플래그 감지
├── 방법 C: Playwright/Puppeteer → ❌ 자동화 플래그 감지
└── 방법 D: 일반 Chrome + Remote Debugging Port → ✅ 성공!
    ├── 핵심: 일반 Chrome 프로세스를 먼저 시작 (자동화 플래그 없음)
    ├── Chrome의 --remote-debugging-port 옵션으로 외부 제어 허용
    ├── ChromeDriver가 이미 실행 중인 Chrome에 debuggerAddress로 연결
    └── 결과: navigator.webdriver === false, window.cdc_ 없음 → Cloudflare 통과
```

#### 핵심 메커니즘

```
[일반적인 방식 - 실패]
ChromeDriver → Chrome 시작 (자동화 플래그 주입) → Cloudflare 감지 → 차단

[Remote Debugging 방식 - 성공]
일반 Chrome 시작 (자동화 플래그 없음) → ChromeDriver가 기존 Chrome에 연결 → Cloudflare 통과
```

## 사전 요구사항

### 시스템 요구사항
- macOS (Google Chrome 설치됨)
- PHP 8.x 이상
- Composer
- ChromeDriver (Chrome 버전과 일치해야 함)

### PHP 패키지
```json
{
    "require-dev": {
        "pestphp/pest": "^4.4",
        "symfony/panther": "^2.4"
    }
}
```

### ChromeDriver 설치 (macOS)
```bash
brew install --cask chromedriver
xattr -d com.apple.quarantine /opt/homebrew/bin/chromedriver
```

## 사용 방법

사용자가 Cloudflare WAF로 보호된 사이트에 접속하여 자동화 작업을 수행하고 싶다고 요청하면, 아래의 템플릿을 기반으로 PHP PEST 테스트 파일을 생성합니다.

### 단계별 실행 흐름

1. **일반 Chrome을 Remote Debugging Port로 시작** - 자동화 플래그 없는 일반 Chrome 프로세스
2. **ChromeDriver를 별도로 시작** - Chrome을 시작하지 않고 제어만 담당
3. **debuggerAddress로 기존 Chrome에 연결** - ChromeDriver가 이미 실행 중인 Chrome에 연결
4. **Cloudflare 챌린지 대기** - 타이틀 기반으로 통과 여부 판단
5. **자동화 작업 수행** - 데이터 추출, 폼 제출 등
6. **정리** - Chrome/ChromeDriver 프로세스 종료

### 템플릿 코드

아래 함수들을 테스트 파일에 포함하여 사용합니다:

```php
<?php

use Facebook\WebDriver\Chrome\ChromeOptions;
use Facebook\WebDriver\Remote\DesiredCapabilities;
use Facebook\WebDriver\Remote\RemoteWebDriver;

/**
 * 일반 Chrome을 remote debugging 포트로 시작
 *
 * @param string $userDataDir Chrome 프로필 경로 (별도 디렉토리 사용하여 기존 프로필과 충돌 방지)
 * @param int $port remote debugging 포트 (기본: 9222~9229 범위 사용)
 */
function launchChrome(string $userDataDir, int $port): void
{
    // 기존 프로세스 정리
    exec("lsof -ti tcp:{$port} | xargs kill -9 2>/dev/null");
    sleep(1);

    $chromePath = '/Applications/Google Chrome.app/Contents/MacOS/Google Chrome';
    $cmd = sprintf(
        '"%s" --remote-debugging-port=%d --user-data-dir="%s" --no-first-run --no-default-browser-check --window-size=1920,1080 --lang=ko-KR > /dev/null 2>&1 &',
        $chromePath,
        $port,
        $userDataDir
    );
    exec($cmd);

    // Chrome이 완전히 시작될 때까지 대기 (최대 15초)
    for ($i = 0; $i < 15; $i++) {
        sleep(1);
        $ch = curl_init("http://localhost:{$port}/json/version");
        curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);
        curl_setopt($ch, CURLOPT_TIMEOUT, 2);
        curl_exec($ch);
        $code = curl_getinfo($ch, CURLINFO_HTTP_CODE);
        curl_close($ch);
        if ($code === 200) return;
    }
    throw new \RuntimeException("Chrome 시작 실패");
}

/**
 * ChromeDriver를 시작하고 기존 Chrome에 연결
 *
 * @param int $debugPort Chrome의 remote debugging 포트
 * @param int $cdPort ChromeDriver 포트 (기본: 9515, 충돌 시 9516 등 사용)
 */
function connectToChrome(int $debugPort, int $cdPort = 9515): RemoteWebDriver
{
    exec("lsof -ti tcp:{$cdPort} | xargs kill -9 2>/dev/null");
    sleep(1);
    exec("chromedriver --port={$cdPort} --silent > /dev/null 2>&1 &");
    sleep(2);

    // 핵심: debuggerAddress로 기존 Chrome에 연결
    $options = new ChromeOptions();
    $options->setExperimentalOption('debuggerAddress', "localhost:{$debugPort}");

    $capabilities = DesiredCapabilities::chrome();
    $capabilities->setCapability(ChromeOptions::CAPABILITY, $options);

    return RemoteWebDriver::create(
        "http://localhost:{$cdPort}",
        $capabilities,
        60000,  // 연결 타임아웃 60초
        120000  // 요청 타임아웃 120초
    );
}

/**
 * Cloudflare 챌린지 통과 대기
 *
 * 타이틀 기반으로 판단:
 * - "Just a moment...", "잠시만", "Cloudflare" 등이 타이틀에 포함되면 챌린지 중
 * - 실제 페이지 타이틀이 나오면 통과 완료
 *
 * @param RemoteWebDriver $driver
 * @param int $maxWait 최대 대기 시간 (초). 최초 접속 시 90초 권장
 * @return bool 통과 여부
 */
function waitForCloudflare(RemoteWebDriver $driver, int $maxWait = 60): bool
{
    $waited = 0;
    while ($waited < $maxWait) {
        $title = $driver->getTitle();

        if (
            stripos($title, 'just a moment') === false &&
            stripos($title, '잠시만') === false &&
            stripos($title, 'attention required') === false &&
            stripos($title, 'cloudflare') === false &&
            !empty($title)
        ) {
            return true; // 통과!
        }

        sleep(2);
        $waited += 2;
    }
    return false; // 시간 초과
}

/**
 * 정리: Chrome 및 ChromeDriver 프로세스 종료
 */
function cleanup(int $debugPort, int $cdPort = 9515): void
{
    exec("lsof -ti tcp:{$cdPort} | xargs kill -9 2>/dev/null");
    exec("lsof -ti tcp:{$debugPort} | xargs kill -9 2>/dev/null");
}
```

### 사용 패턴

```php
test('Cloudflare WAF 사이트 자동화', function () {
    $debugPort = 9222;
    $userDataDir = '/tmp/chrome-automation-profile';

    try {
        // 1. Chrome 시작 + 연결
        launchChrome($userDataDir, $debugPort);
        $driver = connectToChrome($debugPort);

        // 2. 사이트 접속 + Cloudflare 통과
        $driver->get('https://target-site.com');
        $passed = waitForCloudflare($driver, 90);

        // 첫 시도 실패 시 새로고침 후 재시도
        if (!$passed) {
            $driver->navigate()->refresh();
            sleep(5);
            $passed = waitForCloudflare($driver, 60);
        }

        expect($passed)->toBeTrue('Cloudflare 통과 실패');

        // 3. 자동화 작업 수행
        // JavaScript로 데이터 추출:
        $data = $driver->executeScript('return document.title;');

        // DOM 요소 조작:
        // $driver->findElement(WebDriverBy::cssSelector('...'))->click();

    } finally {
        if (isset($driver)) $driver->quit();
        cleanup($debugPort);
    }
});
```

## 중요 팁 및 주의사항

### Cloudflare 관련
1. **최초 접속만 오래 걸림**: 첫 페이지 로드에서 챌린지를 통과하면, 이후 쿠키(`cf_clearance`)로 즉시 통과
2. **새로고침 트릭**: 첫 시도에서 90초 이상 대기해도 통과 안 되면 `$driver->navigate()->refresh()` 후 재시도
3. **user-data-dir 재사용**: 같은 프로필 경로를 재사용하면 이전 Cloudflare 쿠키가 남아있어 후속 실행이 더 빠름
4. **타이틀 기반 판단**: 페이지 소스에 Cloudflare 관련 요소가 잔존할 수 있으므로, 타이틀이 실제 컨텐츠를 보여주면 통과된 것으로 판단

### Chrome/ChromeDriver 관련
5. **포트 충돌 방지**: 실행 전 기존 프로세스를 kill하고, 여러 테스트 시 다른 포트 사용 (9222, 9223 등)
6. **Chrome 버전 = ChromeDriver 버전**: 반드시 일치해야 함. `chromedriver --version`과 Chrome 버전 확인
7. **macOS quarantine 해제**: `xattr -d com.apple.quarantine /opt/homebrew/bin/chromedriver` 필수

### 봇 탐지 방지
8. **요청 간 랜덤 딜레이**: `sleep(rand(3, 7))` 등으로 요청 간격에 변동
9. **자연스러운 타이핑**: 입력 시 한 글자씩 `usleep(rand(50000, 150000))`으로 딜레이
10. **JavaScript로 값 설정**: 직접 `sendKeys()`보다 `executeScript()`로 값을 설정하는 것이 더 안정적

### 데이터 추출 팁
11. **JavaScript 실행**: `$driver->executeScript()` 로 DOM에서 직접 데이터 추출이 가장 효율적
12. **HTML 저장**: 디버깅 시 `$driver->getPageSource()`를 파일로 저장하여 구조 분석
13. **선택자 우선순위**: CSS 선택자 > XPath > innerText 기반 검색

## 테스트 실행

```bash
# 전체 테스트 실행
./vendor/bin/pest tests/Feature/YourTest.php --no-coverage

# 특정 테스트만 실행
./vendor/bin/pest --filter="테스트 이름"
```

## 파일 구조 예시

```
project/
├── composer.json
├── vendor/
├── phpunit.xml
├── tests/
│   ├── Pest.php
│   └── Feature/
│       └── YourScrapingTest.php   ← 자동화 테스트 파일
├── tmp/
│   └── output.json                ← 추출 결과
└── .claude/
    └── skills/
        └── waf/
            └── SKILL.md           ← 이 스킬 문서
```
