from flask import Blueprint, render_template, redirect, url_for, flash, request
from flask_login import login_user, logout_user, current_user, login_required
from werkzeug.security import generate_password_hash, check_password_hash
from app.models import User
from app.extensions import get_db

auth_bp = Blueprint('auth', __name__)

@auth_bp.route('/login', methods=['GET', 'POST'])
def login():
    if current_user.is_authenticated:
        return redirect(url_for('tasks.dashboard'))
    
    if request.method == 'POST':
        username = request.form['username']
        password = request.form['password']

        db = get_db()
        cursor = db.cursor(dictionary=True)
        cursor.execute("SELECT BenutzerID, BenutzerPWD FROM Benutzer WHERE BenutzerName = %s", (username,))
        user_data = cursor.fetchone()
        cursor.close()
        
        if user_data and check_password_hash(user_data['BenutzerPWD'], password):
            user = User(id=user_data["BenutzerID"], username=username)
            login_user(user)
            return redirect(url_for('tasks.dashboard'))
        else:
            flash('Invalid username or password', 'danger')

    return render_template('auth/login.html')

@auth_bp.route('/register', methods=['GET', 'POST'])
def register():
    if current_user.is_authenticated:
        return redirect(url_for('tasks.dashboard'))
    
    if request.method == 'POST':
        username = request.form['username']
        password = request.form['password']
        
        try:
            db = get_db()
            cursor = db.cursor(dictionary=True)
            cursor.execute("SELECT BenutzerID FROM Benutzer WHERE BenutzerName = %s", (username,))
            existing_user = cursor.fetchone()

            if existing_user:
                flash('Username already exists, please choose another.', 'danger')
                cursor.close()
                return redirect(url_for('auth.register'))

            hashed_password = generate_password_hash(password)
            cursor.callproc("CreateUser", (username, hashed_password))
            db.commit()
            cursor.close()
            
            flash('Registered successfully! You can now log in.', 'success')
            return redirect(url_for('auth.login'))
        
        except Exception as e:
            db.rollback()
            flash(f"Error: {str(e)}", 'danger')

    return render_template('auth/register.html')

@auth_bp.route('/logout', methods=['POST'])
@login_required
def logout():
    logout_user()
    flash('You have been logged out.', 'success')
    return redirect(url_for('tasks.home'))