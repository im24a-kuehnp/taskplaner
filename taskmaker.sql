use taskplaner;
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
    IF NOT EXISTS (SELECT 1 FROM Kategorie WHERE ID = p_KategorieID) THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'KategorieID does not exist';
    END IF;

    -- Check PrioritaetID
    IF NOT EXISTS (SELECT 1 FROM Prioritaet WHERE ID = p_PrioritaetID) THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'PrioritaetID does not exist';
    END IF;

    -- Check FortschrittID
    IF NOT EXISTS (SELECT 1 FROM Fortschritt WHERE ID = p_FortschrittID) THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'FortschrittID does not exist';
    END IF;

    -- Check BenutzerID
    IF NOT EXISTS (SELECT 1 FROM Benutzer WHERE ID = p_BenutzerID) THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'BenutzerID does not exist';
    END IF;

    -- Insert the task
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
