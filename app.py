from flask import Flask, render_template
import mysql.connector

app = Flask(__name__)

db = mysql.connector.connect(
    host="localhost",
    user="root",
    password="hello12345",
    database="taskplaner"
)
cursor = db.cursor(dictionary=True)

@app.route("/")
def home():
    cursor.execute("Select * From Aufgabe")
    aufgaben = cursor.fetchall()
    return render_template("home.html", aufgaben=aufgaben)

if __name__ == "__main__":
    app.run(debug=True)