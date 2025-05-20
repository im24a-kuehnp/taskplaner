USE taskplaner;
 
DROP PROCEDURE IF EXISTS CreateUser;
  
DELIMITER //
  
CREATE PROCEDURE CreateUser (
    IN p_name VARCHAR(255),
    IN p_password VARCHAR(300)
)
BEGIN
    INSERT INTO Benutzer (
        BenutzerName,
        BenutzerPWD
    )
    VALUES (
        p_name,
        p_password
    );
END //
  
DELIMITER ;
  
DROP PROCEDURE if exists createtask;
  
DELIMITER //
  
CREATE PROCEDURE CreateTask (
    IN p_Titel VARCHAR(255),
    IN p_Beginn DATETIME,
    IN p_Ende DATETIME,
    IN p_Ort VARCHAR(255),
    IN p_Koordinaten VARCHAR(255),
    IN p_Notiz TEXT,
    IN p_KategorieID INT,
    IN p_PrioritaetID INT,
    IN p_FortschrittID INT,
    IN p_BenutzerID INT
)
BEGIN
    IF NOT EXISTS (SELECT 1 FROM Kategorie WHERE KategorieID = p_KategorieID) THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'KategorieID does not exist';
    END IF;

    IF NOT EXISTS (SELECT 1 FROM Prioritaet WHERE  PrioritaetID = p_PrioritaetID) THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'PrioritaetID does not exist';
    END IF;

    IF NOT EXISTS (SELECT 1 FROM Fortschritt WHERE FortschrittID = p_FortschrittID) THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'FortschrittID does not exist';
    END IF;

    IF NOT EXISTS (SELECT 1 FROM Benutzer WHERE BenutzerID = p_BenutzerID) THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'BenutzerID does not exist';
    END IF;

    INSERT INTO Aufgabe (
        Titel,
        Beginn,
        Ende,
        Ort,
        Koordinaten,
        Notiz,
        KategorieID,
        PrioritaetID,
        FortschrittID,
        BenutzerID
    )
    VALUES (
        p_Titel,
        p_Beginn,
        p_Ende,
        p_Ort,
        p_Koordinaten,
        p_Notiz,
        p_KategorieID,
        p_PrioritaetID,
        p_FortschrittID,
        p_BenutzerID
    );
END //
  
DELIMITER ;
  
DROP PROCEDURE IF EXISTS CreateData; -- ICH HAN KA WIE MER DAS MACHT ---> muess de laul frage
  
DELIMITER //
  
CREATE PROCEDURE CreateData ( -- ICH HAN KA WIE MER DAS MACHT ---> muess de laul frage
    IN p_Aufgabeid int,
    IN p_Dateipfad VARCHAR(255),
    IN p_DateiBLOB BLOB
)
BEGIN
    IF NOT EXISTS (SELECT 1 FROM Aufgabe WHERE AufgabeID = p_AufgabeID) THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'AufgabeID does not exist';
    END IF;  

    INSERT INTO Datei (
        AufgabeID,
        Dateipfad,
        DateiBLOB
    )
    VALUES (
        p_AufgabeID,
        p_Dateipfad,
        p_DateiBLOB
    );
END //
  
DROP PROCEDURE IF EXISTS CreateTaskMaterial;
  
DELIMITER //
  
CREATE PROCEDURE CreateTaskMaterial (
    IN p_AufgabeID INT,
    IN p_MaterialID INT,
    IN p_anzahl INT
)
BEGIN
    IF NOT EXISTS (SELECT 1 FROM Aufgabe WHERE AufgabeID = p_AufgabeID) THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'AufgabeID does not exist';
    END IF;
    IF NOT EXISTS (SELECT 1 FROM Material WHERE MaterialID = p_MaterialID) THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'MaterialID does not exist';
    END IF;
    INSERT INTO AufgabeMaterial (
        AufgabeID,
        MaterialID,
        anzahl
    )
    VALUES (
        p_AufgabeID,
        p_MaterialID,
        p_anzahl
    );
END //
  
DELIMITER ;
  
DROP PROCEDURE IF EXISTS DeleteData;
  
DELIMITER //
  
CREATE PROCEDURE DeleteData (
    IN p_DateiID INT
)
BEGIN
    IF NOT EXISTS (SELECT 1 FROM Datei WHERE DateiID = p_DateiID) THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'DateiID does not exist';
    END IF;
    DELETE FROM Datei WHERE DateiID = p_DateiID;
END //

DELIMITER ;
  

DROP PROCEDURE IF EXISTS DeleteTaskMaterial;
  
DELIMITER //
  

CREATE PROCEDURE DeleteTaskMaterial (
    IN p_AufgabeID INT,
    IN p_MaterialID INT
)
BEGIN
    IF NOT EXISTS (SELECT 1 FROM AufgabeMaterial WHERE AufgabeID = p_AufgabeID) THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'AufgabeID does not exist';
    END IF;
    IF NOT EXISTS (SELECT 1 FROM AufgabeMaterial WHERE MaterialID = p_MaterialID) THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'MaterialID does not exist';
    END IF;
    DELETE FROM AufgabeMaterial
    WHERE AufgabeID = p_AufgabeID AND MaterialID = p_MaterialID;
END //
  
DELIMITER ;
  

DROP PROCEDURE IF EXISTS DeleteTask;
  
DELIMITER //
  

CREATE PROCEDURE DeleteTask (
    IN p_AufgabeID INT,
    IN p_force BOOLEAN
)
BEGIN
    IF NOT EXISTS (SELECT 1 FROM Aufgabe WHERE AufgabeID = p_AufgabeID) THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'AufgabeID does not exist';
    END IF;
    IF p_force THEN

        DELETE FROM AufgabeMaterial
        WHERE AufgabeID = p_AufgabeID;

        DELETE FROM Datei
        WHERE AufgabeID = p_AufgabeID;

    ELSE
        IF EXISTS (SELECT 1 FROM AufgabeMaterial WHERE AufgabeID = p_AufgabeID) OR
           EXISTS (SELECT 1 FROM Datei WHERE AufgabeID = p_AufgabeID) THEN
            SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Task has data';
        END IF;
    END IF;

    DELETE FROM Aufgabe WHERE AufgabeID = p_AufgabeID;
END //
  
DELIMITER ;
  

DROP PROCEDURE IF EXISTS DeleteUser;
  
DELIMITER //
  
CREATE PROCEDURE DeleteUser (
    IN p_BenutzerID INT,
    IN p_force BOOLEAN
)
BEGIN
    IF p_force THEN

        DELETE FROM AufgabeMaterial
        WHERE AufgabeID IN (
            SELECT AufgabeID FROM Aufgabe WHERE BenutzerID = p_BenutzerID
        );

        DELETE FROM Datei
        WHERE AufgabeID IN (
            SELECT AufgabeID FROM Aufgabe WHERE BenutzerID = p_BenutzerID
        );

        DELETE FROM Aufgabe
        WHERE BenutzerID = p_BenutzerID;

    ELSE
        IF EXISTS (SELECT 1 FROM Aufgabe WHERE BenutzerID = p_BenutzerID) THEN
            SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'User has Tasks';
        END IF;
    END IF;

    DELETE FROM Benutzer WHERE BenutzerID = p_BenutzerID;
END //
  
DELIMITER ;
  
CREATE OR REPLACE VIEW v_task AS
SELECT
    BenutzerID,
    Titel,
    Notiz,
    Ende,
    Kategorie,
    Prioritaet,
    Fortschritt
FROM
    Aufgabe a
JOIN
    Kategorie k ON a.KategorieID = k.KategorieID
JOIN
    Prioritaet p ON a.PrioritaetID = p.PrioritaetID
JOIN
    Fortschritt f ON a.FortschrittID = f.FortschrittID;
  

CREATE OR REPLACE VIEW v_taskdetail AS
SELECT
    BenutzerID,
    Titel,
    Beginn,
    Ende,
    Ort,
    Koordinaten,
    Notiz,
    Kategorie,
    Prioritaet,
    Fortschritt,
    AufgabeID
FROM
    Aufgabe a
JOIN
    Kategorie k ON a.KategorieID = k.KategorieID
JOIN
    Prioritaet p ON a.PrioritaetID = p.PrioritaetID
JOIN
    Fortschritt f ON a.FortschrittID = f.FortschrittID;

DROP PROCEDURE IF EXISTS UpdateTask;
DELIMITER //

CREATE PROCEDURE UpdateTask (
    IN p_AufgabeID INT,
    IN p_Titel VARCHAR(255),
    IN p_Beginn DATETIME,
    IN p_Ende DATETIME,
    IN p_Ort VARCHAR(255),
    IN p_Koordinaten VARCHAR(255),
    IN p_Notiz TEXT,
    IN p_KategorieID INT,
    IN p_PrioritaetID INT,
    IN p_FortschrittID INT
)
BEGIN
    -- Validate foreign keys
    IF NOT EXISTS (SELECT 1 FROM Kategorie WHERE KategorieID = p_KategorieID) THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Invalid KategorieID';
    END IF;
    
    IF NOT EXISTS (SELECT 1 FROM Prioritaet WHERE PrioritaetID = p_PrioritaetID) THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Invalid PrioritaetID';
    END IF;
    
    IF NOT EXISTS (SELECT 1 FROM Fortschritt WHERE FortschrittID = p_FortschrittID) THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Invalid FortschrittID';
    END IF;
    
    -- Update task
    UPDATE Aufgabe SET
        Titel = p_Titel,
        Beginn = p_Beginn,
        Ende = p_Ende,
        Ort = p_Ort,
        Koordinaten = p_Koordinaten,
        Notiz = p_Notiz,
        KategorieID = p_KategorieID,
        PrioritaetID = p_PrioritaetID,
        FortschrittID = p_FortschrittID
    WHERE AufgabeID = p_AufgabeID;
    
    IF ROW_COUNT() = 0 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Task not found or no changes made';
    END IF;
END //

DELIMITER ;