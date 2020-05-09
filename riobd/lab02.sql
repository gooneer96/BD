CREATE TABLE WOJEWODZTWA
(
  WOJEWODZTWOID INT GENERATED ALWAYS AS IDENTITY NOT NULL 
, NAZWA VARCHAR2(30) NOT NULL 
, AKTYWNE CHAR(1) DEFAULT '1'
, CONSTRAINT WOJEWODZTWA1_PK PRIMARY KEY
  (
    WOJEWODZTWOID
  )
, CONSTRAINT AKTYWNE CHECK
  (
    AKTYWNE IN('1','0')
  )
  
  ENABLE
);

-- ORACLE nie wspiera typu danych BIT, podobnie jak BOOLEAN, dlatego wprowadzam CHAR(1) w kolumnie AKTYWNE

CREATE TABLE MIASTA
(
  MIASTOID INT GENERATED ALWAYS AS IDENTITY NOT NULL 
, NAZWA VARCHAR2(30) NOT NULL 
, WOJEWODZTWOID INT 
, CONSTRAINT MIASTA1_PK PRIMARY KEY
  (
    MIASTOID
  )
, CONSTRAINT MIASTA1_FK
    FOREIGN KEY (WOJEWODZTWOID)
    REFERENCES WOJEWODZTWA(WOJEWODZTWOID)
  
  ENABLE
);

-- KLIENCI CZY PRACOWNICY? SKORO SPRAWDZAMY WIEK aby nie zatrudniaæ < 18 lat
CREATE TABLE KLIENCI
(
  KLIENTID INT GENERATED ALWAYS AS IDENTITY NOT NULL 
, NAZWISKO VARCHAR2(30) NOT NULL 
, IMIE VARCHAR2(20) NOT NULL 
, PESEL VARCHAR2(11) UNIQUE
, DATA_UR DATE NOT NULL 
, DATA_ZATRUDNIENIA DATE DEFAULT SYSDATE
, PENSJA DEC DEFAULT 0 NOT NULL
, PENSJA_ROCZNA as (PENSJA * 12)
, ULICA VARCHAR2(50) NOT NULL 
, NUMER VARCHAR2(10) NULL
, MIESZKANIA INT NOT NULL 
, MIASTOID INT 
, WIEK as (FLOOR(months_between(DATA_ZATRUDNIENIA, DATA_UR) /12))
, CONSTRAINT KLIENCI_PK PRIMARY KEY
  (
    KLIENTID 
  )
, CONSTRAINT PESEL_CK CHECK
  (
    LENGTH(PESEL)=11
  )
, CONSTRAINT PENSJA_CK CHECK
  (
    PENSJA >=0
  )
, CONSTRAINT DATA_ZATRUDNIENIA_DATA_URODZENIA_CK CHECK
  (
    DATA_UR < DATA_ZATRUDNIENIA
  )
, CONSTRAINT WIEK_CK CHECK
  (
    WIEK >= 18
  )
, CONSTRAINT KLIENCI_FK
    FOREIGN KEY (MIASTOID)
    REFERENCES MIASTA(MIASTOID)
  
  ENABLE 
);
-- czesc adresu taki jak Ulica nie powinien byæ mo¿liwy wypelnieniem wartoscia NULL
-- czesc adresu taka jak Mieszkania nie powinien byæ mo¿liwy wypelnieniem wartoscia NULL
-- nie mozemy uzyc systemowych funkcji zwracajacych aktualna date, ze wgledu na to ze nie sa deterministyczne, oczywiscie mozemy te funkcje zmodyfikwoac lub utworzyc na ich wzor funkcje oznaczone jako determinystyczny,
--mamy tylko datê urodzenia i date zatrudnienia gdzie default to aktualna data, mo¿emy zalozyc ze tak bedzie zawsze a jesli nie to nadal istotnym warunkiem jest to aby w momencie pojawienia sie rekordu wiek byl mniejszy niz 18

INSERT     INTO WOJEWODZTWA(NAZWA,AKTYWNE) VALUES ('£ÓDZKIE',1);
INSERT     INTO WOJEWODZTWA(NAZWA,AKTYWNE) VALUES ('MAZOWIECKIE',1);
INSERT     INTO WOJEWODZTWA(NAZWA,AKTYWNE) VALUES ('LUBELSKIE',1);
INSERT     INTO WOJEWODZTWA(NAZWA,AKTYWNE) VALUES ('PODLASKIE',0);
INSERT     INTO WOJEWODZTWA(NAZWA) VALUES ('WIELKOPOLSKIE');
INSERT     INTO MIASTA(NAZWA,WOJEWODZTWOID) VALUES ('£ÓD',1);
INSERT     INTO MIASTA(NAZWA,WOJEWODZTWOID) VALUES ('WARSZAWA',2);
INSERT     INTO MIASTA(NAZWA,WOJEWODZTWOID) VALUES ('PIASECZNO',2);
INSERT    INTO MIASTA(NAZWA,WOJEWODZTWOID) VALUES ('LUBLIN',3);
INSERT     INTO MIASTA(NAZWA,WOJEWODZTWOID) VALUES ('POZNAÑ',5);
INSERT     INTO KLIENCI(NAZWISKO,IMIE,PESEL,DATA_UR,PENSJA,ULICA,NUMER,MIESZKANIA,MIASTOID)
    VALUES ('Kowalski','Jan',12345678901,TO_DATE('1994/12/12 12:00:00', 'yyyy/mm/dd hh:mi:ss'),2500,'Pulawska','55',64,2);
INSERT     INTO KLIENCI(NAZWISKO,IMIE,PESEL,DATA_UR,PENSJA,ULICA,NUMER,MIESZKANIA,MIASTOID)
    VALUES ('Kowalski','Marcin',12245678901,TO_DATE('1992/06/17 08:00:00', 'yyyy/mm/dd hh:mi:ss'),3500,'Piotrkowska','55',4,1);
INSERT     INTO KLIENCI(NAZWISKO,IMIE,PESEL,DATA_UR,PENSJA,ULICA,NUMER,MIESZKANIA,MIASTOID)
    VALUES ('Kambod¿a','Stefan',12345658901,TO_DATE('1993/06/09 01:00:00', 'yyyy/mm/dd hh:mi:ss'),1500,'Jaracza','32',24,1);






--1
ALTER TABLE WOJEWODZTWA
ADD PAÑSTWO varchar2(20) NULL;

UPDATE WOJEWODZTWA
SET PAÑSTWO='POLSKA';
--2
ALTER TABLE WOJEWODZTWA
MODIFY PAÑSTWO DEFAULT 'POLSKA' NOT NULL;

--3
/*ALTER TABLE WOJEWODZTWA
MODIFY PAÑSTWO varchar2(5)
;

ADD CONSTRAINT PAÑSTWO_CK CHECK
 (
  CASE WHEN LENGTH(PAÑSTWO)=11
 )
Myœlalem nad konstrukcja case when length = restriction then cut input ale nie udalo mi sie zrobic takiej implementacji

*/
-- 4
ALTER TABLE WOJEWODZTWA
MODIFY PAÑSTWO varchar2(35);

-- 5
ALTER TABLE WOJEWODZTWA
RENAME COLUMN AKTYWNE to ACTIVE;

-- 6
ALTER TABLE KLIENCI
DISABLE CONSTRAINT PENSJA_CK;

ALTER TABLE KLIENCI
ENABLE CONSTRAINT PENSJA_CK;

--7
COMMENT ON TABLE MIASTA 
    IS 'Tabela przechowujaca miasta';
COMMENT ON COLUMN MIASTA.MIASTOID
    IS 'Identyfikator miasta';
COMMENT ON COLUMN MIASTA.NAZWA
    IS 'Nazwa miasta';
COMMENT ON COLUMN MIASTA.WOJEWODZTWOID
    IS 'Identyfikator wojewodztwa, FK tabela WOJEWODZTWA';
--8
ALTER TABLE KLIENCI
DROP CONSTRAINT KLIENCI_FK;

ALTER TABLE KLIENCI
ADD CONSTRAINT KLIENCI_FK
    FOREIGN KEY (MIASTOID)
    REFERENCES MIASTA(MIASTOID)
    ON DELETE CASCADE;
    
ALTER TABLE MIASTA
DROP CONSTRAINT MIASTA1_FK;

ALTER TABLE MIASTA
ADD CONSTRAINT MIASTA1_FK
    FOREIGN KEY (WOJEWODZTWOID)
    REFERENCES WOJEWODZTWA(WOJEWODZTWOID)
    ON DELETE CASCADE;

--DELETE FROM WOJEWODZTWA
--WHERE WOJEWODZTWOID=1;
-- usunêlo miasta przypisane do wojewowdztwa i klientow przypisanych do tego miasta

--9
CREATE VIEW TASK_9
AS
SELECT NAZWISKO,WIEK,PENSJA_ROCZNA,m.NAZWA as MIASTO,w.NAZWA AS WOJEWODZTWO
FROM KLIENCI k LEFT JOIN MIASTA m
ON k.MIASTOID=m.MIASTOID
LEFT JOIN WOJEWODZTWA w
ON m.WOJEWODZTWOID=w.WOJEWODZTWOID;
--10

select table_name
from ALL_TAB_COLUMNS;

select column_name,data_type
from ALL_TAB_COLUMNS;

select  VIEW_NAME
from ALL_VIEWS;

--11
ALTER TABLE KLIENCI
RENAME TO KLIENCI1;

--12
/*
Nie ma komendy na reorganizacje kolejnoœci jako takiej,
mo¿emy u¿yæ drop table(drop column chyba wgl nie wchodzi gre) i odtworzyæ tabele w kolejnoœci jakiej chcemy, utracimy dane, aby odtworzyc dane nalezaloby odpowiednio utworzyc dump zawartosci tabeli jako inserty, tj.
podajac nazwy kolumny w nowej kolejnosci a potem dopasowac dane w wykonywanym select
je¿eli chodzi o wyœwietlanie mo¿emy zdefiniowaæ odpowiedni widok,
lub zastosowaæ trick polegajacy na ukryciu kolumny, jednak to nadal ukrywa czêœæ danych


ALTER TABLE MIASTA MODIFY (NAZWA INVISIBLE);

SELECT * FROM MIASTA
*/
-- 13

/*
Je¿eli uwzglêdniamy to na etapie projektowania to najlepiej utworzyæ tabele Adres,
zawierajaca kolumny(ulica,numer, mieszkania nalezy usunac z tabeli klienci)
ID(int identity PK)
KOD_POCZTOWY(varchar2(5) z check (REGEXP_LIKE(KOD_POCZTOWY,'\d{2}-\d{3}'
ULICA(varchar2(50) not null)
NUMER(varchar2(10) not null)
MIESZKANIA(int)
MIASTOID(int not null + constraint FK do tabeli MIASTA)(jezeli polaczenie miasta->wojewodztwa to za malo to jeszcze tabela WOJEWODZTWOID(int not null fk do tabeli WOJEWODZTWAID) ale moim zdaniem wystarczy polaczenie z miastem bo przeciez nie ma kodu pocztowego w wojewodztwie innym niz miasto do ktorego jest przypisany kod pocztowy

+ nowa tabela w KLIENCI
KOD_POCZTOWY_ID(int not null + constraint FK do tabeli KOD_POCZTOWY)

W przypadku gdy dane istnieja w bazie nowa tabela KODY_POCZTOWE
ID(int GENERATED BY DEFAULT AS IDENTITY PK)
KOD_POCZTOWY(varchar2(5) z check (REGEXP_LIKE(KOD_POCZTOWY,'\d{2}-\d{3}')
ULICA(varchar2(50) not null)
NUMER_OD_DO(varchar2(10) not null)
MIASTOID(int not null + constraint FK do tabeli MIASTA)(jezeli polaczenie miasta->wojewodztwa to za malo to jeszcze tabela WOJEWODZTWOID(int not null fk do tabeli WOJEWODZTWAID) ale moim zdaniem wystarczy polaczenie z miastem bo przeciez nie ma kodu pocztowego w wojewodztwie innym niz miasto do ktorego jest przypisany kod pocztowy

+ nowa kolumna od tabeli KLIENCI
KOD_POCZTOWYID(int not null + constraint FK do tabeli KOD_POCZTOWY)

mozna te¿ dorzucic do tabeli KLIENCI tylko kolumne

KOD_POCZTOWYID(varchar2(5) z check (REGEXP_LIKE(KOD_POCZTOWY,'\d{2}-\d{3})

ale wydaje mi siê ze to rozwiaznie nie umozliwia ograniczenia od numeru do numeru( bo co jak na jednej ulicy mamy rozne kody pocztowe dla innych numerów domu) a bazujemy jedynie na adresie klienta wiec lepsze rozwiazanie to nowa tabela + jedna nowa kolumna w tabeli KLIENCI

*/
DROP VIEW TASK_9;
DROP TABLE KLIENCI1;
DROP TABLE MIASTA; 
DROP TABLE WOJEWODZTWA; 