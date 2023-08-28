-- COMP3311 20T3 Assignment 2

-- Q1: students who've studied many courses
create or replace view q1helper(unswid, student_name, cid, num_courses) as 
select p.unswid, p.name, c.student, count(*) from People p join 
Course_enrolments c on (p.id = c.student) group by p.unswid, p.name, 
c.student having count(*) > 65; 

create or replace view Q1(unswid, name)
as select unswid, student_name as name from q1helper;


-- Q2: numbers of students, staff and both

create or replace view num_only_students(id) as (select id from Students) 
except (select id from Staff); 

create or replace view num_only_staff(id) as (select id from Staff) 
except (select id from Students);

create or replace view num_both_students_and_staff(id) as 
(select id from Students) intersect (select id from Staff);

create or replace view Q2(nstudents,nstaff,nboth) 
as select nstudents,nstaff, nboth from (select count(*) as 
nstudents from num_only_students) as num_students , 
(select count(*) as nstaff from num_only_staff) as num_staff, 
(select count(*) as nboth from num_both_students_and_staff) as num_both;


-- Q3: prolific Course Convenor(s)
create or replace view Get_id_Course_Convenor(id) as select id from 
Staff_roles where name = 'Course Convenor';

create or replace view staff_course_num(staff, num_courses) as 
select staff, count(*) from Course_staff where role = 
(select * from Get_id_Course_Convenor) group by staff ;

create or replace view max_courses(max_teach) as 
select max(num_courses) from staff_course_num;

create or replace view Q3(name ,ncourses)
as select p.name, s.num_courses from People p join staff_course_num 
s on (p.id = s.staff) where num_courses = (select * from max_courses);

-- Q4: Comp Sci students in 05s2 and 17s1
create or replace view Get_term_ida(id) as select id from 
Terms where year = 2005 and session = 'S2';

create or replace view Get_program_ida(id) as select 
id from Programs where code = '3978';

create or replace view Q4a(id,name)
as select p.unswid, p.name from Program_enrolments e join People p on 
(e.student = p.id) where term = (select * from Get_term_ida) and 
program = (select * from Get_program_ida);

create or replace view Get_term_idb(id) as select id 
from Terms where year = 2017 and session = 'S1';

create or replace view Get_program_idb(id) as select id 
from Programs where code = '3778';

create or replace view Q4b(id,name)
as select p.unswid, p.name from Program_enrolments e join People p on 
(e.student = p.id) where term = (select * from Get_term_idb) 
and program = (select * from Get_program_idb);

-- Q5: most "committee"d faculty
create or replace view Get_org_id_faculuty_school(id) as 
select id from OrgUnits where utype in ('1', '2');

create or replace view num_commitee(faculty, ncommitee) as 
select facultyOf(id) as faculty,count(*) as ncommitee from OrgUnits 
where id in (select id from OrgUnits where utype = 9) and 
facultyOf(id) in (select * from Get_org_id_faculuty_school) 
group by faculty order by count(*) desc;

create or replace view max_commitee as 
select max(ncommitee) from num_commitee; 

create or replace view Q5(name)
as select o.name from OrgUnits o where id in 
(select faculty from num_commitee where 
ncommitee = (select * from max_commitee));

-- Q6: nameOf function

create or replace function
   Q6(id integer) returns text
as $$ 

select p.name from People p where p.id = $1 or p.unswid = $1;

$$ language sql;

-- Q7: offerings of a subject
create or replace function staff_name(id integer) returns text
as $$ select name from people where id = $1;
$$ language sql;

create or replace function Q7(_subject text) 
returns table (subject text, term text, convenor text)
as $$ 

select su.code::text, termname(t.id), p.name from 
Course_staff cf join courses c on (cf.course = c.id) join 
staff s on (cf.staff = s.id) join staff_roles sr on (cf.role = sr.id) join 
subjects su on (c.subject = su.id) join terms t on (c.term = t.id) join 
people p on (p.id = s.id) where su.code = $1 and sr.name = 'Course Convenor';

$$ language sql;


-- Q8: transcript

create or replace function
   program_code(program_id integer) returns char(4)
as $$ select code from programs where id = $1;
$$ language sql;

create or replace function
   Q8(_zid integer) returns setof TranscriptRecord
as $$
declare
    
    _studentid integer;
    transcript TranscriptRecord;
    student_rec record;
    program_id integer;
    UOCpassed integer := 0;
    totalUOCattempted integer := 0;
    weightedSumOfMarks float := 0;
    num_of_courses integer := 0;
    Wam_achieved numeric := 0.0;

begin
    
    -- Get the student id gor the student from th unswid
    select id from People into _studentid where unswid = $1;
    
    if (not found) then
        raise exception 'Invalid student %',_zid;
    end if;
    
    for student_rec in select s.code as code, c.term as term, 
    substr(s.name,1,20) as name, ce.mark as mark, ce.grade as grade, 
    s.uoc as uoc from Courses c join Course_enrolments ce on 
    (c.id = ce.course) join Subjects s on (s.id = c.subject) 
    where student = _studentid order by termname(c.term), name
    
    loop
        
        transcript.code := student_rec.code;
        transcript.term := termname(student_rec.term);
        
        select program into program_id from program_enrolments
        where term = student_rec.term and student = _studentid;
        
        transcript.prog := program_code(program_id); 
        transcript.name = student_rec.name;
        transcript.mark := student_rec.mark;
        transcript.grade := student_rec.grade;
        
        if (student_rec.grade in ('SY', 'PT', 'PC', 'PS', 'CR', 'DN', 
        'HD', 'A', 'B', 'C', 'XE', 'T', 'PE', 'RC', 'RS')) then
            transcript.uoc := student_rec.uoc;
            UOCpassed := UOCpassed + student_rec.uoc;
        
        else
            transcript.uoc := null; 
        end if;
        
        if (student_rec.grade not in ('SY', 'XE', 'T', 'PE')) then
            totalUOCattempted := totalUOCattempted + student_rec.uoc;
        end if;

        num_of_courses := num_of_courses + 1;
        
        if student_rec.mark is not null and student_rec.grade 
        is not null then
            weightedSumOfMarks := weightedSumOfMarks + 
            student_rec.mark*student_rec.uoc;
        end if;

        return next transcript;

    end loop;
    
    transcript.code := null;
    transcript.term := null;
    transcript.prog :=  null; 
    
    if (num_of_courses = 0 or weightedSumOfMarks = 0 
    or weightedSumOfMarks = null) then 
        
        transcript.name := 'No WAM available';
        transcript.mark := null;
        transcript.grade := null;
        transcript.uoc := null;
    
    else
        transcript.name := 'Overall WAM/UOC';
        Wam_achieved := weightedSumOfMarks::numeric/totalUOCattempted;
        transcript.mark := round(Wam_achieved);
        transcript.grade := null;
        transcript.uoc := UOCpassed;
    
    end if;
    return next transcript;

end

$$ language plpgsql;

-- Q9: members of academic object group
create or replace function
   remove_characters(Group_definition TextString) returns text
as $$ 

declare
    
    removed_semicolon text;
    removed_comma text;
    remove_forward_brackets text;
    removed_all text;

begin

    select replace(Group_Definition, ',', ' ') into removed_comma;
    select replace(removed_comma, ';', ' ') into removed_semicolon;
    select replace(removed_semicolon, '{', '') into remove_forward_brackets;
    select replace(remove_forward_brackets, '}', '') into removed_all;
    return removed_all;

end

$$ language plpgsql;

create or replace function
Get_child_and_parent_id(group_id integer) returns setof integer
as $$ 

(select id from acad_object_groups where id = $1) union 
(select id from acad_object_groups where parent = $1);

$$ language sql;

create or replace function
subject_enumerated_codes(Group_id integer) returns setof AcObjRecord
as $$

    select 'subject' as objtype, s.code::text as objcode 
    from subjects s join Subject_group_members sgm on 
    s.id = sgm.subject where sgm.ao_group in 
    (select * from Get_child_and_parent_id(Group_id));

$$ language sql;

create or replace function
stream_enumerated_codes(Group_id integer) returns setof AcObjRecord
as $$

    select 'stream' as objtype, s.code::text as objcode 
    from streams s join Stream_group_members sgm on 
    s.id = sgm.stream where sgm.ao_group in 
    (select * from Get_child_and_parent_id(Group_id));

$$ language sql;

create or replace function
program_enumerated_codes(Group_id integer) returns setof AcObjRecord
as $$

    select 'program' as objtype, p.code::text as objcode 
    from programs p join program_group_members pgm on 
    p.id = pgm.program where pgm.ao_group in 
    (select * from Get_child_and_parent_id(Group_id));

$$ language sql;

    

create or replace function
    Q9a(_gid integer) returns setof AcObjRecord
    as $$

declare
    
    Group_type AcadObjectGroupType;
    Group_Definition_Type AcadObjectGroupDefType;
    Real_definition_group TextString;
    definition_splitted text;
    pattern_code text;
    code_needed text;
    check_Fequals record;
    check_Free record;
    check_GEN record;
    set_of_pattern text;
    pattern_single AcObjRecord;
    enum_result text;

begin

    select gtype, gdefby, definition into Group_type, 
    Group_Definition_Type, Real_definition_group from 
    acad_object_groups where id = _gid;
        
    if (not found) then
        raise exception 'NO such group %', _gid;
    end if;

    
    if (Group_Definition_Type = 'enumerated') then
        
        -- if (Group_type = 'subject') then 

        --     return QUERY select * from subject_enumerated_codes(_gid);


        -- elsif (Group_type = 'program') then 
            
        --     return QUERY select * from program_enumerated_codes(_gid);
        
        -- elsif (Group_type = 'stream') then
            
        --     return QUERY select * from stream_enumerated_codes(_gid);

        -- end if;
        enum_result := 'select ''' || quote_ident(Group_type) ||  ''' as objtype, g.code::text as objcode from ' || quote_ident(Group_type) || 's g join ' 
        || quote_ident(Group_type) || '_group_members gm on g.id = gm.' 
        || quote_ident(Group_type) || ' where gm.ao_group in (select * from Get_child_and_parent_id(' || quote_literal(_gid) || '))';
        
        return QUERY execute enum_result;

    end if;
    
    if Group_Definition_Type = 'pattern' then
        
        select * from remove_characters(Real_definition_group) 
        into definition_splitted;

        for code_needed in select 
            regexp_split_to_table(definition_splitted, '\s+')
        
        loop
            
            select regexp_matches(code_needed, 'F=') into check_Fequals;
            select regexp_matches(code_needed, 'FREE') into check_Free;
            select regexp_matches(code_needed, 'GEN') into check_GEN;

            if check_Fequals is null and check_Free is null and
            check_GEN is null then
                
                if strpos (code_needed, '#') > 0 or 
                   strpos (code_needed, '[') > 0 or 
                   strpos (code_needed, '(') > 0 then
                    
                    select replace(code_needed, '#', '.') 
                    into code_needed;
                    
                    -- if (Group_type = 'subject') then 

                    --     return QUERY select 'subject' as objtype, 
                    --     code::text as objcode from subjects 
                    --     where code ~* code_needed::text;
                
                    -- elsif (Group_type = 'program') then 
                        
                    --     return QUERY select 'program' as objtype, 
                    --     code::text as objcode from programs 
                    --     where code ~* code_needed::text;
                    
                    -- elsif (Group_type = 'stream') then
                        
                    --     return QUERY select 'stream' as objtype, 
                    --     code::text as objcode from streams 
                    --     where code ~* code_needed::text;

                    -- end if;
                    set_of_pattern := 'select ''' || quote_ident(Group_type) ||  ''' as objtype, code::text as objcode from ' 
                    || quote_ident(Group_type) || 's where code ~* ' || quote_literal(code_needed::text); 

                    return QUERY execute set_of_pattern;
                    
                else 
                    pattern_single.objtype = Group_type::text;
                    pattern_single.objcode = code_needed;
                    return next pattern_single;

                end if;

            end if;
                
        end loop;
    
    end if;

end

$$ language plpgsql;

create or replace function 
    Q9(_gid integer) returns setof AcObjRecord
as $$

begin 
    
    return QUERY select DISTINCT ON(2) objtype, 
    objcode from Q9a(_gid);

end

$$ language plpgsql;

-- Q10: follow-on courses

create or replace function
   Q10a(code text) returns setof text
as $$

declare
    
    definition_check record;
    check_code_exists record;
    acad_id integer;

begin

    for definition_check in select id, 
    definition from acad_object_groups

    loop
        
        select regexp_match(definition_check.definition::text, $1) 
        into check_code_exists;
        
        if check_code_exists is not null then
            
            acad_id := definition_check.id;
            return query select s.code::text from subjects s 
            join subject_prereqs sp on (s.id = sp.subject) 
            join rules r on (sp.rule = r.id) join 
            acad_object_groups aog on (r.ao_group = aog.id) 
            where aog.id = acad_id and r.type = 'RQ';

        end if;

    end loop;

end

$$ language plpgsql;

create or replace function
   Q10(code text) returns setof text
as $$

begin 
    return QUERY select distinct * from q10a(code);
end

$$ language plpgsql;
