---------------------------------------------------------------------------------
-- Wszystkie polecenia szukamy w narzędziu SSMS - SQL Server Management Studio --
-- Jeśli jest możliwość generujemy kod bezpośrednio z SSMS. ---------------------
---------------------------------------------------------------------------------

-- Proszę zwrócić uwagę na polecenia gdzie znajduje się ścieżka dostępu, 
-- każdy może mieć inną i mogą pojawić się błędy w tym miejscu
-- Można ścieżkę sprawdzić poleceniem i wstawić wynik w odpowiednie miejsce
-- lub zdefiniować skrypt, który zrobi to za nas:
SELECT SUBSTRING(filename, 1, CHARINDEX(N'master.mdf', LOWER(filename)) - 1)
FROM master.dbo.sysaltfiles WHERE dbid = 1 AND fileid = 1


---------------------------------------
-- Zarządzanie bazą danych i plikami --
---------------------------------------

-- Tworzymy bazę danych TEST.
-- Definiujemy nową grupę plików dane_hist, w której dołączamy dwa pliki hist01 oraz hist02, 
-- po 100MB każdy z rozrostem bazy danych o 50MB
-- Plik dziennika transakcji ustawiamy na wzrost wartości o 50MB 
-- (baza w trybie Recovery model jako FULL)  

USE master
GO
if exists (select * from sysdatabases where name='TEST')
		drop database TEST
go
create database TEST
Go
ALTER DATABASE [test] ADD FILEGROUP [dane_hist]
GO
ALTER DATABASE [test] ADD FILE ( NAME = N'hist01', FILENAME = N'F:\Program Files\Microsoft SQL Server\MSSQL11.MSSQLSERVER\MSSQL\DATA\hist01.ndf' , SIZE = 102400KB , FILEGROWTH = 51200KB ) TO FILEGROUP [dane_hist]
GO
ALTER DATABASE [test] ADD FILE ( NAME = N'hist02', FILENAME = N'F:\Program Files\Microsoft SQL Server\MSSQL11.MSSQLSERVER\MSSQL\DATA\hist02.ndf' , SIZE = 102400KB , FILEGROWTH = 51200KB ) TO FILEGROUP [dane_hist]
GO
ALTER DATABASE [test] MODIFY FILE ( NAME = N'test_log', MAXSIZE = UNLIMITED, FILEGROWTH = 51200KB )
GO

-- wypełniamy tabelę przykładowymi danymi (nie jest to generator) 
-- Może to potrwać kilka minut 
-- (baza orientacyjnie będzie miała 2,7GB z czego 1,3GB dane i 1,4 dziennik transakcji)
-- Po zakończeniu transakcji w SSMS stajemy na bazie TEST i pod prawym przycikiem myszy wybieramy
-- Reports | Standard Reports | Disk Usage w celu graficznej reprezentacji wykorzystania dysku

use TEST
GO
if exists (select * from sysobjects where id = object_id('dbo.x') and sysstat & 0xf = 3)
	drop table x
GO
create table x (a1 char(100),a2 char(100), a3 char(100))
on dane_hist;
insert into x values ('dowolne dane','dowolne dane','dowolne dane');
go
declare @a int = 0
begin
	while @a<22 --można zwiększyć do 23 ale będzie to trwało zdecydowanie dłużej
	begin
		set @a=@a+1
		print @a
		insert into x select * from x;
	end;
end;
GO

-- ostatnie polecenie można zapisać krócej (dwie linijki uruchamiamy na raz)
	--insert into x select * from x;
	--GO 22

-- Sprawdzenie liczby wstawionych rekordów
use TEST;
select count(*) from x;   

-- sprawdzamy zawartość plików
use TEST
SELECT name, size/128.0 FileSizeInMB, size/128.0 - CAST(FILEPROPERTY(name, 'SpaceUsed') AS int)/128.0 AS EmptySpaceInMB
FROM sys.database_files;
-- pojawia się liczba 128 jako 1024kB/8kB - jako liczba bloków 8kB na 1 Mbajt danych

--aktualne grupy plików
select * from sys.data_spaces
--or
select * from sys.filegroups

--https://msdn.microsoft.com/en-us/library/ms187997.aspx  --Mapping System Tables to System Views (Transact-SQL)

-------------------------------------
-- 1. Opróżnić hist02 i przenieść dane do hist01 w ramach tej samej grupy plików

DBCC showfilestats
GO

USE TEST
GO
SELECT DB_NAME() AS [DatabaseName], Name, file_id, physical_name,
    (size * 8.0/1024) as Size,
    ((size * 8.0/1024) - (FILEPROPERTY(name, 'SpaceUsed') * 8.0/1024)) As FreeSpace
    FROM sys.database_files
GO --- check na rozmiarze plików i wolnym miejscu

USE TEST
GO
DBCC SHRINKFILE('hist02',EMPTYFILE)

-- 2. Wyeksportować całą bazę danych do pliku w celu późniejszego uruchomienia tak jak Nortwhind

PPM na bazie danych -> Tasks -> Back up..

plik TEST.bak rozmiar 1 294 568 KB

BACKUP DATABASE [TEST] TO  DISK = N'F:\Program Files\Microsoft SQL Server\MSSQL11.MSSQLSERVER\MSSQL\Backup\TEST.bak' WITH NOFORMAT, NOINIT,  NAME = N'TEST-Full Database Backup', SKIP, NOREWIND, NOUNLOAD,  STATS = 10
GO


-- 3. Jak zrobić attach i detach bazy danych.

PPM na bazie danych -> Tasks -> Detach..

USE [master]
GO
ALTER DATABASE [TEST] SET  SINGLE_USER WITH ROLLBACK IMMEDIATE
GO
USE [master]
GO
EXEC master.dbo.sp_detach_db @dbname = N'TEST'
GO

PPM na Databases -> Attach .. i należy odnaleźć plik TEST.mdf, potwierdzić i baza wraca na Object Explorera

USE [master]
GO
CREATE DATABASE [TEST] ON 
( FILENAME = N'F:\Program Files\Microsoft SQL Server\MSSQL11.MSSQLSERVER\MSSQL\DATA\TEST.mdf' ),
( FILENAME = N'F:\Program Files\Microsoft SQL Server\MSSQL11.MSSQLSERVER\MSSQL\DATA\TEST_log.ldf' ),
( FILENAME = N'F:\Program Files\Microsoft SQL Server\MSSQL11.MSSQLSERVER\MSSQL\DATA\hist01.ndf' ),
( FILENAME = N'F:\Program Files\Microsoft SQL Server\MSSQL11.MSSQLSERVER\MSSQL\DATA\hist02.ndf' )
 FOR ATTACH
GO


-- 4. Ustawić bazę w trybie OFFline a następnie przywrócić do normalnej pracy

PPM na bazie danych -> Tasks -> Take offline
zmieni się ikona bazy i obok nazwy pojawi się (Offline)

ALTER DATABASE TEST SeT OFFLINE WITH ROLLBACK IMMEDIATE
GO

PPM na bazie danych -> Tasks -> Bring online

ALTER DATABASE TEST SeT ONLINE
GO

-- 5. Przeanalizować bazy AdventureWorks i  AdvantureWorksLT (AdventureWorksDW to hurtownia bazy danych)  
-- Należy pamiętać aby ustawić użytkownika sa jako właściciela całej bazy danych (nie musi to być ustawione)
Co należy zamieści w analizie?



---------------
-- Callation --
---------------
-- Sprawdzić czy widać znaki polskie i kiedy?
CREATE DATABASE TEST1 COLLATE ARABIC_CI_AS;	
USE TEST1;
GO
CREATE TABLE table1(
	a1 nchar(10) NULL,
	a2 char(10) NULL);
insert into table1 values ('ą','ą');
insert into table1 values (N'ą',N'ą');

select * from table1

ą wyświetla tylko w drugim wierszu kolumny a1
	--litera N przed tekstem mówi nam, że jest to element w systemie Unicode
	--i jeśli kolumna ma typ z literką n (np. nchar) to przechowywane dane mogą być w dowolnym języku.
	--W innym przypadku mamy słownik i znaki w tym przypadku języka arabskiego.


--Przykłady do wykonania różnego COLLATION
use TEST1;
DROP TABLE TestCharacter;
CREATE TABLE dbo.TestCharacter
(
  id int NOT NULL IDENTITY(1,1),
  Data varchar(10) COLLATE Polish_CI_AS,
  DataPL nvarchar(10) COLLATE Polish_CI_AS,
  CIData varchar(10) COLLATE CYRILLIC_GENERAL_CI_AS,	-- case insensitive
  CSData varchar(10) COLLATE French_CS_AS	-- case sensitive
);
INSERT INTO TestCharacter (Data,DataPL,CIData,CSData) 
	VALUES (N'Łódź',N'ŁÓDŹ',N'русский',N'passé');
INSERT INTO TestCharacter (Data,DataPL,CIData,CSData) 
	VALUES (N'русский',N'русский',N'русский',N'русский');
	--Mimo ustawienia dla bazy danych i dla konkretnych kolumn możemy 
	--w zapytaniu odnieść się do odpowiedniego sposobu porównywania i sortowania danych.
select * from TestCharacter order by CSData collate Polish_CS_AS;
	--Poleceniami poniżej można skopiować inne znaki jak polskie
	SET LANGUAGE RUSSIAN
	SET LANGUAGE French
	SET LANGUAGE POLISH 

--Przykłady do wykonania różnego COLLATION z rozróżnieniem małych i dużych znaków

DROP TABLE dbo.TestCharacter1;
CREATE TABLE dbo.TestCharacter1
( id int NOT NULL IDENTITY(1,1),
  CIData varchar(10) COLLATE POLISH_CI_AS,	-- case insensitive
  CSData varchar(10) COLLATE POLISH_CS_AS	-- case sensitive
);

INSERT INTO dbo.TestCharacter1 (CIData,CSData) VALUES ('Test Data','Test Data');			
INSERT INTO dbo.TestCharacter1 (CIData,CSData) VALUES (N'Łódź',N'Łódź');	
GO
SELECT * FROM TestCharacter1

-- Zapytanie do kolumny Case InSensitive
SELECT * FROM dbo.TestCharacter1 
	WHERE CIData = 'test data'; -- wszystkie małe litery w klauzuli WHERE

-- Zapytanie do kolumny Case Sensitive
SELECT * FROM dbo.TestCharacter1 
	WHERE CSData = 'test data'; -- brak zwracanych rekordów!

-- Zapytania z rozróżnianiem wielkości liter
SELECT * FROM dbo.TestCharacter1
	WHERE CSData = 'test data' COLLATE Polish_CI_AS;	

-- Wymuszenie porównywania bez względu na wielkość liter mimo porównywania kolumny z ustawieniem CS
-- Wykonać zapytanie, które porównuje dwie kolumny, które mają różne ustawienia COLLATE. 
-- Nie powiedzie się to, ponieważ konfliktu collation nie można rozwiązać.

SELECT * FROM dbo.TestCharacter1	
	WHERE CIData = CSData;
-- Msg 468, Level 16, State 9, Line 170
-- Cannot resolve the collation conflict between "Polish_CS_AS" and "Polish_CI_AS" in the equal to operation.

-- Można tego uniknąć wybierając konkretny sposób callation

SELECT * FROM dbo.TestCharacter1
WHERE CIData = CSData COLLATE Latin1_General_CI_AS;
	-- lub
SELECT * FROM dbo.TestCharacter1
WHERE CIData = CSData COLLATE Polish_CI_AS;

-- Dodajemy sortowanie w danym języku
SELECT * FROM dbo.TestCharacter1 
	where CSData = 'test Data' COLLATE Polish_CS_AS
	order by CIData collate Polish_CI_AS;

-- Sprawdzamy CS i CI - czy wielkość znaków ma znaczenie przy sortowaniu
INSERT INTO dbo.TestCharacter1 (CIData,CSData) VALUES ('test Data','test Data');
INSERT INTO dbo.TestCharacter1 (CIData,CSData) VALUES ('Test Data','Test Data');
INSERT INTO dbo.TestCharacter1 (CIData,CSData) VALUES ('test Data','test Data');
INSERT INTO dbo.TestCharacter1 (CIData,CSData) VALUES ('test Data','test Data');

SELECT * FROM dbo.TestCharacter1 order by CIData collate Polish_CI_AS;
SELECT * FROM dbo.TestCharacter1 order by CIData collate Polish_CS_AS;

-- 6. sprawdzamy akcent na literką é - N'passé' AS i AI

select * from TestCharacter order by CSData collate Polish_CS_AS;
select * from TestCharacter order by CSData collate Polish_CS_AI;


----------------------------------
-- Partycjonowanie i FileStream --
----------------------------------

--Zdefiniować funkcję partycji o 4 przedziałach
USE TEST
CREATE PARTITION FUNCTION myRangePF1 (int)
AS RANGE LEFT FOR VALUES (1, 100, 1000);
GO

--Zdefiniować schemat partycji na podstawie funkcji partycji
--Uwaga musimy najpierw zdefiniować 4 grupy plików i przynajmniej po jednym pliku w danej grupie
--7. Definicja 4 grupy plików

Go
ALTER DATABASE [test] ADD FILEGROUP [test1fg]
GO
ALTER DATABASE [test] ADD FILE ( NAME = N'file01', FILENAME = N'F:\Program Files\Microsoft SQL Server\MSSQL11.MSSQLSERVER\MSSQL\DATA\file01.ndf' , SIZE = 102400KB , FILEGROWTH = 51200KB ) TO FILEGROUP [test1fg]
GO
ALTER DATABASE [test] ADD FILEGROUP [test2fg]
GO
ALTER DATABASE [test] ADD FILE ( NAME = N'file02', FILENAME = N'F:\Program Files\Microsoft SQL Server\MSSQL11.MSSQLSERVER\MSSQL\DATA\file02.ndf' , SIZE = 102400KB , FILEGROWTH = 51200KB ) TO FILEGROUP [test2fg]
GO
ALTER DATABASE [test] ADD FILEGROUP [test3fg]
GO
ALTER DATABASE [test] ADD FILE ( NAME = N'file03', FILENAME = N'F:\Program Files\Microsoft SQL Server\MSSQL11.MSSQLSERVER\MSSQL\DATA\file03.ndf' , SIZE = 102400KB , FILEGROWTH = 51200KB ) TO FILEGROUP [test3fg]
GO
ALTER DATABASE [test] ADD FILEGROUP [test4fg]
GO
ALTER DATABASE [test] ADD FILE ( NAME = N'file04', FILENAME = N'F:\Program Files\Microsoft SQL Server\MSSQL11.MSSQLSERVER\MSSQL\DATA\file04.ndf' , SIZE = 102400KB , FILEGROWTH = 51200KB ) TO FILEGROUP [test4fg]
GO
ALTER DATABASE [test] MODIFY FILE ( NAME = N'test_log', MAXSIZE = UNLIMITED, FILEGROWTH = 51200KB )
GO


USE TEST
CREATE PARTITION SCHEME myRangePS1
AS PARTITION myRangePF1
TO (test1fg, test2fg, test3fg, test4fg);
GO

--Zdefiniować tabelę na podstawie schematu partycji
CREATE TABLE PartitionTable (col1 int, col2 char(10))
ON myRangePS1 (col1) ;
GO

--Wypełnić przykładowymi danymi
INSERT INTO PartitionTable values (0,'tekst'),(50,'tekst'),(150,'tekst'),(2000,'tekst'),(750,'tekst')
GO 1000;

-- 8. Zdefiniować jeszcze jedną grupę plików test5fg
-- Ustawienie aktualnej partycji wykorzystanej przy rozdzieleniu funkcji partycji SPLIT
-- wprowadzając wartość 500
USE TEST
ALTER DATABASE [test] ADD FILEGROUP [test5fg]
GO
ALTER DATABASE [test] ADD FILE ( NAME = N'file05', FILENAME = N'F:\Program Files\Microsoft SQL Server\MSSQL11.MSSQLSERVER\MSSQL\DATA\file05.ndf' , SIZE = 102400KB , FILEGROWTH = 51200KB ) TO FILEGROUP [test5fg]
GO


ALTER PARTITION SCHEME MyRangePS1
NEXT USED test5fg;
/* składnia polecenia funkcji partycjonującej
ALTER PARTITION FUNCTION partition_function_name()
{ 
    SPLIT RANGE ( boundary_value )
  | MERGE RANGE ( boundary_value ) 
} [ ; ]
*/

ALTER PARTITION FUNCTION myRangePF1 ()  
SPLIT RANGE (500);  

-- 9.Połącz grupy partycji MERGE wyrzucając wartość 1 

ALTER PARTITION FUNCTION myRangePF1 ()  
MERGE RANGE (1); 

--10.Zdefiniowac tabelę z typem binarnym FILESTRAM i wstawić tam kilka zdjęć z plików
-- można wykorzystać przykłady z wykładu

ALTER DATABASE TEST
ADD FILEGROUP file01
CONTAINS FILESTREAM;
GO

ALTER DATABASE TEST
ADD FILE ( NAME = file002, FILENAME = 'F:\FILESTREAM\Data')
TO FILEGROUP file01;
GO

USE TEST
CREATE TABLE dbo.Records01
(
[Id] [uniqueidentifier] ROWGUIDCOL NOT NULL UNIQUE,
[SerialNumber] INTEGER UNIQUE,
[Chart] VARBINARY(MAX) FILESTREAM NULL
) ON [PRIMARY] FILESTREAM_ON [file01]
GO

CREATE TABLE [dbo].[Authors]
(
[AuthorID] UNIQUEIDENTIFIER ROWGUIDCOL NOT NULL
UNIQUE ,
[AuthorName] VARCHAR(50) ,
[AuthorImage] VARBINARY(MAX) FILESTREAM NULL
)
GO

INSERT INTO dbo.Authors
( AuthorID, AuthorName,AuthorImage)
SELECT NEWID(), 'PHILfactor' ,
bulkcolumn FROM OPENROWSET(BULK 'F:\plan.JPG',SINGLE_BLOB) AS X
GO

select * from Authors
--11.Zdefiniować tabelę z datą, gdzie funkcja partycjonująca będzie zdefiniowana nakierowana na lata (granice w funkcji partycji 2019,2020,2021)

CREATE PARTITION FUNCTION dateFunc (DATE)
AS RANGE LEFT
FOR VALUES ('2019','2020','2021')