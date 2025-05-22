from flask import Flask, render_template, request, redirect, url_for, flash, jsonify
from flask_login import LoginManager, UserMixin, login_user, login_required, logout_user, current_user
import os
from dotenv import load_dotenv
import mysql.connector
from werkzeug.security import generate_password_hash, check_password_hash

# load enviroment file
load_dotenv()

# create Flask instance
app = Flask(__name__)
app.secret_key = os.getenv("FLASK_SECRET_KEY", "fallback-key-for-dev")

# create LoginManager instance
login_manager = LoginManager()
login_manager.init_app(app)
login_manager.login_view = 'login'

# connect to db
db = mysql.connector.connect(
    host=os.getenv("DB_HOST"),
    user=os.getenv("DB_USER"),
    password=os.getenv("DB_PASSWORD"),
    database=os.getenv("DB_NAME")
)

#create cursor
cursor = db.cursor(dictionary=True)

# create User class
class User(UserMixin):
    def __init__(self, id, username):
        self.id = id
        self.username = username

# function to run sql scripts
def execute_sql_file(cursor, filepath):
    with open(filepath, 'r', encoding='utf-8') as file:
        sql_commands = file.read().split('-- end')
        for command in sql_commands:
            command = command.strip()
            if command:
                cursor.execute(command)

# loads user from db and creates class instance
@login_manager.user_loader
def load_user(user_id):
    cursor.execute("SELECT BenutzerID, BenutzerName FROM Benutzer WHERE BenutzerID = %s", (user_id,))
    user_data = cursor.fetchone()
    if user_data:
        return User(id=user_data["BenutzerID"], username=user_data["BenutzerName"])
    return None

# home screen
@app.route('/')
@login_required
def home():
    return render_template('home.html')

# login function
@app.route('/login', methods=['GET', 'POST'])
def login():
    # login already authenticated user
    if current_user.is_authenticated:
        return redirect(url_for('dashboard'))
    
    # get input
    if request.method == 'POST':
        username = request.form['username']
        password = request.form['password']

        # Query the database for the user
        cursor.execute("SELECT BenutzerID, BenutzerPWD FROM Benutzer WHERE BenutzerName = %s", (username,))
        user_data = cursor.fetchone()
        
        if user_data and check_password_hash(user_data['BenutzerPWD'], password):  # Compare hashed password
            user = User(id=user_data["BenutzerID"], username=username)
            login_user(user)
            flash('Logged in successfully!', 'success')
            return redirect(url_for('dashboard'))
        else:
            flash('Invalid username or password', 'danger')

    return render_template('login.html')

# register function
@app.route('/register', methods=['GET', 'POST'])
def register():
    
    # get input
    if request.method == 'POST':
        username = request.form['username']
        password = request.form['password']
        
        try:
            # Check if the username already exists in the database
            cursor.execute("SELECT BenutzerID FROM Benutzer WHERE BenutzerName = %s", (username,))
            existing_user = cursor.fetchone()

            if existing_user:
                flash('Username already exists, please choose another.', 'danger')
                return redirect(url_for('register'))

            hashed_password = generate_password_hash(password)
            print(hashed_password)

            # If no existing user, proceed with user creation
            cursor.execute("Call CreateUser(%s, %s)", (username, hashed_password))
            db.commit()
            
            flash('Registered successfully! You can now log in.', 'success')
            return redirect(url_for('login'))
        
        except Exception as e:
            db.rollback()
            flash(f"Error: {str(e)}", 'danger')

    return render_template('register.html')

# dashboard function
@app.route('/dashboard')
@login_required
def dashboard():
    # Query the database for tasks specific to the logged-in user
    cursor.execute("SELECT * FROM v_taskdetail WHERE BenutzerID = %s", (current_user.id,))
    tasks = cursor.fetchall()  # Fetch all tasks for the user

    # Get dropdown options
    cursor.execute("SELECT KategorieID, Kategorie FROM Kategorie WHERE IstAktiv = TRUE")
    kategorien = cursor.fetchall()

    cursor.execute("SELECT PrioritaetID, Prioritaet FROM Prioritaet")
    prioritaeten = cursor.fetchall()

    cursor.execute("SELECT FortschrittID, Fortschritt FROM Fortschritt")
    fortschritte = cursor.fetchall()

    return render_template('dashboard.html', 
                         tasks=tasks,
                         kategorien=kategorien,
                         prioritaeten=prioritaeten,
                         fortschritte=fortschritte)
    

# logout function
@app.route('/logout', methods=['POST'])
@login_required
def logout():
    logout_user()  # This logs out the current user
    flash('You have been logged out.', 'success')
    return redirect(url_for('home'))  # Redirecting the user to the login page after logout

@app.route('/delete_all', methods=['POST'])
@login_required
def deleteall():
    try:     
        # Call the stored procedure to delete the task
        cursor.callproc('DeleteAllTasks', [current_user.id, True])  # False = don't force delete
        print(current_user.id)
        db.commit()
        
        return jsonify({'success': True, 'message': 'Tasks deleted'})
        
    except Exception as e:
        db.rollback()
        return jsonify({'success': False, 'message': str(e)}), 500

@app.route('/add_task', methods=['POST'])
@login_required
def add_task():
    try:
        # Get form data
        titel = request.form['title']
        beginn = request.form['anfang']
        ende = request.form['ende']
        ort = request.form['ort']
        koordinaten = request.form['koordinaten']
        notiz = request.form['notiz']
        kategorie_id = int(request.form['kategorie'])
        prioritaet_id = int(request.form['prioritaet'])
        fortschritt_id = int(request.form['fortschritt'])
        benutzer_id = current_user.id

        # Call stored procedure
        cursor.callproc('CreateTask', [
            titel,
            beginn,
            ende,
            ort,
            koordinaten,
            notiz,
            kategorie_id,
            prioritaet_id,
            fortschritt_id,
            benutzer_id
        ])
        db.commit()

        flash('Task successfully created!', 'success')
        return redirect(url_for('dashboard'))

    except Exception as e:
        db.rollback()
        flash(f'Error: {str(e)}', 'danger')
        return redirect(url_for('dashboard'))

@app.route('/edit_task', methods=['POST'])
@login_required
def edit_task():
    try:
        # Get form data
        titel = request.form.get('title')
        beginn = request.form.get('anfang')
        ende = request.form.get('ende')
        ort = request.form.get('ort')
        koordinaten = request.form.get('koordinaten')
        notiz = request.form.get('notiz')
        kategorie_id = int(request.form.get('kategorie'))
        prioritaet_id = int(request.form.get('prioritaet'))
        fortschritt_id = int(request.form.get('fortschritt'))
        aufgabe_id = int(request.form.get('task_id'))
        benutzer_id = current_user.id

        # Verify the task belongs to the current user
        cursor.execute("SELECT BenutzerID FROM Aufgabe WHERE AufgabeID = %s", (aufgabe_id,))
        task_owner = cursor.fetchone()
        
        if not task_owner or task_owner['BenutzerID'] != benutzer_id:
            flash('Unauthorized to edit this task', 'danger')
            return redirect(url_for('dashboard'))

        # Call stored procedure
        cursor.callproc('UpdateTask', [
            aufgabe_id,
            titel,
            beginn,
            ende,
            ort,
            koordinaten,
            notiz,
            kategorie_id,
            prioritaet_id,
            fortschritt_id
        ])
        db.commit()

        flash('Task successfully updated!', 'success')
        return redirect(url_for('dashboard'))

    except Exception as e:
        db.rollback()
        flash(f'Error: {str(e)}', 'danger')
        return redirect(url_for('dashboard'))
    
@app.route('/delete_task/<int:task_id>', methods=['DELETE'])
@login_required
def delete_task(task_id):
    try:
        # First verify the task belongs to the current user
        cursor.execute("SELECT BenutzerID FROM Aufgabe WHERE AufgabeID = %s", (task_id,))
        task_owner = cursor.fetchone()
        
        if not task_owner:
            return jsonify({'success': False, 'message': 'Task not found'}), 404
            
        if task_owner['BenutzerID'] != current_user.id:
            return jsonify({'success': False, 'message': 'Unauthorized'}), 403
            
        # Call the stored procedure to delete the task
        cursor.callproc('DeleteTask', [task_id, True])  # False = don't force delete
        db.commit()
        
        return jsonify({'success': True, 'message': 'Task deleted'})
        
    except Exception as e:
        db.rollback()
        return jsonify({'success': False, 'message': str(e)}), 500
    
if __name__ == "__main__":
    # execute_sql_file(cursor, r"C:\Users\anmel\GithubRepos\Flask\functions.sql")
    app.run(debug=True)