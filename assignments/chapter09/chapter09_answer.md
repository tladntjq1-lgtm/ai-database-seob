# Chapter 09 확장 실습 답안 템플릿

> **과제:** 트랜잭션으로 데이터 정합성 지키기  
> **사용 방법:** 이 파일을 내려받아 본인의 GitHub 저장소에 `chapter09_answer.md`라는 이름으로 저장한 뒤 실습하면서 바로 작성합니다.  
> **제출 방법:** LMS에는 파일을 직접 업로드하지 않고, **본인 GitHub 저장소의 `chapter09_answer.md` 파일 URL**을 제출합니다.

---

## 제출 전 주의

이 파일과 캡처 화면에는 실제 비밀번호, 전체 DB 접속 URL, API Key, 개인정보를 기록하지 않습니다.

```text
GitHub 계정 또는 별칭:tladntjq1-lgtm
과제 작성일:2026-09-30
사용한 AI 도구:claude
```

---

# 1. 시작 환경과 Chapter 07·08 기준 상태 확인

다음을 실행하거나 Chapter 09의 `01_transaction_lab_schema.sql` 사전 검사를 확인합니다.

```sql
SELECT current_database();
SELECT current_user;
SELECT current_schema();
SHOW search_path;
SHOW transaction_read_only;
```

| 확인 항목 | 실제 결과 | 의미 |
| --- | --- | --- |
| `current_database()` | ai_database_book | 실습 대상 데이터베이스 |
| `current_user` | postgres | 현재 접속 계정 |
| `current_schema()` | public | 기본 스키마(트랜잭션 실습은 course_project/transaction_lab을 스키마명으로 명시해서 사용하므로 current_schema가 transaction_lab일 필요는 없음) |
| `search_path` | "$user", public | 스키마 탐색 경로 |
| `transaction_read_only` | off | 쓰기 가능한 연결 |

또한 Chapter 09의 `01_transaction_lab_schema.sql` 사전 검사에서 Chapter 07·08 기준 상태(테이블 존재, 명명 제약조건 15개, NOT NULL 20개, `ai_database_book` CREATE 권한, `transaction_lab` 미존재)까지 자동으로 확인했고, 통과 메시지가 정상적으로 나왔다.

Chapter 07·08 기준값:

```text
students = 3
instructors = 2
courses = 3
enrollments = 5
전체 recorded_amount = 590000
활성 = 3 / 340000
취소 제외 = 4 / 440000
```

### 기준 상태가 다르면 Chapter 09를 계속 진행하면 안 되는 이유

```text
transaction_lab의 course_inventory·enrollments·payments는 course_project.students/courses를 FK로 참조한다. Chapter 07·08 기준(학생 3명, 강의 3개, 신청 5건, 금액 590000 등)이 어긋난 채로 시작하면, 뒤에서 좌석·신청·결제 트랜잭션 결과가 예상과 달라졌을 때 그 원인이 "내 트랜잭션 SQL이 잘못됨"인지 "애초에 Chapter 07 데이터가 달라짐"인지 구분할 수 없다. 실제로 이번 실습 전에 Chapter 08에서 학생 수가 4명으로 잘못 늘어난 적이 있어서, 기준 검사를 먼저 통과시키는 습관이 왜 필요한지 직접 경험했다.
```

---

# 2. `transaction_lab` 스키마 생성

실행 파일:

```text
code/chapter09/01_transaction_lab_schema.sql
```

## 2-1. 생성 전 예상

```text
생성될 스키마: transaction_lab
생성될 테이블 3개: course_inventory, enrollments, payments

course_inventory 한 행의 의미: 특정 강의(course_id)의 좌석 상태 한 건 (capacity, remaining_seats)
enrollments 한 행의 의미: transaction_lab에서 생성한 수강신청 사건 한 건
payments 한 행의 의미: 특정 lab enrollment에 연결된 결제 기록 한 건
```

## 2-2. 생성 결과

```text
통과 메시지: Chapter 09 transaction lab schema validation passed
```

기대 메시지:

```text
Chapter 09 transaction lab schema validation passed
```

### Chapter 07·08의 `course_project`와 별도 `transaction_lab`을 사용하는 이유

```text
course_project를 직접 변경하면서 트랜잭션(BEGIN/COMMIT/ROLLBACK)을 실험하면, 실수로 COMMIT하거나 ROLLBACK 대상을 잘못 잡았을 때 Chapter 07·08에서 애써 맞춰놓은 기준 데이터(학생 3명, 신청 5건, 590000 등)가 훼손될 수 있다. transaction_lab을 별도로 두면 좌석·신청·결제 실험은 이 스키마 안에서 마음껏 반복(리셋 포함)하면서도, course_project는 FK로 참조만 하고 절대 수정하지 않으므로 앞 장의 데이터를 안전하게 보호할 수 있다.
```

### 증거 화면

권장 경로:

```text
assignments/chapter09/images/step02_schema.png
```

`여기에 transaction_lab 구조가 보이는 핵심 화면을 삽입하세요.`

---

# 3. 초기 좌석과 기준 데이터 입력

실행 파일:

```text
code/chapter09/02_transaction_lab_seed.sql
```

## 3-1. 실행 전 예상

```text
course 301 remaining_seats 예상: 3 (본문 STEP 3 안내 문구 기준으로 일단 예상)
course 302 remaining_seats 예상: 0
course 303 remaining_seats 예상: 0
lab enrollments 예상 행 수: 0
payments 예상 행 수: 0
```

## 3-2. 실제 결과

```text
course 301 remaining_seats: 2 (capacity 2)
course 302 remaining_seats: 1 (capacity 1)
course 303 remaining_seats: 1 (capacity 1)
lab enrollments 행 수: 0
payments 행 수: 0
통과 메시지: Chapter 09 transaction lab seed validation passed
```

기대 초기 상태:

```text
course 301 / 302 / 303 remaining_seats = 3 / 0 / 0
lab enrollments = 0
payments = 0
```

### 예상과 실제가 다른 경우 원인

```text
실행 전 예상(301=3/302=0/303=0)은 본문 STEP 3 문구를 그대로 적어본 것이었는데, 실제 02_transaction_lab_seed.sql을 열어보면 초기값은 301=capacity 2/remaining 2, 302=capacity 1/remaining 1, 303=capacity 1/remaining 1로 정의되어 있었다. 즉 "본문에 적힌 문장"과 "실제 시드 스크립트의 값"이 다를 수 있으므로, 예상만 믿지 말고 반드시 실제 실행 결과(그리고 필요하면 시드 SQL 원본)를 직접 확인해야 한다는 걸 다시 확인했다.
```

---

# 4. 첫 번째 정상 COMMIT 추적

실행 파일:

```text
code/chapter09/03_commit_transaction.sql
```

이 실습은 학생 101이 강의 301을 신청하는 하나의 업무 단위를 추적합니다.

## 4-1. 업무 단위 정의

```text
이 트랜잭션에서 함께 성공해야 하는 변경 1: course 301 좌석 1개 감소(remaining_seats > 0일 때만)
변경 2: 학생 101의 lab enrollment(9001) 생성, status='수강중', recorded_amount=course_project.courses.price(100000)
변경 3: 해당 enrollment에 연결된 payment(9901) 생성, amount=recorded_amount와 동일(100000)

하나라도 실패하면 전체를 취소해야 하는 이유: 좌석만 줄고 신청이 없거나, 신청은 있는데 결제가 없거나, 반대로 결제만 있고 좌석이 안 줄어드는 상태는 모두 업무적으로 모순이다. "좌석 확보 + 신청 생성 + 결제 생성"은 하나의 수강신청 업무이므로 셋 다 성공했을 때만 확정(COMMIT)하고, 하나라도 실패하면 아무 것도 반영되지 않아야(ROLLBACK) 데이터가 항상 의미 있는 상태로 남는다.
```

## 4-2. 상태 변화 기록

| 시점 | course 301 남은 좌석 | lab enrollment 9001 | payment 9901 | 설명 |
| --- | ---: | --- | --- | --- |
| BEGIN 전 | 2 | 없음 | 없음 | 시드 직후 초기 상태 |
| 트랜잭션 내부 | 1 | 존재(student 101, course 301, 수강중, 100000) | 존재(amount 100000) | 좌석 UPDATE + CTE 연결 INSERT 실행 직후, 아직 COMMIT 전 |
| COMMIT 후 | 1 | 존재(그대로 유지) | 존재(그대로 유지) | 확정. 다른 세션에서도 이 값이 보임 |

## 4-3. COMMIT 조건

```text
좌석 UPDATE 기대 영향 행 수: 1
실제 영향 행 수: 1
신청 생성 기대 행 수: 1
결제 생성 기대 행 수: 1
recorded_amount와 payment.amount 일치 여부: 일치(100000 = 100000)
최종 COMMIT 판단: 조건을 모두 만족하여 COMMIT. (COMMIT 전 DO 블록 검증도 통과 → Chapter 09 first commit validation passed)
```

기대 메시지:

```text
Chapter 09 first commit validation passed
```

### SQL 오류가 없었다는 사실만으로 COMMIT하면 안 되는 이유

```text
문법적으로 완전히 정상인 UPDATE/INSERT라도 조건이 잘못되면(예: WHERE 조건을 빼먹어 좌석을 2행 감소시키거나, 다른 course_id에 연결하는 등) 오류 메시지 없이 잘못된 값이 그대로 반영될 수 있다. 이번 실습에서도 COMMIT 직전에 좌석 1 감소, 신청 1건, 결제 1건, 두 금액 일치라는 네 가지를 DO 블록으로 다시 확인한 뒤에만 COMMIT했다. "SQL이 에러 없이 실행됐다"와 "업무가 올바르게 완료됐다"는 서로 다른 문장이다.
```

### 증거 화면

권장 경로:

```text
assignments/chapter09/images/step04_commit.png
```

`여기에 COMMIT 후 좌석·신청·결제 관계를 확인할 수 있는 화면을 삽입하세요.`

---

# 5. ROLLBACK으로 전체 원상복구 확인

실행 파일:

```text
code/chapter09/04_rollback_transaction.sql
```

## 5-1. ROLLBACK 전 예상

```text
트랜잭션 안에서 임시로 바뀔 값: course 302 remaining_seats 1→0, enrollment 9002(student 102, course 302, 수강중, 120000) 생성, payment 9902(amount 120000) 생성
ROLLBACK 후 다시 돌아와야 할 값: course 302 remaining_seats=1, enrollment 9002/payment 9902는 존재하지 않음
이미 이전 파일에서 COMMIT된 9001/9901은 유지되어야 하는가: 그렇다 — 이번 트랜잭션과 무관한, 이미 확정된 과거 COMMIT이므로 영향받지 않아야 한다
```

## 5-2. 실제 결과

```text
ROLLBACK 후 course 301 상태: remaining_seats=1로 그대로 유지(9001 COMMIT 결과 그대로)
ROLLBACK 후 course 302 상태: remaining_seats=1로 복구
ROLLBACK 후 lab enrollments 행 수: 9002 없음 (9001만 남음)
ROLLBACK 후 payments 행 수: 9902 없음 (9901만 남음)
9001 존재 여부: 존재(유지됨)
9901 존재 여부: 존재(유지됨)
통과 메시지: Chapter 09 rollback validation passed
```

기대 메시지:

```text
Chapter 09 rollback validation passed
```

## 5-3. ROLLBACK과 IDENTITY

```text
ROLLBACK이 테이블 행 변경을 되돌리는 방식: 현재 트랜잭션 안에서 아직 COMMIT하지 않은 INSERT/UPDATE/DELETE를 모두 취소해 BEGIN 시점 상태로 되돌린다. 이미 COMMIT된 이전 트랜잭션(9001/9901)에는 영향을 주지 않는다.

IDENTITY 자동 번호가 반드시 이전 값으로 되돌아가지는 않는 이유: 이번 실습은 9002/9902처럼 번호를 명시적으로 입력했기 때문에 ROLLBACK 후 같은 번호를 다시 쓸 수 있었다. 하지만 IDENTITY가 자동으로 채번한 값이라면, 내부 시퀀스가 트랜잭션 취소와 무관하게 미리 증가해버려 그 번호가 일반적으로 회수되지 않을 수 있다.

번호가 건너뛰었다고 데이터 손상이라고 단정할 수 없는 이유: ID의 역할은 "행을 고유하게 식별하는 것"이지 "한 번도 빠지지 않는 업무 순번을 보장하는 것"이 아니다. 1, 2, 4, 5처럼 중간이 비어도 각 행이 올바르게 식별되고 관계가 맞다면 데이터는 정상이다.
```

---

# 6. 두 번째 COMMIT과 좌석 부족 0행 관찰

실행 파일:

```text
code/chapter09/05_commit_and_sold_out.sql
```

## 6-1. 두 번째 정상 COMMIT

```text
생성된 enrollment id: 9002
학생 id: 103
course id: 302
recorded_amount: 120000
payment id: 9902
payment amount: 120000
```

이 COMMIT 결과로 course 302의 remaining_seats는 1 → 0이 된다(마지막 좌석 소진).

## 6-2. 좌석 부족 시도

```text
좌석 확보 UPDATE 기대 영향 행 수: 0 (remaining_seats > 0 조건을 만족하는 행이 없음)
실제 영향 행 수: 0
후속 enrollment 생성 행 수: 0 (id=9003 생성되지 않음)
후속 payment 생성 행 수: 0 (id=9903 생성되지 않음)
```

기준상 좌석 부족 시 생성되지 않아야 하는 ID:

```text
9003
9903
```

### `UPDATE 0`이 SQL 실패가 아니라 업무상 실패일 수 있는 이유

```text
UPDATE ... WHERE remaining_seats > 0은 "조건을 만족하는 행이 있으면 감소시켜라"는 뜻이다. 좌석이 이미 0이면 조건을 만족하는 행이 없으므로 0행이 반환되는 게 정상 동작이며, PostgreSQL이 문법 오류를 낸 것도, 자동으로 ROLLBACK한 것도 아니다. 이건 "정원 마감"이라는 업무상 실패이지 SQL 실행 실패가 아니다. 애플리케이션(또는 이번 실습의 DO 블록)이 영향 행 수를 직접 확인해서 실패를 판단해야 한다.
```

### 영향 행 수가 0인데 신청과 결제를 계속 생성하면 어떤 정합성 문제가 생기나요?

```text
좌석은 확보되지 않았는데(remaining_seats 그대로 0) 신청(enrollment)과 결제(payment)만 새로 생성되는 모순이 생긴다. 이 실습에서는 seat CTE가 0행이면 그 결과를 RETURNING으로 넘겨받는 new_enrollment, 그리고 그걸 다시 넘겨받는 payment INSERT도 자동으로 0행이 되도록 CTE 체인으로 연결해뒀기 때문에 이런 모순이 애초에 발생하지 않는다. 만약 좌석 UPDATE 결과와 무관하게 신청/결제 INSERT를 독립적으로 실행했다면, "좌석 없이 신청·결제만 존재"하는 정합성 오류가 생겼을 것이다.
```

---

# 7. 주 실습 최종 정합성 검증

실행 파일:

```text
code/chapter09/06_transaction_validation.sql
```

## 7-1. lab 최종 상태

| 항목 | 기대값 | 실제값 | 일치? |
| --- | ---: | ---: | --- |
| course_inventory 행 수 | 3 | 3 | 일치 |
| lab enrollments 행 수 | 2 | 2 | 일치 |
| payments 행 수 | 2 | 2 | 일치 |
| course 301 remaining | 1 | 1 | 일치 |
| course 302 remaining | 0 | 0 | 일치 |
| course 303 remaining | 1 | 1 | 일치 |

## 7-2. 주요 행

```text
9001 = student 101 / course 301 / amount 100000 / payment 9901
실제: 동일 (수강중, recorded_amount 100000, payment 9901 amount 100000)

9002 = student 103 / course 302 / amount 120000 / payment 9902
실제: 동일 (수강중, recorded_amount 120000, payment 9902 amount 120000)

9003·9903 = 존재하지 않아야 함
실제: 존재하지 않음 (좌석 부족으로 생성되지 않고 ROLLBACK됨, 이후 IDENTITY만 9003/9903으로 재조정)
```

## 7-3. 보호 대상 확인

```text
course_project.enrollments 행 수: 5
전체 recorded_amount: 590000
활성 건수/금액: 3 / 340000
취소 제외 건수/금액: 4 / 440000
```

기대값:

```text
course_project.enrollments = 5
전체 = 590000
활성 = 3 / 340000
취소 제외 = 4 / 440000
```

최종 기대 메시지:

```text
Chapter 09 main transaction validation passed
```

(실제로 이 메시지 확인함)

### transaction_lab 실습 후에도 course_project 기준 상태를 다시 검사하는 이유

```text
이번 장의 목적은 "새 실습 스키마가 격리된 상태로 잘 동작하는가"뿐 아니라 "그 격리 실습이 기존 프로젝트 데이터를 손상시키지 않았는가"까지 확인하는 것이다. transaction_lab만 검증하고 끝내면, 혹시라도 실습 중 실수로 course_project를 건드렸을 가능성을 놓칠 수 있다. 그래서 완료 기준은 "새 실습 상태가 맞다 + 기존 프로젝트 상태도 그대로다" 두 가지를 모두 만족해야 한다.
```

---

# 8. ACID를 이번 실습으로 설명

교과서 정의를 그대로 복사하지 말고 이번 좌석·신청·결제 사례로 작성합니다.

```text
Atomicity: 좌석 감소 + enrollment 생성 + payment 생성 세 변경이 모두 반영되거나(COMMIT) 모두 취소된다(ROLLBACK). 6번 STEP에서 좌석이 부족했을 때 신청/결제도 함께 0건으로 남은 것이 그 예다.

Consistency: 트랜잭션 전후 상태가 이 프로젝트의 규칙(remaining_seats >= 0, payment.amount = enrollment.recorded_amount, 수강중 신청에는 payment가 존재)을 만족해야 한다. 09_error_and_savepoint 실습에서 다루는 "동일 학생·강의 중복 수강중 금지"도 Consistency의 일부다.

Isolation: 마지막 좌석(예: course 302의 남은 1자리)을 두 사용자가 동시에 신청하면, 격리 수준(READ COMMITTED)과 FOR UPDATE/조건부 UPDATE에 의해 한쪽만 성공하고 다른 쪽은 대기하거나 0행을 받아야 한다.

Durability: COMMIT된 9001/9901, 9002/9902는 이후 세션을 새로 열어도 그대로 조회된다 — 실제로 06번 최종 검증에서 다시 확인했다.
```

### Atomicity와 Consistency가 같은 뜻이 아닌 이유

```text
Atomicity는 "여러 변경이 다 반영되거나 다 취소되는가"만 보장하지, 그 변경들이 업무적으로 옳은지는 판단하지 않는다. 예를 들어 좌석 UPDATE 조건을 잘못 짜서(예: remaining_seats > 0 조건을 빼먹고) 좌석이 음수가 되는 SQL 세 개를 한 트랜잭션으로 묶어 COMMIT하면, Atomicity 관점에서는 "세 변경이 모두 성공"했지만 Consistency(remaining_seats >= 0)는 깨진다. 그래서 트랜잭션(Atomicity)만으로는 부족하고, 제약조건·업무 조건·검증 SELECT가 함께 있어야 Consistency까지 지킬 수 있다.
```

---

# 9. 선택 실습 — 두 세션 Lock 대기 관찰

실행 파일:

```text
code/chapter09/07_concurrency_two_sessions.sql
```

가능하면 DBeaver에서 **서로 다른 두 연결 세션**으로 수행합니다.

## 9-1. 내 환경

```text
실제 두 세션 실습 수행 / 절차 분석만 수행: 절차 분석만 수행 (시간 관계상 두 세션 실습은 이번 제출에서는 생략, 07_concurrency_two_sessions.sql 코드와 본문 설명으로 흐름만 분석함)
transaction_isolation: READ COMMITTED (PostgreSQL 기본값, 별도 변경하지 않음)
lock_timeout: 미실행 (실습했다면 SET LOCAL lock_timeout = '5s'로 설정할 예정)
```

## 9-2. 시간 순서 기록 (07 파일과 본문 설명을 근거로 한 절차 분석 — 실제 두 세션 실행은 미실행)

| 순서 | Session A | Session B | 관찰 |
| ---: | --- | --- | --- |
| 1 | `BEGIN; SELECT ... FOR UPDATE` (course 303) 실행, Lock 획득 | - | A가 먼저 Lock을 잡고 아직 COMMIT하지 않음 |
| 2 | (대기 중) | `BEGIN; SET LOCAL lock_timeout='5s'; SELECT ... FOR UPDATE`(같은 course 303) 실행 | B는 A가 Lock을 풀 때까지 대기, 5초 안에 안 풀리면 lock_timeout 오류 |
| 3 | `COMMIT;` (또는 `ROLLBACK;`) 실행 | (계속 대기) | A가 트랜잭션을 끝내는 순간 Lock이 풀림 |
| 4 | - | Lock 획득 성공, 최신 행 값 확인 후 자신의 트랜잭션 진행 | READ COMMITTED이므로 B는 A가 COMMIT한 이후의 최신 값을 보게 됨 |

```text
먼저 Lock을 획득한 세션: Session A
대기한 세션: Session B
A가 COMMIT/ROLLBACK한 뒤 B에서 일어난 일: B가 대기하던 Lock을 획득하고, READ COMMITTED 기준으로 A가 COMMIT한 최신 remaining_seats 값을 보며 자신의 조건부 UPDATE를 이어간다.
```

### Lock 대기와 Deadlock의 차이

```text
Lock 대기는 한쪽 트랜잭션이 이미 가진 잠금을 다른 쪽이 풀릴 때까지 기다리는 것으로, 시간이 걸릴 뿐 결국 앞선 트랜잭션이 COMMIT/ROLLBACK하면 자연히 풀린다. Deadlock은 두 트랜잭션이 서로 상대방이 가진 잠금을 기다리는 순환 구조(A는 course 301을 잡고 302를 기다리고, B는 302를 잡고 301을 기다리는 식)로, 이 경우 누군가 스스로 끝내지 않으면 영원히 풀리지 않으므로 PostgreSQL이 감지해 한쪽을 강제로 오류 종료시킨다. 이번 실습(같은 행 하나를 두 세션이 요청)은 단순 Lock 대기이지 Deadlock이 아니다.
```

### `SELECT ... FOR UPDATE`가 모든 UPDATE 앞에 항상 필요한 것은 아닌 이유

```text
UPDATE ... WHERE ... RETURNING 자체도 수정 대상 행에 필요한 잠금을 이미 획득하고, RETURNING/영향 행 수로 성공 여부를 바로 판단할 수 있다. 단일 조건부 변경 하나로 끝나는 경우라면 선행 SELECT ... FOR UPDATE 없이 조건부 UPDATE만으로 충분하다. FOR UPDATE가 특히 유용한 경우는, 행을 먼저 잠근 상태로 값을 읽고 그 값을 바탕으로 여러 후속 판단(예: 이번 장의 9.1처럼 가격을 확인한 뒤 여러 INSERT를 연결)을 이어가야 할 때다.
```

### 증거 화면

실제 수행했다면 권장 경로:

```text
assignments/chapter09/images/step09_lock.png
```

---

# 10. 선택 실습 — 취소와 좌석 복구

실행 파일:

```text
code/chapter09/08_cancel_and_restore.sql
```

```text
미실행 — 시간 관계상 이번 제출에서는 08_cancel_and_restore.sql을 직접 실행하지 않았다. 아래는 08 파일 코드와 본문 설명을 근거로 한 예상 결과다.

9001 취소 성공 행 수(예상): 1
course 301 좌석 변화(예상): remaining_seats 1 → 2
같은 취소를 다시 시도한 행 수(예상): 0 (이미 status='취소'라 WHERE status='수강중' 조건에 안 걸림)
두 번째 좌석 복구 행 수(예상): 0 (cancelled CTE가 비어 있어 좌석 복구 UPDATE도 대상이 없음)
payment 9901 유지 여부(예상): 유지됨 (환불 처리 로직이 없으므로 결제 기록 자체는 남음)
최종 ROLLBACK 후 원상복구 여부(예상): 선택 실습이라 마지막에 ROLLBACK하여 주 실습 기준 상태(9001=수강중, 좌석 301=1)로 되돌아감
통과 메시지(예상): Chapter 09 cancel rollback validation passed
```

기대 흐름:

```text
9001 수강중 → 취소 1행
course 301 remaining 1 → 2
같은 취소 재시도 → 0행
추가 좌석 복구 → 0행
마지막 ROLLBACK → 주 실습 기준으로 복구
```

### 같은 취소를 두 번 처리해도 좌석이 두 번 증가하지 않아야 하는 이유

```text
만약 취소 UPDATE의 성공 여부와 무관하게 좌석 복구 UPDATE를 매번 독립적으로 실행하면, 같은 취소 요청이 재시도나 중복 클릭으로 두 번 들어왔을 때 좌석이 실제보다 많이 늘어나 capacity를 넘어설 수 있다. 08번 실습은 취소 UPDATE가 실제로 성공한 행(RETURNING으로 넘어온 course_id)에만 좌석 복구 UPDATE를 CTE로 연결하기 때문에, 두 번째 시도에서는 취소 UPDATE 자체가 0행이 되어 좌석 복구도 자동으로 0행이 된다.
```

---

# 11. 선택 실습 — 오류 상태와 SAVEPOINT

실행 파일:

```text
code/chapter09/09_error_and_savepoint.sql
```

미실행 — 09_error_and_savepoint.sql의 오류 유발 문장은 파일 안에서 기본적으로 주석 처리되어 있고, 이번 제출에서는 시간 관계상 직접 실행하지 않았다. 아래는 파일 코드와 본문 설명을 근거로 한 절차 분석이다.

## 11-1. 일반 오류 후 트랜잭션 상태 (분석)

```text
발생시킨 오류(예정): course 301에 학생 101의 두 번째 '수강중' 신청(9003)을 INSERT하여 uq_transaction_enrollments_active 부분 고유 인덱스 위반을 의도적으로 유발
오류 이후 다음 SQL 실행 결과(예상): 트랜잭션이 aborted 상태가 되어 "current transaction is aborted" 오류가 반복됨(SAVEPOINT 없이는)
전체 ROLLBACK이 필요한 이유: PostgreSQL은 문장 오류가 발생하면 현재 트랜잭션 전체를 오류 상태로 만들 수 있어서, SAVEPOINT가 없다면 그 안의 정상 변경(예: 좌석 차감)까지 포함해 전체를 ROLLBACK으로 취소해야 한다.
```

## 11-2. SAVEPOINT 사용 (분석)

```text
SAVEPOINT 이름: before_duplicate_enrollment
오류 발생 위치: SAVEPOINT 직후 좌석을 임시로 1 차감한 다음, 중복 활성 신청 INSERT(9003)에서 오류 발생
ROLLBACK TO SAVEPOINT 후 상태(예상): 좌석 차감까지 포함해 SAVEPOINT 시점으로 되돌아가 course 301 remaining_seats=1, enrollment 9003=0행
이후 계속 실행할 수 있었는가(예상): 그렇다 — ROLLBACK TO SAVEPOINT는 전체 트랜잭션을 끝내지 않고 aborted 상태만 해제하므로, 이후 RELEASE SAVEPOINT 후 트랜잭션을 계속 진행(이 실습에서는 마지막에 전체 ROLLBACK으로 정리)할 수 있다.
```

### SAVEPOINT가 전체 ROLLBACK과 다른 점

```text
전체 ROLLBACK은 BEGIN 이후의 모든 변경을 취소하지만, ROLLBACK TO SAVEPOINT는 그 SAVEPOINT를 찍은 시점 이후의 변경만 취소하고 그 이전(트랜잭션 시작부터 SAVEPOINT까지)의 변경은 유지한 채 트랜잭션을 계속 진행할 수 있게 해준다. 다만 SAVEPOINT는 모든 오류를 무시하기 위한 기능이 아니라, "어느 구간까지 되돌려도 업무가 여전히 의미 있는가"를 먼저 설계한 뒤에만 사용해야 한다.
```

---

# 12. 개인 프로젝트 트랜잭션 시나리오 설계

Chapter 07에서 시작한 개인 프로젝트를 사용합니다.

둘 이상의 변경이 함께 성공해야 하는 업무를 **하나** 선택합니다.

예:

```text
예약 생성 + 좌석 차감
주문 생성 + 재고 차감
대여 생성 + 대여 가능 상태 변경
답변 등록 + 질문 상태 변경
```

개인 프로젝트: "나의 지출내역 관리" (Chapter 07에서 설계, categories / payment_methods / expenses / budgets)

이번 트랜잭션 설계는 Chapter 07에서 미확정으로 남겨뒀던 질문(P07-MQ02: "예산을 초과한 지출을 시스템이 막아야 하는가?")에 "그렇다"고 답하며, budgets에 `limit_amount`(고정 한도)와 별도로 `remaining_amount`(남은 예산, transaction_lab.course_inventory.remaining_seats와 같은 역할)를 추가하는 것을 전제로 설계했다. 아직 실제 테이블에 이 컬럼을 만들지는 않았으므로 SQL은 초안이다.

## 12-1. 업무 정의

```text
시나리오 ID: P09-T01
업무 이름: 지출 등록(예산 차감 포함)
사용자 행동: 사용자가 특정 카테고리·이번 달에 지출 내역을 하나 등록한다.
왜 하나의 트랜잭션이어야 하는가: "예산 잔여 확인·차감"과 "지출 행 생성"이 따로 처리되면, 예산은 줄었는데 지출 기록이 없거나(잔여만 줄고 내역 없음), 반대로 지출은 기록됐는데 예산이 그대로(초과 지출을 못 막음)인 모순이 생긴다. 좌석 확보 + 신청 생성과 같은 구조이므로 두 변경을 하나의 트랜잭션으로 묶어야 한다.
```

## 12-2. 트랜잭션 설계표

| 항목 | 내 설계 |
| --- | --- |
| BEGIN 전 확인 상태 | 해당 category_id·year_month의 budgets 행이 존재하는지, remaining_amount가 지출 금액 이상인지 |
| 잠금/경쟁 가능 데이터 | budgets 행 (같은 카테고리·같은 달에 동시에 여러 지출이 등록될 수 있음) |
| 변경 1 | `UPDATE budgets SET remaining_amount = remaining_amount - :amount WHERE category_id=:cid AND year_month=:ym AND remaining_amount >= :amount` |
| 기대 영향 행 수 | 1 (0이면 예산 부족으로 등록 실패) |
| 변경 2 | 변경 1이 1행 성공했을 때만 `INSERT INTO expenses (category_id, amount, spent_at, memo, payment_method_id) VALUES (...)` |
| 기대 영향 행 수 | 1 |
| 추가 변경 | 없음 (payment_methods는 FK로 참조만 하고 수정하지 않음) |
| COMMIT 전 검증 | budgets.remaining_amount가 0 이상인지, expenses 1건이 정확히 생성됐는지, 두 금액이 서로 대응하는지 확인 |
| COMMIT 조건 | 변경 1·2 모두 정확히 1행, remaining_amount >= 0 |
| ROLLBACK 조건 | 변경 1의 영향 행 수가 0(예산 부족)이거나, expenses INSERT가 실패한 경우 |

## 12-3. 실패 시나리오

```text
실패 1:
어느 단계에서 발생: 변경 1(budgets UPDATE)에서 remaining_amount < 지출 금액이라 0행 반환
남으면 안 되는 부분 상태: 예산은 그대로인데 expenses 행만 생성되는 상태
ROLLBACK 후 기대 상태: budgets.remaining_amount 그대로, expenses 신규 행 없음 — "예산 초과로 등록 실패"라는 업무 결과로 처리

실패 2:
어느 단계에서 발생: 변경 1(예산 차감)까지는 성공했지만 expenses INSERT에서 category_id가 이미 삭제된 카테고리라 FK 오류 발생
남으면 안 되는 부분 상태: 예산은 줄었는데 실제 지출 내역은 없는 상태
ROLLBACK 후 기대 상태: budgets.remaining_amount가 차감 전 값으로 복구, expenses 신규 행 없음
```

## 12-4. SQL 초안

```sql
-- budgets에 remaining_amount 컬럼이 아직 없으므로 의사 SQL(개념 설계)
BEGIN;

WITH budget AS (
    UPDATE budgets
    SET remaining_amount = remaining_amount - 30000
    WHERE category_id = 3
      AND year_month = '2026-09'
      AND remaining_amount >= 30000
    RETURNING category_id
)
INSERT INTO expenses (category_id, amount, spent_at, memo, payment_method_id)
SELECT category_id, 30000, CURRENT_DATE, '점심 식비', 1
FROM budget
RETURNING id, category_id, amount;

-- COMMIT 전 검증: budget CTE가 1행이었는지(=expenses도 1행 생성됐는지) 확인 후 COMMIT/ROLLBACK
COMMIT;
```

---

# 13. AI를 트랜잭션 리뷰어로 활용

AI에게 완성 SQL부터 요구하지 않습니다.

## 13-1. 사용한 프롬프트

```text
이번 실습은 완성 SQL을 처음부터 요청하기보다, DBeaver에서 실제로 트랜잭션을 실행하면서 결과가 이상할 때마다 원인을 같이 진단하는 방식으로 AI(Claude)를 활용했다. 예: "ROLLBACK 했는데 remaining_seats가 그대로예요", "9002 신청이 그대로 남아있어요" 같은 실제 증상을 그대로 전달하고 원인 분석을 요청했다.
```

권장 질문 요소:

```text
1. 하나의 업무 단위가 어디까지인지
2. BEGIN 전 확인할 상태
3. 경쟁 가능 데이터와 잠금 필요성
4. 각 변경의 기대 영향 행 수
5. 여러 테이블 최종 정합성 검증
6. COMMIT 조건
7. ROLLBACK 조건
8. 동시 실행 위험
을 먼저 검토한 뒤 PostgreSQL 초안을 제안하도록 요청
```

## 13-2. AI 제안 검토

| AI 제안 | 수용 / 수정 / 보류 / 거절 | 실제 또는 논리 검증 | 판단 이유 |
| --- | --- | --- | --- |
| DBeaver 툴바가 "Auto"(자동 커밋) 모드라서 텍스트로 입력한 BEGIN/ROLLBACK이 실제로는 각 문장을 즉시 커밋해버리고 있다는 진단 | 수용 | 실제로 "Manual Commit"으로 바꾼 뒤 같은 SQL을 다시 실행하니 ROLLBACK이 정상적으로 좌석·신청·결제를 되돌렸다 | 증상(ROLLBACK 메시지는 성공인데 데이터가 그대로)과 정확히 일치했고, 모드 전환 후 즉시 해결됨 |
| 홈메이드로 직접 만든 transaction_lab 스키마(제약조건 이름·허용 status 값이 공식과 다름)를 버리고 공식 01/02 스크립트로 다시 만들어야 한다는 제안 | 수용 | 공식 01_transaction_lab_schema.sql을 열어 실제 제약조건 이름과 CHECK 범위를 직접 비교해 차이를 확인함 | 이후 06_transaction_validation.sql 같은 자동 검증 파일이 정확한 제약조건 이름/구조를 검사할 가능성이 높아, 미리 공식 구조로 맞추는 게 안전하다고 판단 |
| reset_transaction_lab.sql을 사용해 스키마를 정리하자는 제안(직접 DROP SCHEMA 대신) | 수용 | reset 파일 내용을 읽어보니 course_project 보존 검증까지 포함된 안전한 스크립트였음 | 수동 DROP은 커밋 여부를 놓치기 쉬웠던 반면, 공식 reset 파일은 COMMIT까지 포함되어 있어 더 안전 |

### AI SQL에서 확인한 가장 중요한 위험

```text
가장 중요했던 위험은 "ROLLBACK 실행 성공 메시지"와 "실제로 데이터가 되돌아갔는가"가 다를 수 있다는 점이었다. DBeaver의 자동 커밋 설정 때문에 ROLLBACK 자체는 오류 없이 실행됐지만(Updated Rows: 0), 이미 각 문장이 개별적으로 커밋되어버려 되돌릴 대상이 없었다. SQL 문장이 오류 없이 실행됐다고 트랜잭션이 의도대로 동작했다고 믿으면 안 된다는 걸 직접 겪었다.
```

### “오류가 없으면 COMMIT”만으로 부족한 이유

```text
9001 COMMIT 전에도 "좌석 1 감소, 신청 1건, 결제 1건, 두 금액 일치"를 DO 블록으로 다시 확인한 뒤에만 COMMIT했다. SQL 문장 자체는 조건이 잘못돼도(예: WHERE를 빼먹어 여러 행을 건드려도) 에러 없이 실행될 수 있으므로, 영향 행 수와 최종 상태를 실제로 SELECT/DO 블록으로 검증한 뒤에 COMMIT 여부를 판단해야 한다.
```

---

# 14. 최종 성찰

아래 문장은 본인의 말로 작성합니다.

```text
1. 트랜잭션은 여러 SQL을 단순히 묶는 것이 아니라
   하나의 업무가 어디서 시작해서 어디서 확정되는지, 즉 성공과 실패의 경계를 정하는 설계 이다.

2. ROLLBACK이 필요한 대표 상황은
   조건부 UPDATE가 0행이거나(좌석 부족), COMMIT 전 검증(좌석·신청·결제 일치)이 실패했거나, 외부 요인(결제 승인 실패)으로 임시 변경 전체를 취소해야 할 때 이다.

3. 조건부 UPDATE의 영향 행 수가 중요한 이유는
   SQL이 오류 없이 실행됐다는 사실과 "실제로 원하는 조건을 만족하는 행이 바뀌었는가"는 다른 문제이고, 영향 행 수(0인지 1인지)로만 실제 성공 여부를 판단할 수 있기 때문 이다.

4. 제약조건이 있어도 트랜잭션이 필요한 이유는
   제약조건은 한 행의 값과 참조 오류(음수 좌석, 잘못된 FK 등)만 막아줄 뿐, "좌석·신청·결제가 함께 성공/실패해야 한다"처럼 여러 테이블에 걸친 업무 단위의 원자성은 보장해주지 않기 때문 이다.

5. Lock이 필요한 이유는
   여러 세션이 동시에 같은 자원(예: 마지막 좌석 1자리)을 바꾸려 할 때, 서로의 변경이 뒤섞이지 않도록 한쪽이 끝날 때까지 다른 쪽을 기다리게 해서 데이터 일관성을 지키기 위해서 이다.

6. AI가 만든 트랜잭션 SQL을 검토할 때 가장 먼저 확인할 것은
   BEGIN과 최종 확정(COMMIT/ROLLBACK) 범위가 실제 업무 단위와 맞는지, 그리고 조건부 UPDATE가 0행일 때 후속 INSERT를 막고 있는지 이다.
```

---

# 15. 제출 체크리스트

- [x] `chapter09_answer.md`를 본인 저장소에 만들었다.
- [x] Chapter 07·08 기준 상태를 확인했다.
- [x] `transaction_lab` 스키마와 초기 데이터를 만들었다.
- [x] 정상 COMMIT의 전·중·후 상태를 기록했다.
- [x] ROLLBACK 후 부분 변경이 남지 않는지 확인했다.
- [x] ROLLBACK과 IDENTITY 번호의 차이를 설명했다.
- [x] 좌석 부족 시 영향 행 수 0을 관찰했다.
- [x] 영향 행 수 0일 때 후속 행이 생성되지 않음을 확인했다.
- [x] `06_transaction_validation.sql` 최종 검증을 통과했다.
- [x] `course_project`가 변경되지 않았음을 확인했다.
- [x] ACID를 이번 실습 사례로 설명했다.
- [ ] Lock 실습 또는 두 세션 절차 분석을 수행했다. (절차 분석만 수행, 실제 두 세션 실습은 미실행)
- [x] 개인 프로젝트 트랜잭션 시나리오를 작성했다.
- [x] AI 제안의 COMMIT/ROLLBACK/영향 행 수 검증을 확인했다.
- [ ] 핵심 캡처는 3~4장 정도로 정리했다. (아직 스크린샷 첨부 전)
- [ ] 캡처에 비밀번호·개인정보가 없다.
- [ ] GitHub 웹에서 Markdown과 이미지가 정상적으로 보인다.
- [ ] 최종 파일을 commit/push했다.

---

# 16. LMS 제출 URL

아래 형식의 **본인 GitHub 파일 URL**을 LMS에 제출합니다.

```text
https://github.com/<본인-GitHub-ID>/<본인-저장소>/blob/main/assignments/chapter09/chapter09_answer.md
```

내 제출 URL:

```text

```

> 교수자 템플릿 URL, 저장소 메인 URL, Raw URL이 아니라 **작성 완료된 본인의 `chapter09_answer.md` 파일 화면 URL**을 제출합니다.
