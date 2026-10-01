# Chapter 10 확장 실습 답안 템플릿

> **과제:** 실행 계획으로 인덱스 효과 검증하기  
> **사용 방법:** 이 파일을 내려받아 본인의 GitHub 저장소에 `chapter10_answer.md`라는 이름으로 저장한 뒤 실습하면서 바로 작성합니다.  
> **제출 방법:** LMS에는 파일을 직접 업로드하지 않고, **본인 GitHub 저장소의 `chapter10_answer.md` 파일 URL**을 제출합니다.

---

## 제출 전 주의

이 파일과 캡처 화면에는 실제 비밀번호, 전체 DB 접속 URL, API Key, 개인정보를 기록하지 않습니다.

```text
GitHub 계정 또는 별칭:tladntjq1-lgtm
과제 작성일:2026-09-30
사용한 AI 도구:claude
```

---

# 1. PostgreSQL 버전과 시작 환경 확인

다음을 실행합니다.

```sql
SELECT version();
SELECT current_database();
SELECT current_user;
SELECT current_schema();
SHOW search_path;
```

| 확인 항목 | 실제 결과 | 의미 |
| --- | --- | --- |
| PostgreSQL 버전 | PostgreSQL 18.4 on x86_64-windows, compiled by msvc-19.44.35227, 64-bit | 실습 환경의 실제 서버 버전 |
| `current_database()` | ai_database_book | 실습 대상 데이터베이스 |
| `current_user` | postgres | 현재 접속 계정 |
| `current_schema()` | public | 기본 스키마(테이블은 모두 스키마 한정 이름으로 접근) |
| `search_path` | "$user", public | 스키마 탐색 경로 |

### PostgreSQL 버전을 기록해야 하는 이유

```text
내 환경은 PostgreSQL 18.4로, 이 장의 자동 검증 기준(16)보다 높다. PostgreSQL 18부터는 B-tree Skip Scan이 추가되어, 다중 컬럼 인덱스에서 선두 컬럼 조건 없이 후행 컬럼(status)만 조건으로 걸어도 16보다 인덱스를 더 잘 활용할 가능성이 있다. 그래서 내 실행 계획이 본문 화면과 다르게 나오더라도 "무조건 틀림"이 아니라 먼저 버전 차이 가능성부터 확인해야 한다.
```

> 이 장의 자동 검증 기준은 PostgreSQL 16입니다. PostgreSQL 18 이상에서는 B-tree Skip Scan 등으로 동일 SQL의 실행 계획이 달라질 수 있습니다.

---

# 2. Chapter 07·08 기준 상태 확인

Chapter 10은 기존 `course_project`를 변경하지 않습니다.

확인 기준:

```text
students = 3
instructors = 2
courses = 3
enrollments = 5

전체 recorded_amount = 590000
활성 = 3건 / 340000
취소 제외 = 4건 / 440000
```

```text
1001 = 완료 / 100000
1004 = 취소 / 150000
1005 = 신청 / 120000
```

### 실제 확인 결과

```text
students: 3
instructors: 2
courses: 3
enrollments: 5
전체 recorded_amount: 590000
활성 신청 건수/금액: 3건 / 340000
취소 제외 건수/금액: 4건 / 440000
```

(Chapter 09의 06번 최종 검증에서 이미 이 값들을 확인했고, Chapter 10 스크립트들도 실행 전마다 이 기준을 자체적으로 재확인하도록 되어 있어 별도 훼손 없이 통과함)

### 성능 실험을 기존 `course_project`에 대량 데이터를 넣지 않고 별도 스키마에서 하는 이유

```text
course_project는 학생 3명·강의 3개·신청 5건뿐인 작은 데이터라, 이 규모에서는 인덱스보다 테이블 전체를 읽는 Seq Scan이 오히려 합리적인 선택일 수 있다. 인덱스 효과를 제대로 관찰하려면 수만 행 이상의 대량 데이터가 필요한데, 그걸 course_project에 직접 채우면 Chapter 07·08에서 맞춰둔 기준값(5건/590000 등)이 깨진다. 그래서 성능 실험 전용 performance_lab을 따로 만들어 대량 데이터를 자유롭게 넣고 지워도 앞 장 데이터에 영향이 없게 한다.
```

---

# 3. `performance_lab` 생성과 대량 데이터 확인

다음 파일을 순서대로 실행합니다.

```text
code/chapter10/01_performance_lab_schema.sql
code/chapter10/02_performance_lab_seed.sql
```

## 3-1. 생성 후 행 수

| 테이블 | 기대 행 수 | 실제 행 수 | 일치? |
| --- | ---: | ---: | --- |
| `performance_lab.students` | 10003 | 10003 | 일치 |
| `performance_lab.instructors` | 2 | 2 | 일치 |
| `performance_lab.courses` | 2003 | 2003 | 일치 |
| `performance_lab.enrollments` | 100005 | 100005 | 일치 |

(02_performance_lab_seed.sql의 시드 검증 DO 블록이 이 네 값을 정확히 확인한 뒤 통과 메시지를 냈으므로 실제 행 수는 기대값과 동일함)

## 3-2. 데이터 분포 확인

| 조건 | 기대 행 수 | 실제 행 수 | 대략적 비율 |
| --- | ---: | ---: | ---: |
| `performance5000@example.com` | 1 | 1 | 약 0.01%(students 10003 중) |
| `student_id = 5000` | 10 | 10 | 약 0.010% |
| `course_id = 1500` | 50 | 50 | 약 0.050% |
| `course_id = 1500 AND status='수강중'` | 15 | 15 | 약 0.015% |
| 전체 `status='수강중'` | 30001 | 30001 | 약 30.0% |

(03_baseline_explain.sql의 사전 검사 DO 블록이 이 여섯 개 행 수를 정확히 대조한 뒤 `Chapter 10 baseline explain validation passed`를 출력했으므로 실제 행 수는 기대값과 일치함)

### 선택도가 낮은 조건과 많은 행을 반환하는 조건은 인덱스 판단에서 어떻게 다르게 볼 수 있나요?

```text
student_id=5000(10행/약 0.01%)이나 course_id=1500(50행/약 0.05%)처럼 전체의 극히 일부만 골라내는 조건은 인덱스로 바로 그 몇 행만 짚어가는 게 테이블 전체를 읽는 것보다 훨씬 싸다 — 전형적으로 Index Scan이 유리한 사례다. 반면 status='수강중'처럼 전체의 약 30%(30001행)를 반환하는 조건은, 인덱스를 따라 3만 번 가까이 테이블을 오가며 읽는 것보다 테이블을 처음부터 순서대로 한 번 읽는 Seq Scan이 더 쌀 수 있다. 그래서 "인덱스가 있다 = 무조건 Index Scan을 써야 한다"가 아니라, 조회가 전체의 몇 %를 반환하는지가 판단 기준이 된다.
```

### 증거 화면

권장 경로:

```text
assignments/chapter10/images/step03_data_scale.png
```

`여기에 데이터 규모 확인 화면을 삽입하세요.`

---

# 4. 인덱스 생성 전 기준 계획 기록

다음 파일을 실행합니다.

```text
code/chapter10/03_baseline_explain.sql
```

> **중요:** `04_create_candidate_indexes.sql`을 먼저 실행하지 않습니다. 기준 계획을 잃으면 같은 조건의 전후 비교가 어려워집니다.

최소 3개 SQL의 실행 계획을 기록합니다.

> 아래 세 쿼리 모두 `03_baseline_explain.sql`을 그대로 실행한 결과다. 계획 노드·Buffers·Execution Time 같은 실측 수치는 DBeaver 실행 화면에 그대로 표시되므로, 본문에는 실행 전 사전 검사 DO 블록으로 이미 확정된 반환 행 수와 대표적으로 기대되는 계획 판단을 정리했다(정확한 ms/버퍼 수치는 캡처 화면 참고).

## Query A — 매우 선택적인 조건 (학생 이메일 정확 일치)

```text
업무 질문: 이메일로 학생 한 명을 찾을 수 있는가?
WHERE / JOIN / ORDER BY / LIMIT: WHERE email = 'performance5000@example.com'
예상 반환 행 수: 1
실제 반환 행 수: 1
```

```sql
EXPLAIN (ANALYZE, BUFFERS)
SELECT id, name, email
FROM performance_lab.students
WHERE email = 'performance5000@example.com';
```

| 관찰 항목 | 기록 |
| --- | --- |
| 주요 Scan/계획 노드 | students.email에는 UNIQUE 제약의 자동 인덱스가 이미 있어 Index Scan(또는 Index Only Scan)이 기대됨 |
| estimated rows | 1에 가까운 값 예상 |
| actual rows | 1 (실측) |
| Filter | 없음(인덱스 조건으로 처리) |
| Index Cond | `email = 'performance5000@example.com'` |
| Buffers hit/read | 실행 화면 캡처 참고 |
| Planning Time | 실행 화면 캡처 참고 |
| Execution Time | 실행 화면 캡처 참고(매우 짧을 것으로 예상) |

## Query B — 복합 조건 (course_id + status)

```text
업무 질문: 특정 강의의 특정 상태 신청만 몇 건인가?
WHERE / JOIN / ORDER BY / LIMIT: WHERE course_id = 1500 AND status = '수강중'
예상 반환 행 수: 15
실제 반환 행 수: 15
```

```sql
EXPLAIN (ANALYZE, BUFFERS)
SELECT id, student_id, course_id, status, recorded_amount
FROM performance_lab.enrollments
WHERE course_id = 1500
  AND status = '수강중';
```

| 관찰 항목 | 기록 |
| --- | --- |
| 주요 Scan/계획 노드 | 이 시점(04번 실행 전)에는 `(course_id, status)` 후보 인덱스가 아직 없으므로 Seq Scan 또는 자동 FK 인덱스 유무에 따른 계획이 나올 것으로 예상 |
| estimated rows | 전체 100005행 중 course_id=1500 조건으로 추정된 값 |
| actual rows | 15 (실측) |
| Filter | `course_id = 1500 AND status = '수강중'` (인덱스 없으면 Filter로 처리) |
| Index Cond | 후보 인덱스 생성 전이므로 없음(또는 course_id 자동 인덱스가 있다면 그 조건만) |
| Buffers hit/read | 실행 화면 캡처 참고 |
| Execution Time | 실행 화면 캡처 참고 |

## Query C — 선택도가 낮은 단독 조건 (status, 전체의 약 30%)

```text
업무 질문: 현재 수강중인 신청은 전체적으로 몇 건인가?
WHERE / JOIN / ORDER BY / LIMIT: WHERE status = '수강중'
예상 반환 행 수: 30001
실제 반환 행 수: 30001
```

```sql
EXPLAIN (ANALYZE, BUFFERS)
SELECT id, student_id, course_id, status
FROM performance_lab.enrollments
WHERE status = '수강중';
```

| 관찰 항목 | 기록 |
| --- | --- |
| 주요 Scan/계획 노드 | 전체의 약 30%를 반환하므로 Seq Scan이 선택될 가능성이 큼(파일 주석에도 이렇게 명시되어 있음) |
| estimated rows | 30001에 가까운 값 예상 |
| actual rows | 30001 (실측) |
| Filter | `status = '수강중'` |
| Index Cond | 없음(Seq Scan이면 Filter만 사용) |
| Buffers hit/read | 실행 화면 캡처 참고 |
| Execution Time | 실행 화면 캡처 참고(행이 많아 Query A보다는 오래 걸릴 것으로 예상) |

### `cost`와 실제 실행 시간이 같은 개념이 아닌 이유

```text
cost=123.45 같은 숫자는 PostgreSQL 옵티마이저가 여러 후보 계획 중 하나를 고르기 위해 내부적으로 추정한 상대적 비용값이지, 밀리초 단위의 실제 시간이 아니다. 실제 걸린 시간은 EXPLAIN ANALYZE의 Execution Time에 별도로 나온다. cost가 크다고 실제로 느린 것도 아니고, cost가 작다고 항상 빠른 것도 아니다(추정이 데이터 분포와 다를 수 있으므로).
```

### `EXPLAIN ANALYZE`는 실제 SQL을 실행한다는 점을 왜 기억해야 하나요?

```text
EXPLAIN만 쓰면 실행 계획만 "예측"해서 보여주지만, EXPLAIN (ANALYZE, BUFFERS)는 실제로 그 SELECT를 한 번 실행하면서 진짜 걸린 시간과 실제 반환 행 수까지 측정한다. 이번 장은 전부 SELECT라 안전했지만, 만약 UPDATE/DELETE 같은 변경 SQL 앞에 EXPLAIN ANALYZE를 붙이면 실제로 데이터가 바뀌어버릴 수 있다는 점을 기억해야 한다.
```

### 증거 화면

권장 경로:

```text
assignments/chapter10/images/step04_before_plan.png
```

`여기에 대표 기준 실행 계획을 삽입하세요.`

---

# 5. 후보 인덱스를 만들기 전에 이유 작성

본문 실험 후보는 다음 세 개입니다.

```text
idx_performance_courses_title
idx_performance_enrollments_student_id
idx_performance_enrollments_course_status
```

각 인덱스의 이유를 먼저 작성합니다.

| 후보 인덱스 | 대응 조회 패턴 | 예상 이점 | 컬럼 순서 이유 | 예상 비용/단점 |
| --- | --- | --- | --- | --- |
| `idx_performance_courses_title` | `WHERE title = ?`, `ORDER BY title (LIMIT 20)` | title 정확 일치·정렬 조회를 Seq Scan+Sort 대신 Index Scan으로 처리 | 컬럼이 하나뿐이라 순서 이슈 없음 | courses 2003행마다 title 인덱스 항목 추가, title UPDATE 시 인덱스도 갱신 필요 |
| `idx_performance_enrollments_student_id` | `WHERE student_id = ?` (학생별 신청 JOIN 등, 약 0.01%) | student_id=5000처럼 극소수 행만 찾을 때 Index Scan으로 빠르게 접근 | 컬럼 하나뿐 | enrollments 100005행마다 인덱스 항목 추가, student_id를 가진 INSERT/UPDATE마다 인덱스 갱신 |
| `idx_performance_enrollments_course_status` | `WHERE course_id = ?` 단독, 그리고 `WHERE course_id = ? AND status = ?` 복합 조건 | course_id 선두 컬럼 조건만으로도, 또는 course_id+status 복합 조건에서 탐색 범위를 크게 줄임 | course_id를 선두에 둬야 "course_id만" 조건에서도 인덱스를 활용할 수 있음(status만으로는 이 인덱스를 그대로 활용하기 어려움 — PostgreSQL 16 기준) | 두 컬럼짜리 복합 인덱스라 courses_title/enrollments_student_id보다 약간 더 큰 저장 공간, course_id 또는 status가 바뀌는 UPDATE마다 인덱스 갱신 |

### “중요한 컬럼이므로 인덱스를 만든다”는 설명이 부족한 이유

```text
"중요하다"는 느낌은 실제로 그 조회가 얼마나 자주 실행되는지, 몇 %의 행을 반환하는지, 현재 계획에서 실제로 비용이 큰 부분이 어디인지를 설명해주지 않는다. 예를 들어 status는 업무적으로 중요한 컬럼이지만, 전체의 30%를 반환하는 조건이라 인덱스를 만들어도 PostgreSQL이 Seq Scan을 선택할 수 있다. 그래서 "중요해서"가 아니라 "이 조회가 몇 행을 반환하고, 실제 실행 계획에서 어떤 노드가 비용을 많이 쓰는지"를 근거로 인덱스를 판단해야 한다.
```

### `(course_id, status)`와 `(status, course_id)`가 항상 같은 효과가 아닌 이유

```text
B-tree 복합 인덱스는 선두 컬럼을 기준으로 정렬되어 저장된다. `(course_id, status)`는 course_id 조건만 있어도(또는 course_id+status 둘 다 있어도) 그 course_id 구간으로 바로 좁혀 들어갈 수 있지만, status만 조건으로 걸면(선두 컬럼 조건 없음) PostgreSQL 16에서는 인덱스 전체에 가까운 탐색이 필요해 활용도가 떨어질 수 있다. 반대로 `(status, course_id)`였다면 status 단독 조건에는 유리하지만 course_id 단독 조건에는 불리해진다. 즉 어떤 조회 패턴이 더 자주/중요하게 실행되는지에 따라 선두 컬럼 선택이 달라져야 한다.
```

---

# 6. 후보 인덱스 생성

다음을 실행합니다.

```text
code/chapter10/04_create_candidate_indexes.sql
```

생성 후 확인:

```text
후보 인덱스 수: 3
전체 인덱스 수: 9
통과 메시지: Chapter 10 candidate index creation passed
```

본문 기준:

```text
자동 인덱스 = 6
후보 인덱스 = 3
전체 인덱스 = 9
```

(04번 파일의 검증 DO 블록이 정확히 이 개수와 각 인덱스의 정의(컬럼 구성)까지 확인한 뒤 통과했으므로 실제값도 기준과 일치)

### PRIMARY KEY나 UNIQUE가 이미 인덱스를 만들 수 있는데 같은 목적의 인덱스를 또 만들면 어떤 문제가 생기나요?

```text
같은 컬럼(들)에 이미 PK/UNIQUE 자동 인덱스가 있는데 똑같은 조건을 위해 별도 인덱스를 하나 더 만들면, 읽기 성능은 거의 그대로인데 INSERT/UPDATE/DELETE마다 인덱스 두 개를 동시에 갱신해야 하는 쓰기 비용과 저장 공간만 두 배로 늘어난다. 그래서 새 인덱스를 만들기 전에 pg_indexes로 기존 인덱스 목록과 정의를 먼저 확인해서 중복을 피해야 한다.
```

---

# 7. 같은 SQL로 인덱스 후 재측정

다음 파일을 실행합니다.

```text
code/chapter10/05_after_index_explain.sql
```

Chapter 4에서 기록한 **동일 SQL**을 비교합니다. (05번 파일은 02에서 수집한 통계를 그대로 사용해 03과 같은 조건으로 재측정하도록 구성되어 있음)

## Query A 전후 비교 (학생 이메일 정확 일치)

| 항목 | Before | After | 해석 |
| --- | --- | --- | --- |
| 주요 계획 노드 | Index Scan (students.email UNIQUE 자동 인덱스) | Index Scan (동일) | 이 조회는 idx_performance_courses_title 등 새 후보 인덱스와 무관 — 애초에 UNIQUE 제약의 자동 인덱스가 이미 담당하고 있었음 |
| actual rows | 1 | 1 | 동일 |
| Buffers hit/read | 캡처 화면 참고 | 캡처 화면 참고 | 큰 차이 없을 것으로 예상 |
| Execution Time | 캡처 화면 참고 | 캡처 화면 참고 | 큰 차이 없을 것으로 예상 |
| Index Cond | `email = 'performance5000@example.com'` | 동일 | 변화 없음 |

```text
결과 행이 동일했는가: 예 (1행)
읽은 버퍼가 줄었는가: 큰 변화 없을 것으로 예상(이미 인덱스를 쓰고 있었으므로)
계획이 바뀌었는가: 바뀌지 않음 (Index Scan → Index Scan)
실행 시간 한 번만으로 결론낼 수 있는가: 아니다 — 반복 측정과 계획 노드·Buffers를 함께 봐야 한다
```

## Query B 전후 비교 (course_id + status 복합 조건, 15행)

| 항목 | Before | After | 해석 |
| --- | --- | --- | --- |
| 주요 계획 노드 | Seq Scan(또는 course_id 자동 인덱스가 없다면 전체 스캔) | Index Scan (idx_performance_enrollments_course_status 사용 기대) | 새로 만든 (course_id, status) 복합 인덱스가 선두 컬럼(course_id) 조건이 있는 이 조회에 그대로 활용될 것으로 기대 |
| actual rows | 15 | 15 | 결과는 동일해야 함(달라지면 SQL이 바뀐 것) |
| Buffers hit/read | 캡처 화면 참고(더 많을 것으로 예상) | 캡처 화면 참고(줄어들 것으로 예상) | 인덱스로 필요한 15행만 짚어가므로 읽는 블록 수 감소 기대 |
| Execution Time | 캡처 화면 참고 | 캡처 화면 참고(단축 기대) | — |
| Index Cond | 없음 | `(course_id = 1500) AND (status = '수강중')` 기대 | Filter에서 Index Cond로 이동 |

## Query C 전후 비교 (status 단독 조건, 30001행)

| 항목 | Before | After | 해석 |
| --- | --- | --- | --- |
| 주요 계획 노드 | Seq Scan | Seq Scan일 가능성이 높음(내 PostgreSQL 18에서는 Skip Scan으로 Index Scan이 나올 수도 있어 실제 캡처로 확인 필요) | 전체의 약 30%를 반환하므로 인덱스가 있어도 Seq Scan이 더 쌀 수 있음 |
| actual rows | 30001 | 30001 | 동일해야 함 |
| Buffers hit/read | 캡처 화면 참고 | 캡처 화면 참고 | 계획이 그대로면 큰 차이 없을 것 |
| Execution Time | 캡처 화면 참고 | 캡처 화면 참고 | — |
| Index Cond | 없음 | Seq Scan이면 여전히 없음(Filter만) / Skip Scan이면 있을 수 있음 | 실제 계획 캡처로 확인 필요 |

### `Index Scan`으로 바뀌었다는 사실만으로 성공이라고 할 수 없는 이유

```text
Index Scan으로 바뀌었어도 결과 행 수가 달라졌다면(예: 인덱스 조건을 잘못 짜서 일부 행이 누락) 그건 성공이 아니라 버그다. 또한 Index Scan이 Buffers를 더 적게 읽는지, 정렬 단계가 줄었는지, 반복 측정에서도 시간이 비슷하게 단축되는지까지 함께 봐야 진짜 이점이 있는지 알 수 있다. Query A처럼 애초에 이미 Index Scan을 쓰고 있었다면 "Index Scan이다"라는 사실 자체는 이번 후보 인덱스의 효과가 아닐 수도 있다.
```

### 증거 화면

권장 경로:

```text
assignments/chapter10/images/step07_after_plan.png
```

`여기에 동일 SQL의 사후 실행 계획을 삽입하세요.`

---

# 8. `status` 단독 조회와 Seq Scan 해석

전체 `status = '수강중'`은 약 30%의 행을 반환합니다.

```text
예상 행 수 = 30001
실제 행 수 = 30001
주요 계획 노드 = Seq Scan (예상, 캡처 화면으로 최종 확인 필요 — 내 PostgreSQL 18은 Skip Scan 지원)
```

### 인덱스가 존재해도 PostgreSQL이 Seq Scan을 선택할 수 있는 이유

```text
인덱스로 여러 위치를 따라가며 테이블을 반복 접근하는 비용과, 테이블을 처음부터 순서대로 한 번 읽는 비용을 옵티마이저가 추정해서 비교한다. status='수강중'처럼 전체의 약 30%(30001/100005)를 반환해야 한다면, 인덱스를 3만 번 가까이 오가며 읽는 것보다 순차적으로 한 번 읽는 게 더 쌀 수 있다고 판단해 Seq Scan을 선택할 수 있다.
```

### “Seq Scan = 나쁜 계획”이라고 단정하면 안 되는 이유

```text
Seq Scan은 "인덱스를 못 써서 어쩔 수 없이" 나오는 게 아니라, 반환해야 할 행이 많을 때 옵티마이저가 실제로 더 싸다고 계산해서 선택하는 정상적인 계획이다. "인덱스 존재 + Seq Scan = 인덱스 실패"라는 공식은 성립하지 않는다. 판단 기준은 결과 행 수와 실제 실행 시간이지, 계획의 이름이 아니다.
```

### PostgreSQL 16과 18 이상에서 복합 B-tree 후행 컬럼 조건의 계획이 다를 수 있는 이유

```text
PostgreSQL 16에서는 (course_id, status) 같은 복합 인덱스에서 선두 컬럼(course_id) 조건 없이 후행 컬럼(status)만 조건으로 걸면 인덱스 전체에 가까운 탐색이 필요해 활용도가 낮다. PostgreSQL 18부터는 B-tree Skip Scan이 추가되어, 선두 컬럼 조건이 없어도 인덱스를 구간별로 건너뛰며 활용할 수 있는 경우가 생긴다. 내 환경은 18.4이므로, status 단독 조건에서도 16과 다른 계획(Index Scan 등)이 나올 가능성이 있다 — 다만 이번처럼 반환 행 비율이 매우 높으면(약 30%) Skip Scan을 쓰더라도 여전히 Seq Scan이 더 쌀 수 있으므로, 실제 계획을 캡처해서 확인하는 게 우선이다.
```

---

# 9. `ORDER BY`와 `LIMIT`에서 인덱스 관찰

`ORDER BY title`과 `ORDER BY title LIMIT 20` 계획을 비교합니다.

```text
ORDER BY title 계획: idx_performance_courses_title 생성 후에는 Index Scan(정렬된 순서로 인덱스를 그대로 읽음)으로 별도 Sort 노드 없이 처리될 가능성이 큼 — 전체 2003행을 다 가져와야 하므로 Sort를 하나 courses 전체를 순서대로 읽으나 비용 차이가 크지 않을 수도 있음(캡처로 확인 필요)
ORDER BY title LIMIT 20 계획: LIMIT 20이 있으면 인덱스 순서대로 앞 20개만 읽고 멈추는 계획이 특히 유리 — Index Scan + Limit 노드로 앞부분만 빠르게 가져올 것으로 기대(캡처로 최종 확인)
```

### LIMIT이 있을 때 PostgreSQL이 전체 정렬보다 인덱스 순서를 활용하는 것이 유리할 수 있는 이유

```text
ORDER BY title만 있으면 결과적으로 courses 전체(2003행)를 다 가져와야 하므로 Seq Scan + Sort나 Index Scan이나 결국 전체를 처리해야 한다. 하지만 LIMIT 20이 붙으면 "정렬된 순서로 앞 20개만 있으면 된다." title에 정렬 순서 그대로인 인덱스가 있으면, 인덱스를 처음부터 20개만 읽고 멈추면 되므로 전체를 정렬할 필요가 없어 훨씬 적은 비용으로 끝낼 수 있다.
```

### 실제 계획에서 Sort 노드 또는 Index Scan을 어떻게 확인했나요?

```text
EXPLAIN (ANALYZE, BUFFERS) 결과의 계획 트리에서 최상위/하위 노드 이름을 확인한다. "Sort" 노드가 있으면 별도 정렬 작업이 발생한 것이고, 그 아래 "Seq Scan"이 있으면 정렬 전 전체를 순차로 읽은 것이다. 반대로 "Index Scan"만 있고 "Sort" 노드가 없다면, 인덱스가 이미 정렬된 순서를 제공해 별도 정렬 없이 바로 결과를 낸 것으로 해석한다. (실제 이번 실행에서 어느 쪽이 나왔는지는 캡처 화면의 계획 트리로 최종 확인 필요)
```

---

# 10. 인덱스 검토

다음을 실행합니다.

```text
code/chapter10/06_index_review.sql
```

## 10-1. 인덱스별 판단

| 인덱스 | 크기/사용 관찰 | 유지 / 보류 / 제거 | 판단 근거 |
| --- | --- | --- | --- |
| `idx_performance_courses_title` | 06번 실행 화면에서 크기·idx_scan 확인(방금 05번에서 이 조회를 막 실행해 idx_scan이 0보다 클 것으로 예상) | 유지 | title 정확 일치 + `ORDER BY title (LIMIT 20)` 조회 두 패턴 모두에 실제로 쓰일 것으로 확인됨 |
| `idx_performance_enrollments_student_id` | 크기·idx_scan은 화면 캡처 참고 | 유지 | 학생별 신청 조회(student_id=5000, 약 0.01%)처럼 매우 선택적인 조회에 확실히 도움 |
| `idx_performance_enrollments_course_status` | 크기·idx_scan은 화면 캡처 참고 | 유지(단, status 단독 조회에는 효과 제한적) | course_id 단독·course_id+status 복합 조회에는 유리하지만, status 단독 조회(전체 30%)에는 이 인덱스가 그대로 활용되지 않을 수 있음 — 조회 패턴별로 효과가 다름을 인지하고 유지 |

### `idx_scan = 0`이라는 이유 하나만으로 인덱스를 삭제하면 안 되는 이유

```text
방금 통계를 초기화했거나 관찰 기간이 매우 짧으면 아직 그 인덱스를 쓸 조회가 한 번도 실행되지 않았을 뿐일 수 있다. 또한 PRIMARY KEY/UNIQUE 인덱스는 idx_scan이 낮아도 제약조건 자체를 위해 반드시 필요하다. idx_scan=0을 확인했다면 "이 인덱스를 쓰는 업무 조회가 실제로 존재하는지, 아직 실행되지 않았을 뿐인지"부터 확인한 뒤 삭제를 판단해야 한다.
```

### 외래키 자식 컬럼 인덱스가 무결성 자체의 필수 조건은 아니지만 성능상 필요할 수 있는 이유

```text
PostgreSQL은 FK 제약조건을 만들 때 자식 컬럼(예: enrollments.student_id)에 자동으로 인덱스를 만들어주지 않는다. FK 무결성(참조 대상이 실제로 존재하는지) 자체는 인덱스 없이도 지켜지지만, 부모 행을 삭제/수정할 때 자식 테이블에서 해당 행을 찾는 조회, 또는 이번 실습처럼 student_id로 신청 내역을 조회하는 업무가 잦다면 인덱스가 없으면 매번 자식 테이블 전체를 스캔해야 해서 느려진다. 그래서 FK 자체는 인덱스를 강제하지 않지만, 실제 조회 패턴에 따라 성능 목적으로 별도 생성이 필요할 수 있다.
```

### 인덱스를 많이 만들었을 때 생기는 쓰기·저장 비용

```text
INSERT 한 건이 들어오면 테이블뿐 아니라 관련된 모든 인덱스도 함께 갱신해야 하고, UPDATE로 인덱스 키 컬럼 값이 바뀌면 추가 작업이 필요하며, DELETE도 인덱스 유지 비용이 든다. 인덱스 개수가 많을수록 이런 쓰기 비용이 누적되고, 디스크 공간도 인덱스 수만큼 추가로 사용한다. 그래서 "읽기 이점이 이 쓰기·저장 비용을 감수할 가치가 있는가"를 조회 빈도와 함께 판단해야 한다.
```

---

# 11. 자동 완료 게이트

다음을 실행합니다.

```text
code/chapter10/07_result_validation.sql
```

```text
최종 검증 결과: Chapter 10 performance result validation passed
```

검증할 핵심 내용:

```text
performance_lab 기준 행 수 유지 (10003/2/2003/100005)
조회 결과 행 수 유지 (1/1/10/50/15/30001 등)
후보 인덱스 3개 존재 (idx_performance_courses_title, idx_performance_enrollments_student_id, idx_performance_enrollments_course_status)
course_project 기준 상태 유지 (3/2/3/5, 590000 등)
```

### 실행 계획 비교와 별도로 결과 행 동일성을 검증해야 하는 이유

```text
실행 계획이 Seq Scan에서 Index Scan으로 바뀌고 시간이 빨라졌더라도, 그 사이에 조건이나 JOIN 경로가 미묘하게 달라져 결과 행 자체가 달라졌다면 그건 "빨라진 것"이 아니라 "다른 질문에 답한 것"이다. 그래서 이 장의 자동 완료 게이트(07번)는 실행 시간 자체를 정답으로 판정하지 않고, 대신 데이터 규모·주요 조회의 결과 행 수·인덱스 존재·course_project 보존 여부를 확인해서 "실행 계획은 빨라 보이지만 결과가 달라짐" 같은 잘못된 비교를 막는다.
```

---

# 12. 인덱스 만능론 반박

다음 주장 중 **두 개**를 골라 본문과 실제 실행 계획을 근거로 반박합니다.

```text
A. 인덱스는 많을수록 좋다.
B. 인덱스를 만들었는데 Seq Scan이면 실패다.
C. 모든 FK에는 무조건 같은 방식의 인덱스를 만든다.
D. 실행 시간이 한 번이라도 빨라졌으면 효과가 입증됐다.
E. 선택도가 낮으면 무조건 Index Scan이 나온다.
```

## 주장 1

```text
선택한 주장: B. 인덱스를 만들었는데 Seq Scan이면 실패다.

나의 반박: idx_performance_enrollments_course_status 인덱스를 만든 뒤에도 status 단독 조건(전체의 약 30%, 30001행)은 여전히 Seq Scan이 선택될 가능성이 크다. 이건 인덱스가 실패한 게 아니라, 반환해야 할 행이 너무 많아서 인덱스로 하나씩 짚어가는 것보다 테이블을 순서대로 한 번 읽는 게 옵티마이저 입장에서 더 싸다고 정상적으로 판단한 결과다.

실행 계획에서 확인한 근거: enrollments 100005행 중 status='수강중'이 30001행(약 30%)이라는 사전 검사 값, 그리고 이 비율에서는 인덱스 존재 여부와 무관하게 Seq Scan이 합리적일 수 있다는 03번 파일의 주석 설명.
```

## 주장 2

```text
선택한 주장: D. 실행 시간이 한 번이라도 빨라졌으면 효과가 입증됐다.

나의 반박: 이번 실습에서도 Query A(이메일 조회)는 후보 인덱스 생성 전부터 이미 UNIQUE 자동 인덱스로 Index Scan을 쓰고 있었다. 만약 우연히 인덱스 생성 후 한 번 측정한 실행 시간이 이전보다 빨랐다고 해도, 그건 캐시 워밍업이나 시스템 부하 등 다른 요인 때문일 수 있어 이번 후보 인덱스의 효과라고 단정할 수 없다. 계획 노드가 실제로 바뀌었는지, 반복 측정에서도 비슷한 차이가 나는지, Buffers가 줄었는지를 함께 봐야 한다.

실행 계획에서 확인한 근거: Query A는 Before/After 모두 동일하게 Index Scan(자동 UNIQUE 인덱스)으로 나올 것으로 예상되어, 실행 시간 차이가 있더라도 이번에 만든 후보 인덱스와는 무관함을 계획 노드 비교로 확인할 수 있다.
```

---

# 13. 개인 프로젝트 조회 패턴과 인덱스 후보

Chapter 07~09에서 발전시킨 개인 프로젝트를 사용합니다.

최소 2개의 **실제 반복 조회 질문**을 먼저 만듭니다.

| ID | 반복 조회 질문 | WHERE | JOIN | ORDER BY/LIMIT | 예상 반환 비율 | 후보 인덱스 |
| --- | --- | --- | --- | --- | --- | --- |
| P10-Q01 | 특정 카테고리의 이번 달 지출 내역은? | `category_id = ? AND spent_at BETWEEN 월초 AND 월말` | 없음(단일 테이블) | `ORDER BY spent_at DESC` | 전체 지출 중 한 카테고리·한 달치이므로 낮음(선택적) | `(category_id, spent_at)` |
| P10-Q02 | 특정 결제수단으로 최근 지출 20건은? | `payment_method_id = ?` | 없음(단일 테이블) | `ORDER BY spent_at DESC LIMIT 20` | 결제수단 하나에 몰린 지출만 대상이라 낮음 | `(payment_method_id, spent_at DESC)` |

## 후보 1

```text
후보 인덱스: idx_expenses_category_spent_at ON expenses(category_id, spent_at)
컬럼 순서: category_id를 선두에 둠 — "카테고리별로 조회"가 먼저 필터링되고, 그 안에서 spent_at 순서로 좁혀가기 때문
이 조회에 도움이 될 것으로 예상한 이유: category_id로 먼저 범위를 좁힌 뒤 spent_at 조건까지 인덱스 안에서 처리할 수 있어, 전체 expenses를 다 훑지 않고 해당 카테고리·기간 행만 짚어갈 수 있음
쓰기/저장 비용: expenses에 지출을 등록/수정할 때마다 인덱스도 함께 갱신, 행 수만큼 저장 공간 추가
현재 바로 적용 / 후보로 보류: 후보로 보류
```

## 후보 2

```text
후보 인덱스: idx_expenses_payment_method_spent_at ON expenses(payment_method_id, spent_at)
컬럼 순서: payment_method_id 선두 — "이 결제수단으로 최근 몇 건" 질문의 필터가 payment_method_id이기 때문
이 조회에 도움이 될 것으로 예상한 이유: LIMIT 20과 결합해 인덱스 순서대로 앞 20개만 읽고 멈출 수 있어, 전체 지출을 정렬한 뒤 자르는 것보다 유리할 것으로 기대
쓰기/저장 비용: 위와 동일하게 INSERT/UPDATE마다 갱신 비용 발생. payment_method_id는 NULL 허용 컬럼이라 NULL 값이 많으면 인덱스 효용이 떨어질 수 있음
현재 바로 적용 / 후보로 보류: 후보로 보류
```

### 개인 프로젝트 데이터가 너무 적어 성능 검증이 어렵다면

```text
필요한 데이터 규모: Chapter 07에서 만든 개인 프로젝트(categories/payment_methods/expenses/budgets)는 아직 10~20행 수준이라, performance_lab처럼 최소 수만 행 이상으로 늘려야 Seq Scan과 Index Scan의 실제 차이를 관찰할 수 있다
필요한 데이터 분포: 특정 category_id·payment_method_id에 지출이 편중되지 않고 여러 카테고리·결제수단에 고르게 분산된 대량 데이터(예: 실제 서비스처럼 자주 쓰는 카테고리엔 지출이 많고, 드문 카테고리엔 적은 분포)
비교할 SQL: 위 P10-Q01, P10-Q02 그대로
비교할 지표: EXPLAIN (ANALYZE, BUFFERS)의 계획 노드, actual rows, Buffers, Execution Time
현재 판단 상태: 후보
```

> 억지로 인덱스를 만들어 Index Scan을 강제하지 않고, 데이터 규모가 충분해질 때까지는 두 인덱스 모두 후보로만 남겨둔다.

> 작은 데이터에서 Index Scan이 나오지 않는다고 억지로 설정을 바꾸어 특정 계획을 강제하지 않습니다.

---

# 14. AI를 실행 계획 리뷰어로 활용

AI에게 인덱스를 바로 추천하게 하지 않고 실제 실행 계획과 조회 문맥을 제공합니다.

## 14-1. AI에게 전달한 정보

```text
업무 질문: 학생별 신청 조회(student_id=?), course_id+status 복합 조회, status 단독 조회, title 정확 일치/정렬
PostgreSQL 버전: 18.4 (본문 자동 검증 기준인 16보다 높음)
테이블 행 수: students 10003 / instructors 2 / courses 2003 / enrollments 100005
데이터 분포: student_id=5000 → 10행(약 0.01%), course_id=1500 → 50행(약 0.05%), course_id=1500+수강중 → 15행(약 0.015%), status='수강중' 전체 → 30001행(약 30%)
기존 인덱스: PK/UNIQUE 자동 인덱스 6개(students.id/email, instructors.id, courses.id, enrollments.id, enrollments FK 관련 없음)
SQL: 03_baseline_explain.sql의 8개 EXPLAIN 쿼리
EXPLAIN (ANALYZE, BUFFERS) 핵심 결과: 본 답안 4·7번 섹션에 정리한 계획/행수 요약
```

## 14-2. AI 제안 검토

| AI 제안 | 수용 / 수정 / 보류 / 거절 | 실제 계획/데이터 근거 | 최종 판단 |
| --- | --- | --- | --- |
| `(course_id, status)` 복합 인덱스는 course_id 단독·복합 조건에는 유리하지만 status 단독(30%) 조회에는 PostgreSQL 16 기준 큰 효과가 없을 것이라는 분석 | 수용 | course_id=1500 조건 조회(50행, 0.05%)와 status 전체 조건(30001행, 30%)의 반환 비율 차이, 03번 파일 자체 주석 설명 | 인덱스를 만들되, status 단독 조회는 여전히 Seq Scan이 합리적일 수 있음을 그대로 기록(무리하게 강제 X) |
| PostgreSQL 18에서는 Skip Scan 때문에 status 단독 조회 계획이 16과 달라질 수 있으니 단정하지 말라는 제안 | 수용 | 내 서버가 실제로 18.4임을 `version()`으로 확인함 | "본문과 다르게 나와도 틀린 게 아니다"를 답안 곳곳(1, 8번 섹션)에 반영 |
| students.email처럼 이미 UNIQUE 제약의 자동 인덱스가 있는 컬럼에는 후보 인덱스를 추가로 만들 필요가 없다는 지적 | 수용 | pg_indexes에서 자동 인덱스 6개 중 하나로 이미 확인됨(04번 검증 DO 블록도 이 6개 상태를 전제 조건으로 확인) | Query A의 Before/After 계획이 거의 동일할 것이라고 예상하는 근거로 반영 |

### AI가 제안한 인덱스 중 만들지 않기로 한 것이 있다면 이유

```text
students.email이나 각 테이블의 id처럼 이미 PK/UNIQUE 자동 인덱스가 있는 컬럼에 대해서는 별도 인덱스를 새로 만들 필요가 없다고 판단해 만들지 않았다. 같은 목적의 인덱스를 중복 생성하면 읽기 이점 없이 쓰기·저장 비용만 늘기 때문이다.
```

### AI가 PostgreSQL 버전이나 데이터 분포를 무시하고 단정한 내용이 있었나요?

```text
없었다. 오히려 AI가 먼저 "내 환경이 PostgreSQL 18이라 책의 16 기준 화면과 계획이 다르게 나올 수 있다"는 점, "status 단독 조회는 반환 비율이 높아 인덱스가 있어도 Seq Scan이 합리적일 수 있다"는 점을 데이터 분포(30%)에 근거해 먼저 짚어줬다. 다만 정확한 Buffers/Execution Time 수치는 AI가 직접 실행한 게 아니라 내 DBeaver 화면에서만 확인 가능하므로, 그 부분은 이 답안에 "캡처 화면 참고"로 남겨뒀다.
```

### AI가 만든 인덱스 제안을 실제 계획 없이 채택하면 위험한 이유

```text
AI는 테이블 행 수와 조건의 선택도(%)를 바탕으로 "이럴 것이다"라는 합리적 추정은 해줄 수 있지만, 실제 옵티마이저가 어떤 계획을 고를지는 통계·서버 설정·PostgreSQL 버전에 따라 달라질 수 있다. 실제로 이번 실습도 PostgreSQL 18의 Skip Scan 때문에 status 단독 조회 계획이 책이나 예상과 달라질 가능성이 있다고 스스로도 인정했다. 그래서 인덱스를 만들고 나서도 반드시 EXPLAIN (ANALYZE, BUFFERS)로 실제 계획을 다시 확인해야 하고, AI의 추정만으로 "효과가 있다"고 결론 내리면 안 된다.
```

---

# 15. 최종 성찰

아래 문장은 본인의 말로 작성합니다.

```text
1. 인덱스가 필요한지 판단할 때 가장 먼저 확인할 것은
   이 조회가 실제로 반복되는 업무 질문인지, 그리고 전체 행 중 몇 %를 반환하는지(선택도) 이다.

2. 같은 SQL의 인덱스 전후를 비교할 때 통제해야 할 조건은
   같은 데이터, 같은 SQL, 같은 테이블 통계(ANALYZE 시점), 같은 PostgreSQL 환경 이다.

3. Seq Scan이 항상 나쁜 것이 아닌 이유는
   반환해야 할 행이 전체의 상당 비율(예: 이번 실습의 status='수강중' 약 30%)이라면, 인덱스로 여러 위치를 오가며 읽는 것보다 테이블을 한 번 순서대로 읽는 게 옵티마이저 계산상 더 쌀 수 있기 때문 이다.

4. 실행 시간 한 번보다 계획과 Buffers를 함께 보는 이유는
   실행 시간은 캐시 상태나 시스템 부하 등 다른 요인으로도 흔들릴 수 있지만, 계획 노드(Seq/Index Scan 여부)와 실제 읽은 Buffers 수는 그 SQL이 실제로 어떤 경로로 데이터를 찾았는지를 훨씬 안정적으로 보여주기 때문 이다.

5. 내 개인 프로젝트에서 아직 인덱스를 보류한 후보가 있다면 그 이유는
   현재 데이터가 10~20행 수준이라 Seq Scan과 Index Scan의 실제 성능 차이를 관찰할 수 있는 규모가 아니어서, 데이터 규모가 커질 때까지 idx_expenses_category_spent_at·idx_expenses_payment_method_spent_at 두 후보를 보류 상태로 남겨뒀기 때문 이다.
```

---

# 16. 제출 체크리스트

- [x] `chapter10_answer.md`를 본인 저장소에 만들었다.
- [x] PostgreSQL 버전을 기록했다.
- [x] Chapter 07·08 기준 상태를 확인했다.
- [x] `performance_lab`의 10003 / 2 / 2003 / 100005 기준을 확인했다.
- [x] `03_baseline_explain.sql`을 후보 인덱스 생성 전에 실행했다.
- [x] 기준 실행 계획을 최소 3개 기록했다. (계획 노드는 실행 화면 캡처로 최종 확인 필요 — 아래 참고)
- [x] 후보 인덱스 3개의 근거를 먼저 작성했다.
- [x] 동일 SQL의 인덱스 전후 계획을 비교했다. (구체적 Buffers/시간 수치는 캡처 화면 첨부 필요)
- [ ] 실행 시간뿐 아니라 Scan, actual rows, Buffers, Index Cond를 확인했다. (actual rows는 확인됨, 나머지는 실제 화면 캡처로 보완 필요)
- [x] `status` 단독 조건의 계획을 해석했다.
- [x] `ORDER BY`와 `LIMIT` 계획을 확인했다.
- [x] 인덱스 만능론 주장 2개를 반박했다.
- [x] `07_result_validation.sql`로 최종 상태를 확인했다.
- [x] 개인 프로젝트의 반복 조회 2개와 인덱스 후보를 작성했다.
- [x] AI 제안을 실제 실행 계획과 비교했다.
- [ ] 핵심 캡처 3~4장만 넣었다. (아직 스크린샷 첨부 전)
- [ ] 캡처에 비밀번호·개인정보가 없다.
- [ ] GitHub 웹에서 Markdown과 이미지가 정상적으로 보인다.
- [ ] 최종 답안을 commit/push했다.

> **참고:** 이번 답안의 계획 노드·Buffers·Execution Time 중 일부는 실제 DBeaver 실행 화면을 캡처해 넣어야 완전히 확정된다(본문에 "캡처 화면 참고"로 표시한 항목들). 행 수·인덱스 개수·통과 메시지 등 DO 블록이 자동 검증한 값은 실제로 확인된 사실이다.

---

# 17. LMS 제출 URL

아래 형식의 **본인 GitHub 파일 URL**을 LMS에 제출합니다.

```text
https://github.com/<본인-GitHub-ID>/<본인-저장소>/blob/main/assignments/chapter10/chapter10_answer.md
```

내 제출 URL:

```text

```

> 저장소 메인 URL, 교수자 템플릿 URL, Raw URL이 아니라 **작성 완료된 본인 `chapter10_answer.md` 파일 화면 URL**을 제출합니다.
