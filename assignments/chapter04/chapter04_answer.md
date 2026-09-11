# Chapter 04 확장 실습 답안 템플릿

> **과제:** 관계형 데이터베이스와 SQL 시작하기  
> **사용 방법:** 이 파일을 내려받아 본인의 GitHub 저장소에 `chapter04_answer.md`라는 이름으로 저장한 뒤 실습하면서 바로 작성합니다.  
> **제출 방법:** LMS에는 파일을 직접 업로드하지 않고, **본인 GitHub 저장소의 `chapter04_answer.md` 파일 URL**을 제출합니다.

---

## 제출 전 주의

이 파일과 캡처 화면에는 실제 비밀번호, 전체 DB 접속 URL, API Key, 개인정보를 기록하지 않습니다.

```text
GitHub 계정 또는 별칭:tladntjq1-lgtm
과제 작성일:09.10
사용한 AI 도구:제미나이
```

---

# 1. 실습 환경과 시작 상태 확인

다음을 실행합니다.

```sql
SELECT current_database();ai_database_book
SELECT current_user; postgres
SELECT current_schema();public
SHOW search_path;"$user", public
SHOW transaction_read_only;off
```

| 확인 항목 | 실제 결과 | 의미 |
| --- | --- | --- |
| current_database() 최근에 사용한 데이터베이스 
| current_user |  | 최근 사용한 유저
| current_schema() | 최근 사용한 스키마
| transaction_read_only 읽기전용 꺼져있음

- [x] 현재 DB가 `ai_database_book`이다.
- [x] 변경 가능한 연결인지 확인했다.
- [x] 실행할 SQL 범위를 확인했다.
- [x] Auto-commit 상태를 확인했다.

### 변경 SQL을 실행하기 전에 현재 DB와 실행 범위를 확인해야 하는 이유

```text

```다른 sql

---

# 2. `public.students` 구조 생성

## 2-1. 실행 전 예상

```text
테이블 이름:students
INSERT는 무엇을 하는가?
새 행(데이터) 추가
SELECT는 무엇을 하는가?
데이터 조회(변경 없음)
UPDATE는 무엇을 하는가?
기존 행의 값 수정
DELETE는 무엇을 하는가?
기존 행 삭제
UPDATE와 DELETE 전에 왜 SELECT가 필요한가?
어떤 행이 영향받을지 미리 확인해서 의도치 않은 행까지 바뀌거나 삭제되는 걸 막기 위해
한 행의 의미:학생 1명의 정보
예상 행 수:0 아직 생선전이니까
기본키:id
필수 열:naeme,email,created_at
중복을 막는 열:UNIQUE: email
자동 생성 열:id (IDENTITY), created_at (DEFAULT CURRENT_TIMESTAMP)
```

## 2-2. 실행 파일

```text
code/chapter04/01_create_students.sql
```

## 2-3. 실행 후 확인

```text
테이블 생성 성공 여부:o
실제 행 수:7
DBeaver에서 확인한 위치:스튜던트 테이블
```



### 각 열의 역할

| 열 | 타입 | NULL 가능? | 역할 |
| --- | --- | --- | --- |
| id | INTEGER (IDENTITY) | 아니오 | 기본키. 행을 구분하는 내부 식별자, 값을 넣지 않아도 자동 증가 |
| name | VARCHAR(50) | 아니오 | 학생 이름. 반드시 값이 있어야 함 |
| email | VARCHAR(100) | 아니오 | 학생 이메일. 필수 + 중복 불가(UNIQUE) — 학생을 구분하는 업무 식별자 역할도 겸함 |
| major | VARCHAR(100) | 예 | 전공. 아직 정하지 않았거나 미입력일 수 있어 NULL 허용 |
| grade | INTEGER | 예 | 학년. 신입생 미배정 등으로 NULL 허용 |
| created_at | TIMESTAMPTZ | 아니오 | 행이 생성된 시각. 값을 안 넣으면 CURRENT_TIMESTAMP로 자동 입력 |

### `id`를 학번이나 학생 수로 해야 안 되는 이유

`id`는 IDENTITY로 자동 증가하는 내부 관리용 번호일 뿐, 실제 업무 의미(학번)를
갖지 않는다. 예를 들어 중간에 INSERT가 실패하거나 행이 삭제되면 번호에
빈 구간이 생길 수 있으므로, "현재 id 최댓값 = 전체 학생 수"라고 단정할 수
없다. 학생 수를 알고 싶다면 `id`가 아니라 `COUNT(*)`로 직접 세야 하고,
실제 학번이 필요하다면 별도의 업무 식별자 컬럼(예: student_number)을
만들어야 한다.

### 증거 화면
`assignments/chapter04/images/step02_table.png` 

`여기에 테이블 구조 확인 화면을 삽입하세요.`

---

# 3. 샘플 데이터 6명 입력

## 3-1. 실행 전 예상

```text
현재 행 수:7
실행 후 예상 행 수:7
예상되는 NULL 포함 학생:윤서진
```

## 3-2. 실행 파일

```text
code/chapter04/02_insert_students.sql
```

## 3-3. 실제 결과

```text
실제 행 수: 7
이준호 grade:3
박서연 존재 여부:o
윤서진 major:null
윤서진 grade:null
```

### 예상과 실제 비교

```text
예상과 실제가 일치했는가:네
다르다면 이유:
```

### `created_at` 값이 여러 행에서 같을 수 있는 이유

```text

```
같은시점에서 함께 입력 됐을 수 있어서
---

# 4. SELECT 복습과 결과 검증

각 문제는 **SQL 실행 전에 예상 행 수를 먼저 작성**합니다.

| 번호 | 조회 문제 | 예상 행 수 | 실제 행 수 | 일치? | 다르면 이유 |
| ---: | --- | ---: | ---: | --- | --- |
| 1 | 전체 학생 |  |  |  |  |
| 2 | 이름·이메일만 조회 |  |  |  |  |
| 3 | 특정 전공 |  |  |  |  |
| 4 | 특정 학년 이상 |  |  |  |  |
| 5 | 두 전공 중 하나 |  |  |  |  |
| 6 | `grade IS NULL` |  |  |  |  |
| 7 | 전공 `DISTINCT` |  |  |  |  |
| 8 | 정렬 후 상위 3명 |  |  |  |  |

## 4-1. 내가 직접 작성한 SQL 2개

```sql
-- SQL 1
SELECT * FROM public.students WHERE major = '컴퓨터공학';
```

```text
이 SQL의 한 행 의미:컴퓨터 공학인 사람 나와라
예상 행 수:3
실제 행 수:3
```

```sql
-- SQL 2
SELECT * FROM public.students WHERE grade >= 3;
```

```text
이 SQL의 한 행 의미:3학년이상인사람 나와라
예상 행 수:2
실제 행 수:2
```

## 4-2. `= NULL` 대신 `IS NULL`을 사용하는 이유

SQL에서 NULL은 "값이 없음/알 수 없음"을 의미하기 때문에, `=`(같다) 비교의
대상이 될 수 없다. `NULL = NULL`을 평가해도 결과는 TRUE가 아니라 다시
NULL(알 수 없음)이 되고, WHERE 절에서 NULL은 조건을 만족하지 않는 것으로
처리되어 행이 아예 걸러진다. 그래서 `WHERE grade = NULL`은 항상 0행을
반환하며 원하는 결과(윤서진처럼 grade가 비어있는 행)를 절대 찾을 수 없다.
"값이 없는 상태인지"를 확인하려면 전용 연산자인 `IS NULL`을 써야 한다.
## 4-3. `ORDER BY` 없이 결과 순서를 믿으면 안 되는 이유

RDBMS는 테이블을 정렬된 상태로 저장하지 않는다. `ORDER BY`가 없으면
DB 엔진이 내부적으로 편한 순서(저장 순서, 인덱스 스캔 순서, 실행 계획 등)로
결과를 돌려줄 뿐이며, 이 순서는 데이터 양이 늘거나 실행 계획이 바뀌면
언제든 달라질 수 있다. 실제로 이번 실습에서도 `ORDER BY grade DESC`를
명시했음에도 NULL이 먼저 오는 것처럼, 정렬 규칙을 명확히 지정하지 않으면
"내가 기대한 순서"와 "DB가 실제로 준 순서"가 다를 수 있다는 것을 확인했다.
따라서 순서가 업무적으로 중요한 조회(예: 상위 N개, 최신순)에는 반드시
ORDER BY를 명시해야 한다.
## 4-4. `DISTINCT`가 원본 데이터를 삭제하는 기능인가요?

아니다. `DISTINCT`는 `SELECT`의 조회 결과에서 중복된 값(표현)만 한 번씩
보이도록 걸러주는 것이지, `public.students` 테이블 자체의 행을 지우거나
변경하지 않는다. 예를 들어 `SELECT DISTINCT major`를 실행해도
students 테이블에는 여전히 컴퓨터공학 학생이 3명(김민지, 김민지2, 최현우)
그대로 남아있고, 화면에 보이는 결과에서만 "컴퓨터공학"이 한 번으로
요약되어 보일 뿐이다.
### 증거 화면

권장 경로:

```text
assignments/chapter04/images/step04_select.png
```

`여기에 SELECT 핵심 결과 화면을 삽입하세요.`

---

# 5. 내 가상 학생 2명 추가

실명·실제 이메일 대신 가상 데이터를 사용합니다.

### 5-1. 실행 전 계획
학생 A 이름: 가상학생A
이메일: student_a@example.com
전공: 데이터과학
학년: 2

학생 B 이름: 가상학생B
이메일: student_b@example.com
전공: 인공지능
학년: NULL (아직 학년 미배정 가정)

현재 행 수: 7
추가 후 예상 행 수: 9

## 5-2. 내가 실행한 INSERT

```sql
INSERT INTO public.students (name, email, major, grade)
VALUES
    ('가상학생A', 'student_a@example.com', '데이터과학', 2),
    ('가상학생B', 'student_b@example.com', '인공지능', NULL)
RETURNING id, name, email, major, grade;

SELECT COUNT(*) AS row_count FROM public.students;
```

### 5-3. 실제 결과
RETURNING 결과: 가상학생A(student_a@example.com, 데이터과학, 2), 가상학생B(student_b@example.com, 인공지능, NULL) 정상 삽입 확인
실제 전체 행 수: 9
예상과 일치 여부: 일치 (7 → 9)

### 내가 일부 값을 NULL로 둔 이유
가상학생B는 아직 학년이 배정되지 않은 상황을 가정하여 grade를 NULL로
두었다. 실제 업무에서도 신입생이거나 전공만 정해지고 학년 정보가 아직
확정되지 않은 경우가 있을 수 있으므로, 이런 경우를 NULL로 표현하는 것이
"임의로 0이나 1을 넣는 것"보다 정확하다.

# 6. 안전한 UPDATE

내가 추가한 가상 학생 한 명만 수정합니다.

## 6-1. 먼저 대상 확인 SELECT

```sql
SELECT * FROM public.students WHERE email = 'student_a@example.com';
```

### 6-1. 먼저 대상 확인
예상 대상 = 1행
실제 대상 = 1행

## 6-2. UPDATE

```sql
UPDATE public.students
SET grade = 3
WHERE email = 'student_a@example.com'
RETURNING id, name, email, grade;

```

```text
예상 영향 행 수: 1
실제 영향 행 수: 1
RETURNING 결과: 가상학생A, student_a@example.com, grade=3
```

## 6-3. UPDATE 후 재조회

```sql
SELECT * FROM public.students WHERE email = 'student_a@example.com';
```

### `WHERE` 없는 UPDATE를 실행하면 위험한 이유
WHERE 조건이 없으면 테이블의 모든 행이 대상이 되어, 의도치 않게 전체
학생의 grade가 한 번에 같은 값으로 덮어써진다. 예를 들어
`UPDATE public.students SET grade = 1;`을 실행하면 9명 전체의 학년이
1로 바뀌어버리며, 실수로 실행했을 경우 원래 값을 복구하기 어렵다.
그래서 UPDATE 전에는 항상 같은 조건으로 SELECT해서 영향받을 행을
먼저 눈으로 확인해야 한다.

### 증거 화면

권장 경로:

```text
assignments/chapter04/images/step06_update.png
```

`여기에 UPDATE 전/후 결과 화면을 삽입하세요.`

---

# 7. 안전한 DELETE

내가 추가한 가상 학생 한 명을 삭제합니다.

## 7-1. 삭제 전 확인

```sql
SELECT * FROM public.students WHERE email = 'student_b@example.com';
```

```text
예상 대상 행 수:1
실제 대상 행 수:1
```

## 7-2. DELETE

```sql
DELETE FROM public.students
WHERE email = 'student_b@example.com'
RETURNING id, name, email;
```

```text
예상 영향 행 수:1
실제 영향 행 수:1
RETURNING 결과:0
```

## 7-3. 삭제 후 재조회

```sql
SELECT * FROM public.students WHERE email = 'student_b@example.com';
```

```text
삭제 후 같은 조건의 SELECT 결과 행 수:0
```

### `DELETE` 성공 메시지만 보고 끝내지 않고 다시 SELECT해야 하는 이유

```text
다른데이터가 지워지진 않았나 내가 선택한 데이터가 삭제된게 맞나 재검증
```

---

# 8. 본문 기준 UPDATE·DELETE 상태 검증

`04_update_delete_students.sql`을 본문 시작 상태에서 실행했다면 다음을 확인합니다.

```text
최종 학생 수:8
이준호 grade:3
박서연 존재 여부:존재
```

본문 기준 기대 상태와 비교합니다.

```text
학생 수 = 5
이준호 grade = 4
박서연 = 0행
```

### 내 실제 결과가 기준과 다르다면 원인

```text

```이미 그전에 수업에서 진행해서 진행한 내용과 실습과제의 내용이 다르다.

---

# 9. 의도한 실패 2개 관찰

> 실패 테스트는 데이터베이스 규칙이 실제로 데이터를 보호하는지 확인하는 실험입니다.

## 9-1. 중복 이메일 `UNIQUE` 오류

## 9-1. 중복 이메일 `UNIQUE` 오류

내가 사용한 SQL:
INSERT INTO public.students (name, email, major, grade)
VALUES ('중복테스트', 'minji@example.com', '테스트전공', 1);

오류 메시지 핵심 단서: SQL Error [23505] — "중복된 키 값이 students_email_key
고유 제약 조건을 위반함", (email)=(minji@example.com) 키가 이미 있음

왜 실패해야 맞는가: email 컬럼에 UNIQUE 제약조건이 걸려있어, 이미 존재하는
이메일로는 새 행을 추가할 수 없다. 실패하지 않는다면 오히려 이메일 중복이
허용되어 학생을 이메일로 유일하게 구분할 수 없게 되는 문제가 생긴다.

어떤 규칙이 작동했는가: students_email_key (email 컬럼의 UNIQUE 제약조건)

실패 후 기존 데이터가 어떻게 유지되었는가: INSERT가 통째로 거부(rollback)
되어 기존 김민지(minji@example.com) 행은 변경 없이 그대로 유지됨
## 9-2. 이름 `NULL` 입력 `NOT NULL` 오류

## 9-2. 이름 `NULL` 입력 `NOT NULL` 오류

내가 사용한 SQL:
INSERT INTO public.students (name, email, major, grade)
VALUES (NULL, 'null_name_test@example.com', '테스트전공', 1);

오류 메시지 핵심 단서: SQL Error [23502] — "name 칼럼의 null 값이
not null 제약조건을 위반했습니다", 실패한 자료: (16, null, ...)

왜 실패해야 맞는가: name 컬럼은 NOT NULL로 정의되어 있어, 이름 없는
학생 행은 허용되지 않는다.

어떤 규칙이 작동했는가: name 컬럼의 NOT NULL 제약조건

### 실패한 INSERT 뒤 자동 생성 `id` 번호에 빈 구간이 생길 수 있어도 문제라고 단정할 수 없는 이유
실제로 이번 실패한 INSERT의 오류 메시지에 id=16이 찍혀 있었다. 이는
PostgreSQL의 IDENTITY 시퀀스가 INSERT 시도 시점에 번호를 미리 할당하고,
이후 제약조건 검사에서 실패해 rollback되더라도 이미 소비된 시퀀스 번호는
되돌아가지 않기 때문이다. 즉 다음에 성공하는 INSERT는 16이 아니라 17번을
받게 될 것이다. 이는 오류가 아니라 시퀀스의 정상 동작이며, id는 학생 수가
아니라 "몇 번 INSERT 시도가 있었는지"에 가까운 내부 번호이므로 번호에
구멍이 있어도 데이터 무결성 문제가 아니다.



### 증거 화면

권장 경로:

```text
assignments/chapter04/images/step09_constraint_error.png
```

`여기에 제약조건 오류 화면을 삽입하세요.`

---

# 10. `verify_students.sql`로 최종 상태 확인

실행 파일:

```text
code/chapter04/verify_students.sql
```

```text
현재 전체 학생 수:8
NULL 개수:2
이준호 grade:3
박서연 존재 여부:o
현재 데이터 상태에서 예상과 다른 부분:x
```

### 검증 SQL을 따로 두면 좋은 이유

```text

### 검증 SQL을 따로 두면 좋은 이유

실습 파일 하나를 오류 없이 실행했다는 것과, 최종 데이터가 기대한 상태와
일치한다는 것은 서로 다른 사실이다. 여러 단계의 CREATE/INSERT/UPDATE/DELETE를
거치다 보면 중간에 실수(조건을 잘못 걸거나, 다른 테스트 데이터가 섞이는 등)가
있어도 각 SQL 자체는 "성공"으로 끝날 수 있다. 검증 전용 스크립트를 따로
두면, 데이터를 변경하지 않고 현재 구조와 상태(전체 행 수, 특정 학생 값,
NULL 개수 등)만 조회해서 "실행 성공"과 "최종 결과가 맞는 상태"를 분리해서
확인할 수 있다. 이렇게 하면 문제가 생겼을 때도 어느 단계에서 어긋났는지
추적하기 쉬워지고, 매번 결과를 눈으로 어림짐작하지 않고 같은 기준으로
반복 검증할 수 있다는 장점이 있다.

---

## 11-1. 내가 작성한 SQL
UPDATE public.students
SET major = '데이터공학'
WHERE email = 'student_a@example.com';

## 11-2. AI에게 전달한 핵심 요청
"나는 PostgreSQL 초보자입니다. 아래 SQL을 바로 다시 작성하지 말고
먼저 안전성을 검토해 주세요. 1) 영향받을 행, 2) WHERE 조건이 모호하지
않은지, 3) NULL 처리 주의점, 4) 실행 전 확인용 SELECT, 5) 실행 후
확인용 SELECT, 6) 놓친 위험을 질문 형태로 제시해 주세요."

## 11-3. AI 검토 결과
| AI 제안 | 수용/수정/거절 | 실제 검증 결과 | 나의 이유 |
|---|---|---|---|
| WHERE email='student_a@example.com'로 1행만 영향받을 것으로 예상 | 수용 | 실행 전 SELECT로 1행 확인, 실제 영향 1행 | 이메일이 UNIQUE라 특정 가능 |
| 실행 전 같은 조건으로 SELECT 먼저 하라는 제안 | 수용 | SELECT 결과 1행(가상학생A) 확인 | STEP6과 동일한 원칙이라 타당 |
| major 값에 오타 없는지 재확인하라는 제안 | 수정 | '데이터공학'으로 최종 확정 | 다른 전공명과 헷갈리지 않게 재확인함 |

### AI가 예상한 영향 행 수와 실제 결과가 같았나요?
같았다. WHERE 조건이 UNIQUE 컬럼(email) 기준이라 예측이 정확히 맞았다.

### AI 답변을 실행 전에 검토해야 하는 이유
AI는 실제 테이블에 연결되어 있지 않으므로, 컬럼명이나 실제 데이터
상태를 안다고 확신할 수 없다. AI의 예상은 어디까지나 후보일 뿐이며,
실제 실행 전 SELECT로 대상 행을 직접 확인해야 의도치 않은 행이
바뀌는 것을 막을 수 있다.

서비스 이름: 카페 주문 관리
테이블 이름: menu_items
한 행의 의미: 카페에서 판매하는 메뉴 1종

| 열 이름 | 저장할 값 | 타입 후보 | NULL 가능? | UNIQUE 후보? | 이유 |
|---|---|---|---|---|---|
| id | 메뉴 내부 식별자 | INTEGER IDENTITY | 아니오 | PK | 행 구분용 |
| name | 메뉴 이름 | VARCHAR(100) | 아니오 | 예 | 같은 이름 메뉴 중복 방지 |
| category | 메뉴 분류(음료/디저트 등) | VARCHAR(50) | 예 | 아니오 | 분류 미정 메뉴 있을 수 있음 |
| price | 판매 가격 | INTEGER | 아니오 | 아니오 | 가격은 필수 |
| is_available | 판매 여부 | BOOLEAN | 예 | 아니오 | 아직 정책 미정이라 NULL 허용 |

PK 후보: id
업무 식별자 후보: name (메뉴명, 다만 중복 가능성은 추후 검토 필요)
아직 미확정인 규칙: 품절/시즌 메뉴 처리 방식, 가격 변경 이력 관리 여부

## 선택: CREATE TABLE 초안
CREATE TABLE public.menu_items (
    id INTEGER GENERATED BY DEFAULT AS IDENTITY PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    category VARCHAR(50),
    price INTEGER NOT NULL,
    is_available BOOLEAN
);

### AI에게 검토받은 뒤 수정한 부분
처음에는 name에 UNIQUE를 걸려고 했으나, 업무 규칙(동명 메뉴 허용 여부)이
아직 확정되지 않았다고 판단해 이번 단계에서는 제약을 추가하지 않기로
했다. (Chapter 05~06에서 ERD와 함께 재검토 예정)
서비스 이름: 카페 주문 관리
테이블 이름: menu_items
한 행의 의미: 카페에서 판매하는 메뉴 1종

| 열 이름 | 저장할 값 | 타입 후보 | NULL 가능? | UNIQUE 후보? | 이유 |
|---|---|---|---|---|---|
| id | 메뉴 내부 식별자 | INTEGER IDENTITY | 아니오 | PK | 행 구분용 |
| name | 메뉴 이름 | VARCHAR(100) | 아니오 | 예 | 같은 이름 메뉴 중복 방지 |
| category | 메뉴 분류(음료/디저트 등) | VARCHAR(50) | 예 | 아니오 | 분류 미정 메뉴 있을 수 있음 |
| price | 판매 가격 | INTEGER | 아니오 | 아니오 | 가격은 필수 |
| is_available | 판매 여부 | BOOLEAN | 예 | 아니오 | 아직 정책 미정이라 NULL 허용 |

PK 후보: id
업무 식별자 후보: name (메뉴명, 다만 중복 가능성은 추후 검토 필요)
아직 미확정인 규칙: 품절/시즌 메뉴 처리 방식, 가격 변경 이력 관리 여부

## 선택: CREATE TABLE 초안
CREATE TABLE public.menu_items (
    id INTEGER GENERATED BY DEFAULT AS IDENTITY PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    category VARCHAR(50),
    price INTEGER NOT NULL,
    is_available BOOLEAN
);

### AI에게 검토받은 뒤 수정한 부분
처음에는 name에 UNIQUE를 걸려고 했으나, 업무 규칙(동명 메뉴 허용 여부)이
아직 확정되지 않았다고 판단해 이번 단계에서는 제약을 추가하지 않기로
했다. (Chapter 05~06에서 ERD와 함께 재검토 예정)

# 14. 제출 체크리스트

- [x] `chapter04_answer.md`를 본인 저장소에 만들었다.
- [x] 현재 DB와 실행 환경을 확인했다.
- [x] `public.students`를 생성했다.
- [x] 샘플 6명 입력 결과를 검증했다.
- [x] SELECT 문제에서 실행 전 예상 행 수를 작성했다.
- [x] 가상 학생 2명을 추가했다.
- [x] UPDATE 전후를 SELECT로 확인했다.
- [x] DELETE 전후를 SELECT로 확인했다.
- [x] UNIQUE 오류를 관찰했다.
- [x] NOT NULL 오류를 관찰했다.
- [x] `verify_students.sql`로 상태를 확인했다.
- [x] AI 제안을 실제 SQL 결과와 비교했다.
- [x] 개인 서비스 테이블 하나를 확장 설계했다.
- [x] 핵심 캡처는 3~4장 정도로 제한했다.
- [x] 비밀번호·개인정보가 캡처에 없다.
- [x] Markdown 이미지가 GitHub 웹 화면에서 정상 표시된다.
- [x] commit/push를 완료했다.

---

# 15. LMS 제출 URL

아래 형식의 **본인 GitHub 파일 URL**을 LMS에 제출합니다.

```text
https://github.com/<본인-GitHub-ID>/<본인-저장소>/blob/main/assignments/chapter04/chapter04_answer.md
```

내 제출 URL:

```text

```

> 교수자 템플릿 URL이나 저장소 메인 URL이 아니라 **작성 완료된 본인 `chapter04_answer.md` 파일 화면 URL**을 제출합니다.