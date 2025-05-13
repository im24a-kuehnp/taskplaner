USE taskplaner;
-- end
DROP PROCEDURE IF EXISTS CreateUser;
-- end
DELIMITER //
-- end
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
-- end
DELIMITER ;
-- end
DROP PROCEDURE if exists createtask;
-- end
DELIMITER //
-- end
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
-- end
DELIMITER ;
-- end
DROP PROCEDURE IF EXISTS CreateData; -- ICH HAN KA WIE MER DAS MACHT ---> muess de laul frage
-- end
DELIMITER //
-- end
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
-- end
DROP PROCEDURE IF EXISTS CreateTaskMaterial;
-- end
DELIMITER //
-- end
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
-- end
DELIMITER ;
-- end
DROP PROCEDURE IF EXISTS DeleteData;
-- end
DELIMITER //
-- end
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
-- end

DROP PROCEDURE IF EXISTS DeleteTaskMaterial;
-- end
DELIMITER //
-- end

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
-- end
DELIMITER ;
-- end

DROP PROCEDURE IF EXISTS DeleteTask;
-- end
DELIMITER //
-- end

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
-- end
DELIMITER ;
-- end

DROP PROCEDURE IF EXISTS DeleteUser;
-- end
DELIMITER //
-- end
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
-- end
DELIMITER ;
-- end
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
-- end

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
-- end