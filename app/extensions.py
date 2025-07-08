from flask_login import LoginManager
import mysql.connector
from dotenv import load_dotenv
import os

load_dotenv()

login_manager = LoginManager()

def get_db():
    return mysql.connector.connect(
        host=os.getenv("DB_HOST"),
        user=os.getenv("DB_USER"),
        password=os.getenv("DB_PASSWORD"),
        database=os.getenv("DB_NAME")
    )