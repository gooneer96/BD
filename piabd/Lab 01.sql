-- Konfiguracja serwera baz danych na poziomie:
--   I. Instancji
--  II. Bazy danych
-- III. Sesji u�ytkownika

-- Wszystkie ustawienia szukamy w narz�dziu SSMS - SQL Server Management Studio
-- Je�li jest mo�liwo�� generujemy kod bezpo�rednio z SSMS. 

--------------------------------------------------------------------
-- I. Konfiguracja na poziomie instancji (polecenie sp_configure) --
--------------------------------------------------------------------
sp_configure   
-- lub przegl�danie opcji za pomoc� obiektu sys.configurations 
select * from sys.configurations

--Aby zobaczy� wszystkie ustawienia to nale�y w��czenia opcj� 'show advanced options'
EXEC sys.sp_configure 'show advanced options', 1  
GO
RECONFIGURE WITH OVERRIDE
GO

--01. Sprawdzi� mo�liwo�� wykonania polecenia xp_cmdshell 
--w��czy� t� opcj� i wykona� polecenie:  dir c:\

EXEC sys.sp_configure 'xp_cmdshell', 1  
GO
RECONFIGURE WITH OVERRIDE
GO

xp_cmdshell 'dir c:\'

--02. Ustawienie j�zyka standardowego przy zalogowaniu si� do bazy danych 
--za pomoc� SSMS dla danej instancji SQL Server|Properties|Advanced (tylko do prze�wiczenia)



-- Ustawiamy aktualny j�zyk na j�zyk Polski. 
-- Przy tworzeniu loginu SQL Server nie podaj�c konkretnego j�zyka ustwiony jest on na dany j�zyk 
-- okre�lony jako default
EXEC sys.sp_configure 'default language', '14'   
GO
RECONFIGURE WITH OVERRIDE
GO

--03. W��czenie wyzwalaczy zagnie�dzonych 'nested triggers' jeden wyzwalacz potrafi wykona� 
   -- instrukcj�, kt�ra wyzwoli inny wyzwalacz. 
   -- Na poziomie bazy danych mamy opcj� Recursive Triggers Enabled, 
   -- kt�ra mo�e by� w��czona lub wy��czona) 
   -- (sprawdzi� definiuj�c przyk�adow� struktur� z tabelami i wyzwalaczami dla wszystkich 4 kombinacji)

EXEC sys.sp_configure 'nested triggers', '0'   
GO
RECONFIGURE WITH OVERRIDE
GO

EXEC sys.sp_configure 'server trigger recursion', '0'   
GO
RECONFIGURE WITH OVERRIDE
GO

CREATE DATABASE Showroom
 
GO
 
Use Showroom
CREATE TABLE Car  
(  
   CarId int identity(1,1) primary key,  
   Name varchar(100),  
   Make varchar(100),  
   Model int ,  
   Price int ,  
   Type varchar(20)  
)  
 
insert into Car( Name, Make,  Model , Price, Type)
VALUES ('Corrolla','Toyota',2015, 20000,'Sedan'),
('Civic','Honda',2018, 25000,'Sedan'),
('Passo','Toyota',2012, 18000,'Hatchback'),
('Land Cruiser','Toyota',2017, 40000,'SUV'),
('Corrolla','Toyota',2011, 17000,'Sedan')
 
 
CREATE TABLE CarLog  
(  
   LogId int identity(1,1) primary key,
   CarId int , 
   CarName varchar(100),  
)


CREATE TRIGGER [dbo].[CAR_INSERT]
       ON [dbo].[Car]
AFTER INSERT
AS
BEGIN
       SET NOCOUNT ON;
 
       DECLARE @car_id INT, @car_name VARCHAR(50)
 
       SELECT @car_id = INSERTED.CarId,  @car_name = INSERTED.name       
       FROM INSERTED
 
  
 
       INSERT INTO CarLog
       VALUES(@car_id, @car_name)
END


CREATE TRIGGER [dbo].[CarLOG_INSERT] ON [dbo].[CarLog]
INSTEAD OF INSERT
AS
BEGIN
  IF @@NESTLEVEL = 1
    PRINT('DATA CANNOT BE INSERTED DIRECTLY IN CarLog TABLE')
  ELSE
    BEGIN
       DECLARE @car_id INT, @car_name VARCHAR(50)
 
       SELECT @car_id = INSERTED.CarId,  @car_name = INSERTED.CarName      
       FROM INSERTED
       INSERT INTO CarLog
       VALUES(@car_id, @car_name)
    END
    
END

EXEC sys.sp_configure 'nested triggers', '1'   
GO
RECONFIGURE WITH OVERRIDE
GO


INSERT INTO CarLog(  CarId , CarName)
VALUES (2, 'Civic')

insert into Car( Name, Make,  Model , Price, Type)
VALUES ('Clio','Renault',2012, 5000,'Sedan')

SELECT * FROM CarLog
SELECT * FROM Car

EXEC sys.sp_configure 'nested triggers', '0'   
GO
RECONFIGURE WITH OVERRIDE
GO

INSERT INTO CarLog(  CarId , CarName)
VALUES (2, 'Civic')

insert into Car( Name, Make,  Model , Price, Type)
VALUES ('Lancer','Mitsubishi',2010, 15000,'Sportback')

SELECT * FROM CarLog
SELECT * FROM Car


EXEC sys.sp_configure 'server trigger recursion', '1'   
GO
RECONFIGURE WITH OVERRIDE
GO

INSERT INTO CarLog(  CarId , CarName)
VALUES (2, 'Civic')

insert into Car( Name, Make,  Model , Price, Type)
VALUES ('Lancer','Mitsubishi',2010, 15000,'Sportback')

SELECT * FROM CarLog
SELECT * FROM Car

EXEC sys.sp_configure 'server trigger recursion', '0'   
GO
RECONFIGURE WITH OVERRIDE
GO

INSERT INTO CarLog(  CarId , CarName)
VALUES (2, 'Civic')

insert into Car( Name, Make,  Model , Price, Type)
VALUES ('Lancer','Mitsubishi',2010, 15000,'Sportback')

SELECT * FROM CarLog
SELECT * FROM Car

-- Ustawienie default connections option (podajemy warto�ci jako warto�ci konkretnych bit�w)
	--Pami�tajmy i� SSMS wykorzystuje swoje ustawienia dla po�acze�. 
	--Przyk�adowo chcemy ustawi�:
		--implicit transactions (1 bit) 2
		--quoted identifier (8 bit) 256
		--no count (9 bit) 512
EXEC sys.sp_configure 'user options', '770'
GO
RECONFIGURE WITH OVERRIDE
GO



---------------------------------------------
-- II. Konfiguracja na poziomie bazy danych --
---------------------------------------------
-- Wy�wietlanie informacji o ustawieniach bazy danych
-- https://docs.microsoft.com/en-us/sql/relational-databases/system-catalog-views/sys-databases-transact-sql?view=sql-server-ver15
SELECT * FROM sys.databases where name ='Northwind';

-- Wy�wietlanie informacji o ustawieniach bazy danych
-- do wersji SQL Server 2012 wykorzystujemy polecenie sp_dboption
-- https://docs.microsoft.com/en-us/sql/t-sql/functions/databasepropertyex-transact-sql?view=sql-server-ver15
SELECT DATABASEPROPERTYEX('Northwind', 'IsAutoShrink');

--04. Ustawienie konkretnych opcji dla konkretnej bazy danych
-- https://docs.microsoft.com/en-us/sql/t-sql/statements/alter-database-transact-sql?view=sql-server-ver15
ALTER DATABASE Northwind SET AUTO_SHRINK OFF; -- wy��czenie opcji
ALTER DATABASE Northwind SET AUTO_SHRINK ON; -- w��czenie opcji
--ustawienie bazy tylko do odczytu (sprawdzamy w SSMS za ka�dym razem ikonk� przy nazwie danej bazy danych)
ALTER DATABASE [Northwind] SET  READ_ONLY WITH NO_WAIT
--ustawienie bazy do pracy typu RESTRICTED_USER lub SINGLE_USER
ALTER DATABASE [Northwind] SET  RESTRICTED_USER WITH NO_WAIT
ALTER DATABASE [Northwind] SET  SINGLE_USER WITH NO_WAIT
ALTER DATABASE [Northwind] SET  MULTI_USER WITH NO_WAIT
--i przywr�cenie do normalnej pracy
ALTER DATABASE [Northwind] SET  READ_WRITE WITH NO_WAIT

------------------------------------------------------------------------------

--------------------------------------------------------------------
-- III. Konfiguracja na poziomie sesji u�ytkownika (polecenie SET) --
--------------------------------------------------------------------
--05. Sprawdzi� dzia�anie, ka�dego z ustawie�
SET IMPLICIT_TRANSACTIONS ON

insert into Northwind.dbo.Categories(categoryname) values ('DRINKS')
rollback

select * from Northwind.dbo.Categories

SET IMPLICIT_TRANSACTIONS OFF  -- wy��cza transakcje zatwierdzone automatycznie 

insert into Northwind.dbo.Categories(categoryname) values ('DRINKS')
rollback  -- The ROLLBACK TRANSACTION request has no corresponding BEGIN TRANSACTION. poniewa� wy��czyli�my opcje

select * from Northwind.dbo.Categories



SET QUOTED_IDENTIFIER ON

select * from Northwind.dbo.Categories where "CategoryName"='DRINKS'
SET QUOTED_IDENTIFIER OFF      -- podw�jne cudzys�owy

select * from Northwind.dbo.Categories where CategoryName="DRINKS"

SET NOCOUNT ON				-- po wykonaniu zapytania nie ma informacji o liczbie zwracanych rekord�w

select * from Northwind.dbo.Categories

SET NOCOUNT OFF                

select * from Northwind.dbo.Categories

--06. Sprawdzi� ustawienia SET oraz sposobu ich funkcjonowania dla dodatkowych wybranych 10 parametr�w
-- https://docs.microsoft.com/en-us/sql/t-sql/statements/set-statements-transact-sql?view=sql-server-ver15

SET DATEFIRST 7		-- niedziela

SELECT CAST('2020-4-26' AS datetime2) AS SelectDate  
    ,DATEPART(dw, '2020-4-26') AS DayOfWeek; -- 26 kwietnia to niedziela wi�c zgodnie z ustawieniem zwr�ci DayOfWeek jako 1

SET DATEFIRST 1		-- poniedzia�ek

SELECT CAST('2020-4-26' AS datetime2) AS SelectDate  
    ,DATEPART(dw, '2020-4-26') AS DayOfWeek; -- 26 kwietnia to niedziela wi�c zgodnie z ustawieniem zwr�ci DayOfWeek jako 7


SET LANGUAGE POLISH

select DATENAME(month,'2020-4-26') as MONTH -- domy�lnie ustawiony mia�em j�zyk angielski, wi�c przed wykonaniem set zwr�ci april, po wykonaniu set, zwr�ci kwiecie�

SET DATEFORMAT dmy;  
 
DECLARE @datevar datetime2 = '31/12/2008 09:01:01.1234567';  
SELECT @datevar;  


DECLARE @datevar2 datetime2 = '12/31/2008 09:01:01.1234567';	-- error, nale�a�oby ustawi� dat� w formacie mdy
SELECT @datevar2;

 
SET LOCK_TIMEOUT 0	-- przy wykryciu lock zwr�ci wiadomos�
SET LOCK_TIMEOUT -1	-- nigdy nie zwr�ci waidomo�ci

SET IDENTITY_INSERT NORTHWIND.dbo.Categories  ON  

insert into Northwind.dbo.Categories(CategoryID,CategoryName) values (9,'DRINKS') -- bez set, zwr�ci b��d o ustawieniu identity_insert jako off

select * from Northwind.dbo.Categories

SET ROWCOUNT 5

select * from Northwind.dbo.Categories -- zwr�ci 5 pierwszych rekord�w

SET SHOWPLAN_ALL ON

select * from Northwind.dbo.Categories

SET SHOWPLAN_ALL OFF

SET SHOWPLAN_TEXT ON

select * from Northwind.dbo.Categories

SET SHOWPLAN_TEXT OFF

SET STATISTICS PROFILE ON

select * from Northwind.dbo.Categories

SET STATISTICS PROFILE OFF

SET STATISTICS TIME ON 

select * from Northwind.dbo.Categories

SET STATISTICS TIME OFF


-----------------------------------------------------------------------------------
-- Sprawdzenie bazy systemowej Model jak dzia�a (dzia�a dla nowo utworznych baz) --
-----------------------------------------------------------------------------------
USE model;
create table model.dbo.x (a1 int,a2 varchar(20));
insert into model.dbo.x values (1,'a1'),(2,'a2'),(3,'a3');
-- Sprawdzamy w SSMS czy w bazie model jest dana tabela z danymi
select * from model.dbo.x;
-- Tworzymy w�asn� struktur�
create database test;
GO
USE test;
select * from test.dbo.x;
-- Czy�cimy baz� Model z tabeli x
drop table model.dbo.x;
-- Kasujemy baz� Test
USE MASTER;
GO
DROP DATABASE Test;
GO


------------------------------------------------------------------------------------------------
-- Jak dzia�aj� transakcje jawnie rozpoczynane, dzia�aj�ce na poleceniach DDL (ciekawostka) ----
-- Przy wycofaniu transakcji wycofujemy tak�e operacje DDL (w innych systeamach jest inaczej) --
------------------------------------------------------------------------------------------------
begin tran
	create table x (a1 int,a2 varchar(20));
	insert into x values (1,'a1'),(2,'a2'),(3,'a3');
	select * from x;
rollback tran;
--------------------------------------------------------------------------------------


