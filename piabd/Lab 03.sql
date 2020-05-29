-----------------
-- Uprawnienia --
-----------------

-- Podmiot zabezpiecze� (ang. security principal)
-- Przedmiot zabezpiecze� (ang. securable)
-- Wszystkie polecenia mo�na utworzy� za pomoc� narz�dzia SSMS i za pommoc� tego narz�dzia sprawdza� przypisane upranienia (warto z tego narz�dzia korzysta�)
-- Uwaga: Login na poziomie instancji SQL Server zawiera has�o. Natomiast, ka�da baza danych ma swoich uzytkownik�w na poziomie ka�dej z baz.
	-- Login jest mapowany w kazdej bazie danych na konkretne konto bazy danych 
	-- (je�li takiego konta nie ma to mapowany jest jako u�ytkownik Guest z odpowiednimi uprawnieniami chyba, �e konto to jest wy��czone)


-- Tworzymy baz� TEST i dwie tabel� Categories i Products
CREATE DATABASE TEST;
GO
select * into test.dbo.categories from Northwind.dbo.Categories
select * into test.dbo.products from Northwind.dbo.Products

-- Tworzymy nowe konto na poziomie serwera o nazwie admin (pr�bujemy si� zalogowa�)
-- aby to si� uda�o musimy zdefiniowa� domy�ln� baz� danych dla danego konta logowania (default MASTER)
-- je�li damy baz� TEST jako default to niestety system nie pozwoli nam na zalogowanie bo nie mampy uprawnie� do bazy TEST
CREATE LOGIN [admin] WITH PASSWORD='admin', DEFAULT_DATABASE=[master], 
	DEFAULT_LANGUAGE=[polski], CHECK_EXPIRATION=OFF, CHECK_POLICY=OFF;
GO

-- Sprawdzamy co widzimy w SSMS (w Object Explorer mo�emy wykona� dodatkowe po��czenie za pomoc� CONNECT podaj�c powy�sze konto
-- Nast�pnie kasujemy to konto
-- Je�li s� k�opoty to w pasku jest ikonka Activity Monitor, gdzie mo�emy zamkn�� dane po��czenie dla u�ytkownika admin (Kill Process)
DROP LOGIN [admin]
GO
-- Jeszcze raz definiujemy dane konto generuj�c kod za pomoc� SSMS (Security | Logins | pod prawym przyciskiem myszy mamy New Logins ...)
CREATE LOGIN [admin] WITH PASSWORD='admin', DEFAULT_DATABASE=[Test], 
	DEFAULT_LANGUAGE=[polski], CHECK_EXPIRATION=OFF, CHECK_POLICY=OFF;
-- Tutaj niestety nie jeste�my wstanie zalogowa� si� do bazy Test.

-- Sprawdzamy czy konto GUEST jest w��czone (na poziomie bazy danych TEST)
-- standardowo uprawnienie connect jest wy��czone i je�li w��czymy to uprawnienie to mo�emy wej�� do danej bazy danych 
-- z racji uprawnie� u�ytkownika GUEST oraz uprawnie� roli PUBLIC (konto u�ytkownika bazy GUEST jest typu "SQL user without login")
USE TEST
GO
REVOKE CONNECT TO [guest] -- polecenie do wy��czenia konta Guest (ikonka w SSMS pokazuje ikonk� z przekre�lonym czerwonym krzy�ykiem)
-- Miejsce sprawdzenia (Databases | Test | Security | Users)
GO
GRANT CONNECT TO [guest]  -- admin widzi struktur� bazy ale bez obiekt�w (sprawdzamy)
GO
GRANT SELECT ON categories TO public -- admin widzi tak�e obiekt Categories (sprawdzamy)
GO
REVOKE SELECT ON categories TO public -- wracamy do stanu poprzedniego (sprawdzamy)


---------------------------------------------------
-- Zapisujemy u�ytkownika admin do roli sysadmin --
-- i sprawdzamy co widzi w bazie TEST, Northwind --
---------------------------------------------------
ALTER SERVER ROLE [sysadmin] ADD MEMBER [admin] -- (sprawdzamy)
-- wypisujemy go z roli sysadmin
ALTER SERVER ROLE [sysadmin] DROP MEMBER [admin]

-- sprawdzamy jakie s� role serwera i jakie maj� uprawnienia
EXEC sp_srvrolepermission		        -- ogl�danie wszystkich praw
EXEC sp_srvrolepermission 'dbcreator'	-- ogl�danie szczeg�owych praw

ALTER SERVER ROLE [dbcreator] ADD MEMBER [admin] --sprawdzi� czy mo�e za�o�y� i usun�� swoj� baz� danych np. Test1
--wracamy do poprzedniego stanu wcze�niej kasujac baz� Test1
ALTER SERVER ROLE [dbcreator] DROP MEMBER [admin]


----------------------------------------------------------------------------------------------------------------------------
-- Zamiast za ka�dym razem pod��cza� si� do serwera w okienku Object Explorer mo�emy wykorzysta� polecenie execute as ... --
----------------------------------------------------------------------------------------------------------------------------
USE TEST
GRANT CONNECT TO [guest]
GO
use Test  -- po wykonaniu polecenia EXECUTE AS LOGIN ... a przed wykonaniem polecenia REVERT musimy znajdowa� si� w tej samej bazie danych
print Suser_Sname();
print user_name();

execute as login='admin'; -- tym poleceniem podszywamy si� pod konto 'admin' (mo�na u�y� te� polecenie EXECUTE AS USER ... dla u�ytkownika bazy danych a nie instancji)
print Suser_Sname(); -- konto na poziomie instancji
print user_name();   -- konto na poziomie bazy danych
revert; -- tym poleceniem wracamy do u�ytkownika sa, kt�ry ma prawo IMPERSONATE aby podszy� si� pod czyje� konto bez logowania

GO
-- wracamy do standardowych ustawie� dla go�cia (wy��czamy to konto)
USE TEST
REVOKE CONNECT TO [guest]  


---------------------------------------------
-- Prawa szczeg�owe na poziomie instancji --
---------------------------------------------
use master
GRANT CREATE ANY DATABASE to admin
-- i sprawdzamy uprawnienia graficznie Instancja|Properties|Permmisions
-- lub SECURITY|LOGINS|admin|Properties|Securables
use master
print Suser_Sname();
execute as login='admin';
print Suser_Sname();
create database Test2; 
drop database Test2;
revert;
-- wracamy do poprzedniego stanu i zabieramy uprawnienia do instancji
REVOKE CREATE ANY DATABASE to admin;

---------------------------------------
-- Tworzenie w�asnej roli serwerowej --
---------------------------------------
USE [master]
GO
CREATE SERVER ROLE [RolaSerwerowa1];
GO
GRANT CREATE ANY DATABASE TO [RolaSerwerowa1];
GO
ALTER SERVER ROLE [RolaSerwerowa1] ADD MEMBER [admin];
GO
-- i sprawdzamy czy admin potrafi utworzy� i skasowa� swoj� baz� danych
execute as login='admin';
print Suser_Sname();
create database Test2; 
drop database Test2;
revert;

-- Sprawdzamy nazw� u�ytkownik�w serwera
select * from sys.syslogins;

------------------------------------------------
-- Na poziomie serwera i kont logowania LOGIN --
------------------------------------------------
-- wy��czamy konto logowania i jako admin nie mo�emy si� logowa� do instancji SQL Server 
ALTER LOGIN [admin] DISABLE
GO
-- w��czamy konto logowania
ALTER LOGIN [admin] ENABLE
GO

-- Brak uprawnie� do logowania do serwera
DENY CONNECT SQL TO [admin]
GO
-- W��czenie uprawnie� do logowania do serwera
GRANT  CONNECT SQL TO [admin]
GO

--------------------------------------------------------------------------------------------
-- Definiujemy u�ytkownika [Test] 
-- w bazie Test dopisujemy u�ytkownika bazy, tak�e o nazwie [test] (sa ma przypisany w bazach u�ytkownika dbo) 
-- (nazwa nie musi by� taka sama jak login) na podstawie loginu [test]
-- Tym samym dodajemy u�ytkownika do konkretnej bazy danych (z prawem CONNECT standardowo)
-- i wtedy nie ma ju� uprawnie� zwi�zanych z u�ytkownikiem GUEST tylko z rol� PUBLIC
USE MASTER
CREATE LOGIN [test] WITH PASSWORD='test', DEFAULT_DATABASE=[Test], 
	DEFAULT_LANGUAGE=[polski], CHECK_EXPIRATION=OFF, CHECK_POLICY=OFF;

USE [TEST]
GO
CREATE USER [test] FOR LOGIN [test]
GO
ALTER USER [test] WITH DEFAULT_SCHEMA=[dbo]
GO
-- Sprawdzamy i dodajemy konkretne uprawnienia
use TEST
GRANT SELECT ON products to GUEST; -- to uprawnienie dzia�a je�li jest w��czony GUEST i nie mamy przypisanego �adnego konta
GRANT SELECT ON categories to PUBLIC; -- to uprawnienie dzia�a zawsze

print Suser_Sname();
execute as login='test'; 
-- lub 
-- execute as user='test'
print Suser_Sname();
select * from products; -- nie dzia�a
select * from categories; -- dzia�a
revert;

-- Wracamy do uprawnie� poprzednich bez uprawnie� dla GUEST i PUBLIC 
-- (mo�na tak�e zablokowa� GUEST) i sprawdzamy j.w.
REVOKE SELECT ON products to GUEST; 
REVOKE SELECT ON categories to PUBLIC; 

-- 1. Przypisujemy uprawnienia SELECT, INSERT na tabeli Categories
USE TEST
GRANT SELECT, INSERT ON CATEGORIES to "test";
-- 2. Sprawdzamy czy dzia�aj� dane polecenia polecenie SELECT i INSERT na tabeli Categories
USE TEST
execute as login='test';
select count(*) from  categories;
insert into categories (CategoryName) values('Drinks');
select count(*) from  categories;
revert;
-- 3. Kasujemy dodany rekord (ewentualnie dodajemy uprawnienia)
USE TEST
GRANT DELETE ON CATEGORIES to "test";
execute as login='test';
select count(*) from  categories;
delete from categories where CategoryName = 'Drinks';
select count(*) from  categories;
revert;

-- Systemowe procedury sk�adowane do przegl�dania uprawnie�
exec sp_helpsrvrole
exec sp_srvrolepermission securityadmin
exec sp_srvrolepermission diskadmin
exec sp_srvrolepermission sysadmin

exec sp_helprole
exec sp_dbfixedrolepermission db_securityadmin 
exec sp_dbfixedrolepermission db_datawriter
exec sp_dbfixedrolepermission db_datareader

-- Przypisanie uprawnie� z opcj� WITH GRANT OPTION (admin b�dzie m�g� uzytkownikowi bazy danych test przypisa� dane uprawnienia) 
grant select, insert on dbo.categories to admin with grant option

-- 4. Przypisz u�ytkownikowi test powy�sze uprawnienia i sprawd� poprawno�� tych praw

grant select, insert on dbo.categories to "test" with grant option
execute as login='test';
USE TEST
GRANT SELECT, INSERT ON CATEGORIES to PUBLIC;
revert;


-- Zabieramy prawa przypisane z opcj� WITH GRANT OPTION
exec sp_helprotect 'dbo.categories', null, null -- mo�na te prawa sprawdzi� jako prawa efektywne w SSMS
revoke select, INSERT on dbo.categories from test cascade

-- Sprawdzanie r�nych uprawnie� procedur� sp_helprotect
exec sp_helprotect null, null, null, 's'
exec sp_helprotect null, 'test', null, 'o'
exec sp_helprotect null
exec sp_helprotect 'CREATE TABLE', [dbo]

------------------------------------------------------------------------------------------------
-- Przyk�ady -----------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------
-- Tworzymy trzy loginy u11, u21 i u31 z takimi samymi nazwami u�ytkownik�w w bazie Northiwnd --
------------------------------------------------------------------------------------------------
USE [master]
CREATE LOGIN [u11] WITH PASSWORD=N'u11', DEFAULT_DATABASE=[Northwind], CHECK_EXPIRATION=OFF, CHECK_POLICY=OFF
CREATE LOGIN [u21] WITH PASSWORD=N'u21', DEFAULT_DATABASE=[Northwind], CHECK_EXPIRATION=OFF, CHECK_POLICY=OFF
CREATE LOGIN [u31] WITH PASSWORD=N'u31', DEFAULT_DATABASE=[Northwind], CHECK_EXPIRATION=OFF, CHECK_POLICY=OFF
GO
USE [Northwind]
CREATE USER [u11] FOR LOGIN [u11];
GO
CREATE SCHEMA [u11] AUTHORIZATION [u11];
GO
ALTER USER [u11] WITH DEFAULT_SCHEMA=[u11];
GO
CREATE USER [u21] FOR LOGIN [u21]
GO
CREATE SCHEMA [u21] AUTHORIZATION [u21];
GO
ALTER USER [u21] WITH DEFAULT_SCHEMA=[u21]
GO
CREATE USER [u31] FOR LOGIN [u31]
GO
CREATE SCHEMA [u31] AUTHORIZATION [u31];
GO
ALTER USER [u31] WITH DEFAULT_SCHEMA=[u31]
GO
--------------------------------------------------------------------------------
-- I. Prawo CREATE TABLE nadajemy u�ytkownikowi u31
GRANT CREATE TABLE TO u31; -- prawo do tworzenia tabeli na bazie Northwind
exec sp_helprotect 'CREATE TABLE', 'u31', NULL, s   --dla konkretnej bazy danych
GO
-- II. Prawo CREATE PROCEDURE nadajemy u�ytkownikowi u21
GRANT create proc to u21;
exec sp_helprotect 'CREATE PROCEDURE', 'u21', null, s --dla konkretnej bazy danych
GO
-- III. U�ytkownik bazy Northwind u11 bez praw
  --uprawnienia systemowe dla wszystkich user'�w w danej bazie 
exec sp_helprotect NULL, NULL, null, s
GO
--------------------------------------------------------------------------------
-- IV. Jako u31 tworzy tabel� customer1 w schemacie u31
execute as login='u31';
create table u31.customer1 (CustomerName varchar(20));
insert into u31.customer1 values ('Cust1'),('Cust2'),('Cust3'); --doda� kilka rekord�w
select * from u31.customer1 --wy�wietli� dane
--create table dbo.customer1 (CustomerName varchar(20)); --nie mo�e w innym schemacie tworzy� tabel

exec sp_helprotect NULL, 'u31', NULL, s  --sprawdzenie uprawnie� dla danego user'a
SELECT * FROM fn_my_permissions (NULL, 'DATABASE');--sprawdzenie upranie� na poziomie bazy danych
revert; --pami�tajmy o tym poleceniu
---------------------------------------------------------------------------------
-- V. U�ytkownik bazy danych u21 ma dost�p select tylko do tabeli, kt�r� utworzy u31 (i to on ma nada� to uprawnienie)
execute as login='u31';
grant select on u31.customer1 to u21
revert
  --Tworzymy procedur�
execute as login='u21';
SELECT * FROM fn_my_permissions ('u31.customer1', 'OBJECT');
exec sp_helprotect customer1, null, null, 'o'
exec sp_helprotect NULL, null, null, 's'
go
create proc u21.customer_proc with execute as caller
as begin select * from u31.customer1; end;
go
exec u21.customer_proc; --u2 potrafi wykona� t� procedur�
revert
-----------------------------------------------------------------------------------
-- VI. U�ytkownik u11 ma uprawnienia do wykonywania procedury utworzonej przez u21 (i to on ma nada� to uprawnienie)
execute as login='u21';
grant execute on u21.customer_proc to u11
revert
  --wykonyjemy procedur�
execute as login='u11';
select * from u31.Customer1 --brakuje uprawnie�
exec u21.customer_proc; --brakuje uprawnie�
revert
--Modyfikujemy jako u21 procedur�, aby by�a wywo�ywana z prawami w�a�ciciela
execute as login='u21';
go
alter proc u21.customer_proc with execute as owner  
as begin select * from u31.customer1; end;
go
revert
--Sprawdzamy jako u11 czy mamy prawo wykonywania danej procedury
execute as login='u11';
go
select * from u31.Customer1 --brakuje uprawnie�
go
exec u21.customer_proc; --jest ok
go
revert
--lub musimy nada� uprawnienia do wszystkich obiekt�w (czyli do customer1 jako u31 dla u11)
execute as login='u31';
GRANT SELECT on u31.customer1 TO u11
revert
--wracamy z procedur� jako wykonywana z prawami wywo�uj�cego
execute as login='u21';
go
alter proc u21.customer_proc with execute as caller  
as begin select * from u31.customer1; end;
go
revert
--Sprawdzamy jako u11 czy mamy prawo wykonywania danej procedury
execute as login='u11';
select * from u31.Customer1 --jest ok
exec u21.customer_proc; --jest ok
revert

--------------------------------------------------------------------------------
-- co z procedur�, gdy obiekty s� w tym samym schemacie i mamy jako u11 prawo --
-- tylko wywo�ania procedury ---------------------------------------------------
--------------------------------------------------------------------------------
-- jako sa
go
create proc dbo.customer_proc with execute as caller --oboj�tnie
as begin select * from dbo.Customers; end;
go
grant exec on dbo.customer_proc to u11;
go
-------
execute as login='u11';
select * from dbo.Customers --brakuje uprawnie�
exec dbo.customer_proc; --ok
revert
-- co z widokiem
-- jako sa
go
create view dbo.view_1 as select * from dbo.Customers;
go
create view u31.view_1 as select * from dbo.Customers;
go
grant select on dbo.view_1 to u11 --jako sa dali�my prawo do widoku dbo.view_1
grant select on u31.view_1 to u11 --jako sa dali�my prawo do widoku u31.view_1

--sprawdzamy dla u�ytkownika u11
execute as login='u11';
select * from dbo.Customers --brakuje uprawnie�
select * from dbo.View_1    --Ok (obiekty w tym samym schematacie)
select * from u31.View_1    --brakuje uprawnie� (obiekty w r�nych schematach)
revert

-- co zrobi� aby u31.view_1 wykona� si� poprawnie 
-- (doda� uprawnienie SELECT do tabeli dbo.customers dla u11) 
go

grant select on dbo.customers to u11;
----------------------------------------------------------------
-- Uwaga na niebezpieczny kod (np. polecenie delete products) --
----------------------------------------------------------------

create PROCEDURE a1 
	@p1 varchar(50)
AS
BEGIN
	execute (@p1)
END
GO
exec dbo.a1 'select * from customers';

--------------
-- SYNONIMY --
--------------
USE [Northwind]
/****** Object:  Synonym [dbo].[emp] ******/
CREATE SYNONYM [dbo].[emp] FOR [Northwind].[dbo].[Employees]
GO
GRANT SELECT ON [dbo].[emp] TO [u31]
GO

-- logujemy si� jako u31
execute as login='u31';
select * from dbo.employees  --brak prawa
select * from dbo.emp;  --OK
revert;
------------------------------------------------------------------------

---------------------
--ROLE U�YTKOWNIKA --
---------------------

-- 5. Utw�rz dwie role R1 oraz R2

USE [Northwind]
GO
CREATE ROLE [R1] AUTHORIZATION [dbo];
GO
CREATE ROLE [R2] AUTHORIZATION [dbo];
GO


-- 6. Roli R1 przypisa� prawa SELECT, INSERT dla tabeli EMPLOYEES
USE [Northwind]
GO
GRANT SELECT, INSERT ON dbo.EMPLOYEES TO [R1];
GO
-- 7. Roli R2 przypisa� prawa SELECT, INSERT, UPDATE, DELETE dla tabeli ORDERS z opcj� WITH GRANT OPTION oraz zabieramy prawo DENY do polecenia INSERT dla tabeli EMPLOYEES

USE [Northwind]
GO
GRANT SELECT, INSERT,UPDATE,DELETE ON dbo.ORDERS TO [R2] WITH GRANT OPTION;
GO
DENY INSERT on dbo.EMPLOYEES to [R2];
GO

-- 8. U�ytkownika u31 zapisujemy do roli R1 i sprawdzamy czy ma mo�liwo�� wykonywania polecenia SELECT, INSERT oraz DELETE na tabeli EMPLOYEES.
	-- Nast�pnie sprawdzamy czy mo�emy wykona� select na tabeli ORDERS.

ALTER ROLE [R1] ADD MEMBER [u31];
GO

execute as login='u31';
select * from dbo.employees
revert;

execute as login='u31';
insert into dbo.employees(LastName,FirstName) values ( 'Jan','Jan');
revert;

execute as login='u31';
delete from dbo.employees where LastName='Jan';  -- b��d poniewa� nie nadali�my uprawnie�
revert;

execute as login='u31';
select * from dbo.orders
revert;

-- 9. Zapisujemy uzytkownika u31 do roli R2 i sprawdzamy powy�sze uprawnienia.

ALTER ROLE [R2] ADD MEMBER [u31];
GO

execute as login='u31';
select * from dbo.employees
revert;

execute as login='u31';
insert into dbo.employees(LastName,FirstName) values ( 'Jan','Jan');
revert;

execute as login='u31';
delete from dbo.employees where LastName='Jan';  -- b��d poniewa� nie nadali�my uprawnie�
revert;

execute as login='u31';
select * from dbo.orders
revert;

--10. Do roli DENYDATAREADER dodajemy rol� R2 i sprawdzamy uprawnienia (odwrotnie nie da rady)

USE [Northwind]
GO
ALTER ROLE [db_denydatareader] ADD MEMBER [R2]
GO

execute as login='u31';
select * from dbo.employees  --The SELECT permission was denied...
revert;

execute as login='u31';
insert into dbo.employees(LastName,FirstName) values ( 'Jan','Jan'); --The INSERT permission was denied ..
revert;

execute as login='u31';
delete from dbo.employees where LastName='Jan';  -- The DELETE permission was denied...
revert;

execute as login='u31';
select * from dbo.orders -- The SELECT permission was denied...
revert;

--11. Wypisujemy rol� R2 z roli DENYDATAREADER i wracamy do poprzeniego stanu z pkt.4;

-- przycisk Remove w Databases -> Northwind -> Security ->Roles ->Database Roles -> db_denydatareader properties

--12. Jako u31 dodajemy uprawnienie SELECT dla tabeli ORDERS dla uzytkownika u21, tak�e z prawami WITH GRANT OPTION 
	-- nie dzia�a mimo, �e jeste�my zapisani do roli R2 to musimy przypisa� bezpo�rednio uprawnienia jako sa
grant select on northwind.dbo.Orders to u31 with grant option  --jako sa
execute as login='u31';
grant select on northwind.dbo.Orders to u21 with grant option
select * from Orders
revert;

--13. Sprawdzamy czy jako u21 mamy prawo wykonywania tego zapytania i dodatkowo dajemy uprawnienia SELECT dla u�ytkownika u11
execute as login='u21';
grant select on northwind.dbo.Orders to u11
select * from Orders
revert;
--sprawdzamy u11
execute as login='u11';
select * from Orders
revert;
--Je�li jako user31 chcieliby�my wy��czy� CASCADE OPTION to polecenie wygl�da nast�puj�co
revoke select on northwind.dbo.Orders to u21 cascade AS [u31]

--14. Jako 'sa' zabieramy prawo GRANT OPTION i sprawdzamy czy 'u21' i 'u11' maj� dalej uprawnienia przypisane przez uzytkownika 'u31'.
REVOKE GRANT OPTION FOR SELECT ON [dbo].[Orders] TO [u31] CASCADE AS [dbo] -- cofamy tylko opcj� GRANT OPTION (musi by� cascade)
--tylko u31 wykona instrukcj� select * from orders
revoke select on northwind.dbo.Orders to u31 cascade AS [dbo] -- cofamy uprawnienie SELECT
--tylko u31 wykona t� instrukcj�, gdy� nale�y do grupy R2, pozostali u�ytkownicy nie wykonaj� instrukcji: select * from orders
----------------------------------------------------------------------------------------------------------------------------------


-- przyk�adowe polecenia do wykorzystania w powy�szych przyk�adach 
grant select on northwind.dbo.Orders to u31 with grant option as dbo

execute as login='u31';
SELECT * FROM fn_my_permissions ('dbo.orders', 'OBJECT'); --uprawnienia
grant select on northwind.dbo.Orders to u21 with grant option
select * from Orders
revert;

execute as login='u21';
grant select on northwind.dbo.Orders to user11
select * from Orders
revert;

execute as login='u11';
select * from Orders
revert;

