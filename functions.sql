USE taskplaner;

DROP PROCEDURE IF EXISTS CreateUser;
DELIMITER //

CREATE PROCEDURE CreateUser (
    IN p_name VARCHAR(255),
    IN p_password VARCHAR(255)
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
    -- Check KategorieID
    IF NOT EXISTS (SELECT 1 FROM Kategorie WHERE KategorieID = p_KategorieID) THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'KategorieID does not exist';
    END IF;

    -- Check PrioritaetID
    IF NOT EXISTS (SELECT 1 FROM Prioritaet WHERE  PrioritaetID = p_PrioritaetID) THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'PrioritaetID does not exist';
    END IF;

    -- Check FortschrittID
    IF NOT EXISTS (SELECT 1 FROM Fortschritt WHERE FortschrittID = p_FortschrittID) THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'FortschrittID does not exist';
    END IF;

    -- Check BenutzerID
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

DROP PROCEDURE IF EXISTS CreateUser;
DELIMITER //

CREATE PROCEDURE CreateUser (
    IN p_name VARCHAR(255),
    IN p_password VARCHAR(255)
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
        SET MESSAGE_TEXT = 'MaterialID does not exist';
    END IF;
    IF p_force THEN

        -- First delete related task material
        DELETE FROM AufgabeMaterial
        WHERE AufgabeID = p_AufgabeID;

        -- Then delete related files
        DELETE FROM Datei
        WHERE AufgabeID = p_AufgabeID;

    ELSE
        -- Check if dependent data exists
        IF EXISTS (SELECT 1 FROM AufgabeMaterial WHERE AufgabeID = p_AufgabeID) OR
           EXISTS (SELECT 1 FROM Datei WHERE AufgabeID = p_AufgabeID) THEN
            SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Task has data';
        END IF;
    END IF;

    -- Delete the task itself
    DELETE FROM Aufgabe WHERE AufgabeID = p_AufgabeID;
END //

DELIMITER ;


DROP PROCEDURE IF EXISTS DeleteUser;
DELIMITER //

CREATE PROCEDURE DeleteUser (
    IN p_BenutzerID INT,
    IN p_deleteDependencies BOOLEAN
)
BEGIN
    IF p_deleteDependencies THEN

        -- Delete all dependent task-material relations
        DELETE FROM AufgabeMaterial
        WHERE AufgabeID IN (
            SELECT AufgabeID FROM Aufgabe WHERE BenutzerID = p_BenutzerID
        );

        -- Delete all dependent files
        DELETE FROM Datei
        WHERE AufgabeID IN (
            SELECT AufgabeID FROM Aufgabe WHERE BenutzerID = p_BenutzerID
        );

        -- Delete all tasks of this user
        DELETE FROM Aufgabe
        WHERE BenutzerID = p_BenutzerID;

    ELSE
        -- If dependencies exist, raise error
        IF EXISTS (SELECT 1 FROM Aufgabe WHERE BenutzerID = p_BenutzerID) THEN
            SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'User has Tasks';
        END IF;
    END IF;

    -- Finally, delete the user
    DELETE FROM Benutzer WHERE BenutzerID = p_BenutzerID;
END //

DELIMITER ;
