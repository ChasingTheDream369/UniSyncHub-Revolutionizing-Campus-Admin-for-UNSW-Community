-- select $1 as subject, term, convenor from (select substring(t.year::text,3,4) || '' || LOWER(t.session) as term from Terms where id in (select term from course_term_id)) as needed_terms, 
-- (select name as convenor from people where id in (select * from staff_id)) as staff_names;

-- create or replace function
--    Q7(subject text)
--      returns table (subject text, term text, convenor text)
-- as $$ with subject_id as (select id, code from Subjects where code = $1), 
-- course_term_id as (select id, term from Courses where subject = (select id from subject_id)), 
-- staff_id as (select staff from Course_staff where course in (select id from course_term_id) and role in ( select * from Get_id_Course_Convenor))
-- SELECT s.code::text, substring(t.year::text,3,4) || '' || LOWER(t.session), p.name FROM Subjects as s 
-- JOIN Courses as c ON s.id = c.subject JOIN Terms as t ON c.term = t.id 
-- JOIN Course_staff u on u.course = c.id JOIN Staff as f on f.id = u.staff 
-- JOIN people as p on p.id = u.staff where s.code = $1 and s.id in (select id from subject_id) and t.id in (select term from course_term_id) and p.id in (select * from staff_id) ;
-- $$ language sql;

-- create or replace function
--    Q7(_subject text)
--      returns table (subject text, term text, convenor text)
-- as $$ SELECT s.code::text, substring(t.year::text,3,4) || '' || LOWER(t.session), p.name FROM Subjects as s 
-- JOIN Courses as c ON s.id = c.subject JOIN Terms as t ON c.term = t.id 
-- JOIN Course_staff u on u.course = c.id JOIN Staff as f on f.id = u.staff 
-- JOIN people as p on p.id = u.staff where s.code = $1 and s.id in (select id from subject_id) and t.id in (select term from course_term_id) and p.id in (select * from staff_id) ;
-- $$ language sql;
--select su.code,termname(t.id),p.name from Course_staff cf join courses c on (cf.course = c.id) join staff s on (cf.staff = s.id) join staff_roles sr on (cf.role = sr.id) join subjects su on (c.subject = su.id) join terms t on (c.term = t.id) join people p on (p.id = s.id) where su.code = 'COMP3311';

-- create or replace view student_records(code, term, name, mark, grade, uoc) as 
-- select s.code as code, c.term as term, substr(s.name,1,20) as name,
-- ce.mark as mark, ce.grade as grade, s.uoc as uoc from Courses c join Course_enrolments 
-- ce on (c.id = ce.course) join Subjects s on (s.id = c.subject) where student = _studentid;

--create or replace view num_subjects_studied(sub_studied) as select count(*) from student_records;