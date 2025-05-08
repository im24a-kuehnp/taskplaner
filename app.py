from flask import Flask, render_template, request, redirect, url_for, flash
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
        sql_commands = file.read().split(';')  # Basic split; assumes semicolons end statements
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
    cursor.execute("SELECT * FROM v_task WHERE BenutzerID = %s", (current_user.id,))
    tasks = cursor.fetchall()  # Fetch all tasks for the user
    
    return render_template('dashboard.html', tasks=tasks)

# logout function
@app.route('/logout', methods=['POST'])
@login_required
def logout():
    logout_user()  # This logs out the current user
    flash('You have been logged out.', 'success')
    return redirect(url_for('home'))  # Redirecting the user to the login page after logout

if __name__ == "__main__":
    app.run(debug=True)
