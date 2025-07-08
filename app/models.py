from flask_login import UserMixin
from app.extensions import login_manager, get_db

class User(UserMixin):
    def __init__(self, id, username):
        self.id = id
        self.username = username

@login_manager.user_loader
def load_user(user_id):
    from app import create_app
    app = create_app()
    with app.app_context():
        db = get_db()
        cursor = db.cursor(dictionary=True)
        cursor.execute("SELECT BenutzerID, BenutzerName FROM Benutzer WHERE BenutzerID = %s", (user_id,))
        user_data = cursor.fetchone()
        cursor.close()
        if user_data:
            return User(id=user_data["BenutzerID"], username=user_data["BenutzerName"])
        return None