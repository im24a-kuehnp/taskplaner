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