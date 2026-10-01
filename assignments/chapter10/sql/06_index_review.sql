-- Chapter 10. 인덱스 목록·크기·사용 통계 검토
-- 이 파일은 인덱스를 자동 삭제하지 않습니다.
-- 세 실험 후보 인덱스가 생성된 상태에서 실행합니다.

SELECT current_database();
SELECT current_schema();
SHOW search_path;
SHOW server_version;

DO $$
DECLARE
    v_index_count bigint;
    v_candidate_count bigint;
    v_invalid_count bigint;
BEGIN
    IF current_database() <> 'ai_database_book' THEN
        RAISE EXCEPTION
            '인덱스 리뷰 중단: 현재 데이터베이스는 %입니다.', current_database();
    END IF;

    IF (SELECT COUNT(*) FROM performance_lab.students) <> 10003
       OR (SELECT COUNT(*) FROM performance_lab.instructors) <> 2
       OR (SELECT COUNT(*) FROM performance_lab.courses) <> 2003
       OR (SELECT COUNT(*) FROM performance_lab.enrollments) <> 100005 THEN
        RAISE EXCEPTION
            '인덱스 리뷰 중단: performance_lab 기준 행 수가 예상과 다릅니다.';
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
            '인덱스 리뷰 중단: 전체 9개, 후보 3개가 모두 valid/ready여야 합니다.';
    END IF;
END
$$;

-- 1. 자동·수동 인덱스 전체 정의
SELECT
    schemaname,
    tablename,
    indexname,
    indexdef
FROM pg_indexes
WHERE schemaname = 'performance_lab'
ORDER BY tablename, indexname;

-- 2. 통계가 언제 초기화되었는지 함께 확인합니다.
SELECT datname, stats_reset
FROM pg_stat_database
WHERE datname = current_database();

-- 3. 인덱스 크기와 사용 통계
SELECT
    psi.schemaname,
    psi.relname AS table_name,
    psi.indexrelname AS index_name,
    psi.idx_scan,
    psi.idx_tup_read,
    psi.idx_tup_fetch,
    pg_size_pretty(pg_relation_size(psi.indexrelid)) AS index_size
FROM pg_stat_user_indexes AS psi
WHERE psi.schemaname = 'performance_lab'
ORDER BY psi.relname, psi.indexrelname;

-- idx_scan은 사용자 SQL 횟수와 1:1로 대응하지 않을 수 있습니다.
-- 통계 초기화 시점, 관찰 기간, 실제 워크로드와 함께 해석합니다.

-- 4. 테이블·인덱스 전체 크기
SELECT
    schemaname,
    relname AS table_name,
    pg_size_pretty(pg_relation_size(relid)) AS table_size,
    pg_size_pretty(pg_indexes_size(relid)) AS all_indexes_size,
    pg_size_pretty(pg_total_relation_size(relid)) AS total_size
FROM pg_stat_user_tables
WHERE schemaname = 'performance_lab'
ORDER BY relname;

-- 5. 인덱스 키 컬럼과 제약조건 역할 확인
SELECT
    t.relname AS table_name,
    i.relname AS index_name,
    ix.indisprimary AS is_primary,
    ix.indisunique AS is_unique,
    ix.indisvalid AS is_valid,
    ix.indisready AS is_ready,
    pg_get_indexdef(ix.indexrelid) AS index_definition
FROM pg_index AS ix
JOIN pg_class AS i ON i.oid = ix.indexrelid
JOIN pg_class AS t ON t.oid = ix.indrelid
JOIN pg_namespace AS n ON n.oid = t.relnamespace
WHERE n.nspname = 'performance_lab'
ORDER BY t.relname, i.relname;

-- 전후 측정을 위한 실험 후보:
-- idx_performance_courses_title
-- idx_performance_enrollments_student_id
-- idx_performance_enrollments_course_status

-- 제거는 자동 실행하지 않습니다.
-- DROP INDEX performance_lab.idx_performance_courses_title;
-- DROP INDEX performance_lab.idx_performance_enrollments_student_id;
-- DROP INDEX performance_lab.idx_performance_enrollments_course_status;

-- PK·UNIQUE 인덱스는 제약조건 유지에 직접 사용됩니다.
-- FK 자식 컬럼 인덱스는 FK 정확성을 위한 필수 구조는 아니며 조회·부모 변경 성능을 위해 검토합니다.
-- idx_scan = 0만으로 즉시 삭제하지 않습니다.

DO $$
BEGIN
    RAISE NOTICE 'Chapter 10 index review validation passed';
END
$$;
