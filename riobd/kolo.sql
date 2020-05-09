CREATE TABLE EMPNEW as SELECT * FROM HR.EMPLOYEES;
CREATE TABLE DEPTNEW as SELECT * FROM HR.DEPARTMENTS;


select * from EMPNEW;
--1
ALTER TABLE EMPNEW 
    ADD CONSTRAINT EMPNEW_PK PRIMARY KEY
    (
    EMPLOYEE_ID
    );
    
ALTER TABLE DEPTNEW 
    ADD CONSTRAINT DEPTNEW_PK PRIMARY KEY
    (
    DEPARTMENT_ID
    );
ALTER TABLE EMPNEW
ADD CONSTRAINT EMPNEW_FK
    FOREIGN KEY (DEPARTMENT_ID)
    REFERENCES DEPTNEW(DEPARTMENT_ID)
    ON DELETE CASCADE;
    
--2

CREATE SEQUENCE COUNTER_EMP maxvalue 999999 increment by 1 start with 207;

CREATE or REPLACE TRIGGER AUTO_INC_EMP_ID
BEFORE INSERT on HR.EMPNEW
FOR EACH ROW
ENABLE
BEGIN
    if  :new.EMPLOYEE_ID is NULL then
        :new.EMPLOYEE_ID  := COUNTER_EMP.NEXTVAL;
    else
        :new.EMPLOYEE_ID  := COUNTER_EMP.NEXTVAL;
    END IF;
END;
/
--3
select d.DEPARTMENT_NAME, max(e.SALARY) as MAX_SALARY ,min(e.SALARY) as MIN_SALARY
from EMPLOYEES e
right join DEPARTMENTS d
ON e.DEPARTMENT_ID = d.DEPARTMENT_ID
GROUP BY d.DEPARTMENT_NAME;

--4
-- aby przetestowaæ obsluge dzielenia przez 0 nalezy zmodyfikowac select z sal , przykladowo tak:select salary into sal from EMPLOYEES where EMPLOYEE_ID=200;

DECLARE
sal number (10,0);
var number (10,0);
BEGIN
select salary into sal from EMPLOYEES where EMPLOYEE_ID=200;
var :=10/0;
EXCEPTION
when TOO_MANY_ROWS then
dbms_output.put_line('Zbyt du¿o danych');
ROLLBACK;
when ZERO_DIVIDE then
dbms_output.put_line('Error code: ' || SQLCODE || ', error message :' || SQLERRM);
end;
/

SELECT * FROM Employees WHERE first_name  BETWEEN 'A%' AND 'D%';

--5
CREATE OR REPLACE PROCEDURE emp_count
(job_titl in varchar2,employees_count out int)
IS
BEGIN
SELECT count(*) into employees_count FROM EMPLOYEES e LEFT JOIN JOBS j on e.JOB_ID=j.JOB_ID where j.JOB_TITLE=job_titl;
dbms_output.put_line('count of employees on specified job : ' || employees_count );
END;
/
declare
var int;
begin
emp_count('Programmer',var);
end;
/

--6

CREATE OR REPLACE FUNCTION checkNumber(var in DECIMAL)
return int
is
begin
if( var>0) then
return  1;
elsif (var=0) then
return 0;
else 
return -1;
end if;
end checkNumber;
/
select checkNumber(23131222.25) as checkNumberPositive,checkNumber(0) as checkNumberZero,checkNumber(-23131222.25) as checkNumberNegative from DUAL;
