-- Chapter 08. JOIN 쿼리
-- 실행 전 Chapter 07의 01→02→03→04 파일과
-- Chapter 08의 00_check_course_project.sql을 실행합니다.
-- 이 파일은 데이터를 변경하지 않습니다.

SELECT current_database();
SELECT current_schema();
SHOW search_path;

-- 1. INNER JOIN: 신청 한 건을 한 행으로 조회
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

-- 2. 다중 JOIN: recorded_amount는 신청 시 기록 금액입니다.
SELECT
    e.id AS enrollment_id,
    s.name AS student_name,
    c.title AS course_title,
    i.name AS instructor_name,
    e.status,
    e.recorded_amount,
    e.enrolled_at
FROM course_project.enrollments AS e
JOIN course_project.students AS s
    ON e.student_id = s.id
JOIN course_project.courses AS c
    ON e.course_id = c.id
JOIN course_project.instructors AS i
    ON c.instructor_id = i.id
ORDER BY e.id;

-- 3. LEFT JOIN: 모든 학생 유지 + 취소 제외 신청만 연결
SELECT
    s.id AS student_id,
    s.name AS student_name,
    e.id AS enrollment_id,
    e.status
FROM course_project.students AS s
LEFT JOIN course_project.enrollments AS e
    ON s.id = e.student_id
   AND e.status <> '취소'
ORDER BY s.id, e.id;

-- 4. ON 조건: 0건 학생도 유지
SELECT
    s.id,
    s.name,
    COUNT(e.id) AS non_cancelled_count
FROM course_project.students AS s
LEFT JOIN course_project.enrollments AS e
    ON s.id = e.student_id
   AND e.status <> '취소'
GROUP BY s.id, s.name
ORDER BY s.id;

-- 5. WHERE 조건: 취소 제외 신청이 없는 학생은 제거됨
SELECT
    s.id,
    s.name,
    COUNT(e.id) AS non_cancelled_count
FROM course_project.students AS s
LEFT JOIN course_project.enrollments AS e
    ON s.id = e.student_id
WHERE e.status <> '취소'
GROUP BY s.id, s.name
ORDER BY s.id;

-- 6. LEFT JOIN + IS NULL: 취소 제외 신청이 없는 학생
SELECT
    s.id,
    s.name,
    s.email
FROM course_project.students AS s
LEFT JOIN course_project.enrollments AS e
    ON s.id = e.student_id
   AND e.status <> '취소'
WHERE e.id IS NULL;

-- 7. NOT EXISTS: 같은 질문을 다른 방식으로 표현
SELECT
    s.id,
    s.name,
    s.email
FROM course_project.students AS s
WHERE NOT EXISTS (
    SELECT 1
    FROM course_project.enrollments AS e
    WHERE e.student_id = s.id
      AND e.status <> '취소'
);

-- 8. 강의 기준 LEFT JOIN: 취소 제외 신청이 없는 강의도 유지
SELECT
    c.id,
    c.title,
    COUNT(e.id) AS non_cancelled_count
FROM course_project.courses AS c
LEFT JOIN course_project.enrollments AS e
    ON c.id = e.course_id
   AND e.status <> '취소'
GROUP BY c.id, c.title
ORDER BY c.id;