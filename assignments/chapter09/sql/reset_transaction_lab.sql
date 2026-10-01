-- Chapter 09. transaction_lab 초기화
-- 주의: transaction_lab 스키마와 실습 데이터만 삭제합니다.
-- course_project 스키마와 Chapter 07·08 데이터는 변경하지 않습니다.
-- 처음부터 다시 시작해야 할 때만 실행합니다.

SELECT current_database();
SELECT current_schema();
SHOW search_path;

BEGIN;

DO $$
BEGIN
    IF current_database() <> 'ai_database_book' THEN
        RAISE EXCEPTION
            '초기화 중단: 현재 데이터베이스는 %입니다. ai_database_book에 연결하세요.',
            current_database();
    END IF;

    IF to_regclass('course_project.students') IS NULL
       OR to_regclass('course_project.instructors') IS NULL
       OR to_regclass('course_project.courses') IS NULL
       OR to_regclass('course_project.enrollments') IS NULL THEN
        RAISE EXCEPTION
            '초기화 중단: 보호해야 할 course_project 기준 테이블을 확인하세요.';
    END IF;
END
$$;

DROP TABLE IF EXISTS transaction_lab.payments;
DROP TABLE IF EXISTS transaction_lab.enrollments;
DROP TABLE IF EXISTS transaction_lab.course_inventory;
DROP SCHEMA IF EXISTS transaction_lab;

DO $$
BEGIN
    IF to_regnamespace('transaction_lab') IS NOT NULL THEN
        RAISE EXCEPTION
            '초기화 검증 실패: transaction_lab 스키마가 남아 있습니다.';
    END IF;

    IF (SELECT COUNT(*) FROM course_project.students) <> 3
       OR (SELECT COUNT(*) FROM course_project.instructors) <> 2
       OR (SELECT COUNT(*) FROM course_project.courses) <> 3
       OR (SELECT COUNT(*) FROM course_project.enrollments) <> 5
       OR (SELECT SUM(recorded_amount) FROM course_project.enrollments) <> 590000 THEN
        RAISE EXCEPTION
            '초기화 검증 실패: course_project 기준 데이터가 변경되었습니다.';
    END IF;
END
$$;

COMMIT;

SELECT 'Chapter 09 transaction lab reset passed' AS validation_result;

-- 삭제 후 실행 순서:
-- 1. 01_transaction_lab_schema.sql
-- 2. 02_transaction_lab_seed.sql
-- 3. 03_commit_transaction.sql
-- 4. 04_rollback_transaction.sql
-- 5. 05_commit_and_sold_out.sql
-- 6. 06_transaction_validation.sql
-- 7. 07~09 파일은 선택 실습
