-- Chapter 08. course_project 실행 상태 확인
-- 목적: Chapter 07 최종 데이터가 정확히 준비되었는지 확인합니다.
-- 이 파일은 데이터를 변경하지 않습니다.
-- 조건이 맞지 않으면 예외를 발생시켜 Chapter 08 실행을 중단합니다.

SELECT current_database();
SELECT current_schema();
SHOW search_path;

DO $$
DECLARE
    v_student_count bigint;
    v_instructor_count bigint;
    v_course_count bigint;
    v_enrollment_count bigint;
    v_total_recorded_amount numeric;
    v_avg_recorded_amount numeric;
    v_active_count bigint;
    v_active_recorded_amount numeric;
    v_non_cancelled_count bigint;
    v_non_cancelled_recorded_amount numeric;
    v_requested_count bigint;
    v_learning_count bigint;
    v_completed_count bigint;
    v_cancelled_count bigint;
    v_orphan_student_count bigint;
    v_orphan_course_count bigint;
    v_orphan_instructor_count bigint;
    v_active_duplicate_count bigint;
    v_named_constraint_count bigint;
    v_not_null_count bigint;
    v_status_1001 text;
    v_amount_1001 numeric;
    v_status_1004 text;
    v_amount_1004 numeric;
    v_status_1005 text;
    v_amount_1005 numeric;
BEGIN
    IF current_database() <> 'ai_database_book' THEN
        RAISE EXCEPTION
            '실행 중단: 현재 데이터베이스는 %입니다. ai_database_book에 연결하세요.',
            current_database();
    END IF;

    IF to_regclass('course_project.students') IS NULL
       OR to_regclass('course_project.instructors') IS NULL
       OR to_regclass('course_project.courses') IS NULL
       OR to_regclass('course_project.enrollments') IS NULL
       OR to_regclass('course_project.uq_course_enrollments_active') IS NULL THEN
        RAISE EXCEPTION
            '실행 중단: Chapter 07의 course_project 객체가 모두 준비되지 않았습니다.';
    END IF;

    IF NOT EXISTS (
        SELECT 1
        FROM information_schema.columns
        WHERE table_schema = 'course_project'
          AND table_name = 'enrollments'
          AND column_name = 'recorded_amount'
          AND data_type = 'numeric'
          AND numeric_precision = 12
          AND numeric_scale = 0
    ) THEN
        RAISE EXCEPTION
            '실행 중단: enrollments.recorded_amount NUMERIC(12,0) 열이 없습니다.';
    END IF;

    SELECT COUNT(*) INTO v_named_constraint_count
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

    SELECT COUNT(*) INTO v_not_null_count
    FROM information_schema.columns
    WHERE table_schema = 'course_project'
      AND table_name IN ('students', 'instructors', 'courses', 'enrollments')
      AND is_nullable = 'NO';

    IF v_named_constraint_count <> 15 OR v_not_null_count <> 20 THEN
        RAISE EXCEPTION
            '실행 중단: Chapter 07 구조 기준과 다릅니다. named_constraints=%, not_null_columns=%',
            v_named_constraint_count,
            v_not_null_count;
    END IF;

    SELECT COUNT(*) INTO v_student_count
    FROM course_project.students;

    SELECT COUNT(*) INTO v_instructor_count
    FROM course_project.instructors;

    SELECT COUNT(*) INTO v_course_count
    FROM course_project.courses;

    SELECT
        COUNT(*),
        COALESCE(SUM(recorded_amount), 0),
        ROUND(AVG(recorded_amount), 2),
        COUNT(*) FILTER (WHERE status = '신청'),
        COUNT(*) FILTER (WHERE status = '수강중'),
        COUNT(*) FILTER (WHERE status = '완료'),
        COUNT(*) FILTER (WHERE status = '취소'),
        COUNT(*) FILTER (WHERE status IN ('신청', '수강중')),
        COALESCE(SUM(recorded_amount) FILTER (WHERE status IN ('신청', '수강중')), 0),
        COUNT(*) FILTER (WHERE status <> '취소'),
        COALESCE(SUM(recorded_amount) FILTER (WHERE status <> '취소'), 0)
    INTO
        v_enrollment_count,
        v_total_recorded_amount,
        v_avg_recorded_amount,
        v_requested_count,
        v_learning_count,
        v_completed_count,
        v_cancelled_count,
        v_active_count,
        v_active_recorded_amount,
        v_non_cancelled_count,
        v_non_cancelled_recorded_amount
    FROM course_project.enrollments;

    SELECT COUNT(*) INTO v_orphan_student_count
    FROM course_project.enrollments AS e
    LEFT JOIN course_project.students AS s
        ON e.student_id = s.id
    WHERE s.id IS NULL;

    SELECT COUNT(*) INTO v_orphan_course_count
    FROM course_project.enrollments AS e
    LEFT JOIN course_project.courses AS c
        ON e.course_id = c.id
    WHERE c.id IS NULL;

    SELECT COUNT(*) INTO v_orphan_instructor_count
    FROM course_project.courses AS c
    LEFT JOIN course_project.instructors AS i
        ON c.instructor_id = i.id
    WHERE i.id IS NULL;

    SELECT COUNT(*) INTO v_active_duplicate_count
    FROM (
        SELECT student_id, course_id
        FROM course_project.enrollments
        WHERE status IN ('신청', '수강중')
        GROUP BY student_id, course_id
        HAVING COUNT(*) > 1
    ) AS duplicated_active_enrollments;

    SELECT status, recorded_amount
    INTO v_status_1001, v_amount_1001
    FROM course_project.enrollments
    WHERE id = 1001;

    SELECT status, recorded_amount
    INTO v_status_1004, v_amount_1004
    FROM course_project.enrollments
    WHERE id = 1004;

    SELECT status, recorded_amount
    INTO v_status_1005, v_amount_1005
    FROM course_project.enrollments
    WHERE id = 1005;

    IF v_student_count <> 3
       OR v_instructor_count <> 2
       OR v_course_count <> 3
       OR v_enrollment_count <> 5
       OR v_total_recorded_amount <> 590000
       OR v_avg_recorded_amount <> 118000.00
       OR v_requested_count <> 2
       OR v_learning_count <> 1
       OR v_completed_count <> 1
       OR v_cancelled_count <> 1
       OR v_active_count <> 3
       OR v_active_recorded_amount <> 340000
       OR v_non_cancelled_count <> 4
       OR v_non_cancelled_recorded_amount <> 440000
       OR v_orphan_student_count <> 0
       OR v_orphan_course_count <> 0
       OR v_orphan_instructor_count <> 0
       OR v_active_duplicate_count <> 0
       OR v_status_1001 IS DISTINCT FROM '완료'
       OR v_amount_1001 IS DISTINCT FROM 100000::numeric
       OR v_status_1004 IS DISTINCT FROM '취소'
       OR v_amount_1004 IS DISTINCT FROM 150000::numeric
       OR v_status_1005 IS DISTINCT FROM '신청'
       OR v_amount_1005 IS DISTINCT FROM 120000::numeric THEN
        RAISE EXCEPTION
            '실행 중단: Chapter 07 기준 상태와 다릅니다. rows=%/%/%/%, total=% avg=%, status=%/%/%/%, active=%/%, non_cancelled=%/%, orphan=%/%/%, active_duplicate=%, 1001=%/%, 1004=%/%, 1005=%/%',
            v_student_count,
            v_instructor_count,
            v_course_count,
            v_enrollment_count,
            v_total_recorded_amount,
            v_avg_recorded_amount,
            v_requested_count,
            v_learning_count,
            v_completed_count,
            v_cancelled_count,
            v_active_count,
            v_active_recorded_amount,
            v_non_cancelled_count,
            v_non_cancelled_recorded_amount,
            v_orphan_student_count,
            v_orphan_course_count,
            v_orphan_instructor_count,
            v_active_duplicate_count,
            v_status_1001,
            v_amount_1001,
            v_status_1004,
            v_amount_1004,
            v_status_1005,
            v_amount_1005;
    END IF;

    RAISE NOTICE 'Chapter 08 prerequisite check passed';
END
$$;

SELECT id, student_id, course_id, status, recorded_amount
FROM course_project.enrollments
ORDER BY id;

SELECT
    COUNT(*) AS enrollment_count,
    SUM(recorded_amount) AS total_recorded_amount,
    ROUND(AVG(recorded_amount), 2) AS avg_recorded_amount,
    COUNT(*) FILTER (WHERE status = '신청') AS requested_count,
    COUNT(*) FILTER (WHERE status = '수강중') AS learning_count,
    COUNT(*) FILTER (WHERE status IN ('신청', '수강중')) AS active_enrollment_count,
    SUM(recorded_amount) FILTER (WHERE status IN ('신청', '수강중')) AS active_recorded_amount,
    COUNT(*) FILTER (WHERE status = '완료') AS completed_count,
    COUNT(*) FILTER (WHERE status = '취소') AS cancelled_count,
    COUNT(*) FILTER (WHERE status <> '취소') AS non_cancelled_count,
    SUM(recorded_amount) FILTER (WHERE status <> '취소') AS non_cancelled_recorded_amount
FROM course_project.enrollments;