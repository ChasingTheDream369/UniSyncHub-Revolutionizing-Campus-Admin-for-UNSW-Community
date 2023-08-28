-- COMP3311 20T3 Assignment 2

-- Q1: students who've studied many courses

-- Created a helper view which finds the id, name, student id, count
-- of the students who have done more than 65 courses.

create or replace view q1helper(unswid, student_name, cid, num_courses) 
as 
    select p.unswid, p.name, c.student, count(*) from People p
    join Course_enrolments c on (p.id = c.student) group by 
    p.unswid, p.name, c.student having count(*) > 65; 

-- For the desired output just select the unswid nad student_name
-- of the students meeting the condition from the helper view.

create or replace view Q1(unswid, name)
as 
    select unswid, student_name as name from q1helper;

-----##################################################-----

-- Q2: numbers of students, staff and both

--Created helper view to find the id's for only the 
-- student's.
create or replace view num_only_students(id) 
as
    (select id from Students) 
    except (select id from Staff); 

--Get all the staff id's except the student id's
create or replace view num_only_staff(id) 
as 
    (select id from Staff) 
    except (select id from Students);

-- Get the id's corresponding to both the staff and 
-- students.
create or replace view num_both_students_and_staff(id) 
as 
    (select id from Students) 
    intersect (select id from Staff);

-- Using the from clause now select the count of all the 
-- three different set of id's.
create or replace view Q2(nstudents,nstaff,nboth) 
as 
    select nstudents, nstaff, nboth from 
    (select count(*) as nstudents from num_only_students) as num_students, 
    (select count(*) as nstaff from num_only_staff) as num_staff, 
    (select count(*) as nboth from num_both_students_and_staff) 
    as num_both;

-----###################################################-----

-- Q3: prolific Course Convenor(s)

-- Helper view to find the staff id's which are 
-- Course Convenor's.
create or replace view Get_id_Course_Convenor(id) 
as 
    select id from Staff_roles where 
    name = 'Course Convenor';

-- Get the number of courses that every Course Convenor is 
-- teaching.
create or replace view staff_course_num(staff, num_courses) 
as 
    select staff, count(*) from Course_staff where role = 
    (select * from Get_id_Course_Convenor) group by staff;

-- Helper view to find the max number of courses taught by 
-- any course convenor.
create or replace view max_courses(max_teach) 
as 
    select max(num_courses) from staff_course_num;

-- Select the name of staff which teaches the maximum
-- number of courses(where the num_courses after grouping the staff is 
-- equal to the maximum number of courses taught by a staff.)
create or replace view Q3(name ,ncourses)
as 
    select p.name, s.num_courses from People p join 
    staff_course_num s on (p.id = s.staff) where 
    num_courses = (select * from max_courses);

-----###################################################-----

-- Q4a: Comp Sci students in 05s2, 3978

-- Helper view to find the term for id the desired 
-- session.
create or replace view Get_term_ida(id) 
as 
    select id from Terms where year = 2005 
    and session = 'S2';

-- Helper view to find the program id where 
-- code is '3978'
create or replace view Get_program_ida(id) 
as 
    select id from Programs where code = '3978';

-- Helper view to find the unswid and name of all the 
-- students enrolled in the course and the desired session. 
create or replace view Q4a(id,name)
as 
    select p.unswid, p.name from Program_enrolments e join 
    People p on (e.student = p.id) where term = 
    (select * from Get_term_ida) and program = 
    (select * from Get_program_ida);

-----###################################################-----

-- Q4b: Comp Sci students in 17s1, 3778. 

-- Helper view to find the term for id the desired 
-- session.
create or replace view Get_term_idb(id) 
as 
    select id from Terms where year = 2017 
    and session = 'S1';

-- Helper view to find the program id where 
-- code is '3778'.
create or replace view Get_program_idb(id) 
as 
    select id 
    from Programs where code = '3778';

-- Helper view to find the unswid and name of all the 
-- students enrolled in the course and the desired session.
create or replace view Q4b(id,name)
as 
    select p.unswid, p.name from Program_enrolments e 
    join People p on (e.student = p.id) where 
    term = (select * from Get_term_idb) and 
    program = (select * from Get_program_idb);

-----###################################################-----

-- Q5: most "committee"d faculty

-- Helper view to find the type id for the Faculty or
-- School orgunits.
create or replace view Get_faculty_school_typeid(id)
as
    select id from orgunit_types where name in ('Faculty', 'School');

-- Helper View to find the orgid's for all the 
-- faculties and schools.
create or replace view Get_org_id_faculty_school(id) 
as 
    select id from OrgUnits where utype in 
    (select * from Get_faculty_school_typeid);

-- Finds the type id of the committee type orgunits.
create or replace view Get_commitee_typeid(id)
as
    select id from orgunit_types where name = 'Committee';

-- Gets the count of each faculty which has a committee
-- type subfaculty, it uses facultyof funtion to find the 
-- faculty of all committee type objects and checks that the 
-- id returned by faculty of is a faculty type or school type.   
create or replace view num_committee(faculty, ncommittee) 
as 
    select facultyOf(id) as faculty, count(*) as ncommittee 
    from OrgUnits where id in (select id from OrgUnits 
    where utype in (select * from Get_commitee_typeid)) and 
    facultyOf(id) in (select * from Get_org_id_faculty_school) 
    group by faculty order by count(*) desc;

-- Get the maximum committees by a faculty.
create or replace view max_committee 
as 
    select max(ncommittee) from num_committee; 

-- Now get the name for the faculty where ncommitee is the 
-- maximum using both helper views above.
create or replace view Q5(name)
as 
    select o.name from OrgUnits o where id in 
    (select faculty from num_committee where 
    ncommittee = (select * from max_committee));

-----###################################################-----

-- Q6: nameOf function

-- Gets the name of the person where the id given 
-- matches in the People table. 
create or replace function
   Q6(id integer) returns text
as $$ 

    select p.name from People p where 
    p.id = $1 or p.unswid = $1;

$$ language sql;

-----###################################################-----

-- Q7: offerings of a subject

-- Gets the name of staff if a staff id is given
-- otherwise returns nothing.
create or replace function 
    staff_name(id integer) returns text
as $$ 

    select name from people where id = $1;

$$ language sql;

-- Retruns the subject code, termname using the termname fucnition
-- and name of the course convenor who is teaching the course just uses
-- a basic of all the tables which are required and retursn the result
-- using the subject id given
create or replace function 
    Q7(_subject text) returns table (subject text, term text, convenor text)
as $$ 

    select su.code::text, termname(t.id), p.name from 
    Course_staff cf join courses c on (cf.course = c.id) 
    join staff s on (cf.staff = s.id) join staff_roles sr 
    on (cf.role = sr.id) join subjects su on (c.subject = su.id)
    join terms t on (c.term = t.id) join people p on (p.id = s.id)
    where su.code = $1 and sr.name = 'Course Convenor';

$$ language sql;

-----###################################################-----

-- Q8: transcript

-- Returns the program code for the program id given.
create or replace function
   program_code(program_id integer) returns char(4)
as $$ 

    select code from programs where id = $1;

$$ language sql;

-- Returns the transcript for a zid given.
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
    
    -- Get the student id for the student where unswid matches the given id
    select id from People into _studentid where unswid = $1;
    
    if (not found) then
        raise exception 'Invalid student %',_zid;
    end if;
    
    -- Gets the set of records for the student using ,multiple joins and
    -- uses substr to create the cut hsort name of the subject.
    for student_rec in select s.code as code, c.term as term, 
        substr(s.name,1,20) as name, ce.mark as mark, ce.grade 
        as grade, s.uoc as uoc from Courses c join Course_enrolments
        ce on (c.id = ce.course) join Subjects s on (s.id = c.subject) 
        where student = _studentid order by termname(c.term), name
    
    loop
        
        -- looping through to the individula records and then 
        -- adding the individual results into the trasncript which has the
        -- same return type as desired.
        transcript.code := student_rec.code;
        transcript.term := termname(student_rec.term);
        
        -- Get the program id for the particular term for the 
        -- student
        select program into program_id from program_enrolments
        where term = student_rec.term and student = _studentid;
        
        -- converts the program to the program name using the
        -- helper function.
        transcript.prog := program_code(program_id); 
        transcript.name = student_rec.name;
        transcript.mark := student_rec.mark;
        transcript.grade := student_rec.grade;
        
        -- if the grade is in the following set then only show the uoc
        -- and then increment the UOCpasses for all these grades.
        if (student_rec.grade in ('SY', 'PT', 'PC', 'PS', 'CR', 'DN', 
        'HD', 'A', 'B', 'C', 'XE', 'T', 'PE', 'RC', 'RS')) then
            transcript.uoc := student_rec.uoc;
            UOCpassed := UOCpassed + student_rec.uoc;
        
        -- for any other grade set the uoc in the transcript to null
        else
            transcript.uoc := null;
        end if;
        
        -- if the grade is in ('SY', 'XE', 'T', 'PE') then dont add them
        -- to the totalUOCattempted as given in the spec.
        if (student_rec.grade not in ('SY', 'XE', 'T', 'PE')) then
            totalUOCattempted := totalUOCattempted + student_rec.uoc;
        end if;

        num_of_courses := num_of_courses + 1;
        
        -- find the weighted sum when the marks and grade are not null
        if student_rec.mark is not null and student_rec.grade 
        is not null then
            weightedSumOfMarks := weightedSumOfMarks + 
            student_rec.mark*student_rec.uoc;
        end if;

        return next transcript;

    end loop;
    
    -- after returning the entire transcript records create 
    -- the last record as (null, null, null) for code, term and 
    -- program.
    transcript.code := null;
    transcript.term := null;
    transcript.prog :=  null; 
    
    -- if the student has not studied any courses or if all 
    -- research courses(leading the weighted to null) have 
    -- been studied or if the student has done courses which 
    -- have no marks and have SY or any special grade leading
    -- to total sum to be 0 in all these cases NO WAM IS AVAILABLE.
    if (num_of_courses = 0 or weightedSumOfMarks = 0 
    or weightedSumOfMarks = null) then 
        
        transcript.name := 'No WAM available';
        transcript.mark := null;
        transcript.grade := null;
        transcript.uoc := null;
    
    -- otherwise WAM is available and is counted using the 
    -- formulae given in the spec.
    else
        transcript.name := 'Overall WAM/UOC';
        
        -- typecasting the Weighted sum to numeric type so that
        -- it also takes into account floating values
        Wam_achieved := weightedSumOfMarks::numeric/totalUOCattempted;
        
        -- the WAM calculated is then rounded off to the nearest 
        -- integer since the mark is integer type in the return type.
        transcript.mark := round(Wam_achieved);
        transcript.grade := null;
        transcript.uoc := UOCpassed;
    
    end if;
    return next transcript;

end

$$ language plpgsql;

-----###################################################-----

-- Q9: members of academic object group

-- Creates a useful helper funciton which removes all 
-- the tokens like ,;{} and replaces them with '' to create
-- the definition as a string that can be converted to a 
-- table with useful values for the pattern matching in the 
-- respective group_type tables.
create or replace function
   remove_characters(Group_definition TextString) returns text
as $$ 

declare
    
    removed_semicolon text;
    removed_comma text;
    remove_forward_brackets text;
    removed_all text;

begin
    
    -- replaces all ,;{} from the group definition and returns the 
    -- parsed string without any tokens.
    select replace(Group_Definition, ',', ' ') into removed_comma;
    select replace(removed_comma, ';', ' ') into removed_semicolon;
    select replace(removed_semicolon, '{', '') into remove_forward_brackets;
    select replace(remove_forward_brackets, '}', '') into removed_all;
    return removed_all;

end

$$ language plpgsql;

-- Useful helper functioin to find the id of the 
-- acad_object_group where group id is given which is 
-- unioned withe the acad_objects whose parent is the group id given
-- useful for finding the enumerated type objects matching. 
create or replace function
    Get_child_and_parent_id(group_id integer) returns setof integer
as $$ 

    (select id from acad_object_groups where id = $1) union 
    (select id from acad_object_groups where parent = $1);

$$ language sql;

-- Creates a fucnition which returns all the set of AConjRecord
-- according to the gid given and finds all the onjects related
-- based on the definition being enumerated or pattern.
-- (NOTE : This produces a list of the required results but also 
-- contains duplicates, so to remove the duplicates i define it as q9a
-- and remove all duplicates in q9 which returns the results 
-- without any duplicates)
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

    -- Generates a dynamic query when the type is 
    -- enumerated which just selects the group type as the 
    -- objtype and selects the code from the corresponding 
    -- group type table after joinig it with the group_memebers 
    -- table where ao_grouo in its group memebers table is 
    -- the corresponding acad_id + the acad_id of those items 
    -- whose parent is this which is generated by calling the helper 
    -- function created
    if (Group_Definition_Type = 'enumerated') then
    
        enum_result := 'select ''' || quote_ident(Group_type) ||  
        ''' as objtype, g.code::text as objcode from ' || 
        quote_ident(Group_type) || 's g join ' || quote_ident(Group_type) 
        || '_group_members gm on g.id = gm.' || quote_ident(Group_type) 
        || ' where gm.ao_group in (select * from Get_child_and_parent_id(' 
        || quote_literal(_gid) || '))';
        
        return QUERY execute enum_result;

    end if;
    
    if Group_Definition_Type = 'pattern' then
        
        -- calls the remove_characters helper function which 
        -- removes all the unrequired characters and creates 
        -- a string of all pattern definition.
        select * from remove_characters(Real_definition_group) 
        into definition_splitted;

        -- splits the text string created into table and now
        -- use individual table element to find the realted codes to 
        -- the pattern in the respective group_types's table. 
        for code_needed in select 
            regexp_split_to_table(definition_splitted, '\s+')
        
        loop
            
            -- neglecting any pattern with 'F=', 'FREE' and 'GEN' using 
            -- regexp_matches if in any pattern we find these code then
            -- regexp_matches would return an array showing the real code 
            -- where it matches it otherwise it will return null.
            select regexp_matches(code_needed, 'F=') into check_Fequals;
            select regexp_matches(code_needed, 'FREE') into check_Free;
            select regexp_matches(code_needed, 'GEN') into check_GEN;

            -- only consider those codes where regexp_matches returns null
            -- for all three cases.
            if check_Fequals is null and check_Free is null and
            check_GEN is null then
                
                -- checking if the pattern contains a #, [, (
                -- using strpos which will return an integer 
                -- reflecting the position at which the 
                -- desired character is present.
                if strpos (code_needed, '#') > 0 or 
                   strpos (code_needed, '[') > 0 or 
                   strpos (code_needed, '(') > 0 then
                    
                    -- replacing all # with . when a pattern with #
                    -- is found to create the required code for ~, 
                    -- as . is the equivalent of # for producing 
                    -- results using ~* .
                    select replace(code_needed, '#', '.') 
                    into code_needed;
                    
                    -- Creates and returns the result of a dynamic query 
                    -- which finds out all the codes relating to the current 
                    -- pattern using the ~ from the group_types table*. 
                    set_of_pattern := 'select ''' || quote_ident(Group_type)
                    ||  ''' as objtype, code::text as objcode from ' || 
                    quote_ident(Group_type) || 's where code ~* ' || 
                    quote_literal(code_needed::text); 

                    return QUERY execute set_of_pattern;

                -- if there is no #,(,[ in the pattern then just directly return the 
                -- code without checking that it exists in the table or not as stated
                -- in the spec.
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

-- Creates a function which takes all the result from 
-- q9a but removes the duplicate codes by applying 
-- DISTINCT ON(objcode).
create or replace function 
    Q9(_gid integer) returns setof AcObjRecord
as $$

begin 
    
    return QUERY select DISTINCT ON(2) objtype, 
    objcode from Q9a(_gid);

end

$$ language plpgsql;

-----###################################################-----

-- Q10: follow-on courses

--Returns a set of all course which have the given 
-- course code as its pre requisite.
-- (NOTE : This produces a list of the required results but also 
-- contains duplicates, so to remove the duplicates i define it as q10a
-- and remove all duplicates in q10 which returns the results 
-- without any duplicates)
create or replace function
   Q10a(code text) returns setof text
as $$

declare
    
    definition_check record;
    check_code_exists record;
    acad_id integer;

begin
    -- To find which courses have the given course
    -- as it's pre-req we jus use a basic fact that 
    -- if any subject has given subject as its pre-req it will appear in
    -- the definition of a acad_object, so we search for the course _code
    -- in the individual definitons and then find the acad_id which is joined to 
    -- rules->subject-pre_reqs_subjects->code. 
    for definition_check in select id, 
        definition from acad_object_groups

    loop
        -- check whether the current definiton contains the given course_code
        select regexp_match(definition_check.definition::text, $1) 
        into check_code_exists;
        
        -- if the reqexp_matches then it is not null that means the
        -- definiton has the code.
        if check_code_exists is not null then
            
            -- We get the acad_id if the code is present in the 
            -- definition and then run the query by joining the 
            -- associated tables to find the subject code which has this 
            -- aca d id showing that this subject has the given subject as
            -- it's pre-req.(subject->subject_Prereqs->rules(on type = 'RQ')
            -- ->acad_object_groups(linkage of the groups)).
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

-- Creates a function which takes all the result from 
-- q10a but removes the duplicate codes by selecting
-- distinct codes only which works by applying select
-- distinct * from the helper function.
create or replace function
   Q10(code text) returns setof text
as $$

begin 
    return QUERY select distinct * from q10a(code);
end

$$ language plpgsql;
