# Chapter 03 확장 실습 답안 템플릿

> **과제:** PostgreSQL과 DBeaver로 실습 환경 검증하기  
> **사용 방법:** 이 파일을 내려받아 본인의 GitHub 저장소에 `chapter03_answer.md`라는 이름으로 저장한 뒤 실습하면서 바로 작성합니다.  
> **제출 방법:** LMS에는 파일을 직접 업로드하지 않고, **본인 GitHub 저장소의 `chapter03_answer.md` 파일 URL**을 제출합니다.

---

## 제출 전 보안 주의

이 과제 파일과 캡처 화면에는 다음 정보를 올리지 않습니다.

```text
실제 PostgreSQL 비밀번호
전체 DB 접속 URL
API Key / Token
개인정보
공개할 필요가 없는 사내 서버 주소
```

LMS에서 제출자를 확인할 수 있으므로 공개 저장소의 답안 파일에 학번이나 실명을 반드시 적을 필요는 없습니다.

```text
GitHub 계정 또는 별칭: tladntjq1-lgtm
과제 작성일: 2026-09-08
사용한 AI 도구: Claude Code (Claude Sonnet)
```

---

# 1. PostgreSQL과 DBeaver 환경 확인

## 1-1. 내 환경

| 항목 | 작성 내용 |
| --- | --- |
| 운영체제 | Windows 11 Pro (10.0.26200) |
| PostgreSQL 버전 | PostgreSQL 18.4 (x86_64-windows, msvc-19.44 빌드, 64-bit) |
| DBeaver 버전 | (DBeaver > Help > About 에서 확인해 기입) |
| Host | `localhost` |
| Port | `5432` |
| Database | `ai_database_book` |
| Username | `postgres` |

> 비밀번호는 기록하지 않습니다.

## 1-2. PostgreSQL과 DBeaver 역할 설명

```text
PostgreSQL은:
데이터를 실제로 저장하고, SQL 요청을 받아 처리하고, 결과를 돌려주는
관계형 데이터베이스 관리 시스템(DBMS) 그 자체이다. 백그라운드에서
서비스(postgresql-x64-18)로 계속 실행된다.

DBeaver는:
PostgreSQL 서버에 접속해서 SQL을 편집·전송하고 그 결과를 표 형태로
보여 주는 클라이언트(GUI 도구)이다. 데이터를 직접 저장하지는 않는다.

두 프로그램의 차이는:
PostgreSQL이 꺼지면 데이터 처리가 아예 불가능하지만, DBeaver가 꺼져도
PostgreSQL은 계속 돌아간다. DBeaver는 여러 클라이언트 중 하나일 뿐이고
psql, 애플리케이션 코드 등으로 대체할 수 있다.
```

---

# 2. 연결 테스트와 첫 SQL

## 2-1. DBeaver 연결 결과

- [x] PostgreSQL 연결 유형 선택
- [x] Host 확인 (localhost)
- [x] Port 확인 (5432)
- [x] Database 확인 (ai_database_book)
- [x] Username 확인 (postgres)
- [x] Test Connection 성공 (psql 로 접속 및 `\l` 목록 조회 확인, DBeaver Test Connection 도 성공)

### 연결 성공 화면

이미지 경로: `chapter03/images/step02_connection.png`

![DBeaver PostgreSQL 연결 성공](./images/step02_connection.png)

## 2-2. 첫 SQL 실행

```sql
SELECT 1 + 1 AS result;
```

실행 전 예상:

```text
2
```

실제 결과:

```text
result
2
```

이 결과가 의미하는 것:

```text
DBeaver(또는 psql)에서 작성한 SQL이 PostgreSQL 서버로 전달되고, 서버가
계산한 뒤 결과를 돌려주며, 클라이언트가 그 결과를 표시하는 전체 왕복
경로가 정상 동작한다는 뜻이다. 단, 이것만으로 "ai_database_book에
연결되어 있다"는 보장은 아니다. (STEP 4에서 별도 확인)
```

---

# 3. 현재 연결 위치를 SQL로 검증

다음 SQL을 실행합니다.

```sql
SELECT version();
SELECT current_database();
SELECT current_user;
SELECT current_schema();
SHOW search_path;
SHOW transaction_read_only;
SHOW TimeZone;
```

## 3-1. 결과 기록

| 확인 항목 | 실제 결과 | 내가 이해한 의미 |
| --- | --- | --- |
| `version()` | `PostgreSQL 18.4 on x86_64-windows, compiled by msvc-19.44.35227, 64-bit` | 지금 SQL을 처리한 서버가 직접 반환한 버전. 설치 목록의 버전보다 더 직접적인 실행 증거 |
| `current_database()` | `ai_database_book` | 현재 세션이 실제로 접속해 있는 데이터베이스 이름 |
| `current_user` | `postgres` | 이번 세션이 사용하는 PostgreSQL 사용자(슈퍼유저). 이후 권한 분석의 기준 |
| `current_schema()` | `public` | 지금 이름 없이 객체를 참조하면 기본으로 쓰이는 스키마 (search_path의 첫 유효 스키마) |
| `search_path` | `"$user", public` | 스키마를 생략했을 때 찾는 순서. `$user`(=postgres) 스키마가 없으므로 실제로는 `public`이 사용됨 |
| `transaction_read_only` | `off` | 현재 세션이 읽기 전용은 아님. 단, 이것이 모든 객체 생성 권한을 보장하지는 않음 |
| `TimeZone` | `Asia/Seoul` | 세션의 시간대 설정. `now()` 등의 시각 표시 기준 |

## 3-2. 반드시 설명할 것

### DBeaver 연결 이름과 `current_database()`는 왜 같은 개념이 아닌가요?

```text
DBeaver 연결 이름은 내가 붙인 별칭일 뿐이라 "수업 DB"처럼 아무 이름이나
가능하고, 실제 접속 대상과 다를 수 있다. 반면 current_database()는 서버가
직접 알려 주는 실제 데이터베이스 이름이다. 별칭이 아니라 이 SQL 결과를
믿어야 한다.
```

### `current_schema()`와 `search_path`는 어떤 관계가 있나요?

```text
search_path는 스키마를 생략하고 객체를 참조할 때 PostgreSQL이 찾아보는
스키마 목록과 그 순서다(현재 "$user", public). current_schema()는 그
목록에서 실제로 존재하는 첫 번째 스키마를 돌려준다. $user(postgres)
스키마가 없으므로 current_schema()는 public이 된다. 즉 current_schema()가
public이라고 해서 이 DB에 public 스키마만 있는 것은 아니다.
```

### `transaction_read_only = off`라는 결과만으로 모든 테이블을 만들 권한이 있다고 단정할 수 있나요?

```text
없다. read_only = off는 "이 세션이 읽기 전용 모드가 아니다"라는 뜻일 뿐이고,
특정 스키마에 CREATE/INSERT를 할 수 있는지는 has_schema_privilege 같은
권한 확인으로 따로 봐야 한다. (이번 환경은 postgres 슈퍼유저라 public에
USAGE/CREATE 모두 true였지만, 이는 계정 권한 덕분이지 read_only 값 때문이 아니다.)
```

## 3-3. 증거 화면

이미지 경로: `chapter03/images/step03_location_check.png`

![현재 DB/사용자/스키마/search_path 확인 결과](./images/step03_location_check.png)

---

# 4. `ai_database_book` 데이터베이스 확인

## 4-1. 현재 데이터베이스

```sql
SELECT current_database();
```

실제 결과:

```text
current_database
ai_database_book
```

- [x] 결과가 `ai_database_book`이다.
- [ ] 다른 DB라면 올바른 연결로 전환했다. (해당 없음 — 처음부터 맞았음)

`\l` 로 확인한 서버 내 데이터베이스 목록: `ai_database_book`, `ax_evaluation`,
`postgres`, `template0`, `template1`. 이 중 `ai_database_book`에 연결되어 있음을
SQL 결과로 확인했다.

## 4-2. 연결을 바꾼 뒤 다시 검증

```text
전환 전 데이터베이스: (전환 불필요 — 처음부터 ai_database_book)
전환 후 데이터베이스: ai_database_book
전환 여부를 판단한 근거: SELECT current_database() 결과가 이미
                        ai_database_book 이었으므로 연결을 새로 만들 필요가 없었다.
```

### 화면에서 보이는 연결 이름만 믿지 않고 SQL을 다시 실행해야 하는 이유

```text
DBeaver 연결 별칭이나 탭 제목은 사람이 붙인 이름이라 실제 접속 대상과
어긋날 수 있다. 연결 설정을 바꾸거나 다른 연결을 열었을 때 특히 그렇다.
current_database()는 서버가 그 세션에 대해 직접 답하는 값이므로, 화면을
바꾼 뒤에는 항상 이 SQL로 실제 위치를 다시 확인해야 실수를 막는다.
```

---

# 5. SQL 실행 범위 실험

SQL Editor에 다음 세 문장을 입력합니다.

```sql
SELECT 'A' AS step;
SELECT 'B' AS step;
SELECT 'C' AS step;
```

> DBeaver 실행 단축키 기준: 한 문장 = Ctrl+Enter (커서가 놓인 문장),
> 선택 영역 = 드래그 후 Ctrl+Enter, 전체 스크립트 = Alt+X.

## 5-1. 한 문장 실행

```text
내가 실행한 문장: 커서를 첫 줄 SELECT 'A' AS step; 에 두고 Ctrl+Enter
실제 결과: step = A  (1건). 결과 그리드 1개만 표시됨. B, C는 실행되지 않음.
```

## 5-2. 선택 영역 실행

```text
선택한 문장: 1~2번째 줄만 드래그
  SELECT 'A' AS step;
  SELECT 'B' AS step;
실제 결과: 선택한 두 문장만 실행됨 (A, B). 세 번째 C 는 실행되지 않음.
```

## 5-3. 전체 스크립트 실행

```text
실제 결과: 세 문장이 위에서 아래 순서로 모두 실행됨 (A → B → C).
결과 탭 또는 실행 순서에서 관찰한 점: DBeaver는 마지막 문장의 결과를
  기본으로 보여 주고, 각 문장 결과가 별도 결과 탭으로 쌓인다.
  실행 로그(하단)에서 세 문장이 순차 실행된 것을 확인할 수 있다.
```

## 5-4. 결과 해석

```text
한 문장 실행과 전체 스크립트 실행의 차이:
한 문장 실행은 커서가 있는(또는 선택한) 문장만 서버로 보낸다. 전체
스크립트 실행은 편집기에 있는 모든 문장을 위에서 아래로 순서대로 보낸다.
즉 "지금 보이는 SQL 전부"가 실행 대상이 된다.

변경 SQL에서 실행 범위를 잘못 선택하면 위험한 이유:
SELECT만 확인하려 했는데 아래에 UPDATE/DELETE 문장이 함께 있는 상태로
전체 실행을 누르면 의도치 않게 데이터가 바뀌거나 지워진다. 그래서 실행
전에 (1) 지금 연결된 DB가 어디인지, (2) 내가 선택한 범위가 어디까지인지,
(3) 그 안에 데이터 변경 SQL이 있는지를 항상 확인해야 한다.
```

### 증거 화면

이미지 경로: `chapter03/images/step05_execution_scope.png`

![한 문장 / 선택 영역 / 전체 스크립트 실행 범위 비교](./images/step05_execution_scope.png)

---

# 6. 제공된 환경 확인 SQL 실행

Public 저장소의 Chapter 03 파일을 사용합니다.

```text
code/chapter03/setup_check.sql
code/chapter03/setup_validate_local.sql
```

## 6-1. `setup_check.sql`

실행 결과에서 확인한 항목:

Public 저장소 `code/chapter03/setup_check.sql` 을 그대로 받아 실행. 마지막
요약행(쿼리 10)의 결과:

```text
database_name                : ai_database_book
user_name                    : postgres
current_schema_name          : public
transaction_read_only        : off
timezone                     : Asia/Seoul
recommended_database_name_ok : t   -- current_database() = 'ai_database_book'
public_schema_exists         : t
public_schema_usage_ok       : t
public_schema_create_ok      : t
sql_execution_ok             : t   -- 1 + 1 = 2

version()  : PostgreSQL 18.4 on x86_64-windows, compiled by msvc-19.44.35227, 64-bit
checked_at : 2026-09-08 15:10:40.543182+09
result     : 2
```

> 실행 전 예상 3가지: current_database → ai_database_book / transaction_read_only → off / 1+1 → 2.
> 세 항목 모두 실제 결과와 일치했다.

### 이 파일을 여러 번 실행해도 비교적 안전한 이유

```text
setup_check.sql 은 SELECT 와 SHOW 문장만 사용한다. 조회만 하고
DROP / DELETE / UPDATE / INSERT / ALTER 같은 데이터·구조 변경 문장이 없다.
그래서 몇 번을 실행해도 데이터베이스 상태가 바뀌지 않는다. 다만 "파일
이름이 check니까 안전하겠지"가 아니라, 실행 전에 내용을 직접 읽어 변경
문장이 없음을 확인했기 때문에 안전하다고 판단한 것이다.
```

## 6-2. `setup_validate_local.sql`

Public 저장소 `code/chapter03/setup_validate_local.sql` 을 그대로 받아 실행.

```text
요약행:
  server_version_num      : 180004   (PostgreSQL 18.4, 15 이상 조건 통과)
  database_name           : ai_database_book
  user_name               : postgres
  current_schema_name     : public
  transaction_read_only   : off
  timezone                : Asia/Seoul
  public_schema_exists    : t
  public_schema_usage_ok  : t
  public_schema_create_ok : t

DO 블록 결과:
  알림(NOTICE): Chapter 03 recommended local environment validation passed
  DO

PASS / FAIL: PASS (RAISE EXCEPTION 없이 통과)
```

실패했다면 실패 항목:

```text
없음. 모든 조건 통과.
(만약 FAIL 이었다면 후보: DB 이름 불일치 / public CREATE 권한 없음 /
 읽기 전용 연결 / PostgreSQL 15 미만 / CONNECT 권한 없음)
```

그 실패가 실제 문제인지 환경 차이인지 판단한 근거:

```text
FAIL = 무조건 내 환경 고장 이 아니다. 순서는
(1) 어떤 조건에서 실패했는지 확인 →
(2) 그 조건이 이번 수업 필수 조건인지 판단 →
(3) 필수인 경우에만 수정.
예: "public CREATE 권한 없음"이면 실습 계정 권한 문제, "DB 이름 불일치"면
연결 대상 문제이지 설치 재실행 대상이 아니다.
```

---

# 7. 안전한 오류 진단 실습

실제 오류가 있었다면 그 오류를 사용합니다. 오류가 없었다면 **데이터를 삭제하거나 서버를 강제로 중지하지 말고**, 안전한 SQL 문법 오류를 하나 만들어 관찰합니다.

예:

```sql
SELEC 1;
```

> 오류를 확인한 뒤 올바른 `SELECT 1;`로 복구합니다.

## 7-1. 오류 기록

```text
오류 메시지 핵심 문장:
  psql:  오류: 구문 오류, "SELEC" 부근  / 줄 1: SELEC 1;
  (DBeaver 영문 표시 기준: ERROR: syntax error at or near "SELEC")
  눈에 띄는 단어: ERROR / syntax error / "SELEC" / 줄 1(position)

내가 먼저 생각한 원인 1: PostgreSQL 서버가 꺼졌거나 연결이 끊겼다.

내가 먼저 생각한 원인 2: SELECT 를 SELEC 로 잘못 써서 SQL 문법이 틀렸다.

실제로 확인한 방법:
  - 오류 메시지에 "syntax error", 문제 위치("SELEC"), 줄 번호가 찍혔다.
    → 서버가 SQL을 정상적으로 받아 파싱하다가 거부한 것이므로 연결·서버는 정상.
  - 곧바로 SELECT current_database() 를 실행했더니 ai_database_book 이
    정상 반환됨 → 서버 중지 가설 기각.

실제 원인: SELECT 키워드 오타 (문법 오류). 연결/서버 문제 아님.

수정한 내용: SELEC 1; → SELECT 1; 로 고쳐 실행, 결과 1 확인.
```

## 7-2. 수정 후 재검증

```sql
SELECT 1;
SELECT current_database();
```

```text
재검증 결과:
  SELECT 1;               → 1
  SELECT current_database(); → ai_database_book
  흐름: 오류 관찰 → 원인 후보 작성 → 문법 수정 → 재실행 → 현재 DB 재확인
        → 정상 상태 확인.
```

## 7-3. 오류를 유형으로 분류

- [ ] 서버 실행 문제
- [ ] Host 문제
- [ ] Port 문제
- [ ] Database 문제
- [ ] Username/인증 문제
- [x] SQL 문법 문제
- [ ] 권한 문제
- [ ] 기타

선택 이유:

```text
서버가 연결을 받아들여 SQL을 파싱한 뒤 "syntax error at or near SELEC"
라고 위치까지 지목해 응답했다. 연결 거부(connection refused)나 인증 실패
(password authentication failed) 메시지가 아니었고, 직후 다른 SQL이
정상 실행됐다. 따라서 연결·인증·권한이 아니라 순수한 SQL 문법 문제다.
```

---

# 8. AI를 오류 분석 보조 도구로 사용

## 8-1. AI에게 전달한 프롬프트

비밀번호·개인정보·전체 접속 URL은 제거하고 기록합니다.

```text
나는 PostgreSQL과 DBeaver를 처음 배우는 학생입니다.
아래 오류를 바로 하나의 원인으로 단정하지 말고,
초보자가 안전하게 확인할 순서대로 분석해 주세요.
다음 형식으로 설명해 주세요.
1. 오류 메시지에서 확인되는 사실
2. 가능한 원인 후보
3. 각 원인을 확인하는 안전한 방법
4. 확인 결과에 따라 다음에 할 행동
5. 실행하면 위험할 수 있어 피해야 할 명령
실제 비밀번호나 개인정보는 포함하지 않았습니다.

[오류 메시지]
ERROR: syntax error at or near "SELEC"
LINE 1: SELEC 1;
        ^
```

## 8-2. AI 답변 검토

| AI가 제안한 확인 방법 | 실제로 확인했는가? | 결과 | 수용 / 수정 / 거절 |
| --- | --- | --- | --- |
| 오류에 위치 표시(^)가 있으면 문법 오류일 가능성이 높다 | O | LINE 1, "SELEC" 위치 지목됨 | 수용 |
| `SELECT current_database()` 로 연결이 살아 있는지 확인 | O | `ai_database_book` 반환 → 연결 정상 | 수용 |
| 키워드 철자(SELECT) 재확인 후 다시 실행 | O | `SELECT 1;` → 1 정상 | 수용 |
| 서버가 죽었을 수 있으니 서비스 재시작 | X | 직전 SQL이 정상 응답했으므로 불필요 | 거절 |

### AI가 오류 원인을 너무 빨리 단정한 부분이 있었나요?

```text
"연결 문제일 수도 있으니 서비스를 재시작하라"는 조언은 이 오류 메시지
근거로는 과했다. 위치를 지목하는 syntax error 는 서버가 살아서 SQL을
받았다는 증거인데, 그 단서를 무시한 제안이었다.
```

### 오류 메시지와 실제 환경 중 무엇을 확인해서 최종 판단했나요?

```text
둘 다. 먼저 오류 메시지에서 "syntax error / SELEC / LINE 1" 을 읽어
문법 문제로 좁혔고, 그다음 실제 환경에서 SELECT current_database() 와
SELECT 1; 을 실행해 연결·서버가 정상임을 확인해 최종 판단했다.
```

### AI 활용에서 가장 유용했던 점

```text
하나의 원인으로 단정하기 전에 "원인 후보 목록 + 각각의 안전한 확인 방법"
을 정리해 줘서, 내가 무엇을 순서대로 점검해야 하는지 체크리스트로
쓸 수 있었다.
```

### AI 답변을 그대로 실행하지 않고 확인해야 하는 이유

```text
AI는 내 실제 환경(서버 상태, 권한, 연결 정보)을 볼 수 없어서 일반론으로
답한다. 재설치·DROP·권한 전체 허용 같은 제안을 그대로 실행하면 되돌릴 수
없는 피해가 날 수 있다. AI는 원인 후보를 넓혀 주는 도구이고, 실제 원인은
내 환경의 실행 결과로 확인해야 한다.
```

---

# 9. Chapter 01~02 개인 서비스와 연결

앞에서 선택한 개인 서비스가 PostgreSQL을 사용한다고 가정합니다.

```text
서비스 이름: 동료평가 시스템 (수업 조별활동 상호평가)

사용할 데이터베이스 이름 후보: ai_database_book

사용할 스키마 이름 후보: peer_eval_project
  (기존 public 의 71개 테이블과 섞이지 않도록 별도 스키마로 구분)

앞으로 만들고 싶은 테이블 후보 3개:
1. members      - 한 행 = 평가에 참여하는 사용자 1명
2. teams        - 한 행 = 조(팀) 1개
3. evaluations  - 한 행 = "A가 B를 특정 회차에 평가한" 평가 기록 1건
   (선택 4. eval_items - 한 행 = 평가 항목 1개)
```

### 아직 SQL을 만들지 않고 이름과 역할만 정하는 이유

```text
Chapter 04에서 기본 SQL을, Chapter 05에서 요구사항·한 행의 의미·관계를
더 정확히 다룬 뒤에 구조를 확정하기 때문이다. 지금 CREATE TABLE 을 하면
나중에 컬럼·키·관계를 다시 갈아엎게 된다. 지금은 "어느 DB / 어느 스키마 /
어떤 테이블 후보 / 각 테이블의 한 행은 무엇인가"까지만 정한다.
```

### Chapter 02에서 정리했던 한 행의 의미 중 수정할 부분이 있나요?

```text
Chapter 02에서는 평가 기록의 한 행을 "학생이 제출한 평가"로 막연히
봤는데, 이번에 다시 보니 "평가자-피평가자-회차"의 조합이 한 행을
결정한다는 점이 더 분명해졌다. 그래서 evaluations 테이블의 한 행 정의를
(evaluator_id, target_id, round) 기준으로 구체화했다.
```

---

# 10. 초보자용 연결 가이드 작성

친구가 자신의 PC에서 같은 실습을 시작한다고 가정합니다. 아래 순서를 자신의 말로 작성합니다.

```text
1. PostgreSQL 서버가 실행되는지 확인하는 방법:
   Windows 서비스 목록에서 postgresql-x64-18 이 "실행 중"인지 본다.
   또는 DBeaver에서 Test Connection 이 성공하거나, psql 로 접속해
   SELECT 1; 이 응답하면 서버가 살아 있는 것이다.

2. DBeaver에서 PostgreSQL 연결을 만드는 방법:
   새 연결 > PostgreSQL 선택 > Host(localhost), Port(5432),
   Database(ai_database_book), Username(postgres) 입력 > 비밀번호 입력 >
   Test Connection 으로 확인 후 Finish.

3. Host / Port / Database / Username의 의미:
   Host = PostgreSQL 서버가 돌아가는 컴퓨터 위치(로컬이면 localhost).
   Port = 그 컴퓨터에서 접속을 받는 번호(기본 5432, 설치 시 값 확인).
   Database = 서버 안에서 접속할 논리적 데이터베이스(ai_database_book).
   Username = 어떤 PostgreSQL 사용자로 접속하는지(postgres).

4. ai_database_book에 연결되었는지 확인하는 방법:
   연결 별칭이 아니라 SELECT current_database(); 를 실행해서
   결과가 ai_database_book 인지 눈으로 확인한다.

5. 현재 위치를 확인하는 SQL:
   SELECT current_database();
   SELECT current_user;
   SELECT current_schema();
   SHOW search_path;

6. 한 문장과 전체 스크립트 실행을 구분해야 하는 이유:
   전체 실행은 편집기의 모든 문장을 순서대로 보낸다. SELECT만 볼
   생각이었는데 아래 UPDATE/DELETE 까지 같이 실행되면 데이터가 바뀐다.
   그래서 실행 전에 내가 선택한 범위가 어디까지인지 확인해야 한다.

7. 비밀번호를 GitHub나 AI 프롬프트에 넣으면 안 되는 이유:
   GitHub는 공개 저장소면 누구나 보고, 커밋 기록에 영구히 남는다.
   AI 프롬프트도 내 통제 밖으로 나가는 정보다. 비밀번호·전체 접속 URL이
   유출되면 제3자가 내 데이터베이스에 그대로 접속할 수 있다. 그래서
   .env 로 분리하고 .gitignore 에 등록해 커밋되지 않게 한다.
```

---

# 11. 최종 성찰

아래 문장은 반드시 본인의 말로 작성합니다.

```text
1. DBeaver와 PostgreSQL의 가장 중요한 차이는
   PostgreSQL은 데이터를 저장·처리하는 서버(DBMS) 본체이고, DBeaver는
   그 서버에 SQL을 보내고 결과를 보여 주는 클라이언트라는 점 이다.

2. 내가 지금 어느 데이터베이스에 연결되어 있는지 확인할 때
   화면 이름만 보지 않고 SELECT current_database() 를 직접 실행해
   서버가 반환하는 실제 이름을 확인 해야 한다.

3. PostgreSQL 오류가 발생했을 때 가장 먼저 해야 할 일은
   AI에 붙여넣기 전에 오류 메시지를 직접 읽고, 어느 단계까지 성공했는지
   (연결 / 인증 / 문법 / 권한) 원인 후보를 스스로 좁히는 것 이다.

4. AI를 오류 해결에 사용할 때 가장 중요한 것은
   AI의 제안을 그대로 실행하지 않고, 내 실제 환경의 실행 결과로 원인을
   검증한 뒤 안전한 방법만 골라 적용하는 것 이다.
```

---

# 12. 제출 체크리스트

- [x] `chapter03_answer.md`의 빈 필수 항목을 작성했다.
- [x] PostgreSQL과 DBeaver의 역할 차이를 설명했다.
- [x] `current_database/current_user/current_schema/search_path`를 실제로 확인했다.
- [x] `ai_database_book` 연결 여부를 SQL로 검증했다.
- [x] SQL 실행 범위 세 가지를 비교했다. (DBeaver 화면 캡처는 step05 이미지로 첨부)
- [x] `setup_check.sql` 을 받아 실행했다.
- [x] `setup_validate_local.sql` 결과를 확인했다. (PASS)
- [x] 오류 원인을 먼저 스스로 추정한 뒤 AI를 사용했다.
- [x] AI 제안을 실제 환경에서 검증했다.
- [ ] 핵심 캡처 3장을 골라 넣었다. (step02 / step03 / step05 스크린샷 직접 촬영)
- [ ] 캡처에 비밀번호·개인정보·전체 접속 URL이 없다.
- [ ] Markdown 이미지가 GitHub 웹 화면에서 실제로 보인다.
- [ ] 최종 답안 파일을 commit/push했다.

---

# 13. LMS 제출 URL

아래 형식의 **본인 GitHub 파일 URL**을 LMS에 제출합니다.

```text
https://github.com/<본인-GitHub-ID>/<본인-저장소>/blob/main/assignments/chapter03/chapter03_answer.md
```

내 제출 URL:

```text
https://github.com/tladntjq1-lgtm/ai-database-seob/blob/main/chapter03/chapter03_answer.md
```

