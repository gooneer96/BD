-- TRIGGER
--1
CREATE or REPLACE TRIGGER lab04zad1
BEFORE INSERT OR UPDATE on HR.EMPLOYEES
FOR EACH ROW
ENABLE
BEGIN
:NEW.last_name:=UPPER(:NEW.last_name);
:NEW.first_name:=UPPER(:NEW.first_name);
END;
/

DELETE  FROM EMPLOYEES where employee_ID=208;

INSERT INTO EMPLOYEES(EMPLOYEE_ID,FIRST_NAME,LAST_NAME,EMAIL,PHONE_NUMBER,HIRE_DATE,JOB_ID,SALARY,COMMISSION_PCT,MANAGER_ID,DEPARTMENT_ID)
VALUES(208,'Janek','kOWALski','dsa@dsa.pl','500100200',SYSDATE,'IT_PROG',8000,null,null,null);

select * from EMPLOYEES where EMPLOYEE_ID=208;

ALTER TRIGGER lab04zad1 DISABLE;
/
-- 2
CREATE SEQUENCE HR.EMPLOYEES_INC maxvalue 999999 increment by 1 start with 210;

CREATE or REPLACE TRIGGER lab04zad2
BEFORE INSERT on HR.EMPLOYEES
FOR EACH ROW
ENABLE
BEGIN
    if :new.EMPLOYEE_ID is NULL then
       :new.EMPLOYEE_ID  := EMPLOYEES_INC.NEXTVAL;
    END IF;
END;
/
INSERT INTO EMPLOYEES(FIRST_NAME,LAST_NAME,EMAIL,PHONE_NUMBER,HIRE_DATE,JOB_ID,SALARY,COMMISSION_PCT,MANAGER_ID,DEPARTMENT_ID)
VALUES('Janek','kOWALski','dsad@dsa.pl','500100200',SYSDATE,'IT_PROG',8000,null,null,null);
select * from EMPLOYEES;

DROP SEQUENCE EMPLOYEES_INC;
/
ALTER TRIGGER lab04zad2 DISABLE;
/
--3 

CREATE OR REPLACE TRIGGER lab04zad3
BEFORE INSERT or UPDATE on HR.EMPLOYEES
FOR EACH ROW
ENABLE
BEGIN
    if SYSDATE-:new.HIRE_DATE<=10 AND SYSDATE -:new.HIRE_DATE>=-10 then
        RAISE_APPLICATION_ERROR(-20000, 'Actual date difference with HIRE DATE can not be more than +- 10 days');       
    END IF;
END;
/
INSERT INTO EMPLOYEES(EMPLOYEE_ID,FIRST_NAME,LAST_NAME,EMAIL,PHONE_NUMBER,HIRE_DATE,JOB_ID,SALARY,COMMISSION_PCT,MANAGER_ID,DEPARTMENT_ID)
VALUES(209,'Janek','kOWALski','dsed@dsa.pl','500100200',SYSDATE,'IT_PROG',8000,null,null,null);

ALTER TRIGGER lab04zad3 DISABLE;
/
-- 4
CREATE OR REPLACE TRIGGER lab04zad4
AFTER INSERT or UPDATE or DELETE on HR.EMPLOYEES
FOR EACH ROW
ENABLE
BEGIN
IF INSERTING THEN
    dbms_output.put_line(:NEW.FIRST_NAME || ' ' || :NEW.LAST_NAME);
END IF;
IF UPDATING THEN
    dbms_output.put_line('OLD NAME:' || :OLD.FIRST_NAME || ' ' || :OLD.LAST_NAME);
    dbms_output.put_line('NEW NAME' || :NEW.FIRST_NAME || ' ' || :NEW.LAST_NAME);
END IF;
IF DELETING THEN
    dbms_output.put_line(:OLD.FIRST_NAME || ' ' || :OLD.LAST_NAME);
END IF;
END;
/
INSERT INTO EMPLOYEES(EMPLOYEE_ID,FIRST_NAME,LAST_NAME,EMAIL,PHONE_NUMBER,HIRE_DATE,JOB_ID,SALARY,COMMISSION_PCT,MANAGER_ID,DEPARTMENT_ID)
VALUES(209,'Janek','kOWALski','dsed@dsa.pl','500100200',SYSDATE,'IT_PROG',8000,null,null,null);

DELETE FROM EMPLOYEES where EMPLOYEE_ID=209;
DBMS_OUTPUT.ENABLE;

ALTER TRIGGER lab04zad4 DISABLE;
/
--5
CREATE TABLE EMP_HIST
(
  ID INT GENERATED ALWAYS AS IDENTITY NOT NULL
,EMPLOYEE_ID NUMBER(6,0), 
	FIRST_NAME VARCHAR2(20 BYTE), 
	LAST_NAME VARCHAR2(25 BYTE) NOT NULL ENABLE, 
	EMAIL VARCHAR2(25 BYTE) NOT NULL ENABLE, 
	PHONE_NUMBER VARCHAR2(20 BYTE), 
	HIRE_DATE DATE NOT NULL ENABLE, 
	JOB_ID VARCHAR2(10 BYTE)  NOT NULL ENABLE, 
	SALARY NUMBER(8,2), 
	COMMISSION_PCT NUMBER(2,2), 
	MANAGER_ID NUMBER(6,0), 
	DEPARTMENT_ID NUMBER(4,0)
, DATA_CZAS_OPERACJI DATE
, typ_operacji VARCHAR2(20)
, CONSTRAINT EMP_HIST_PK PRIMARY KEY
  (
    ID
  ) 
  ENABLE
);
/
CREATE OR REPLACE TRIGGER lab04zad5
AFTER UPDATE OR DELETE on EMPLOYEES
FOR EACH ROW
BEGIN
IF UPDATING THEN
INSERT INTO EMP_HIST(EMPLOYEE_ID,FIRST_NAME,LAST_NAME,EMAIL,PHONE_NUMBER,HIRE_DATE,JOB_ID,SALARY,COMMISSION_PCT,MANAGER_ID,DEPARTMENT_ID,DATA_CZAS_OPERACJI,TYP_OPERACJI)
VALUES(:NEW.EMPLOYEE_ID,:NEW.FIRST_NAME,:NEW.LAST_NAME,:NEW.EMAIL,:NEW.PHONE_NUMBER,:NEW.HIRE_DATE,:NEW.JOB_ID,:NEW.SALARY,:NEW.COMMISSION_PCT,:NEW.MANAGER_ID,:NEW.DEPARTMENT_ID,SYSDATE,'UPDATE');
END IF;
IF DELETING THEN
INSERT INTO EMP_HIST(EMPLOYEE_ID,FIRST_NAME,LAST_NAME,EMAIL,PHONE_NUMBER,HIRE_DATE,JOB_ID,SALARY,COMMISSION_PCT,MANAGER_ID,DEPARTMENT_ID,DATA_CZAS_OPERACJI,TYP_OPERACJI)
VALUES(:OLD.EMPLOYEE_ID,:OLD.FIRST_NAME,:OLD.LAST_NAME,:OLD.EMAIL,:OLD.PHONE_NUMBER,:OLD.HIRE_DATE,:OLD.JOB_ID,:OLD.SALARY,:OLD.COMMISSION_PCT,:OLD.MANAGER_ID,:OLD.DEPARTMENT_ID,SYSDATE,'DELETE');
END IF;
END;
/
UPDATE EMPLOYEES set MANAGER_ID=200 where EMPLOYEE_ID=208;
DELETE FROM EMPLOYEES where EMPLOYEE_ID=208;
select * from EMP_HIST;

DROP TABLE EMP_HIST;
/
ALTER TRIGGER lab04zad5 DISABLE;
/
--6
CREATE VIEW TASK_6
AS
SELECT e.FIRST_NAME,e.LAST_NAME,e.email,e.PHONE_NUMBER,e.HIRE_DATE,e.JOB_ID,e.SALARY,e.COMMISSION_PCT,e.MANAGER_ID,e.DEPARTMENT_ID,d.DEPARTMENT_NAME
FROM EMPLOYEES e LEFT JOIN DEPARTMENTS d
ON e.DEPARTMENT_ID=d.DEPARTMENT_ID;
/

CREATE OR REPLACE TRIGGER lab04zad6
INSTEAD OF INSERT ON TASK_6
FOR EACH ROW
BEGIN
IF (:NEW.DEPARTMENT_ID is NULL) then
INSERT INTO TASK_6(FIRST_NAME,LAST_NAME,EMAIL,PHONE_NUMBER,HIRE_DATE,JOB_ID,SALARY,COMMISSION_PCT,MANAGER_ID,DEPARTMENT_ID)
VALUES(:NEW.FIRST_NAME,:NEW.LAST_NAME,:NEW.EMAIL,:NEW.PHONE_NUMBER,:NEW.HIRE_DATE,:NEW.JOB_ID,:NEW.SALARY,:NEW.COMMISSION_PCT,:NEW.MANAGER_ID,NULL);
END IF;
END;
/

INSERT INTO EMPLOYEES(EMPLOYEE_ID,FIRST_NAME,LAST_NAME,EMAIL,PHONE_NUMBER,HIRE_DATE,JOB_ID,SALARY,COMMISSION_PCT,MANAGER_ID,DEPARTMENT_ID)
VALUES(208,'Janek','kOWALski','dsa@dsa.pl','500100200',SYSDATE,'IT_PROG',8000,null,null,20);

select * from task_6;


DROP VIEW TASK_6;
/
--7
CREATE OR REPLACE TRIGGER lab04zad7
BEFORE INSERT OR UPDATE on EMPLOYEES
FOR EACH ROW
WHEN (NEW.SALARY<0)
BEGIN
:NEW.SALARY :=1;
END;
/
-- ustawiane 1 zamiast 0 ze wzgledu na constraint emp_min_salary(salary>0) ustawienie na 0 nie pozwoli wstawic rekordu
INSERT INTO EMPLOYEES(EMPLOYEE_ID,FIRST_NAME,LAST_NAME,EMAIL,PHONE_NUMBER,HIRE_DATE,JOB_ID,SALARY,COMMISSION_PCT,MANAGER_ID,DEPARTMENT_ID)
VALUES(209,'Janek','kOWALski','dsd@dsa.pl','500100200',SYSDATE,'IT_PROG',-200,null,null,null);

ALTER TRIGGER lab04zad7 DISABLE;
/
--8

CREATE OR REPLACE TRIGGER lab04zad8
BEFORE UPDATE on DEPARTMENTS
FOR EACH ROW
WHEN (NEW.DEPARTMENT_ID<>OLD.DEPARTMENT_ID or (NEW.DEPARTMENT_ID is null and OLD.DEPARTMENT_ID is not null) or (NEW.DEPARTMENT_ID is not null and OLD.DEPARTMENT_ID is null))
BEGIN
UPDATE EMPLOYEES e set e.DEPARTMENT_ID= :NEW.DEPARTMENT_ID where e.DEPARTMENT_ID = :OLD.DEPARTMENT_ID;
UPDATE JOB_HISTORY  jh set jh.DEPARTMENT_ID= :NEW.DEPARTMENT_ID where jh.DEPARTMENT_ID = :OLD.DEPARTMENT_ID;
END;
/

UPDATE DEPARTMENTS SET DEPARTMENT_ID=101 where DEPARTMENT_ID=100;

select * from employees;

ALTER TRIGGER lab04zad8 DISABLE;
/

--9

CREATE TABLE REJESTR_ZMIAN
(
  ID INT GENERATED ALWAYS AS IDENTITY NOT NULL
, Nazwisko_pracownika VARCHAR2(25 BYTE) NOT NULL
, data DATE 
, pensja_stara NUMBER (8,2)
, pensja_nowa NUMBER (8,2)
, akcja varchar2(20)
, CONSTRAINT REJESTR_ZMIAN_PK PRIMARY KEY
  (
    ID
  ) 
  ENABLE
);
/
CREATE OR REPLACE TRIGGER lab04zad9
AFTER INSERT or UPDATE on EMPLOYEES
FOR EACH ROW
WHEN (OLD.JOB_ID<>'AD_PRES' or NEW.JOB_ID <>'AD_PRES')
BEGIN
if updating then
insert into REJESTR_ZMIAN(nazwisko_pracownika,data,pensja_stara,pensja_nowa,akcja)
VALUES(:OLD.LAST_NAME,SYSDATE,:OLD.SALARY,:NEW.SALARY,'Zmodyfikowano rekord');
    if :NEW.SALARY>(:OLD.SALARY +(:OLD.SALARY * 0.1)) then
        RAISE_APPLICATION_ERROR(-20001, 'Salary rise can not be more than 10%');       
    END IF;
end if;
if inserting then
insert into REJESTR_ZMIAN(nazwisko_pracownika,data,pensja_stara,pensja_nowa,akcja)
VALUES(:NEW.LAST_NAME,SYSDATE,NULL,:NEW.SALARY,'wstawiono_rekord');
end if;
END;
/

UPDATE EMPLOYEES SET SALARY=8700 where EMPLOYEE_ID=208;
INSERT INTO EMPLOYEES(EMPLOYEE_ID,FIRST_NAME,LAST_NAME,EMAIL,PHONE_NUMBER,HIRE_DATE,JOB_ID,SALARY,COMMISSION_PCT,MANAGER_ID,DEPARTMENT_ID)
VALUES(210,'Janek','kOWALski','dsdsa@dsa.pl','500100200',SYSDATE,'IT_PROG',6000,null,null,null);


select * from REJESTR_ZMIAN;


DROP TABLE REJESTR_ZMIAN;
/
ALTER TRIGGER lab04zad9 DISABLE;
/

--10
CREATE VIEW TASK_10
AS
SELECT e.FIRST_NAME,e.LAST_NAME,e.email,e.PHONE_NUMBER,e.HIRE_DATE,e.JOB_ID,e.SALARY,e.COMMISSION_PCT,e.MANAGER_ID,e.DEPARTMENT_ID,d.DEPARTMENT_NAME
FROM EMPLOYEES e LEFT JOIN DEPARTMENTS d
ON e.DEPARTMENT_ID=d.DEPARTMENT_ID;

/
CREATE OR REPLACE TRIGGER lab04zad10
INSTEAD OF INSERT OR UPDATE ON TASK_10
FOR EACH ROW
DECLARE
department_id_exist number := 0;
BEGIN
select count(*) into department_id_exist from departments where :NEW.DEPARTMENT_ID in ( select department_ID from departments);
IF (department_id_exist=0) then
INSERT INTO TASK_10(FIRST_NAME,LAST_NAME,EMAIL,PHONE_NUMBER,HIRE_DATE,JOB_ID,SALARY,COMMISSION_PCT,MANAGER_ID,DEPARTMENT_ID)
VALUES(:NEW.FIRST_NAME,:NEW.LAST_NAME,:NEW.EMAIL,:NEW.PHONE_NUMBER,:NEW.HIRE_DATE,:NEW.JOB_ID,:NEW.SALARY,:NEW.COMMISSION_PCT,:NEW.MANAGER_ID,NULL);
else
UPDATE EMPLOYEES set DEPARTMENT_ID=:NEW.DEPARTMENT_ID;
END IF;
END;
/


DELETE FROM EMPLOYEES where EMPLOYEE_ID=209;

INSERT INTO EMPLOYEES(EMPLOYEE_ID,FIRST_NAME,LAST_NAME,EMAIL,PHONE_NUMBER,HIRE_DATE,JOB_ID,SALARY,COMMISSION_PCT,MANAGER_ID,DEPARTMENT_ID)
VALUES(209,'Janek','kOWALski','dsed@dsa.pl','500100200',SYSDATE,'IT_PROG',8000,null,null,15);

select * from TASK_10;

DROP VIEW TASK_10;
/
-- 11

CREATE TABLE REJESTR_DEPT
(
ID INT GENERATED ALWAYS AS IDENTITY NOT NULL
, NAZWA_DEPARTAMENTU varchar2(40) not null
, data_wstawienia date
, CONSTRAINT REJESTR_DEPT_PK PRIMARY KEY
  (
    ID
  ) 
  ENABLE
);
/
CREATE OR REPLACE TRIGGER lab04zad11
BEFORE INSERT ON DEPARTMENTS
FOR EACH ROW
DECLARE
PRAGMA autonomous_transaction;
BEGIN
INSERT into REJESTR_DEPT(nazwa_departamentu, data_wstawienia)
VALUES(:NEW.DEPARTMENT_NAME,SYSDATE);
COMMIT;
END;
/

INSERT INTO DEPARTMENTS(DEPARTMENT_ID,DEPARTMENT_NAME,MANAGER_ID,LOCATION_ID)
VALUES(18,'test',200,1000);
COMMIT;


INSERT INTO DEPARTMENTS(DEPARTMENT_ID,DEPARTMENT_NAME,MANAGER_ID,LOCATION_ID)
VALUES(19,'test2',201,1000);
ROLLBACK;
select * from REJESTR_DEPT;
select * from DEPARTMENTS;

DROP TABLE REJESTR_DEPT;
/
ALTER TRIGGER lab04zad11 DISABLE;
/
-- 12
CREATE OR REPLACE TRIGGER lab04zad12
BEFORE INSERT ON DEPARTMENTS
FOR EACH ROW
DECLARE
department_name_exist number := 0;
BEGIN
select count(*) into department_name_exist from departments where department_name = :NEW.DEPARTMENT_NAME; 
IF (department_name_exist>0) then
RAISE_APPLICATION_ERROR( -20001,'There is already department named like this in database' );
END IF;
END;
/

INSERT INTO DEPARTMENTS(DEPARTMENT_ID,DEPARTMENT_NAME,MANAGER_ID,LOCATION_ID)
VALUES(28,'test',200,1000);

ALTER TRIGGER lab04zad12 DISABLE;
/
-- END TRIGGER --
-- PROCEDURE --
-- 1

CREATE OR REPLACE PROCEDURE lab04zad1
(e_id in VARCHAR2)
IS
f_name varchar2(30);
l_name varchar2(30);
sal number(8,2);
BEGIN
SELECT FIRST_NAME,LAST_NAME,SALARY into f_name,l_name,sal FROM EMPLOYEES where EMPLOYEE_ID=e_id;
dbms_output.put_line('First name: ' || f_name || ' || Last name: ' || l_name ||  ' || SALARY: ' || sal );
END;
/

EXEC lab04zad1(200);
dbms.output.enable;
/
--2

CREATE OR REPLACE PROCEDURE lab04zad2
IS
var int;
BEGIN
SELECT count(*) into var FROM EMPLOYEES;
dbms_output.put_line('All employees count : ' || var );
END;
/

EXEC lab04zad2;
dbms.output.enable;
/
--3
CREATE OR REPLACE PROCEDURE lab04zad3
IS
var int;
var2 int;
BEGIN
SELECT count(*) into var FROM DEPARTMENTS d where d.DEPARTMENT_ID in (select distinct e.DEPARTMENT_ID from EMPLOYEES e);
SELECT count(*) into var2 FROM DEPARTMENTS;
var2 := var2-var;
dbms_output.put_line('Departments without employees count : ' || var2 );
END;
/

EXEC lab04zad3;
dbms.output.enable;
/

--4
CREATE OR REPLACE PROCEDURE lab04zad4
(dept_id in int, var out int)
IS
BEGIN
SELECT count(*) into var FROM EMPLOYEES where DEPARTMENT_ID=dept_id;
dbms_output.put_line('employees in given department count : ' || var );
END;
/

DECLARE 
var int;
begin
lab04zad4(10,var);
end;
/
dbms.output.enable;
/
--5
CREATE OR REPLACE PROCEDURE lab04zad5
(dept_id in int,job_id in varchar2, var out int)
IS
BEGIN
SELECT count(*) into var FROM EMPLOYEES where DEPARTMENT_ID=dept_id and JOB_ID=job_id;
dbms_output.put_line('employees in given department on specified job count : ' || var );
END;
/

DECLARE 
var int;
begin
lab04zad5(60,'IT_PROG',var);
end;
/
dbms.output.enable;
/
--6
CREATE OR REPLACE PROCEDURE lab04zad6
(dept_id in int)
IS

BEGIN
dbms_output.put_line('employees in given department count : ');
FOR  var in (SELECT FIRST_NAME,LAST_NAME FROM EMPLOYEES where DEPARTMENT_ID=dept_id)
loop
dbms_output.put_line(' ' || var.FIRST_NAME || ' ' || var.LAST_NAME );
END LOOP;
END;
/


EXEC lab04zad6(60);
dbms.output.enable;
/
--7
CREATE OR REPLACE PROCEDURE lab04zad7
(mang_id in int, var out int)
IS
BEGIN
SELECT AVG(SALARY) into var FROM EMPLOYEES where MANAGER_ID=mang_id;
dbms_output.put_line('Average salary for given manager : ' || var );
END;
/

DECLARE 
var int;
begin
lab04zad7(100,var);
end;
/
dbms.output.enable;
/

-- END PROCEDURE --
-- FUNCTIONS--
--1
CREATE OR REPLACE FUNCTION cutSPACE(var in varchar2)
return varchar2
is
var_return varchar2(30);
begin
SELECT TRIM(BOTH ' ' from var) into var_return FROM DUAL;
return (var_return);
end cutSPACE;
/
select cutSpace('   kamikaze kamikaze  ') as CUT_SPACE from DUAL;
/
--2
CREATE OR REPLACE FUNCTION checkNumber(var in int)
return varchar2
is
begin
if( MOD(var,2)=0) then
return('EVEN');
else
return ('ODD');
end if;
end checkNumber;
/
select checkNumber(4) as Parity from DUAL;
/
--3
ALTER SESSION SET NLS_DATE_LANGUAGE = 'POLAND';

CREATE OR REPLACE FUNCTION dayCheck(var in date)
return varchar2
is
var1 varchar2(20);
begin
SELECT TO_CHAR(var,'DAY','NLS_DATE_LANGUAGE = POLISH') into var1 from dual;
return(var1);
end dayCheck;
/
select dayCheck('2020-04-13') as day from DUAL;
/
--4
CREATE OR REPLACE FUNCTION averageSalary
(dep_id in int)
return int
IS
var int;
BEGIN
SELECT AVG(SALARY) into var FROM EMPLOYEES where DEPARTMENT_ID=dep_id;
RETURN(var);
END averageSalary;

/
select averageSalary(60) as avgSalary from DUAL;
/
--5
CREATE OR REPLACE FUNCTION trojkat(a in binary_double,b in binary_double,c in binary_double)
return varchar2
IS
p binary_double;
o binary_double;
BEGIN
if(a+b>c AND a+c>b AND b+c>a) then
o:=(a+b+c)/2;
SELECT ROUND(SQRT(o*(o-a)*(o-b)*(o-c)),2) into p from dual;
return('Mozesz zbudowac trojkat, jego pole to: ' || p);
else
return('Z podanych bokow nie zbudujesz trojkata');
end if;
END trojkat;

/
select trojkat(3,4,5) as trojkat from DUAL;
/

--6
CREATE OR REPLACE FUNCTION switchSPACE(var in varchar2)
return varchar2
is
var_return varchar2(30);
begin
SELECT REPLACE(var,' ','_') into var_return FROM DUAL;
return (var_return);
end switchSPACE;
/
select switchSPACE('   kamikaze kamikaze  ') as CUT_SPACE from DUAL;
/
--7
CREATE OR REPLACE FUNCTION reverseString(var in varchar2)
return varchar2
is
var_return varchar2(30);
begin
SELECT REVERSE(var) into var_return FROM DUAL;
return (var_return);
end reverseString;
/
select reverseString('to bedzie tak') as rev from DUAL;
/
--8
CREATE OR REPLACE FUNCTION PESEL(var in char)
return varchar2
is
begin
if (LENGTH(VAR)<>9) then
return('Pesel powinien skladac sie z 9 znakow');
elsif not regexp_like(var,'[0-9]{9}') then
return ('Pesel sklada sie z niedozwolonych znakow');
else
return('Pesel poprawny');
end if;
end PESEL;
/
select PESEL('b234c678a') as peselCheckC,PESEL('1234') as peselCheckL,PESEL('123456789') as peselCheckV from DUAL;
/
--9
CREATE OR REPLACE FUNCTION checkN(var in int)
return varchar2
is
i int;
c int;
begin
c:=0;
for i in 2..var
LOOP
if(MOD(var,i)=0) then
 c :=c+1;
end if;
end LOOP;
if(c>1) then
return('Liczba nie jest pierwsza');
else
return ('Liczba jest pierwsza');
end if;
end checkN;
/
select checkN(2) as checkN from DUAL;
/
--10
CREATE OR REPLACE FUNCTION silnia(var in int)
return varchar2
is
lowerThan1 exception;
buff int;
i int;
begin
if(var<1) then
raise lowerThan1;
end if;
buff:=1;
for i in 1..var
LOOP
buff:=buff*i;
END LOOP;
return('Silnia podanej liczby calkowitej=' || buff);
exception
WHEN lowerThan1 then
return('Podales liczbe mniejsza niz 1');
WHEN OTHERS then
return('Nie podales liczby calkowitej lub wynik wykracza poza zakres typu danych int');
end silnia;
/
select silnia(-2) as silniaLowerThan1,silnia(4212412421421) as silniaMoreThanInt,silnia(5) as silniaProper from DUAL;
/
-- END FUNCTION--