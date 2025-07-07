from flask import Blueprint, render_template, request, flash, redirect, url_for, jsonify
from flask_login import login_required, current_user
from app.extensions import get_db

tasks_bp = Blueprint('tasks', __name__)

@tasks_bp.route('/')  # This will handle the root URL
@login_required
def home():
    return render_template('home.html')

@tasks_bp.route('/dashboard')
@login_required
def dashboard():
    db = get_db()
    cursor = db.cursor(dictionary=True)
    
    try:
        # Get user tasks
        cursor.execute("SELECT * FROM v_taskdetail WHERE BenutzerID = %s", (current_user.id,))
        tasks = cursor.fetchall()

        # Get dropdown options
        cursor.execute("SELECT KategorieID, Kategorie FROM Kategorie WHERE IstAktiv = TRUE")
        kategorien = cursor.fetchall()

        cursor.execute("SELECT PrioritaetID, Prioritaet FROM Prioritaet")
        prioritaeten = cursor.fetchall()

        cursor.execute("SELECT FortschrittID, Fortschritt FROM Fortschritt")
        fortschritte = cursor.fetchall()

        return render_template('tasks/dashboard.html',
                            tasks=tasks,
                            kategorien=kategorien,
                            prioritaeten=prioritaeten,
                            fortschritte=fortschritte)
    finally:
        cursor.close()

@tasks_bp.route('/delete_all', methods=['POST'])
@login_required
def deleteall():
    db = get_db()
    cursor = db.cursor()
    
    try:
        cursor.callproc('DeleteAllTasks', [current_user.id, True])
        db.commit()
        return jsonify({'success': True, 'message': 'Tasks deleted'})
    except Exception as e:
        db.rollback()
        return jsonify({'success': False, 'message': str(e)}), 500
    finally:
        cursor.close()

@tasks_bp.route('/add_task', methods=['POST'])
@login_required
def add_task():
    db = get_db()
    cursor = db.cursor()
    
    try:
        cursor.callproc('CreateTask', [
            request.form['title'],
            request.form['anfang'],
            request.form['ende'],
            request.form['ort'],
            request.form['koordinaten'],
            request.form['notiz'],
            int(request.form['kategorie']),
            int(request.form['prioritaet']),
            int(request.form['fortschritt']),
            current_user.id
        ])
        db.commit()
        flash('Task successfully created!', 'success')
        return redirect(url_for('tasks.dashboard'))
    except Exception as e:
        db.rollback()
        flash(f'Error: {str(e)}', 'danger')
        return redirect(url_for('tasks.dashboard'))
    finally:
        cursor.close()

@tasks_bp.route('/edit_task', methods=['POST'])
@login_required
def edit_task():
    db = get_db()
    cursor = db.cursor(dictionary=True)
    
    try:
        task_id = int(request.form.get('task_id'))
        
        # Verify ownership
        cursor.execute("SELECT BenutzerID FROM Aufgabe WHERE AufgabeID = %s", (task_id,))
        task_owner = cursor.fetchone()
        
        if not task_owner or task_owner['BenutzerID'] != current_user.id:
            flash('Unauthorized to edit this task', 'danger')
            return redirect(url_for('tasks.dashboard'))

        cursor.callproc('UpdateTask', [
            task_id,
            request.form.get('title'),
            request.form.get('anfang'),
            request.form.get('ende'),
            request.form.get('ort'),
            request.form.get('koordinaten'),
            request.form.get('notiz'),
            int(request.form.get('kategorie')),
            int(request.form.get('prioritaet')),
            int(request.form.get('fortschritt'))
        ])
        db.commit()
        flash('Task successfully updated!', 'success')
        return redirect(url_for('tasks.dashboard'))
    except Exception as e:
        db.rollback()
        flash(f'Error: {str(e)}', 'danger')
        return redirect(url_for('tasks.dashboard'))
    finally:
        cursor.close()

@tasks_bp.route('/delete_task/<int:task_id>', methods=['DELETE'])
@login_required
def delete_task(task_id):
    db = get_db()
    cursor = db.cursor(dictionary=True)
    
    try:
        cursor.execute("SELECT BenutzerID FROM Aufgabe WHERE AufgabeID = %s", (task_id,))
        task_owner = cursor.fetchone()
        
        if not task_owner:
            return jsonify({'success': False, 'message': 'Task not found'}), 404
            
        if task_owner['BenutzerID'] != current_user.id:
            return jsonify({'success': False, 'message': 'Unauthorized'}), 403
            
        cursor.callproc('DeleteTask', [task_id, True])
        db.commit()
        return jsonify({'success': True, 'message': 'Task deleted'})
    except Exception as e:
        db.rollback()
        return jsonify({'success': False, 'message': str(e)}), 500
    finally:
        cursor.close()