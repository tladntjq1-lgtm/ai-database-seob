# Chapter 08 확장 실습 답안 템플릿

> **과제:** JOIN과 집계로 서비스 질문에 답하기  
> **사용 방법:** 이 파일을 내려받아 본인의 GitHub 저장소에 `chapter08_answer.md`라는 이름으로 저장한 뒤 실습하면서 바로 작성합니다.  
> **제출 방법:** LMS에는 파일을 직접 업로드하지 않고, **본인 GitHub 저장소의 `chapter08_answer.md` 파일 URL**을 제출합니다.

---

## 제출 전 주의

이 파일과 캡처 화면에는 실제 비밀번호, 전체 DB 접속 URL, API Key, 개인정보를 기록하지 않습니다.

```text
GitHub 계정 또는 별칭:tladntjq1-lgtm
과제 작성일:2026-09-17
사용한 AI 도구:claude
```

---

# 1. Chapter 07 기준 상태 확인

다음을 실행합니다.

```text
code/chapter08/00_check_course_project.sql
```

## 1-1. 사전 검사 결과

```text
검증 메시지:Chapter 08 prerequisite check passed

students 행 수:3
instructors 행 수:
courses 행 수:
enrollments 행 수:

전체 신청 건수:
전체 recorded_amount:
활성 신청 건수:
활성 recorded_amount:
취소 제외 신청 건수:
취소 제외 recorded_amount:
```

기준값:

```text
students = 3
instructors = 2
courses = 3
enrollments = 5

전체 = 5 / 590000
활성 = 3 / 340000
취소 제외 = 4 / 440000
```

### 기준값이 다르면 그대로 진행하면 안 되는 이유

```text
실제로 처음 00번 검사를 실행했을 때 학생 수가 3명이 아니라 4명으로 나와서 예외가 발생했다. 원인을 찾아보니 어디선가 테스트로 넣었던 104번 학생(문강)이 남아 있었던 것이었고, 이 학생은 enrollments에 연결된 신청도 없는 상태였다.

이걸 그냥 무시하고 "내 데이터에서는 학생이 4명이니까 4명 기준으로 결과를 해석하자"라고 넘어갔다면, 이후 JOIN·집계 실습에서 나오는 모든 예상 행 수와 검산 기준(강의 301=2건, 강의 303=0건, 전체 5건/590000 등)이 교재 기준과 안 맞게 되고, 뒤에서 SQL이 틀렸는지 데이터가 틀렸는지 구분할 수 없게 됐을 것이다.

그래서 실제 결과에 기대값을 맞추는 대신, 여분의 104번 학생 행을 지우고 시퀀스를 RESTART WITH 104로 되돌려서 Chapter 07 기준 상태(3/2/3/5, 590000)를 먼저 복구한 뒤에 Chapter 08을 시작했다.
```

### 증거 화면

권장 경로:

```text
assignments/chapter08/images/step01_prerequisite.png
```

`여기에 사전 검사 통과 화면을 삽입하세요.`

---

# 2. 업무 질문을 SQL보다 먼저 정의하기

다음 세 질문을 각각 SQL 작성 전에 먼저 정의합니다.

## 질문 A

```text
업무 질문: 각 수강신청 건마다 학생 이름, 강의 제목, 담당 강사 이름을 한 번에 보여주세요.
결과 한 행의 의미: 수강신청 한 건
포함 상태: 전체 상태(신청/수강중/완료/취소 모두 포함) — 상태로 거르는 질문이 아니라 신청 기록 자체를 보여주는 목적
제외 상태: 없음
JOIN할 테이블: enrollments, students, courses, instructors
JOIN 경로: enrollments.student_id → students.id / enrollments.course_id → courses.id / courses.instructor_id → instructors.id
INNER JOIN / LEFT JOIN 선택: INNER JOIN
그 이유: 신청 행은 반드시 학생·강의와 연결되어 있고(FK NOT NULL), 강의도 반드시 강사가 있으므로 INNER JOIN으로 연결해도 신청 행이 하나도 빠지지 않는다.
예상 행 수: 5행 (enrollments 전체 건수와 동일)
```

## 질문 B

```text
업무 질문: 전체/활성/취소 제외 신청 건수와 기록 금액 합계는 각각 얼마인가요?
결과 한 행의 의미: 상태 범위 하나(전체 / 활성 / 취소 제외) 당 한 행 요약
포함 상태: 범위별로 다름 — 활성=신청·수강중, 취소 제외=취소를 뺀 나머지
제외 상태: 활성 기준은 완료·취소 제외 / 취소 제외 기준은 취소만 제외
JOIN할 테이블: 없음 (enrollments 단일 테이블에서 COUNT/SUM FILTER로 계산)
JOIN 경로: 해당 없음
집계 대상: COUNT(*), SUM(recorded_amount) — 상태 조건별 FILTER
예상 결과: 전체 5건/590000, 활성 3건/340000, 취소 제외 4건/440000
```

## 질문 C

```text
업무 질문: 강의별로 취소되지 않은 신청 건수와 기록 금액은 얼마인가요? (취소 제외 신청이 0건인 강의도 표시)
결과 한 행의 의미: 강의 한 개 (신청 여부와 무관하게 존재하는 모든 강의)
포함 상태: 취소 제외 신청(신청/수강중/완료)은 연결하되, 강의 자체는 조건 없이 전부 포함
제외 상태: 취소된 신청 (자식 쪽만 제외, 부모인 강의는 제외 대상 아님)
0건인 부모도 보여야 하는가: 그렇다 — 강의 303처럼 취소 제외 신청이 없어도 강의 행 자체는 남아야 한다.
NULL을 어떻게 해석할 것인가: LEFT JOIN 결과에서 enrollments 쪽 컬럼이 NULL이면 "그 강의에 취소 제외 신청이 실제로 없다"는 뜻이며 데이터 누락이 아니다. COUNT(*)로 세면 부모 행 때문에 1이 나올 수 있으니, 실제 신청 수는 COUNT(e.id)로 세야 한다.
예상 결과: 강의 301=2건/200000, 강의 302=2건/240000, 강의 303=0건/0원(행 자체는 1개 남음)
```

---

# 3. INNER JOIN과 다중 JOIN

## 3-1. 신청 한 건마다 학생 이름과 강의 제목 조회

실행 전 예상:

```text
결과 한 행 = 수강신청 한 건
예상 행 수 = 5행
JOIN 경로 = enrollments.student_id → students.id / enrollments.course_id → courses.id
```

내가 실행한 SQL:

```sql
SELECT
    e.id AS enrollment_id,
    s.name AS student_name,
    c.title AS course_title,
    e.status
FROM course_project.enrollments AS e
INNER JOIN course_project.students AS s
    ON e.student_id = s.id
INNER JOIN course_project.courses AS c
    ON e.course_id = c.id
ORDER BY e.id;
```

실제 결과:

```text
실제 행 수: 5행
예상과 일치 여부: 일치 (1001 김민지, 1002 김민지, 1003 이준호, 1004 박서연, 1005 이준호)
```

### 학생 이름이 여러 번 보이는 것이 중복 오류가 아닐 수 있는 이유

```text
결과의 기준(한 행)은 "학생"이 아니라 "수강신청 한 건"이다. 학생 한 명이 여러 강의에 신청할 수 있는 1:N 관계이므로, 김민지(101)가 두 강의(301, 302)에 신청했다면 신청 기준 결과에서는 김민지 이름이 두 번 나오는 게 정상이다. 이준호(102)도 두 강의(301, 302)에 신청해서 두 번 나온다.
만약 여기서 이름 중복이 이상해 보인다고 SELECT DISTINCT student_name을 넣으면, 오히려 "학생이 어떤 강의들에 신청했는지"를 알 수 없게 결과가 왜곡된다. 중복 제거는 결과 한 행의 기준을 먼저 정한 뒤에, 그 기준과 실제로 안 맞을 때만 검토해야 한다.
```

## 3-2. 학생·강의·강사까지 연결

```text
결과 한 행 = 수강신청 한 건
강사까지 가는 JOIN 경로 = enrollments.course_id → courses.id → courses.instructor_id → instructors.id (enrollments와 instructors는 직접 연결되지 않으므로 courses를 거쳐야 함)
```

```sql
SELECT
    e.id AS enrollment_id,
    s.name AS student_name,
    c.title AS course_title,
    i.name AS instructor_name,
    e.status
FROM course_project.enrollments AS e
INNER JOIN course_project.students AS s
    ON e.student_id = s.id
INNER JOIN course_project.courses AS c
    ON e.course_id = c.id
INNER JOIN course_project.instructors AS i
    ON c.instructor_id = i.id
ORDER BY e.id;
```

실제 행 수:

```text
5행 (예상과 일치). 문길래 강사가 담당한 강의(데이터베이스 입문, 정규화 실습)에 신청 4건, 홍길동 강사가 담당한 강의(파이썬 데이터 분석)에 신청 1건으로 나뉘어 나온다.
```

### 증거 화면

권장 경로:

```text
assignments/chapter08/images/step03_inner_join.png
```

`여기에 다중 JOIN 결과 화면을 삽입하세요.`

---

# 4. LEFT JOIN과 0건 표현

## 4-1. 강의별 취소 제외 신청 수

신청이 없는 강의도 결과에 남도록 작성합니다.

실행 전:

```text
결과 한 행 = 강의 한 개
강의 303의 예상 실제 신청 수 =
강의 303의 예상 고유 학생 수 =
강의 303의 예상 recorded_amount =
```

내 SQL:

```sql

```

실제 결과:

```text
강의 301:
강의 302:
강의 303:
```

## 4-2. `COUNT(*)`와 `COUNT(e.id)` 비교

강의 303을 기준으로 작성합니다.

```text
COUNT(*) 결과:
COUNT(e.id) 결과:
COUNT(DISTINCT e.student_id) 결과:
```

### 왜 `COUNT(*) = 1`인데 실제 신청 수는 0일 수 있나요?

```text

```

### 자식 사건 수를 셀 때 `COUNT(child.id)`가 더 적절한 이유

```text

```

---

# 5. `LEFT JOIN`에서 `ON`과 `WHERE` 조건 비교

취소 제외 신청만 연결한다고 가정합니다.

## 5-1. 조건을 `ON`에 둔 경우

```sql

```

```text
결과 학생 수:
박서연 포함 여부:
```

## 5-2. 조건을 `WHERE`에 둔 경우

```sql

```

```text
결과 학생 수:
박서연 포함 여부:
```

## 5-3. 차이 설명

```text
ON 조건이 LEFT JOIN의 오른쪽 연결 대상을 제한하는 방식:

WHERE 조건이 JOIN 이후 결과 행을 제거하는 방식:

이번 사례에서 ON = 3명, WHERE = 2명이 되는 이유:
```

---

# 6. 신청이 없는 학생 찾기 — 두 방법 비교

## 방법 1. `LEFT JOIN ... IS NULL`

```sql

```

## 방법 2. `NOT EXISTS`

```sql

```

```text
방법 1 결과:
방법 2 결과:
두 결과가 같은가:
찾아진 학생:
```

### 두 방식의 공통 의미를 자신의 말로 설명

```text

```

---

# 7. 기본 집계 검산

다음 결과를 직접 확인합니다.

| 분석 범위 | 예상 건수 | 실제 건수 | 예상 금액 | 실제 금액 | 일치? |
| --- | ---: | ---: | ---: | ---: | --- |
| 전체 신청 | 5 |  | 590000 |  |  |
| 활성 신청 | 3 |  | 340000 |  |  |
| 취소 제외 | 4 |  | 440000 |  |  |
| 취소 | 1 |  | 150000 |  |  |

## 7-1. 전체 평균 `recorded_amount`

```text
예상 평균:
실제 평균:
```

## 7-2. 취소 제외 평균

```text
예상 평균:
실제 평균:
```

### `recorded_amount`를 실제 회계 매출이라고 부르면 안 되는 이유

```text

```

---

# 8. `GROUP BY`, `HAVING`, `FILTER`

## 8-1. 상태별 신청 건수

```sql

```

결과:

```text
신청:
수강중:
완료:
취소:
상태별 합계:
```

### 상태별 건수 합이 전체 신청 5건과 맞는지 검산

```text

```

## 8-2. 강의별 취소 제외 신청 수와 금액

```sql

```

```text
강의 301:
강의 302:
강의 303:
강의별 합계를 다시 더한 값:
전체 취소 제외 기준 440000과 일치 여부:
```

## 8-3. `HAVING` 사용

취소 제외 신청이 2건 이상인 강의를 조회합니다.

```sql

```

```text
예상 강의 수:
실제 강의 수:
```

---

# 9. 과대 집계 오류 직접 관찰

강사 201의 강의 가격 합계를 구한다고 가정합니다.

## 9-1. 신청까지 JOIN해서 잘못 집계한 결과

```sql

```

```text
강사 201 잘못된 가격 합계:
```

본문 기준:

```text
440000
```

## 9-2. 강의 수준에서 올바르게 집계

```sql

```

```text
강사 201 올바른 가격 합계:
```

본문 기준:

```text
220000
```

## 9-3. 왜 두 결과가 달라졌나요?

```text
JOIN 전 강의 행 수:
JOIN 후 강의가 반복된 이유:
SUM이 무엇을 반복해서 더했는가:
```

### `SUM(DISTINCT c.price)`를 일반적인 해결책으로 사용하면 안 되는 이유

```text

```

### 증거 화면

권장 경로:

```text
assignments/chapter08/images/step09_over_aggregation.png
```

`여기에 잘못된 합계와 올바른 합계를 비교한 화면을 삽입하세요.`

---

# 10. 상세 결과 ↔ 집계 결과 교차 검산

강의 하나를 선택합니다.

```text
선택한 course_id:
강의 제목:
```

## 10-1. 상세 신청 행 조회

```sql

```

```text
상세 행 수:
상세 recorded_amount를 직접 더한 값:
```

## 10-2. 집계 SQL

```sql

```

```text
집계 건수:
집계 금액:
```

## 10-3. 비교

```text
상세 행 수와 COUNT 결과 일치 여부:
상세 금액 합과 SUM 결과 일치 여부:
다르다면 원인:
```

---

# 11. 자동 완료 게이트

다음을 실행합니다.

```text
code/chapter08/03_join_aggregation_validation.sql
```

```text
최종 검증 메시지:
```

기대 메시지:

```text
Chapter 08 join and aggregation validation passed
```

### 자동 검증이 통과했어도 사람이 SQL 의미를 설명해야 하는 이유

```text

```

---

# 12. 개인 프로젝트 업무 질문 3개 만들기

Chapter 07에서 작성한 개인 프로젝트를 사용합니다.

| 질문 ID | 업무 질문 | 결과 한 행 | 포함/제외 범위 | JOIN 경로 | 집계 대상 | 검산 방법 |
| --- | --- | --- | --- | --- | --- | --- |
| P08-Q01 |  |  |  |  |  |  |
| P08-Q02 |  |  |  |  |  |  |
| P08-Q03 |  |  |  |  |  |  |

## 12-1. 질문 1 SQL

```sql

```

```text
예상 결과:
실제 결과:
검산 결과:
```

## 12-2. 질문 2 SQL

```sql

```

```text
예상 결과:
실제 결과:
검산 결과:
```

## 12-3. 질문 3 SQL

```sql

```

```text
예상 결과:
실제 결과:
검산 결과:
```

> 아직 개인 프로젝트 테이블을 PostgreSQL로 완성하지 않았다면 SQL 초안과 예상 검산 방법까지만 작성하고 `미실행`이라고 명시합니다.

---

# 13. AI를 JOIN·집계 리뷰어로 활용

## 13-1. 내가 AI에게 전달한 질문

```text

```

## 13-2. 내 SQL과 AI SQL 비교

| 검토 항목 | 내 판단/SQL | AI 제안 | 최종 선택 | 이유 |
| --- | --- | --- | --- | --- |
| 결과 한 행 |  |  |  |  |
| 상태 범위 |  |  |  |  |
| JOIN 경로 |  |  |  |  |
| INNER/LEFT 선택 |  |  |  |  |
| COUNT 대상 |  |  |  |  |
| 과대 집계 위험 |  |  |  |  |
| 상세 검산 방법 |  |  |  |  |

### AI가 만든 SQL에서 발견한 위험 또는 확인한 점

```text

```

### AI SQL이 실행 성공했다고 바로 정답이라고 할 수 없는 이유

```text

```

---

# 14. 최종 성찰

아래 문장은 본인의 말로 작성합니다.

```text
1. JOIN SQL을 작성하기 전에 가장 먼저 정해야 하는 것은
   ____________________________________________________________ 이다.

2. LEFT JOIN에서 COUNT(*) 대신 COUNT(child.id)를 검토해야 하는 이유는
   ____________________________________________________________ 이다.

3. ON과 WHERE 조건 위치가 중요한 이유는
   ____________________________________________________________ 이다.

4. 여러 1:N 관계를 JOIN한 뒤 바로 SUM하면 위험한 이유는
   ____________________________________________________________ 이다.

5. 집계 결과를 신뢰하기 전에 가장 좋은 검산 방법 중 하나는
   ____________________________________________________________ 이다.
```

---

# 15. 제출 체크리스트

- [ ] `chapter08_answer.md`를 본인 저장소에 만들었다.
- [ ] `00_check_course_project.sql`이 통과했다.
- [ ] 업무 질문마다 결과 한 행을 먼저 정의했다.
- [ ] INNER JOIN과 다중 JOIN을 실행했다.
- [ ] LEFT JOIN에서 0건 부모를 확인했다.
- [ ] `COUNT(*)`와 `COUNT(child.id)` 차이를 설명했다.
- [ ] ON과 WHERE 조건 위치 차이를 직접 비교했다.
- [ ] `LEFT JOIN ... IS NULL`과 `NOT EXISTS`를 비교했다.
- [ ] 전체/활성/취소 제외 기준값을 직접 검산했다.
- [ ] `GROUP BY`, `HAVING`을 사용했다.
- [ ] 과대 집계 오류와 수정 결과를 비교했다.
- [ ] 상세 결과와 집계 결과를 교차 검산했다.
- [ ] `03_join_aggregation_validation.sql`이 통과했다.
- [ ] 개인 프로젝트 업무 질문 3개를 작성했다.
- [ ] AI SQL을 실행 성공 여부가 아니라 의미와 검산 결과로 평가했다.
- [ ] 핵심 캡처는 3~4장 정도만 사용했다.
- [ ] 비밀번호·개인정보·비밀정보가 없다.
- [ ] GitHub 웹에서 Markdown과 이미지가 정상적으로 보인다.
- [ ] 최종 답안을 commit/push했다.

---

# 16. LMS 제출 URL

아래 형식의 **본인 GitHub 파일 URL**을 LMS에 제출합니다.

```text
https://github.com/<본인-GitHub-ID>/<본인-저장소>/blob/main/assignments/chapter08/chapter08_answer.md
```

내 제출 URL:

```text

```

> 저장소 메인 URL, 교수자 템플릿 URL, Raw URL이 아니라 **작성 완료된 본인 `chapter08_answer.md` 파일 화면 URL**을 제출합니다.
