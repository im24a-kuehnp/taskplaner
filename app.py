import os
from flask import Flask, render_template, request, redirect, url_for, session, flash
import mysql.connector

app = Flask(__name__)
app.secret_key = os.getenv("FLASK_SECRET_KEY", "fallback-key-for-dev")

db = mysql.connector.connect(
    host="localhost",
    user="root",
    password="hello12345",
    database="taskplaner"
)
cursor = db.cursor(dictionary=True)

@app.route('/')
def index():
    cursor = db.cursor(dictionary=True)
    cursor.execute("SELECT * FROM Aufgabe")
    aufgaben = cursor.fetchall()
    return render_template('index.html', aufgaben=aufgaben)


if __name__ == "__main__":
    app.run(debug=True)