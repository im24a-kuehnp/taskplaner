
    function openTaskPopup(titel, notiz, anfang, ende, ort, koordinaten, kategorie, prioritaet, fortschritt, aufgabeID) {
        document.getElementById('popupTitle').value = titel;
        document.getElementById('popupNotiz').innerText = notiz;
        document.getElementById('popupAnfang').innerText = anfang;
        document.getElementById('popupEnde').innerText = ende;
        document.getElementById('popupOrt').innerText = ort;
        document.getElementById('popupKoordinaten').innerText = koordinaten;
        document.getElementById('popupKategorie').innerText = kategorie;
        document.getElementById('popupPrioritaet').innerText = prioritaet;
        document.getElementById('popupFortschritt').innerText = fortschritt;
        document.getElementById('taskPopup').style.display = 'block';
        document.getElementById('overlay1').style.display = 'block';
        const doneButton = document.getElementById('popupDoneButton');
        doneButton.onclick = function(event) {
            deleteTask(event, aufgabeID);
        };

        const editButton = document.getElementById('popupEditButton');
        editButton.onclick = function(event) {
            openEditTaskPopup(titel, notiz, anfang, ende, ort, koordinaten, kategorie, prioritaet, fortschritt, aufgabeID);
        };
    }

    function closeTaskPopup() {
        document.getElementById('taskPopup').style.display = 'none';
        document.getElementById('overlay1').style.display = 'none';
    }

    function openNewTaskPopup() {
        document.getElementById('newTaskPopup').style.display = 'block'
        document.getElementById('overlay2').style.display='block'
    }

    function closeNewTaskPopup() {
        document.getElementById('newTaskPopup').style.display = 'none'
        document.getElementById('overlay2').style.display='none'
    }

    function openEditTaskPopup(titel, notiz, anfang, ende, ort, koordinaten, kategorie, prioritaet, fortschritt, aufgabeID) {
            closeTaskPopup();
            
            // Set the values in the edit form
            document.getElementById('editTitle').value = titel;
            document.getElementById('editNotiz').value = notiz;
            document.getElementById('editOrt').value = ort;
            document.getElementById('editAnfang').value = formatDate(anfang);
            document.getElementById('editEnde').value = formatDate(ende);
            document.getElementById('editKoordinaten').value = koordinaten;
            
            // Set dropdown values
            setDropdownValue('editKategorie', kategorie);
            setDropdownValue('editPrioritaet', prioritaet);
            setDropdownValue('editFortschritt', fortschritt);
            
            // Store the task ID for submission
            document.getElementById('EditTaskPopup').dataset.taskId = aufgabeID;
            
            document.getElementById('EditTaskPopup').style.display = 'block';
            document.getElementById('overlay1').style.display = 'block';
    }

    function formatDate(dateTimeString) {
        const date = new Date(dateTimeString);
        const year = date.getFullYear();
        const month = String(date.getMonth() + 1).padStart(2, '0');
        const day = String(date.getDate()).padStart(2, '0');
        return `${year}-${month}-${day}`; // Format required by <input type="date">
    }

    function closeEditTaskPopup() {
        document.getElementById('EditTaskPopup').style.display = 'none'
        document.getElementById('overlay1').style.display='none'
    }
    const uploadedFiles = [];

    function setDropdownValue(selectId, displayValue) {
        const select = document.getElementById(selectId);
        for (let i = 0; i < select.options.length; i++) {
            if (select.options[i].text === displayValue) {
                select.selectedIndex = i;
                break;
            }
        }
    }

    function closeEditTaskPopup() {
        document.getElementById('EditTaskPopup').style.display = 'none';
        document.getElementById('overlay1').style.display = 'none';
    }

    function handleFileDrop(event) {
        event.preventDefault();
        const files = Array.from(event.dataTransfer.files);
        files.forEach(file => {
            const blob = new Blob([file], { type: file.type });
            const fileObj = {
                name: file.name,
                type: file.type,
                size: file.size,
                blob: blob
            };
            uploadedFiles.push(fileObj);
            displayFile(fileObj);
        });
    }

    function displayFile(fileObj) {
        const list = document.getElementById('fileList');
        const listItem = document.createElement('li');
        listItem.innerText = `${fileObj.name} (${Math.round(fileObj.size / 1024)} KB)`;

        const removeBtn = document.createElement('button');
        removeBtn.innerText = 'Remove';
        removeBtn.style.marginLeft = '10px';
        removeBtn.onclick = () => {
            const index = uploadedFiles.indexOf(fileObj);
            if (index !== -1) uploadedFiles.splice(index, 1);
            listItem.remove();
        };

        listItem.appendChild(removeBtn);
        list.appendChild(listItem);
    }

    function deleteTask(event, taskId) {
    event.stopPropagation(); // Prevent triggering the row click event --> das isch de andere button
    
    if (confirm('Are you sure you want to delete this task?')) {
        console.log('Attempting to delete task ID:', taskId);
        fetch(`/delete_task/${taskId}`, {
            method: 'DELETE',
            headers: {
                'Content-Type': 'application/json',
            },
        })
        .then(response => {
            if (response.ok) {
                //alert('Task deleted successfully!');
                location.reload(); // Refresh the page
            } else {
                alert('Failed to delete task.');
            }
        })
        .catch(error => {
            console.error('Error:', error);
            alert('An error occurred while deleting the task.');
        });
    }
}
function deleteall(userid) {
    if (confirm('Are you sure you want to delete all tasks?')) {
        console.log('Attempting to delete tasks');
        fetch(`/delete_all`, {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json',
            },
        })
        .then(response => {
            if (response.ok) {
                //alert('Tasks deleted successfully!');
                location.reload(); // Refresh the page
            } else {
                alert('Failed to delete tasks.');
            }
        })
        .catch(error => {
            console.error('Error:', error);
            alert('An error occurred while deleting the tasks.');
        });
    }
}

    function SubmitEditTask() {
        const taskId = document.getElementById('EditTaskPopup').dataset.taskId;
        const getToday = () => new Date().toISOString().split('T')[0];
        // Create form data object
        const formData = {
            task_id: taskId,
            title: document.getElementById('editTitle').value || 'Untitled Task',
            notiz: document.getElementById('editNotiz').value || 'Keine Notiz',
            anfang: document.getElementById('editAnfang').value || getToday(), 
            ende: document.getElementById('editEnde').value || getToday(),
            ort: document.getElementById('editOrt').value || 'Unbekannter Ort',
            koordinaten: document.getElementById('editKoordinaten').value || "0,0",
            kategorie: document.getElementById('editKategorie').value,  
            prioritaet: document.getElementById('editPrioritaet').value, 
            fortschritt: document.getElementById('editFortschritt').value 
                };
        fetch('/edit_task', {
            method: 'POST',
            headers: {
                'Content-Type': 'application/x-www-form-urlencoded',
            },
            body: new URLSearchParams(formData).toString()
        })
        .then(response => {
            if (response.ok) {
                location.reload();
            } else {
                alert("Failed to update task.");
            }
        })
        .catch(error => {
            console.error("Error updating task:", error);
            alert("An error occurred while updating the task.");
        });
    }

    function submitNewTask() {
        const formData = new FormData();

        // Add text fields
        const getToday = () => new Date().toISOString().split('T')[0];
        const getVal = (id, defaultVal = '') => document.getElementById(id)?.value?.trim() || defaultVal;
        formData.append('title', getVal('title', 'Untitled Task'));
        formData.append('notiz', getVal('notiz', 'Keine Notiz'));
        formData.append('anfang', getVal('anfang', getToday()));
        formData.append('ende', getVal('ende', getToday()));
        formData.append('ort', getVal('ort', 'Unbekannter Ort'));
        formData.append('koordinaten', getVal('koordinaten', '0,0'));
        formData.append('kategorie', getVal('kategorie', 'Hausaufgaben'));
        formData.append('prioritaet', getVal('prioritaet', 'Hoch'));
        formData.append('fortschritt', getVal('fortschritt', '0%'));

        // Add uploaded files
        // uploadedFiles.forEach((fileObj, i) => {
        //    formData.append(`file${i}`, fileObj.blob, fileObj.name);
        // });

        fetch('/add_task', {
            method: 'POST',
            body: formData
        })
        .then(response => {
            if (response.ok) {
                //alert("Task submitted successfully!"); --> das isch so ein popup gsi kb popups ha
                location.reload();  // Reload page to show new task
            } else {
                alert("Failed to submit task.");
            }
        })
        .catch(error => {
            console.error("Error submitting task:", error);
            alert("An error occurred.");
        });
    }

    function handleFileInputChange(event) {
        const files = Array.from(event.target.files);
        files.forEach(file => {
            const blob = new Blob([file], { type: file.type });
            const fileObj = {
                name: file.name,
                type: file.type,
                size: file.size,
                blob: blob
            };
            uploadedFiles.push(fileObj);
            displayFile(fileObj);
        });
    }

    document.getElementById('fileInput').addEventListener('change', handleFileInputChange);

