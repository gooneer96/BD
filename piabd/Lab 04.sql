----------------------------------------------------
-- Kopie bezpieczeństwa i przywracanie baz danych --
----------------------------------------------------

-- Utworzenie nowej bazy test3 z jednym obiektem wypełnionym danymi

drop database test3
go
create database test3 -- baza ma zdefiniowany Recovery model - jako Full lub Bulk-logged
USE [master]
ALTER DATABASE [test3] SET RECOVERY FULL WITH NO_WAIT
go
use test3
drop table cat
select * into cat from northwind.dbo.categories
select * from cat

-- Przygotowanie urządzenia do backupu o nazwie b3, b3_log i b3_log1 (nie musimy tworzyć osobnych plików ale łatwiej będzie pokazać sposoby backupu i przywracania)
-- (uwaga na ścieżki podane w skrypcie bo mogą nie odpowiadać ścieżką w instalacji lokalnej)
USE [master]
EXEC master.dbo.sp_addumpdevice  @devtype = N'disk', @logicalname = N'b3', @physicalname = N'F:\Program Files\Microsoft SQL Server\MSSQL11.MSSQLSERVER\MSSQL\Backup\b3.bak'
EXEC master.dbo.sp_addumpdevice  @devtype = N'disk', @logicalname = N'b3_log', @physicalname = N'F:\Program Files\Microsoft SQL Server\MSSQL11.MSSQLSERVER\MSSQL\Backup\b3_log.bak'
EXEC master.dbo.sp_addumpdevice  @devtype = N'disk', @logicalname = N'b3_log1', @physicalname = N'F:\Program Files\Microsoft SQL Server\MSSQL11.MSSQLSERVER\MSSQL\Backup\b3_log1.bak'
GO

-- Operacje backupu i operacji pomiędzy nimi
-- Pełny backup baz danych - 1
BACKUP DATABASE [test3] TO  [b3] WITH NOFORMAT, INIT,  NAME = N'Full', SKIP, NOREWIND, NOUNLOAD,  STATS = 10
GO
INSERT INTO test3.dbo.cat (categoryname) values ('A1');
GO
-- Różnicowy backup baz danych - 2
BACKUP DATABASE [test3] TO  [b3] WITH  DIFFERENTIAL , NOFORMAT, NOINIT,  NAME = N'DIFF1', SKIP, NOREWIND, NOUNLOAD,  STATS = 10
GO
INSERT INTO test3.dbo.cat (categoryname) values ('A2');
GO
-- Backup baz danych z opcją COPY_ONLY - 3
BACKUP DATABASE [test3] TO  [b3] WITH  COPY_ONLY, NOFORMAT, NOINIT,  NAME = N'Kopia', SKIP, NOREWIND, NOUNLOAD,  STATS = 10
GO
INSERT INTO test3.dbo.cat (categoryname) values ('A3');
GO
-- Różnicowy backup baz danych - 4
BACKUP DATABASE [test3] TO  [b3] WITH  DIFFERENTIAL , NOFORMAT, NOINIT,  NAME = N'DIF2', SKIP, NOREWIND, NOUNLOAD,  STATS = 10
GO
-- ten element zostaje w dzienniku transakcji aktywnym
INSERT INTO test3.dbo.cat (categoryname) values ('A4');
go
select * from test3.dbo.cat

-----------------------------
-- Przywracanie baz danych --
-----------------------------
-- Scenariusz 1 -------------
-----------------------------
-- do urządzenia b3_log dokładamy kolejne wersje backup log i czyścimy dziennik bazy (bez opcji NO_TRUNCATE) 
-- dokładamy zamiast do b3 do nowego urządzenia b3_log (pierwsze polecenie Backup Log jest z opcją INIT aby wyczyścić poprzednią zawartość pliku bak jeśli istniał)
INSERT INTO test3.dbo.cat (categoryname) values ('Tran 1');
BACKUP LOG [test3] TO [b3_log] WITH NOFORMAT, INIT,  NAME = N'Tran 1', SKIP, NOREWIND, NOUNLOAD,   STATS = 5
--
INSERT INTO test3.dbo.cat (categoryname) values ('Tran 2');
BACKUP LOG [test3] TO [b3_log] WITH NOFORMAT, NOINIT,  NAME = N'Tran 2', SKIP, NOREWIND, NOUNLOAD,   STATS = 5
--
INSERT INTO test3.dbo.cat (categoryname) values ('Tran 3');
BACKUP LOG [test3] TO [b3_log] WITH NOFORMAT, NOINIT,  NAME = N'Tran 3', SKIP, NOREWIND, NOUNLOAD,  STATS = 5
	
-- Przywracamy całość (nikt nie może pracować na danej bazie lub przechodzimy z tryb pracy SINGLE_USER lub RESTRICTED_USER)
-- ALTER DATABASE [test3] SET SINGLE_USER WITH ROLLBACK IMMEDIATE
-- ALTER DATABASE [test3] SET MULTI_USER

USE MASTER
ALTER DATABASE [test3] SET SINGLE_USER WITH ROLLBACK IMMEDIATE
RESTORE DATABASE [test3] FROM [b3] WITH  FILE = 1,  NORECOVERY,  NOUNLOAD,   REPLACE,  STATS = 5
RESTORE DATABASE [test3] FROM  [b3] WITH  FILE = 4,  NORECOVERY,  NOUNLOAD,  STATS = 5
RESTORE LOG [test3] FROM  [b3_log] WITH  FILE = 1,  NOUNLOAD, NORECOVERY, STATS = 5
RESTORE LOG [test3] FROM  [b3_log] WITH  FILE = 2,  NOUNLOAD, NORECOVERY, STATS = 5
RESTORE LOG [test3] FROM  [b3_log] WITH  FILE = 3,  NOUNLOAD, NORECOVERY, STATS = 5
RESTORE DATABASE [test3] with RECOVERY
ALTER DATABASE [test3] SET MULTI_USER
--
select * from test3.dbo.cat --sprawdzamy co odzyskaliśmy

-----------------------------
-- Scenariusz 2 -------------
-----------------------------
-- do urządzenia b3_log1 dokładamy kolejne wersje backup log i nie czyścimy dziennika (opcja NO_TRUNCATE)
-- (pierwsze polecenie Backup Log jest z opcją INIT aby wyczyścić poprzednią zawartość pliku bak jeśli istniał)
INSERT INTO test3.dbo.cat (categoryname) values ('Tran 4');
BACKUP LOG [test3] TO [b3_log1] WITH NOFORMAT, INIT,  NAME = N'Tran 4', SKIP, NOREWIND, NOUNLOAD, NO_TRUNCATE,  STATS = 5
--
INSERT INTO test3.dbo.cat (categoryname) values ('Tran 5');
BACKUP LOG [test3] TO  [b3_log1] WITH NOFORMAT, NOINIT,  NAME = N'Tran 5', NOSKIP, NOREWIND, NOUNLOAD, NO_TRUNCATE,  STATS = 5
--
INSERT INTO test3.dbo.cat (categoryname) values ('Tran 6');
BACKUP LOG [test3] TO  [b3_log1] WITH NOFORMAT, NOINIT,  NAME = N'Tran 6', NOSKIP, NOREWIND, NOUNLOAD, NO_TRUNCATE, STATS = 5

-- Przywracamy całość
RESTORE DATABASE [test3] FROM  [b3] WITH  FILE = 1,  NORECOVERY,  NOUNLOAD,   REPLACE,  STATS = 5;
RESTORE DATABASE [test3] FROM  [b3] WITH  FILE = 4,  NORECOVERY,  NOUNLOAD,  STATS = 5;
-- Dzienniki transakcji z b3_log są potrzebne wszytskie w odpowiedniej kolejności
RESTORE LOG [test3] FROM  [b3_log] WITH  FILE = 1,  NOUNLOAD, NORECOVERY, STATS = 5;
RESTORE LOG [test3] FROM  [b3_log] WITH  FILE = 2,  NOUNLOAD, NORECOVERY, STATS = 5;
RESTORE LOG [test3] FROM  [b3_log] WITH  FILE = 3,  NOUNLOAD, NORECOVERY, STATS = 5;
-- Dzienniki transakcji z b3_log1 (wystarczy tylko ostatni - opcja NO_TRUNCATE nie kasowała poprzednich transakcji przy backupie)
RESTORE LOG [test3] FROM  [b3_log1] WITH  FILE = 3,  NOUNLOAD, NORECOVERY, STATS = 5;
RESTORE DATABASE [test3] with RECOVERY
--
select * from test3.dbo.cat --sprawdzamy co odzyskaliśmy

-----------------------------
-- Scenariusz 3 -------------
-----------------------------
-- Scenariusz (naturalny) - Przywracamy całość aby nie stracić żadnej z zatwierdzonych transakcji
-- Tworzymy w danej chwili backup dziennika (tails) z opcją NORECOVERY i odtwarzamy dany strukturę i tail (tylko jeden)
INSERT INTO test3.dbo.cat (categoryname) values ('Tail log');
-- tail log - przy tworzeniu tego backupu od razu przechodzimy do tryby Recovery --
BACKUP LOG [test3] TO  DISK = N'C:\Program Files\Microsoft SQL Server\MSSQL13.MSSQLSERVER\MSSQL\Backup\test3_Log_tail.bak' WITH NOFORMAT, INIT,  NAME = N'test3_Log_tail', NOSKIP, NOREWIND, NOUNLOAD,  NORECOVERY,  STATS = 5
	-- tak jak poprzednio
	RESTORE DATABASE [test3] FROM  [b3] WITH  FILE = 1,  NORECOVERY,  NOUNLOAD,   REPLACE,  STATS = 5;
	RESTORE DATABASE [test3] FROM  [b3] WITH  FILE = 4,  NORECOVERY,  NOUNLOAD,  STATS = 5;
	-- Dzienniki transakcji z b3_log są potrzebne wszytskie w odpowiedniej kolejności
	RESTORE LOG [test3] FROM  [b3_log] WITH  FILE = 1,  NOUNLOAD, NORECOVERY, STATS = 5;
	RESTORE LOG [test3] FROM  [b3_log] WITH  FILE = 2,  NOUNLOAD, NORECOVERY, STATS = 5;
	RESTORE LOG [test3] FROM  [b3_log] WITH  FILE = 3,  NOUNLOAD, NORECOVERY, STATS = 5;
	-- Dzienniki transakcji z b3_log1 (wystarczy tylko ostatni - opcja NO_TRUNCATE nie kasowała poprzednich transakcji przy backupie)
	RESTORE LOG [test3] FROM  [b3_log1] WITH  FILE = 3,  NOUNLOAD, NORECOVERY, STATS = 5;
-- Przywracanie tail log (aby nie stracić żadnej transakcji - od razu jest opcja RECOVERY aby nie wykonywać polecenia RESTORE DATABASE [test3] with RECOVERY)
RESTORE LOG [test3] FROM  DISK = N'C:\Program Files\Microsoft SQL Server\MSSQL13.MSSQLSERVER\MSSQL\Backup\test3_Log_tail.bak' WITH  FILE = 1,  NOUNLOAD,  STATS = 5
--
select * from test3.dbo.cat --sprawdzamy co odzyskaliśmy

------------------------------------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------------------------------------
-- Opis opcji:
-- opcja NORECOVERY - baza w tym stanie po tym backupie przechodzi w stan Restoring (dodałem nadpisywanie pliku backupu - INIT,SKIP) - można świadomie przywrócić poleceniem --RESTORE DATABASE [test3] with RECOVERY
-- opcja NO_TRUNCUTE powoduje nie wycięcie dziennika transakcji (możemy robić kilka kopii i będą one poprawne i z aktualnymi danymi) - bez tej opcji dziennik jest wycinany i ponowne BACKUP LOG i przywracanie z wykorzystaniem tego pliku jest w innym miejscu niż cały backup 
-- BACKUP LOG [test3] TO  [b3_log] WITH NOFORMAT, INIT,  NAME = N'test3_Log_tail', NOSKIP, NOREWIND, NOUNLOAD,  NORECOVERY,  STATS = 5
-- bez opcji NORECOVERY - baza w tym stanie po tym backupie może być normalnie używana (i może zmienić się stan bazy (chyba że damy opcję SINGLE_USER i sami nic nie zmienimy
-- BACKUP LOG [test3] TO  [b3_log] WITH NOFORMAT, INIT,  NAME = N'test3_Log_tail', SKIP, NOREWIND, NOUNLOAD, STATS = 5

-- NORECOVERY
-- Tworzy kopię zapasową końca dziennika i pozostawia bazę danych w stanie PRZYWRACANIA. 
-- NORECOVERY przydaje się w przypadku przełączania awaryjnego do dodatkowej bazy danych lub podczas zapisywania końca dziennika przed operacją PRZYWRACANIA.
-- Aby wykonać najlepszą kopię zapasową dziennika, która pomija obcinanie dziennika, a następnie atomowo wprowadza bazę danych do stanu PRZYWRACANIE, użyj razem opcji NO_TRUNCATE i NORECOVERY.

-- NO_TRUNCATE
-- Określa, że ​​dziennik nie jest obcinany i powoduje, że aparat bazy danych spróbuje wykonać kopię zapasową bez względu na stan bazy danych. W związku z tym kopia zapasowa wykonana przy użyciu NO_TRUNCATE może mieć niepełne metadane. Ta opcja umożliwia tworzenie kopii zapasowej dziennika w sytuacjach, w których baza danych jest uszkodzona.
-- Opcja NO_TRUNCATE w BACKUP LOG jest równoważna określeniu zarówno COPY_ONLY, jak i CONTINUE_AFTER_ERROR.
-- Bez opcji NO_TRUNCATE baza danych musi znajdować się w trybie ONLINE. Jeśli baza danych jest w stanie SUSPENDED, możesz utworzyć kopię zapasową, określając NO_TRUNCATE. Ale jeśli baza danych znajduje się w trybie OFFLINE lub AWARYJNYM, BACKUP nie jest dozwolony nawet przy NO_TRUNCATE. Aby uzyskać informacje o stanach bazy danych, zobacz Stany baz danych.
-- https://msdn.microsoft.com/en-us/library/ms186865.aspx
------------------------------------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------------------------------------

---------------------------------------------
-- Przywracanie bazy z ostatniej COPY_ONLY --
---------------------------------------------
RESTORE DATABASE [test3] FROM  [b3] WITH  FILE = 3,  NORECOVERY,  NOUNLOAD,   REPLACE,  STATS = 5
-- Uwaga
-- RESTORE DATABASE [test3] FROM  [b3] WITH  FILE = 4,  RECOVERY,  NOUNLOAD,   REPLACE,  STATS = 5 
-- tutaj kopia różnicowa do tego backupu nie może być wykorzystana
RESTORE DATABASE [test3] WITH RECOVERY

-- Zadania do wykonania

-- I. Tworzymy dla bazy danych TEST4 następujące typy kopie bezpieczeństwa w kolejności na urządzeniu o nazwie b4 
-- W kolejnosci wykonujemy backup typu: 
-- backup pełny o nazwie w opisie FULL (przy tym backupie ustawiamy opcję INIT aby skasować wszystko co było wcześniej w danym urządzeniu)
-- backup różnicowy o nazwie w opisie DIF1 
-- backup różnicowy o nazwie w opisie DIF2 
-- backup dziennika transakcji o nazwie w opisie LOG1 
-- backup dziennika transakcji o nazwie w opisie LOG2 
-- backup różnicowy o nazwie w opisie DIF3 
-- backup dziennika transakcji o nazwie w opisie LOG3 
-- backup dziennika transakcji o nazwie w opisie LOG4
-- Utworzenie nowej bazy test3 z jednym obiektem wypełnionym danymi

drop database test4
go
create database test4 
USE [master]
ALTER DATABASE [test4] SET RECOVERY FULL WITH NO_WAIT
go
use [test4]
select * into cat from northwind.dbo.categories
select * from cat

USE [master]
EXEC master.dbo.sp_addumpdevice  @devtype = N'disk', @logicalname = N'b4', @physicalname = N'F:\Program Files\Microsoft SQL Server\MSSQL11.MSSQLSERVER\MSSQL\Backup\b4.bak'
EXEC master.dbo.sp_addumpdevice  @devtype = N'disk', @logicalname = N'b4_log', @physicalname = N'F:\Program Files\Microsoft SQL Server\MSSQL11.MSSQLSERVER\MSSQL\Backup\b4_log.bak'
GO

BACKUP DATABASE [test4] TO  [b4] WITH NOFORMAT, INIT,  NAME = N'FULL', SKIP, NOREWIND, NOUNLOAD,  STATS = 10
GO
INSERT INTO test4.dbo.cat (categoryname) values ('A1');
GO

BACKUP DATABASE [test4] TO  [b4] WITH  DIFFERENTIAL , NOFORMAT, NOINIT,  NAME = N'DIF1', SKIP, NOREWIND, NOUNLOAD,  STATS = 10
GO
INSERT INTO test4.dbo.cat (categoryname) values ('A2');
GO

BACKUP DATABASE [test4] TO  [b4] WITH  DIFFERENTIAL , NOFORMAT, NOINIT,  NAME = N'DIF2', SKIP, NOREWIND, NOUNLOAD,  STATS = 10
GO
INSERT INTO test4.dbo.cat (categoryname) values ('A3');
GO

BACKUP LOG [test4] TO  [b4_log] WITH NOFORMAT, INIT,  NAME = N'LOG1', SKIP, NOREWIND, NOUNLOAD,NO_TRUNCATE,  STATS = 10
GO
INSERT INTO test4.dbo.cat (categoryname) values ('A4');
GO

BACKUP LOG [test4] TO  [b4_log] WITH NOFORMAT, NOINIT,  NAME = N'LOG2', SKIP, NOREWIND, NOUNLOAD,NO_TRUNCATE,  STATS = 10
GO
INSERT INTO test4.dbo.cat (categoryname) values ('A5');
GO

BACKUP DATABASE [test4] TO  [b4] WITH  DIFFERENTIAL , NOFORMAT, NOINIT,  NAME = N'DIF3', SKIP, NOREWIND, NOUNLOAD,  STATS = 10
GO
INSERT INTO test4.dbo.cat (categoryname) values ('A6');
GO

BACKUP LOG [test4] TO  [b4_log] WITH NOFORMAT, NOINIT,  NAME = N'LOG3', SKIP, NOREWIND, NOUNLOAD,NO_TRUNCATE,  STATS = 10
GO
INSERT INTO test4.dbo.cat (categoryname) values ('A7');
GO

BACKUP LOG [test4] TO  [b4_log] WITH NOFORMAT, NOINIT,  NAME = N'LOG4', SKIP, NOREWIND, NOUNLOAD,NO_TRUNCATE, STATS = 10
GO

drop database test3
go
create database test3 
USE [master]
ALTER DATABASE [test3] SET RECOVERY FULL WITH NO_WAIT
go
use test3
select * into obiekt from northwind.dbo.Region
select * from obiekt


-----------------------------------------------------
-- Przywracamy bazę danych do pracy w danym czasie
-- 1. FULL
USE MASTER
ALTER DATABASE [test4] SET SINGLE_USER WITH ROLLBACK IMMEDIATE
RESTORE DATABASE [test4] FROM [b4] WITH  FILE = 1,  NORECOVERY,  NOUNLOAD,   REPLACE,  STATS = 5
RESTORE DATABASE [test4] WITH RECOVERY
ALTER DATABASE [test4] SET MULTI_USER
USE [test4]
select * from cat

-- 2. FULL + DIF3
USE MASTER
ALTER DATABASE [test4] SET SINGLE_USER WITH ROLLBACK IMMEDIATE
RESTORE DATABASE [test4] FROM [b4] WITH  FILE = 1,  NORECOVERY,  NOUNLOAD,   REPLACE,  STATS = 5
RESTORE DATABASE [test4] FROM [b4] WITH  FILE = 4,  NORECOVERY,  NOUNLOAD,   REPLACE,  STATS = 5
RESTORE DATABASE [test4] WITH RECOVERY
ALTER DATABASE [test4] SET MULTI_USER
USE [test4]
select * from cat
-- 3. FULL + DIF2 + LOG1 + LOG2
USE MASTER
ALTER DATABASE [test4] SET SINGLE_USER WITH ROLLBACK IMMEDIATE
RESTORE DATABASE [test4] FROM [b4] WITH  FILE = 1,  NORECOVERY,  NOUNLOAD,   REPLACE,  STATS = 5
RESTORE DATABASE [test4] FROM [b4] WITH  FILE = 3,  NORECOVERY,  NOUNLOAD,   REPLACE,  STATS = 5
RESTORE LOG [test4] FROM  [b4_log] WITH  FILE = 1,  NOUNLOAD, NORECOVERY, STATS = 5;
RESTORE LOG [test4] FROM  [b4_log] WITH  FILE = 2,  NOUNLOAD, NORECOVERY, STATS = 5;
RESTORE DATABASE [test4] WITH RECOVERY
ALTER DATABASE [test4] SET MULTI_USER
USE [test4]
select * from cat
-- 4. FULL + DIF3 + LOG3/LOG4 (wybrać dowolny czas między LOG3 a LOG4
USE MASTER
ALTER DATABASE [test4] SET SINGLE_USER WITH ROLLBACK IMMEDIATE
RESTORE DATABASE [test4] FROM [b4] WITH  FILE = 1,  NORECOVERY,  NOUNLOAD,   REPLACE,  STATS = 5
RESTORE DATABASE [test4] FROM [b4] WITH  FILE = 4,  NORECOVERY,  NOUNLOAD,   REPLACE,  STATS = 5
RESTORE LOG [test4] FROM  [b4_log] WITH  FILE = 3,  NOUNLOAD, NORECOVERY, STATS = 5;
RESTORE DATABASE [test4] WITH RECOVERY
ALTER DATABASE [test4] SET MULTI_USER
USE [test4]
select * from cat
-- 5. Korzystając z Tail_log czyli w scenariuszu, gdzie odtwarzamy wszystkie możliwe dane 
USE MASTER
INSERT INTO test4.dbo.cat (categoryname) values ('Tail log');
BACKUP LOG [test4] TO  DISK = N'F:\Program Files\Microsoft SQL Server\MSSQL11.MSSQLSERVER\MSSQL\Backup\test4_Log_tail.bak' WITH NOFORMAT, INIT,  NAME = N'test4_Log_tail', NOSKIP, NOREWIND, NOUNLOAD,  NORECOVERY,  STATS = 5

ALTER DATABASE [test4] SET SINGLE_USER WITH ROLLBACK IMMEDIATE
RESTORE DATABASE [test4] FROM [b4] WITH  FILE = 1,  NORECOVERY,  NOUNLOAD,   REPLACE,  STATS = 5
RESTORE DATABASE [test4] FROM [b4] WITH  FILE = 4,  NORECOVERY,  NOUNLOAD,   REPLACE,  STATS = 5
RESTORE LOG [test4] FROM  [b4_log] WITH  FILE = 4,  NOUNLOAD, NORECOVERY, STATS = 5;
RESTORE LOG [test4] FROM  DISK = N'F:\Program Files\Microsoft SQL Server\MSSQL11.MSSQLSERVER\MSSQL\Backup\test4_Log_tail.bak' WITH  FILE = 1,  NOUNLOAD,  STATS = 5
RESTORE DATABASE [test4] WITH RECOVERY
ALTER DATABASE [test4] SET MULTI_USER

USE [test4]
select * from cat

-- 6. Przywracamy bazę z czasu wykonania backupu FULL pod nową nazwą TEST4_NEW
USE MASTER

ALTER DATABASE [test4] SET SINGLE_USER WITH ROLLBACK IMMEDIATE
RESTORE DATABASE [TEST4_NEW] FROM  DISK = N'F:\Program Files\Microsoft SQL Server\MSSQL11.MSSQLSERVER\MSSQL\Backup\b4.bak' WITH  FILE = 1,  MOVE N'test4' TO N'F:\Program Files\Microsoft SQL Server\MSSQL11.MSSQLSERVER\MSSQL\DATA\TEST4_NEW',  MOVE N'test4_log' TO N'F:\Program Files\Microsoft SQL Server\MSSQL11.MSSQLSERVER\MSSQL\DATA\TEST4_NEW_log',  NOUNLOAD,  STATS = 5
ALTER DATABASE [test4] SET MULTI_USER
GO

USE [TEST4_NEW]
select * from cat
---------------------------------------------------------------------------------------

-- 7. Utwórz bazę danych TEST5 z trzema grupami plików (g1,g2,g3).
CREATE DATABASE [TEST5]
 CONTAINMENT = NONE
 ON  PRIMARY 
( NAME = N'TEST5', FILENAME = N'F:\Program Files\Microsoft SQL Server\MSSQL11.MSSQLSERVER\MSSQL\DATA\TEST5.mdf' , SIZE = 5120KB , FILEGROWTH = 1024KB )
 LOG ON 
( NAME = N'TEST5_log', FILENAME = N'F:\Program Files\Microsoft SQL Server\MSSQL11.MSSQLSERVER\MSSQL\DATA\TEST5_log.ldf' , SIZE = 2048KB , FILEGROWTH = 10%)
GO
ALTER DATABASE [TEST5] ADD FILEGROUP [g1]
GO
ALTER DATABASE [TEST5] ADD FILEGROUP [g2]
GO
ALTER DATABASE [TEST5] ADD FILEGROUP [g3]
GO
ALTER DATABASE [TEST5] SET COMPATIBILITY_LEVEL = 110
GO
ALTER DATABASE [TEST5] SET ANSI_NULL_DEFAULT OFF 
GO
ALTER DATABASE [TEST5] SET ANSI_NULLS OFF 
GO
ALTER DATABASE [TEST5] SET ANSI_PADDING OFF 
GO
ALTER DATABASE [TEST5] SET ANSI_WARNINGS OFF 
GO
ALTER DATABASE [TEST5] SET ARITHABORT OFF 
GO
ALTER DATABASE [TEST5] SET AUTO_CLOSE OFF 
GO
ALTER DATABASE [TEST5] SET AUTO_CREATE_STATISTICS ON 
GO
ALTER DATABASE [TEST5] SET AUTO_SHRINK OFF 
GO
ALTER DATABASE [TEST5] SET AUTO_UPDATE_STATISTICS ON 
GO
ALTER DATABASE [TEST5] SET CURSOR_CLOSE_ON_COMMIT OFF 
GO
ALTER DATABASE [TEST5] SET CURSOR_DEFAULT  GLOBAL 
GO
ALTER DATABASE [TEST5] SET CONCAT_NULL_YIELDS_NULL OFF 
GO
ALTER DATABASE [TEST5] SET NUMERIC_ROUNDABORT OFF 
GO
ALTER DATABASE [TEST5] SET QUOTED_IDENTIFIER OFF 
GO
ALTER DATABASE [TEST5] SET RECURSIVE_TRIGGERS OFF 
GO
ALTER DATABASE [TEST5] SET  DISABLE_BROKER 
GO
ALTER DATABASE [TEST5] SET AUTO_UPDATE_STATISTICS_ASYNC OFF 
GO
ALTER DATABASE [TEST5] SET DATE_CORRELATION_OPTIMIZATION OFF 
GO
ALTER DATABASE [TEST5] SET PARAMETERIZATION SIMPLE 
GO
ALTER DATABASE [TEST5] SET READ_COMMITTED_SNAPSHOT OFF 
GO
ALTER DATABASE [TEST5] SET  READ_WRITE 
GO
ALTER DATABASE [TEST5] SET RECOVERY FULL 
GO
ALTER DATABASE [TEST5] SET  MULTI_USER 
GO
ALTER DATABASE [TEST5] SET PAGE_VERIFY CHECKSUM  
GO
ALTER DATABASE [TEST5] SET TARGET_RECOVERY_TIME = 0 SECONDS 
GO
USE [TEST5]
GO
IF NOT EXISTS (SELECT name FROM sys.filegroups WHERE is_default=1 AND name = N'PRIMARY') ALTER DATABASE [TEST5] MODIFY FILEGROUP [PRIMARY] DEFAULT
GO




-- Następnie utwórz kopię bazy danych z wszystkich grup plików jako jeden backup (w tym samym czasie)

BACKUP DATABASE [TEST5] FILEGROUP = N'PRIMARY',  FILEGROUP = N'g1',  FILEGROUP = N'g2',  FILEGROUP = N'g3' TO  DISK = N'F:\Program Files\Microsoft SQL Server\MSSQL11.MSSQLSERVER\MSSQL\Backup\TEST5.bak' WITH NOFORMAT, INIT,  NAME = N'TEST5', SKIP, NOREWIND, NOUNLOAD,  STATS = 10
GO

-- Przywróć daną bazę danę pod nową nazwą TEST5_1.

USE MASTER

ALTER DATABASE [TEST5] SET SINGLE_USER WITH ROLLBACK IMMEDIATE
RESTORE DATABASE [TEST5_1] FROM  DISK = N'F:\Program Files\Microsoft SQL Server\MSSQL11.MSSQLSERVER\MSSQL\Backup\TEST5.bak' WITH  FILE = 1,  MOVE N'TEST5' TO N'F:\Program Files\Microsoft SQL Server\MSSQL11.MSSQLSERVER\MSSQL\DATA\TEST5_1',  MOVE N'TEST5_log' TO N'F:\Program Files\Microsoft SQL Server\MSSQL11.MSSQLSERVER\MSSQL\DATA\TEST5_1_log',  NOUNLOAD,  STATS = 5
ALTER DATABASE [TEST5] SET MULTI_USER
GO

USE TEST5_1
select * from sys.filegroups

-- 8. Utwórz kopię bazy danych TEST5 w grup plików jako trzy osobne backupy w różnym czasie (backup filegroup (files))

-- Przywróc daną bazę danę pod nową nazwą TEST5_2.




-- Zadanie do wykonanai bez potrzeby wpisywania odpwowiedzi w postaci skryptu.
-- Przygotowanie planów obsługi baz danych (SQL Server Agent musi być uruchomiony)
-- Management|Maintenance Plans i wybieramy prawym przyciskim myszy Maintenance Plan Wizard i przygotowujemy plan wykonania do: 
-- a. Check Database Integrity
-- b. Shrink Database
-- c. Reorganize Index
-- d. Rebuild Index
-- w trybie uruchamiania na życzenie i wywołujemy, każdy z planów albo z zadań, które są definiowane w SQL Server Agent 
--------------------------------------------------------------------------------------
