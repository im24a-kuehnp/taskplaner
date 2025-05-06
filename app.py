from flask import Flask, render_template, request, redirect, url_for, flash, session
from flask_login import LoginManager, UserMixin, login_user, login_required, logout_user, current_user
from werkzeug.security import check_password_hash
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
    print(f"Current user: {current_user.is_authenticated}, {current_user.username}")
    return render_template('home.html')

@app.route('/login', methods=['GET', 'POST'])
def login():
    if current_user.is_authenticated:
        return redirect(url_for('home'))
    
    if request.method == 'POST':
        username = request.form['username']
        password = request.form['password']
        
        # Query the database for user
        cursor.execute("SELECT BenutzerID, BenutzerPWD FROM Benutzer WHERE BenutzerName = %s", (username,))
        user_data = cursor.fetchone()
        
        if user_data and user_data['BenutzerPWD'] == password:
            user = User(id=user_data["BenutzerID"], username=username)
            login_user(user)
            flash('Logged in successfully!', 'success')
            return redirect(url_for('dashboard'))
        else:
            flash('Invalid username or password', 'danger')

    return render_template('login.html')

@app.route('/logout')
@login_required
def logout():
    logout_user()
    flash('Logged out successfully!', 'info')
    return redirect(url_for('login'))

@app.route('/dashboard')
@login_required
def dashboard():
    return render_template('dashboard.html')

if __name__ == "__main__":
    app.run(debug=True)