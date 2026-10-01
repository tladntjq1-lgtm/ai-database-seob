# Chapter 09 확장 실습 답안 템플릿

> **과제:** 트랜잭션으로 데이터 정합성 지키기  
> **사용 방법:** 이 파일을 내려받아 본인의 GitHub 저장소에 `chapter09_answer.md`라는 이름으로 저장한 뒤 실습하면서 바로 작성합니다.  
> **제출 방법:** LMS에는 파일을 직접 업로드하지 않고, **본인 GitHub 저장소의 `chapter09_answer.md` 파일 URL**을 제출합니다.

---

## 제출 전 주의

이 파일과 캡처 화면에는 실제 비밀번호, 전체 DB 접속 URL, API Key, 개인정보를 기록하지 않습니다.

```text
GitHub 계정 또는 별칭:
과제 작성일:
사용한 AI 도구:
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
| `current_database()` |  |  |
| `current_user` |  |  |
| `current_schema()` |  |  |
| `search_path` |  |  |
| `transaction_read_only` |  |  |

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

```

---

# 2. `transaction_lab` 스키마 생성

실행 파일:

```text
code/chapter09/01_transaction_lab_schema.sql
```

## 2-1. 생성 전 예상

```text
생성될 스키마:
생성될 테이블 3개:

course_inventory 한 행의 의미:
enrollments 한 행의 의미:
payments 한 행의 의미:
```

## 2-2. 생성 결과

```text
통과 메시지:
```

기대 메시지:

```text
Chapter 09 transaction lab schema validation passed
```

### Chapter 07·08의 `course_project`와 별도 `transaction_lab`을 사용하는 이유

```text

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
course 301 remaining_seats 예상:
course 302 remaining_seats 예상:
course 303 remaining_seats 예상:
lab enrollments 예상 행 수:
payments 예상 행 수:
```

## 3-2. 실제 결과

```text
course 301 remaining_seats:
course 302 remaining_seats:
course 303 remaining_seats:
lab enrollments 행 수:
payments 행 수:
통과 메시지:
```

기대 초기 상태:

```text
course 301 / 302 / 303 remaining_seats = 3 / 0 / 0
lab enrollments = 0
payments = 0
```

### 예상과 실제가 다른 경우 원인

```text

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
이 트랜잭션에서 함께 성공해야 하는 변경 1:
변경 2:
변경 3:

하나라도 실패하면 전체를 취소해야 하는 이유:
```

## 4-2. 상태 변화 기록

| 시점 | course 301 남은 좌석 | lab enrollment 9001 | payment 9901 | 설명 |
| --- | ---: | --- | --- | --- |
| BEGIN 전 |  |  |  |  |
| 트랜잭션 내부 |  |  |  |  |
| COMMIT 후 |  |  |  |  |

## 4-3. COMMIT 조건

```text
좌석 UPDATE 기대 영향 행 수:
실제 영향 행 수:
신청 생성 기대 행 수:
결제 생성 기대 행 수:
recorded_amount와 payment.amount 일치 여부:
최종 COMMIT 판단:
```

기대 메시지:

```text
Chapter 09 first commit validation passed
```

### SQL 오류가 없었다는 사실만으로 COMMIT하면 안 되는 이유

```text

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
트랜잭션 안에서 임시로 바뀔 값:
ROLLBACK 후 다시 돌아와야 할 값:
이미 이전 파일에서 COMMIT된 9001/9901은 유지되어야 하는가:
```

## 5-2. 실제 결과

```text
ROLLBACK 후 course 301 상태:
ROLLBACK 후 lab enrollments 행 수:
ROLLBACK 후 payments 행 수:
9001 존재 여부:
9901 존재 여부:
통과 메시지:
```

기대 메시지:

```text
Chapter 09 rollback validation passed
```

## 5-3. ROLLBACK과 IDENTITY

```text
ROLLBACK이 테이블 행 변경을 되돌리는 방식:

IDENTITY 자동 번호가 반드시 이전 값으로 되돌아가지는 않는 이유:

번호가 건너뛰었다고 데이터 손상이라고 단정할 수 없는 이유:
```

---

# 6. 두 번째 COMMIT과 좌석 부족 0행 관찰

실행 파일:

```text
code/chapter09/05_commit_and_sold_out.sql
```

## 6-1. 두 번째 정상 COMMIT

```text
생성된 enrollment id:
학생 id:
course id:
recorded_amount:
payment id:
payment amount:
```

## 6-2. 좌석 부족 시도

```text
좌석 확보 UPDATE 기대 영향 행 수:
실제 영향 행 수:
후속 enrollment 생성 행 수:
후속 payment 생성 행 수:
```

기준상 좌석 부족 시 생성되지 않아야 하는 ID:

```text
9003
9903
```

### `UPDATE 0`이 SQL 실패가 아니라 업무상 실패일 수 있는 이유

```text

```

### 영향 행 수가 0인데 신청과 결제를 계속 생성하면 어떤 정합성 문제가 생기나요?

```text

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
| course_inventory 행 수 | 3 |  |  |
| lab enrollments 행 수 | 2 |  |  |
| payments 행 수 | 2 |  |  |
| course 301 remaining | 1 |  |  |
| course 302 remaining | 0 |  |  |
| course 303 remaining | 1 |  |  |

## 7-2. 주요 행

```text
9001 = student 101 / course 301 / amount 100000 / payment 9901
실제:

9002 = student 103 / course 302 / amount 120000 / payment 9902
실제:

9003·9903 = 존재하지 않아야 함
실제:
```

## 7-3. 보호 대상 확인

```text
course_project.enrollments 행 수:
전체 recorded_amount:
활성 건수/금액:
취소 제외 건수/금액:
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

### transaction_lab 실습 후에도 course_project 기준 상태를 다시 검사하는 이유

```text

```

---

# 8. ACID를 이번 실습으로 설명

교과서 정의를 그대로 복사하지 말고 이번 좌석·신청·결제 사례로 작성합니다.

```text
Atomicity:

Consistency:

Isolation:

Durability:
```

### Atomicity와 Consistency가 같은 뜻이 아닌 이유

```text

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
실제 두 세션 실습 수행 / 절차 분석만 수행:
transaction_isolation:
lock_timeout:
```

## 9-2. 시간 순서 기록

| 순서 | Session A | Session B | 관찰 |
| ---: | --- | --- | --- |
| 1 |  |  |  |
| 2 |  |  |  |
| 3 |  |  |  |
| 4 |  |  |  |

```text
먼저 Lock을 획득한 세션:
대기한 세션:
A가 COMMIT/ROLLBACK한 뒤 B에서 일어난 일:
```

### Lock 대기와 Deadlock의 차이

```text

```

### `SELECT ... FOR UPDATE`가 모든 UPDATE 앞에 항상 필요한 것은 아닌 이유

```text

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
9001 취소 성공 행 수:
course 301 좌석 변화:
같은 취소를 다시 시도한 행 수:
두 번째 좌석 복구 행 수:
payment 9901 유지 여부:
최종 ROLLBACK 후 원상복구 여부:
통과 메시지:
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

```

---

# 11. 선택 실습 — 오류 상태와 SAVEPOINT

실행 파일:

```text
code/chapter09/09_error_and_savepoint.sql
```

## 11-1. 일반 오류 후 트랜잭션 상태

```text
발생시킨 오류:
오류 이후 다음 SQL 실행 결과:
전체 ROLLBACK이 필요한 이유:
```

## 11-2. SAVEPOINT 사용

```text
SAVEPOINT 이름:
오류 발생 위치:
ROLLBACK TO SAVEPOINT 후 상태:
이후 계속 실행할 수 있었는가:
```

### SAVEPOINT가 전체 ROLLBACK과 다른 점

```text

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

## 12-1. 업무 정의

```text
시나리오 ID: P09-T01
업무 이름:
사용자 행동:
왜 하나의 트랜잭션이어야 하는가:
```

## 12-2. 트랜잭션 설계표

| 항목 | 내 설계 |
| --- | --- |
| BEGIN 전 확인 상태 |  |
| 잠금/경쟁 가능 데이터 |  |
| 변경 1 |  |
| 기대 영향 행 수 |  |
| 변경 2 |  |
| 기대 영향 행 수 |  |
| 추가 변경 |  |
| COMMIT 전 검증 |  |
| COMMIT 조건 |  |
| ROLLBACK 조건 |  |

## 12-3. 실패 시나리오

최소 두 개 작성합니다.

```text
실패 1:
어느 단계에서 발생:
남으면 안 되는 부분 상태:
ROLLBACK 후 기대 상태:

실패 2:
어느 단계에서 발생:
남으면 안 되는 부분 상태:
ROLLBACK 후 기대 상태:
```

## 12-4. SQL 초안

```sql
-- 아직 테이블 구현 전이라면 의사 SQL이어도 됩니다.

```

---

# 13. AI를 트랜잭션 리뷰어로 활용

AI에게 완성 SQL부터 요구하지 않습니다.

## 13-1. 사용한 프롬프트

```text

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
|  |  |  |  |
|  |  |  |  |
|  |  |  |  |

### AI SQL에서 확인한 가장 중요한 위험

```text

```

### “오류가 없으면 COMMIT”만으로 부족한 이유

```text

```

---

# 14. 최종 성찰

아래 문장은 본인의 말로 작성합니다.

```text
1. 트랜잭션은 여러 SQL을 단순히 묶는 것이 아니라
   ____________________________________________________________ 이다.

2. ROLLBACK이 필요한 대표 상황은
   ____________________________________________________________ 이다.

3. 조건부 UPDATE의 영향 행 수가 중요한 이유는
   ____________________________________________________________ 이다.

4. 제약조건이 있어도 트랜잭션이 필요한 이유는
   ____________________________________________________________ 이다.

5. Lock이 필요한 이유는
   ____________________________________________________________ 이다.

6. AI가 만든 트랜잭션 SQL을 검토할 때 가장 먼저 확인할 것은
   ____________________________________________________________ 이다.
```

---

# 15. 제출 체크리스트

- [ ] `chapter09_answer.md`를 본인 저장소에 만들었다.
- [ ] Chapter 07·08 기준 상태를 확인했다.
- [ ] `transaction_lab` 스키마와 초기 데이터를 만들었다.
- [ ] 정상 COMMIT의 전·중·후 상태를 기록했다.
- [ ] ROLLBACK 후 부분 변경이 남지 않는지 확인했다.
- [ ] ROLLBACK과 IDENTITY 번호의 차이를 설명했다.
- [ ] 좌석 부족 시 영향 행 수 0을 관찰했다.
- [ ] 영향 행 수 0일 때 후속 행이 생성되지 않음을 확인했다.
- [ ] `06_transaction_validation.sql` 최종 검증을 통과했다.
- [ ] `course_project`가 변경되지 않았음을 확인했다.
- [ ] ACID를 이번 실습 사례로 설명했다.
- [ ] Lock 실습 또는 두 세션 절차 분석을 수행했다.
- [ ] 개인 프로젝트 트랜잭션 시나리오를 작성했다.
- [ ] AI 제안의 COMMIT/ROLLBACK/영향 행 수 검증을 확인했다.
- [ ] 핵심 캡처는 3~4장 정도로 정리했다.
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
