# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## 개요

Jar Exporter(`_JarUtil.exe`)는 Eclipse 프로젝트의 Java 소스를 컴파일한 뒤, 패키지 폴더 단위로 묶어 여러 개의 jar를 한 번에 만드는 Delphi VCL 유틸리티다. EzQ 서버(`_Source/_Server/_Server`)의 서버 모듈별 jar(`EzQCNS.jar`, `EzQLib.jar` 등)를 패키징할 때 쓴다. 상위 폴더 CLAUDE.md들에 나오는 `_JarUtil.exe` + `_JarUtil.ini`가 이 도구다. 같은 일을 하는 PowerShell 버전이 서버 폴더의 `_BuildJar.ps1`이며, 컴파일 옵션은 그 스크립트와 맞춰 두었다.

소스는 `_JarUtil.dpr`(진입점)과 `UnitMain.pas`/`.dfm`(폼 하나, 로직 전부) 두 개뿐이다. 이 폴더는 SVN 작업 사본 안에 있는 독립 git 저장소(branch `master`)다.

## 빌드

Delphi XE5(BDS 12.0), Win32 VCL 전용. 외부 라이브러리 의존성은 없다.

```
cmd /c '"C:\Program Files (x86)\Embarcadero\RAD Studio\12.0\bin\rsvars.bat" && msbuild _JarUtil.dproj /t:Build /p:Config=Debug /p:Platform=Win32'
```

- `Debug|Win32` 구성은 `DCC_ExeOutput=..\..\_Server`라서 빌드하면 **서버 폴더의 `_JarUtil.exe`가 바로 교체된다**. `Debug` 공통 구성의 `Bin`은 Win32 설정에 덮인다.
- `Bin/_JarUtil.exe`는 git에 커밋되는 배포 바이너리다. 빌드 후 서버 폴더의 exe를 `Bin/`으로 복사해 함께 커밋한다.
- 단위 테스트는 없다. 서버 프로젝트 사본(`.classpath`, `.settings`, `src`, `lib`, exe, ini)을 짧은 경로에 만들고 `_JarUtil.exe silent`를 실행해 종료 코드와 `_JarUtil.log`를 확인한다. 긴 경로(예: scratchpad 아래)에서는 MAX_PATH를 넘는 소스 파일을 열지 못한다.

## 동작 방식

exe는 Eclipse 프로젝트 루트(`.classpath`가 있는 곳)에 두고 실행한다. 모든 경로는 exe 폴더 기준이다.

설정 파일은 `<exe이름>.ini`(`Bin/_JarUtil.ini`는 샘플):

```ini
[Config]
JarExe Path=...\bin\jar.exe   ; javac.exe 도 같은 폴더에서 찾는다
Export Path=                  ; 비우면 <exe폴더>\JarExport
View Folder=0                 ; 체크박스를 클릭하면 프로그램이 다시 씀
Build Before Export=1         ; 0이면 컴파일 없이 Eclipse 출력 폴더를 그대로 묶음
[ExportConfig]
EzQCNS.jar=CNSServer          ; jar 이름 = 클래스 폴더 아래의 패키지 폴더
```

빌드는 **JDK 8 전용**이다. 서버 소스가 JDK 9에서 제거된 `sun.misc.BASE64*`를 쓰기 때문이다.
- `JarExe Path`가 없으면 `%JAVA8_HOME%\bin\jar.exe`를 찾는다. 그것도 없으면 `%JAVA_HOME%\bin\jar.exe`를 쓰되, `JAVA_HOME`이 JDK 8일 때만 쓴다.
- JDK 버전은 `<JDK>\release`의 `JAVA_VERSION`으로 판단한다(`JdkVersionOf`/`IsJdk8`). JDK 8이 아니면 `Jar.exe Path`가 빨갛게 표시된다.
- 컴파일 직전에 `javac -version` 결과도 확인한다. 1.8이 아니면 컴파일하지 않고 실패로 끝난다.

`MakeJar`의 처리 단계는 `[1/3]`→`[3/3]` 순서로 화면 로그(`memoLog`)와 진행바에 표시된다.
1. **소스 수집**(`CompileSources`): `.classpath`의 `kind="src"` 폴더를 탐색하고 `build\`를 지운 뒤 새로 만든다. `.java`가 아닌 파일은 Eclipse처럼 `build\classes`로 복사한다. 인코딩이 UTF-8인데 BOM이 있는 `.java`가 있으면 파일명을 출력하고 중단한다(javac 8은 BOM을 오류로 처리한다).
2. **컴파일**: `javac -XDignore.symbol.file -nowarn -encoding <enc> -source/-target <level> -g:<source,lines,vars> -d build/classes -cp <lib들> @build/sources.txt`. 인코딩, 레벨, 디버그 정보는 `.settings/*.prefs`에서 읽는다(`-g`를 빼면 지역변수 정보가 빠져 Eclipse 빌드보다 jar가 작아진다). 클래스패스는 `.classpath`의 `kind="lib"`를 **선언 순서 그대로** 읽는다. 순서가 바뀌면 다른 jar에 든 구버전 org.json이 잡힌다. 컴파일이 실패하면 jar를 하나도 만들지 않는다.
3. **jar 생성**(`ArchiveJars`): 항목마다 `jar cf <jar>.tmp -C build\classes <패키지>`를 실행한 뒤 `MoveFileEx`로 교체한다. 실행 중인 서버가 jar를 잡고 있으면 이 단계에서 실패로 표시된다. 값이 `WebContent`인 항목만 `<exe폴더>\WebContent`를 묶는다.

외부 프로세스는 `RunProcess`가 파이프로 stdout/stderr를 받아 한 줄씩 로그에 찍는다. 출력은 시스템 ANSI 코드페이지(CP949)로 해석한다. 작업 중에는 `Application.ProcessMessages`로 화면을 갱신한다. 그동안 다시 실행되지 않도록 버튼과 목록을 비활성화하고(`SetRunning`), 창도 닫히지 않게 막는다(`FormCloseQuery`). 끝나면 로그 전체를 `_JarUtil.log`(UTF-8)로 저장한다. 실패하면 진행바를 끝까지 채운 뒤 오류 상태(`pbsError`, 빨강)로 바꾸고 상태 글자도 빨갛게 표시한다. 이어서 `ShowFailDialog`가 로그에서 실패·오류 줄과 javac `error:` 줄을 최대 15줄 모아 오류 다이얼로그로 보여준다(silent 모드에서는 띄우지 않는다). jar.exe를 찾지 못하면 `Jar.exe Path` 글씨가 빨갛게 표시된다(`UpdateJarPathColor`).

UI에서 "Export All"을 누르면 전체를, 목록 항목을 더블클릭하면 그 jar 하나만 만든다(두 경우 모두 컴파일은 전체). `_JarUtil.exe silent`는 창 없이 ini의 전체 목록을 처리하고, 실패하면 종료 코드 1을 반환한다.

## 주의사항

- `UnitMain.pas`는 **CP949** 인코딩에 CRLF 줄바꿈이다. UTF-8로 저장하면 한글 주석이 깨진다. 셸 도구로 치환할 때는 백슬래시가 변형되기 쉬우므로 스크립트를 파일로 저장해 실행하는 편이 안전하다.
- 들여쓰기는 3칸이다. 이벤트 핸들러 이름이 `.dfm`에 바인딩되어 있으므로 `.pas`와 `.dfm`을 같이 수정한다.
- `build\` 폴더는 `_BuildJar.ps1`과 같이 쓴다. 두 도구 모두 실행할 때마다 지우고 새로 만든다.
- `dcu/`, `*.dproj.local`은 빌드 산출물이므로 커밋하지 않는다.
