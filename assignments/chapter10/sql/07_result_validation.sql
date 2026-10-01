-- Chapter 10. 성능 실험 결과·데이터 상태 검증
-- 실행 전 01→06 파일을 순서대로 실행합니다.
-- 실행 계획 노드 자체는 환경·버전·캐시·설정에 따라 달라질 수 있으므로 고정 정답으로 판정하지 않습니다.
-- 데이터 상태, 결과 행 수, Chapter 07·08 보호와 인덱스 상태를 자동 검증합니다.

SELECT current_database();
SELECT current_schema();
SHOW search_path;
SHOW server_version;

-- 핵심 결과 행 수
SELECT COUNT(*) AS email_result_count
FROM performance_lab.students
WHERE email = 'performance5000@example.com';

SELECT COUNT(*) AS title_result_count
FROM performance_lab.courses
WHERE title = '성능 테스트 강의 00500';

SELECT COUNT(*) AS student_5000_enrollment_count
FROM performance_lab.enrollments
WHERE student_id = 5000;

SELECT COUNT(*) AS course_1500_enrollment_count
FROM performance_lab.enrollments
WHERE course_id = 1500;

SELECT COUNT(*) AS course_1500_learning_count
FROM performance_lab.enrollments
WHERE course_id = 1500
  AND status = '수강중';

SELECT COUNT(*) AS all_learning_count
FROM performance_lab.enrollments
WHERE status = '수강중';

-- 기대 결과: 1 / 1 / 10 / 50 / 15 / 30001

-- 활성 신청 중복: 기대 0행
SELECT student_id, course_id, COUNT(*) AS active_count
FROM performance_lab.enrollments
WHERE status IN ('신청', '수강중')
GROUP BY student_id, course_id
HAVING COUNT(*) > 1
ORDER BY student_id, course_id;

DO $$
DECLARE
    v_requested_count bigint;
    v_learning_count bigint;
    v_completed_count bigint;
    v_cancelled_count bigint;
    v_total_amount numeric(20,0);
    v_active_count bigint;
    v_active_amount numeric(20,0);
    v_non_cancelled_count bigint;
    v_non_cancelled_amount numeric(20,0);
    v_duplicate_active_pairs bigint;
    v_amount_mismatch bigint;
    v_bad_student_distribution bigint;
    v_bad_course_distribution bigint;
    v_index_count bigint;
    v_candidate_count bigint;
    v_invalid_count bigint;
    v_project_named_constraint_count bigint;
    v_project_not_null_count bigint;
BEGIN
    IF current_database() <> 'ai_database_book' THEN
        RAISE EXCEPTION
            '최종 검증 실패: 현재 데이터베이스는 %입니다.', current_database();
    END IF;

    -- Chapter 07·08 기준 상태가 그대로인지 다시 확인합니다.
    IF to_regclass('course_project.students') IS NULL
       OR to_regclass('course_project.instructors') IS NULL
       OR to_regclass('course_project.courses') IS NULL
       OR to_regclass('course_project.enrollments') IS NULL
       OR to_regclass('course_project.uq_course_enrollments_active') IS NULL THEN
        RAISE EXCEPTION
            '최종 검증 실패: Chapter 07 course_project 기준 객체가 없습니다.';
    END IF;

    SELECT COUNT(*) INTO v_project_named_constraint_count
    FROM pg_constraint
    WHERE conrelid IN (
        'course_project.students'::regclass,
        'course_project.instructors'::regclass,
        'course_project.courses'::regclass,
        'course_project.enrollments'::regclass
    )
      AND conname IN (
        'uq_course_students_email',
        'chk_course_students_name_not_blank',
        'chk_course_students_email_not_blank',
        'uq_course_instructors_email',
        'chk_course_instructors_name_not_blank',
        'chk_course_instructors_email_not_blank',
        'chk_course_instructors_specialty_not_blank',
        'fk_course_courses_instructor',
        'chk_course_courses_title_not_blank',
        'chk_course_courses_level',
        'chk_course_courses_price',
        'fk_course_enrollments_student',
        'fk_course_enrollments_course',
        'chk_course_enrollments_status',
        'chk_course_enrollments_recorded_amount'
      );

    SELECT COUNT(*) INTO v_project_not_null_count
    FROM information_schema.columns
    WHERE table_schema = 'course_project'
      AND table_name IN ('students', 'instructors', 'courses', 'enrollments')
      AND is_nullable = 'NO';

    IF v_project_named_constraint_count <> 15 OR v_project_not_null_count <> 20 THEN
        RAISE EXCEPTION
            '최종 검증 실패: Chapter 07 구조 기준이 변경되었습니다. named_constraints=%, not_null_columns=%',
            v_project_named_constraint_count, v_project_not_null_count;
    END IF;

    IF (SELECT COUNT(*) FROM course_project.students) <> 3
       OR (SELECT COUNT(*) FROM course_project.instructors) <> 2
       OR (SELECT COUNT(*) FROM course_project.courses) <> 3
       OR (SELECT COUNT(*) FROM course_project.enrollments) <> 5 THEN
        RAISE EXCEPTION
            '최종 검증 실패: Chapter 07·08 기준 행 수 3/2/3/5가 유지되지 않았습니다.';
    END IF;

    SELECT
        COUNT(*) FILTER (WHERE status = '신청'),
        COUNT(*) FILTER (WHERE status = '수강중'),
        COUNT(*) FILTER (WHERE status = '완료'),
        COUNT(*) FILTER (WHERE status = '취소'),
        COALESCE(SUM(recorded_amount), 0),
        COUNT(*) FILTER (WHERE status IN ('신청', '수강중')),
        COALESCE(SUM(recorded_amount) FILTER (WHERE status IN ('신청', '수강중')), 0),
        COUNT(*) FILTER (WHERE status <> '취소'),
        COALESCE(SUM(recorded_amount) FILTER (WHERE status <> '취소'), 0)
    INTO
        v_requested_count,
        v_learning_count,
        v_completed_count,
        v_cancelled_count,
        v_total_amount,
        v_active_count,
        v_active_amount,
        v_non_cancelled_count,
        v_non_cancelled_amount
    FROM course_project.enrollments;

    IF v_requested_count <> 2
       OR v_learning_count <> 1
       OR v_completed_count <> 1
       OR v_cancelled_count <> 1
       OR v_total_amount <> 590000
       OR v_active_count <> 3
       OR v_active_amount <> 340000
       OR v_non_cancelled_count <> 4
       OR v_non_cancelled_amount <> 440000 THEN
        RAISE EXCEPTION
            '최종 검증 실패: Chapter 07·08 상태·금액 기준이 변경되었습니다.';
    END IF;

    IF NOT EXISTS (
        SELECT 1 FROM course_project.enrollments
        WHERE id = 1001 AND status = '완료' AND recorded_amount = 100000
    ) OR NOT EXISTS (
        SELECT 1 FROM course_project.enrollments
        WHERE id = 1004 AND status = '취소' AND recorded_amount = 150000
    ) OR NOT EXISTS (
        SELECT 1 FROM course_project.enrollments
        WHERE id = 1005 AND status = '신청' AND recorded_amount = 120000
    ) THEN
        RAISE EXCEPTION
            '최종 검증 실패: 기준 신청 1001·1004·1005가 변경되었습니다.';
    END IF;

    -- performance_lab 구조·행 수
    IF to_regclass('performance_lab.students') IS NULL
       OR to_regclass('performance_lab.instructors') IS NULL
       OR to_regclass('performance_lab.courses') IS NULL
       OR to_regclass('performance_lab.enrollments') IS NULL THEN
        RAISE EXCEPTION
            '최종 검증 실패: performance_lab 핵심 테이블이 없습니다.';
    END IF;

    IF EXISTS (
        SELECT 1
        FROM information_schema.columns
        WHERE table_schema = 'performance_lab'
          AND table_name = 'enrollments'
          AND column_name = 'paid_amount'
    ) OR NOT EXISTS (
        SELECT 1
        FROM information_schema.columns
        WHERE table_schema = 'performance_lab'
          AND table_name = 'enrollments'
          AND column_name = 'recorded_amount'
          AND data_type = 'numeric'
          AND numeric_precision = 12
          AND numeric_scale = 0
    ) THEN
        RAISE EXCEPTION
            '최종 검증 실패: performance_lab 금액 열은 recorded_amount NUMERIC(12,0)이어야 합니다.';
    END IF;

    IF (SELECT COUNT(*) FROM performance_lab.students) <> 10003
       OR (SELECT COUNT(*) FROM performance_lab.instructors) <> 2
       OR (SELECT COUNT(*) FROM performance_lab.courses) <> 2003
       OR (SELECT COUNT(*) FROM performance_lab.enrollments) <> 100005 THEN
        RAISE EXCEPTION
            '최종 검증 실패: performance_lab 기준 행 수가 10003/2/2003/100005와 다릅니다.';
    END IF;

    SELECT
        COUNT(*) FILTER (WHERE status = '신청'),
        COUNT(*) FILTER (WHERE status = '수강중'),
        COUNT(*) FILTER (WHERE status = '완료'),
        COUNT(*) FILTER (WHERE status = '취소')
    INTO v_requested_count, v_learning_count, v_completed_count, v_cancelled_count
    FROM performance_lab.enrollments;

    IF v_requested_count <> 30002
       OR v_learning_count <> 30001
       OR v_completed_count <> 20001
       OR v_cancelled_count <> 20001 THEN
        RAISE EXCEPTION
            '최종 검증 실패: performance_lab 상태 분포가 30002/30001/20001/20001과 다릅니다.';
    END IF;

    -- 기준 조회 결과
    IF (SELECT COUNT(*) FROM performance_lab.students
        WHERE id = 5000 AND email = 'performance5000@example.com') <> 1
       OR (SELECT COUNT(*) FROM performance_lab.courses
           WHERE id = 1500 AND title = '성능 테스트 강의 00500') <> 1
       OR (SELECT COUNT(*) FROM performance_lab.enrollments
           WHERE student_id = 5000) <> 10
       OR (SELECT COUNT(*) FROM performance_lab.enrollments
           WHERE course_id = 1500) <> 50
       OR (SELECT COUNT(*) FROM performance_lab.enrollments
           WHERE course_id = 1500 AND status = '수강중') <> 15
       OR (SELECT COUNT(*) FROM performance_lab.enrollments
           WHERE status = '수강중') <> 30001 THEN
        RAISE EXCEPTION
            '최종 검증 실패: 기준 SQL 결과 행 수가 1/1/10/50/15/30001과 다릅니다.';
    END IF;

    SELECT COUNT(*) INTO v_duplicate_active_pairs
    FROM (
        SELECT student_id, course_id
        FROM performance_lab.enrollments
        WHERE status IN ('신청', '수강중')
        GROUP BY student_id, course_id
        HAVING COUNT(*) > 1
    ) AS duplicated_active_pairs;

    SELECT COUNT(*) INTO v_amount_mismatch
    FROM performance_lab.enrollments AS e
    JOIN performance_lab.courses AS c ON c.id = e.course_id
    WHERE e.recorded_amount <> c.price;

    SELECT COUNT(*) INTO v_bad_student_distribution
    FROM (
        SELECT s.id
        FROM performance_lab.students AS s
        LEFT JOIN performance_lab.enrollments AS e ON e.student_id = s.id
        WHERE s.id BETWEEN 1001 AND 11000
        GROUP BY s.id
        HAVING COUNT(e.id) <> 10
    ) AS bad_students;

    SELECT COUNT(*) INTO v_bad_course_distribution
    FROM (
        SELECT c.id
        FROM performance_lab.courses AS c
        LEFT JOIN performance_lab.enrollments AS e ON e.course_id = c.id
        WHERE c.id BETWEEN 1001 AND 3000
        GROUP BY c.id
        HAVING COUNT(e.id) <> 50
    ) AS bad_courses;

    IF v_duplicate_active_pairs <> 0
       OR v_amount_mismatch <> 0
       OR v_bad_student_distribution <> 0
       OR v_bad_course_distribution <> 0 THEN
        RAISE EXCEPTION
            '최종 검증 실패: active_dup=%, amount_mismatch=%, bad_students=%, bad_courses=%',
            v_duplicate_active_pairs,
            v_amount_mismatch,
            v_bad_student_distribution,
            v_bad_course_distribution;
    END IF;

    -- 자동 6개 + 실험 후보 3개 = 전체 9개
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
            '최종 검증 실패: indexes=%, candidates=%, invalid=%',
            v_index_count, v_candidate_count, v_invalid_count;
    END IF;

    RAISE NOTICE 'Chapter 10 performance result validation passed';
END
$$;

-- 실행 계획의 적용·보류·제거 판단은 워크북에 기록합니다.
-- 계획 노드·Buffers·시간은 PostgreSQL 버전, 하드웨어, 캐시, 플래너 설정의 영향을 받습니다.
