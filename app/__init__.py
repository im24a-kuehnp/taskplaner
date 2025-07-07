from flask import Flask
from app.extensions import login_manager
from app.config import Config

def create_app():
    app = Flask(__name__)
    
    # Configuration
    app.config.from_object(Config)
    
    # Initialize extensions
    login_manager.init_app(app)
    login_manager.login_view = 'auth.login'
    
    # Register blueprints
    from app.auth.routes import auth_bp
    from app.tasks.routes import tasks_bp
    
    app.register_blueprint(auth_bp)
    app.register_blueprint(tasks_bp)
    
    return app