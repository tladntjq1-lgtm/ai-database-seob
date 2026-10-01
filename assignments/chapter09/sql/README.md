# Chapter 09 실습 코드

## 트랜잭션으로 데이터 정합성 지키기

이 폴더는 Chapter 07·08의 `course_project` 기준 데이터를 보호하면서 별도 `transaction_lab` 스키마에서 좌석·수강신청·결제 트랜잭션을 실습합니다.

## 실행 전 조건

Chapter 07의 다음 파일을 완료합니다.

```text
01_course_project_schema.sql
→ 02_course_project_seed.sql
→ 03_course_project_changes.sql
→ 04_course_project_validation.sql
```

Chapter 09의 `01_transaction_lab_schema.sql`은 단순히 테이블 존재만 확인하지 않고 다음 Chapter 07·08 기준 상태를 자동 검사합니다.

```text
students / instructors / courses / enrollments = 3 / 2 / 3 / 5
상태 = 신청 2 / 수강중 1 / 완료 1 / 취소 1
전체 recorded_amount = 590000
활성 신청 = 3 / 340000
취소 제외 = 4 / 440000
1001 = 완료 / 100000
1004 = 취소 / 150000
1005 = 신청 / 120000
recorded_amount = NUMERIC(12,0)
uq_course_enrollments_active 존재
Chapter 07 명명 제약조건 = 15 / NOT NULL 열 = 20
현재 역할의 ai_database_book CREATE 권한
강의 301/302/303 가격 = 100000/120000/150000
```

기준이 다르면 `transaction_lab`을 만들지 않고 실행을 중단합니다.

## 파일 목록

| 파일 | 설명 |
| --- | --- |
| `01_transaction_lab_schema.sql` | Chapter 07·08 사전 게이트 + 격리 스키마·테이블·인덱스 원자적 생성 |
| `02_transaction_lab_seed.sql` | 강의 301~303 좌석 초기화와 정확한 3/0/0 상태 자동 검증 |
| `03_commit_transaction.sql` | 학생 101·강의 301 성공 COMMIT과 자동 판정 |
| `04_rollback_transaction.sql` | 임시 변경 ROLLBACK 후 좌석·행·이전 COMMIT 상태 자동 복구 검증 |
| `05_commit_and_sold_out.sql` | 두 번째 COMMIT, 좌석 부족 0행, IDENTITY 조정과 최종 상태 자동 판정 |
| `06_transaction_validation.sql` | Chapter 07·08 보존 + lab 최종 정합성 전체 자동 판정 |
| `07_concurrency_two_sessions.sql` | READ COMMITTED 두 세션 잠금 대기 선택 실습 |
| `08_cancel_and_restore.sql` | 취소·좌석 복구 후 ROLLBACK 원상복구 자동 검증 |
| `09_error_and_savepoint.sql` | 오류 상태와 SAVEPOINT 선택 실습 |
| `reset_transaction_lab.sql` | DB와 `course_project`를 검사한 뒤 `transaction_lab`만 원자적으로 초기화 |
| `transaction_consistency_practice.sql` | 기존 링크 호환용 읽기 전용 상태 확인 |

주 실습:

```text
01 → 02 → 03 → 04 → 05 → 06
```

선택 실습:

```text
07 두 세션 Lock 대기
08 취소 + 좌석 복구 + ROLLBACK
09 중복 활성 신청 오류 + SAVEPOINT 복구
```

## 자동 통과 메시지

```text
01 → Chapter 09 transaction lab schema validation passed
02 → Chapter 09 transaction lab seed validation passed
03 → Chapter 09 first commit validation passed
04 → Chapter 09 rollback validation passed
05 → Chapter 09 sold-out validation passed
06 → Chapter 09 main transaction validation passed
08 → Chapter 09 cancel rollback validation passed
reset → Chapter 09 transaction lab reset passed
```

메시지가 보이기 전에 예외가 발생했다면 다음 파일로 넘어가지 않습니다.

## 금액 의미

```text
course_project.courses.price
→ 현재 강의 기준 가격

transaction_lab.enrollments.recorded_amount
→ 신청을 만들 때 기록한 금액

transaction_lab.payments.amount
→ 이 트랜잭션 실습에서 생성한 결제 기록 금액
```

두 lab 금액 열은 `NUMERIC(12,0)`을 사용합니다. 성공 트랜잭션에서는 신청 당시 기록 금액과 결제 기록 금액이 일치하는지 검증합니다. 이 값은 실제 외부 결제 승인·환불·회계 매출 전체를 모델링한 값이 아닙니다.

## 스키마 관계

```text
course_inventory.course_id → course_project.courses.id
transaction_lab.enrollments.student_id → course_project.students.id
transaction_lab.enrollments.course_id → course_project.courses.id
transaction_lab.payments.enrollment_id → transaction_lab.enrollments.id
```

핵심 규칙:

```text
capacity > 0
0 <= remaining_seats <= capacity
status IN ('수강중', '취소')
recorded_amount >= 0
payment.amount >= 0
학생·강의의 수강중 신청 최대 한 건
신청당 payment 최대 한 건
수강중 신청에는 payment 필요
신청 recorded_amount = payment.amount
활성 신청 수 = capacity - remaining_seats
```

마지막 세 규칙처럼 여러 행·테이블을 함께 보아야 하는 규칙은 트랜잭션 흐름과 자동 검증 SQL이 담당합니다.

## 주 실습 최종 상태

```text
transaction_lab.course_inventory = 3
transaction_lab.enrollments = 2
transaction_lab.payments = 2
course 301 remaining = 1
course 302 remaining = 0
course 303 remaining = 1
course_project.enrollments = 5
```

```text
9001 → student 101 / course 301 / recorded_amount 100000 / payment 9901
9002 → student 103 / course 302 / recorded_amount 120000 / payment 9902
9003·9903 → 좌석 부족으로 생성되지 않음
```

`06_transaction_validation.sql`은 lab 상태만 아니라 Chapter 07·08의 3/2/3/5, 상태별 건수와 590000/340000/440000도 다시 검사합니다.

## COMMIT 보호 흐름

```text
시작 상태 검사
→ 대상 좌석 잠금
→ 조건부 좌석 차감
→ 좌석 성공 결과에 신청·결제 연결
→ 자동 상태 판정
→ COMMIT
```

`SELECT ... FOR UPDATE`는 행을 잠근 상태로 읽고 여러 후속 판단을 이어갈 때 유용합니다. `UPDATE ... WHERE ... RETURNING` 자체도 수정 대상 행에 필요한 잠금을 획득하므로 선행 `FOR UPDATE`가 항상 필수인 것은 아닙니다. 실제 좌석 확보 성공은 `UPDATE ... WHERE remaining_seats > 0`의 결과와 `RETURNING`으로 판단합니다.

좌석 확보가 0행이면 SQL 오류가 아니라 업무상 좌석 부족이며 후속 신청·결제도 0건이어야 합니다.

## ROLLBACK과 IDENTITY

```text
ROLLBACK
→ 현재 트랜잭션의 미확정 행 변경 취소

명시적 ID 9002·9902
→ ROLLBACK 후 같은 숫자를 다시 직접 입력 가능

IDENTITY 자동값
→ 트랜잭션이 취소돼도 이미 할당된 번호는 일반적으로 회수되지 않음
```

명시적 ID 입력은 IDENTITY 다음 값을 자동으로 이동시키지 않으므로 `05`에서 두 `RESTART WITH`를 하나의 트랜잭션으로 묶어 다음 값을 9003·9903으로 맞춥니다.

## SAVEPOINT

```text
BEGIN
→ SAVEPOINT
→ 오류 가능 단계
→ 오류 발생
→ ROLLBACK TO SAVEPOINT
→ 필요한 작업 계속
→ COMMIT 또는 ROLLBACK
```

PostgreSQL에서 문장 오류가 발생하면 현재 트랜잭션이 aborted 상태가 될 수 있습니다. 기본 복구는 전체 `ROLLBACK`이고, 일부 단계만 복구하려면 오류 전에 SAVEPOINT를 만들어야 합니다.

## 동시성 실습

`07_concurrency_two_sessions.sql`은 PostgreSQL 기본 격리 수준 `READ COMMITTED`를 기준으로 합니다.

```sql
SHOW transaction_isolation;
SET LOCAL lock_timeout = '5s';
```

한 세션이 course 303을 `FOR UPDATE`로 잠근 상태에서 다른 세션이 같은 행을 잠그면 대기할 수 있습니다. timeout 오류가 나면 해당 트랜잭션을 `ROLLBACK`합니다.

한 잠금 해제를 기다리는 **Lock 대기**와 서로가 가진 잠금을 기다리는 순환 구조인 **Deadlock**은 구분합니다.

## 취소와 좌석 복구

`08_cancel_and_restore.sql`은 취소 UPDATE의 `RETURNING` 결과를 좌석 복구 CTE에 연결합니다.

```text
9001 수강중 → 취소 성공 1행
→ 성공 행의 course_id만 좌석 복구에 전달
→ course 301 remaining 1 → 2
→ 동일 취소 재시도 = 취소 0행 / 좌석 복구 0행
payment 9901 기록 유지
```

따라서 이미 취소된 신청을 다시 처리해도 좌석을 두 번 늘리지 않습니다. 선택 실습이므로 마지막에 ROLLBACK하고, 자동 게이트가 9001·9901·좌석이 주 실습 기준으로 정확히 돌아왔는지 확인합니다.

## 초기화

`reset_transaction_lab.sql`은 현재 DB와 보호 대상 `course_project`를 먼저 확인한 뒤 `transaction_lab` 객체만 삭제합니다. 삭제 후에도 Chapter 07·08 기준 행 수와 전체 기록 금액 590000이 유지되는지 자동 확인합니다.

## 자동 검증

전용 GitHub Actions `.github/workflows/validate-chapter09.yml`은 정적 정합성과 PostgreSQL 실제 실행을 함께 검사합니다. 주 실습 성공·ROLLBACK·좌석 부족·취소 복구뿐 아니라 의도적인 SAVEPOINT 오류 복구와 두 세션 Lock timeout도 자동 재현하도록 구성합니다.
