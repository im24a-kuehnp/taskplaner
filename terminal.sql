use taskplaner;
select * from benutzer;
INSERT INTO Benutzer (BenutzerName, BenutzerPWD)
VALUES ('testuser', '1234');

CALL CreateUser(
    'testuser1',
    '12345'
);
CALL CreateTask(
    'Flask lernen',
    '2025-05-06 10:00:00',
    '2025-05-06 12:00:00',
    'Zuhause',
    '47.3769, 8.5417',
    'Basics von Flask durchgehen',
    1, 1, 1, 1
);

select * from aufgabe