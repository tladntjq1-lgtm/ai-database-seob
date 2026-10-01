-- Chapter 10. 후보 인덱스 생성 후 실행 계획
-- 실행 전 01→02→03→04 파일을 순서대로 실행합니다.
-- 검증 기준: PostgreSQL 16
-- 03과 완전히 같은 8개 SELECT를 사용해 비교합니다.

SELECT current_database();
SELECT current_schema();
SHOW search_path;
SHOW server_version;
SHOW enable_seqscan;
SHOW enable_indexscan;
SHOW enable_bitmapscan;

DO $$
DECLARE
    v_index_count bigint;
    v_candidate_count bigint;
    v_invalid_count bigint;
BEGIN
    IF current_database() <> 'ai_database_book' THEN
        RAISE EXCEPTION
            '사후 계획 측정 중단: 현재 데이터베이스는 %입니다.', current_database();
    END IF;

    IF to_regclass('performance_lab.students') IS NULL
       OR to_regclass('performance_lab.instructors') IS NULL
       OR to_regclass('performance_lab.courses') IS NULL
       OR to_regclass('performance_lab.enrollments') IS NULL THEN
        RAISE EXCEPTION
            '사후 계획 측정 중단: performance_lab이 준비되지 않았습니다.';
    END IF;

    IF (SELECT COUNT(*) FROM performance_lab.students) <> 10003
       OR (SELECT COUNT(*) FROM performance_lab.instructors) <> 2
       OR (SELECT COUNT(*) FROM performance_lab.courses) <> 2003
       OR (SELECT COUNT(*) FROM performance_lab.enrollments) <> 100005 THEN
        RAISE EXCEPTION
            '사후 계획 측정 중단: 기준 데이터 행 수가 10003/2/2003/100005와 다릅니다.';
    END IF;

    SELECT COUNT(*) INTO v_index_count
    FROM pg_indexes
    WHERE schemaname = 'performance_lab';

    SELECT COUNT(*) INTO v_candidate_count
    FROM pg_indexes
    WHERE schemaname = 'performance_lab'
      AND indexname IN (
          'idx_performance_courses_title',
          'idx_performance_enrollments_student_id',
          'idx_performance_enrollments_course_status'
      );

    SELECT COUNT(*) INTO v_invalid_count
    FROM pg_index AS ix
    JOIN pg_class AS i ON i.oid = ix.indexrelid
    JOIN pg_namespace AS n ON n.oid = i.relnamespace
    WHERE n.nspname = 'performance_lab'
      AND i.relname IN (
          'idx_performance_courses_title',
          'idx_performance_enrollments_student_id',
          'idx_performance_enrollments_course_status'
      )
      AND (NOT ix.indisvalid OR NOT ix.indisready);

    IF v_index_count <> 9 OR v_candidate_count <> 3 OR v_invalid_count <> 0 THEN
        RAISE EXCEPTION
            '사후 계획 측정 중단: 전체 인덱스 9개, 실험 후보 3개가 모두 valid/ready 상태여야 합니다.';
    END IF;

    IF current_setting('enable_seqscan') <> 'on'
       OR current_setting('enable_indexscan') <> 'on'
       OR current_setting('enable_bitmapscan') <> 'on' THEN
        RAISE EXCEPTION
            '사후 계획 측정 중단: enable_seqscan/indexscan/bitmapscan을 모두 on으로 맞추세요.';
    END IF;

    IF (SELECT COUNT(*) FROM performance_lab.students
        WHERE email = 'performance5000@example.com') <> 1
       OR (SELECT COUNT(*) FROM performance_lab.courses
           WHERE title = '성능 테스트 강의 00500') <> 1
       OR (SELECT COUNT(*) FROM performance_lab.enrollments
           WHERE student_id = 5000) <> 10
       OR (SELECT COUNT(*) FROM performance_lab.enrollments
           WHERE course_id = 1500) <> 50
       OR (SELECT COUNT(*) FROM performance_lab.enrollments
           WHERE course_id = 1500 AND status = '수강중') <> 15
       OR (SELECT COUNT(*) FROM performance_lab.enrollments
           WHERE status = '수강중') <> 30001 THEN
        RAISE EXCEPTION
            '사후 계획 측정 중단: 기준 SQL 결과 행 수가 1/1/10/50/15/30001과 다릅니다.';
    END IF;
END
$$;

-- 1. UNIQUE 자동 인덱스가 있는 이메일 검색
EXPLAIN (ANALYZE, BUFFERS)
SELECT id, name, email
FROM performance_lab.students
WHERE email = 'performance5000@example.com';

-- 2. 일반 컬럼 title 정확 일치
EXPLAIN (ANALYZE, BUFFERS)
SELECT id, title, level, price
FROM performance_lab.courses
WHERE title = '성능 테스트 강의 00500';

-- 3. 학생별 신청 JOIN: student_id 5000은 10행
EXPLAIN (ANALYZE, BUFFERS)
SELECT
    e.id,
    s.name AS student_name,
    c.title AS course_title,
    e.status,
    e.recorded_amount
FROM performance_lab.enrollments AS e
JOIN performance_lab.students AS s ON s.id = e.student_id
JOIN performance_lab.courses AS c ON c.id = e.course_id
WHERE e.student_id = 5000;

-- 4. course_id 단독 조건: 50행
EXPLAIN (ANALYZE, BUFFERS)
SELECT id, student_id, course_id, status, recorded_amount
FROM performance_lab.enrollments
WHERE course_id = 1500;

-- 5. course_id + status 복합 조건: 수강중 15행
EXPLAIN (ANALYZE, BUFFERS)
SELECT id, student_id, course_id, status, recorded_amount
FROM performance_lab.enrollments
WHERE course_id = 1500
  AND status = '수강중';

-- 6. status 단독 조건: 수강중 30001행
-- PostgreSQL 16에는 B-tree Skip Scan 최적화가 없습니다.
-- (course_id, status)의 후행 status만 조건으로 사용하면 인덱스 전체에 가까운 탐색이 필요할 수 있어
-- 이 데이터 분포에서는 Seq Scan이 합리적일 가능성이 큽니다.
-- PostgreSQL 18+에서는 Skip Scan이 추가되어 동일 SQL의 계획이 달라질 수 있습니다.
EXPLAIN (ANALYZE, BUFFERS)
SELECT id, student_id, course_id, status
FROM performance_lab.enrollments
WHERE status = '수강중';

-- 7. 전체 정렬
EXPLAIN (ANALYZE, BUFFERS)
SELECT id, title, level, price
FROM performance_lab.courses
ORDER BY title;

-- 8. 정렬 + LIMIT
EXPLAIN (ANALYZE, BUFFERS)
SELECT id, title, level, price
FROM performance_lab.courses
ORDER BY title
LIMIT 20;

DO $$
BEGIN
    RAISE NOTICE 'Chapter 10 after-index explain validation passed';
END
$$;
