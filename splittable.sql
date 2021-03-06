-- splittable.sql
-- 02- Refills table mapsjobs
-- Uses table mapsjobstmp as input

SET NOCOUNT ON 
DECLARE @rowid integer, 
		@Piperowvalue varchar(8000), 
		@Delimiter char(1), 
		@LeftDelimter smallint, 
		@Word varchar(8000), 
		@rowvalue varchar(8000),
		@colcount int,
		@currcol int,
		@firstpass int,
		@s varchar(8000),
		@s2 varchar(8000),
		@sinsert varchar(8000),
		@sinsert2 varchar(8000),
		@tablename varchar(100) 

SET @colcount = 0
SET @currcol = 0
SET @firstpass = 0
SET @sinsert = ''
SET @tablename = 'mapsjobs'
SET @s = 'DROP TABLE [' + @tablename +  ']'
if exists (select name from sysobjects where name = @tablename) EXEC(@s)

DECLARE @name varchar(8000)

DECLARE cursor_name CURSOR
READ_ONLY
FOR SELECT rowvalue FROM mapsjobstmp

OPEN cursor_name

FETCH NEXT FROM cursor_name INTO @name



WHILE (@@fetch_status <> -1)
BEGIN  --begin while(@@fetch_status <> -1) ***********************************************************************
	IF (@@fetch_status <> -2)
	BEGIN --begin (@@fetch_status <> -2)
-----------------------------------------------------
		SELECT @Piperowvalue = @name
		SELECT @LeftDelimter = 1, 
			@Delimiter = '|', 
			@rowvalue = @Delimiter + @Piperowvalue + @Delimiter 
		WHILE CHARINDEX( @Delimiter, @rowvalue, @LeftDelimter + 1) > 0 
		BEGIN 
			SELECT @Word = SUBSTRING( @rowvalue, @LeftDelimter + 1, CHARINDEX( @Delimiter, @rowvalue, @LeftDelimter + 1) - ( @LeftDelimter + 1))
			SET @Word = REPLACE(@Word, char(39), char(39) + char(39))
			SELECT @LeftDelimter = CHARINDEX( @Delimiter, @rowvalue, @LeftDelimter + 1) 
			SET @currcol = @currcol + 1
			IF (@sinsert = '')
			BEGIN
				SET @sinsert = char(39) + @Word
			END
			ELSE
			BEGIN
				SET @sinsert = @sinsert + char(39) + ',' + char(39) + @Word 
			END
		END 
		SET @firstpass = @firstpass + 1
		SET @sinsert = '(' + @sinsert + char(39) + ') ' 
		IF (@firstpass = 1)
		BEGIN 
			SET @colcount = @currcol
			SET @currcol = 1
			SET @s = 'CREATE TABLE ' + @tablename + ' ('
			SET @s2 = 'INSERT INTO ' + @tablename + ' ('
			WHILE (@currcol < @colcount + 1)
			BEGIN
				IF (@currcol < @colcount)
				BEGIN
					SET @s = @s + 'col' + LTRIM(str(@currcol)) + ' varchar(8000) null,' 
					SET @s2 = @s2 + 'col' + LTRIM(str(@currcol)) + ',' 
				END
				ELSE
				BEGIN
					SET @s = @s + 'col' + LTRIM(str(@currcol)) + ' varchar(8000) null)' 
					SET @s2 = @s2 + 'col' + LTRIM(str(@currcol)) + ') VALUES '
				END
				SET @currcol = @currcol +  1
			END
			EXEC(@s)
			EXEC(@s2 + @sinsert)
		END --if firstpass
		ELSE
		BEGIN
			EXEC(@s2 + @sinsert)
---------------------------------------------------------------------------
		END
		SET @sinsert = ''
		FETCH NEXT FROM cursor_name INTO @name
	END -- end (@@fetch_status <> -2)
END -- end while *********************************************************************************

CLOSE cursor_name
DEALLOCATE cursor_name
--drop table tmptable
--select *  from mapsjobs


