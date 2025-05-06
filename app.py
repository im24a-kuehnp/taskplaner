from flask import Flask, render_template, request, redirect, url_for, flash, session
from flask_login import LoginManager, UserMixin, login_user, login_required, logout_user, current_user
import os
from dotenv import load_dotenv
import mysql.connector

load_dotenv()

app = Flask(__name__)
app.secret_key = os.getenv("FLASK_SECRET_KEY", "fallback-key-for-dev")

login_manager = LoginManager()
login_manager.init_app(app)
login_manager.login_view = 'login'

db = mysql.connector.connect(
    host=os.getenv("DB_HOST"),
    user=os.getenv("DB_USER"),
    password=os.getenv("DB_PASSWORD"),
    database=os.getenv("DB_NAME")
)

cursor = db.cursor(dictionary=True)

class User(UserMixin):
    def __init__(self, id, username):
        self.id = id
        self.username = username

@login_manager.user_loader
def load_user(user_id):
    cursor.execute("SELECT BenutzerID, BenutzerName FROM Benutzer WHERE BenutzerID = %s", (user_id,))
    user_data = cursor.fetchone()
    if user_data:
        return User(id=user_data["BenutzerID"], username=user_data["BenutzerName"])
    return None

@app.route('/')
@login_required
def home():
    return render_template('home.html')

@app.route('/login', methods=['GET', 'POST'])
def login():
    if current_user.is_authenticated:
        return redirect(url_for('dashboard'))
    
    if request.method == 'POST':
        username = request.form['username']
        password = request.form['password']

        # Query the database for the user
        cursor.execute("SELECT BenutzerID, BenutzerPWD FROM Benutzer WHERE BenutzerName = %s", (username,))
        user_data = cursor.fetchone()
        
        if user_data and user_data['BenutzerPWD'] == password:  # Compare plain text password
            user = User(id=user_data["BenutzerID"], username=username)
            login_user(user)
            flash('Logged in successfully!', 'success')
            return redirect(url_for('dashboard'))
        else:
            flash('Invalid username or password', 'danger')

    return render_template('login.html')

@app.route('/register', methods=['GET', 'POST'])
def register():
    if current_user.is_authenticated:
        return redirect(url_for('dashboard'))
    
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

            # If no existing user, proceed with user creation
            cursor.execute("Call CreateUser(%s, %s)", (username, password))
            db.commit()
            
            flash('Registered successfully! You can now log in.', 'success')
            return redirect(url_for('login'))
        
        except Exception as e:
            db.rollback()
            flash(f"Error: {str(e)}", 'danger')

    return render_template('register.html')

@app.route('/dashboard')
@login_required
def dashboard():
    # Query the database for tasks specific to the logged-in user
    cursor.execute("SELECT AufgabeID, Titel, Notiz, Ende FROM Aufgabe WHERE BenutzerID = %s", (current_user.id,))
    tasks = cursor.fetchall()  # Fetch all tasks for the user
    
    return render_template('dashboard.html', tasks=tasks)

@app.route('/logout', methods=['POST'])
@login_required
def logout():
    logout_user()  # This logs out the current user
    flash('You have been logged out.', 'success')
    return redirect(url_for('home'))  # Redirecting the user to the login page after logout

if __name__ == "__main__":
    app.run(debug=True)
