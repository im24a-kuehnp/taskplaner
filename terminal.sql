use taskplaner;

CALL CreateTask(
    'Flask lernen',
    '2025-05-06 10:00:00',
    '2025-05-06 12:00:00',
    'Zuhause',
    '47.3769, 8.5417',
    'Basics von Flask durchgehen',
    1, 1, 1, 1
);

-- CALL CreateData(1, 'oki', NULL); -- ICH HAN KA WIE MER DAS MACHT ---> muess de laul frage
call createtaskmaterial(
    1,
    1
);

select * from aufgabe;
select * from benutzer;
<<<<<<< Updated upstream
select * from aufgabematerial;
select * from datei;

DELETE from datei;
=======

select * from benutzer where BenutzerID = 1;
select * from Aufgabe where AufgabeID = 1;
>>>>>>> Stashed changes
