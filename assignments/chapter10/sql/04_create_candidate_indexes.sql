-- Chapter 10. 전후 측정을 위한 실험 후보 인덱스 생성
-- 03_baseline_explain.sql은 읽기 전용이므로 DB 상태만으로 '기준 계획 기록 완료'를 판정할 수 없습니다.
-- 반드시 03 결과를 먼저 기록한 뒤 이 파일을 실행합니다. 자동 검증은 03→04 실행 순서를 별도로 확인합니다.
-- 후보 인덱스 생성 후 ANALYZE를 다시 실행하지 않아 기준·사후 측정이 같은 테이블 통계를 사용하게 합니다.

SELECT current_database();
SELECT current_schema();
SHOW search_path;
SHOW server_version;

BEGIN;

DO $$
DECLARE
    v_index_count bigint;
BEGIN
    IF current_database() <> 'ai_database_book' THEN
        RAISE EXCEPTION
            '인덱스 생성 중단: 현재 데이터베이스는 %입니다.', current_database();
    END IF;

    IF current_setting('transaction_read_only')::boolean THEN
        RAISE EXCEPTION
            '인덱스 생성 중단: 현재 연결이 읽기 전용입니다.';
    END IF;

    IF to_regclass('performance_lab.students') IS NULL
       OR to_regclass('performance_lab.instructors') IS NULL
       OR to_regclass('performance_lab.courses') IS NULL
       OR to_regclass('performance_lab.enrollments') IS NULL THEN
        RAISE EXCEPTION
            '인덱스 생성 중단: performance_lab이 준비되지 않았습니다.';
    END IF;

    IF (SELECT COUNT(*) FROM performance_lab.students) <> 10003
       OR (SELECT COUNT(*) FROM performance_lab.instructors) <> 2
       OR (SELECT COUNT(*) FROM performance_lab.courses) <> 2003
       OR (SELECT COUNT(*) FROM performance_lab.enrollments) <> 100005 THEN
        RAISE EXCEPTION
            '인덱스 생성 중단: 기준 데이터 행 수가 예상과 다릅니다.';
    END IF;

    SELECT COUNT(*) INTO v_index_count
    FROM pg_indexes
    WHERE schemaname = 'performance_lab';

    IF v_index_count <> 6
       OR to_regclass('performance_lab.idx_performance_courses_title') IS NOT NULL
       OR to_regclass('performance_lab.idx_performance_enrollments_student_id') IS NOT NULL
       OR to_regclass('performance_lab.idx_performance_enrollments_course_status') IS NOT NULL THEN
        RAISE EXCEPTION
            '인덱스 생성 중단: 자동 인덱스 6개, 실험 후보 0개 상태여야 합니다.';
    END IF;
END
$$;

CREATE INDEX idx_performance_courses_title
ON performance_lab.courses(title);

CREATE INDEX idx_performance_enrollments_student_id
ON performance_lab.enrollments(student_id);

CREATE INDEX idx_performance_enrollments_course_status
ON performance_lab.enrollments(course_id, status);

DO $$
DECLARE
    v_index_count bigint;
    v_candidate_count bigint;
    v_invalid_count bigint;
BEGIN
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

    IF v_index_count <> 9
       OR v_candidate_count <> 3
       OR v_invalid_count <> 0
       OR position('(title)' in pg_get_indexdef('performance_lab.idx_performance_courses_title'::regclass)) = 0
       OR position('(student_id)' in pg_get_indexdef('performance_lab.idx_performance_enrollments_student_id'::regclass)) = 0
       OR position('(course_id, status)' in pg_get_indexdef('performance_lab.idx_performance_enrollments_course_status'::regclass)) = 0 THEN
        RAISE EXCEPTION
            '후보 인덱스 생성 검증 실패: indexes=%, candidates=%, invalid=%',
            v_index_count, v_candidate_count, v_invalid_count;
    END IF;

    RAISE NOTICE 'Chapter 10 candidate index creation passed';
END
$$;

COMMIT;

-- 02에서 수집한 동일한 테이블 통계를 계속 사용합니다.
-- 이 파일에서는 ANALYZE를 다시 실행하지 않습니다.

SELECT tablename, indexname, indexdef
FROM pg_indexes
WHERE schemaname = 'performance_lab'
ORDER BY tablename, indexname;

-- 운영 환경에서는 쓰기 잠금 영향, 생성 시간과 추가 공간을 검토합니다.
-- 필요하면 CONCURRENTLY 방식의 운영 인덱스 생성을 별도 절차로 고려할 수 있습니다.
-- CONCURRENTLY는 트랜잭션 블록 안에서 실행할 수 없고,
-- 실패한 동시 생성 작업 뒤에는 INVALID 인덱스가 남았는지 확인해야 합니다.
