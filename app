from flask import Flask, render_template, request, redirect, url_for, session, flash
import json, os
from werkzeug.utils import secure_filename

app = Flask(__name__)
app.secret_key = 'admin123'
UPLOAD_FOLDER_LOGO = 'static/logo/'
UPLOAD_FOLDER_BG = 'static/background/'
DATA_FILE = 'data/siswa.json'
CONFIG_FILE = 'data/config.json'

def load_data():
    with open(DATA_FILE, ' 'r') as f:
        return json.load(f)

def save_data(data):
    with open(DATA_FILE, 'w') as f:
        json.dump(data, f, indent=4)

def load_config():
    with open(CONFIG_FILE, 'r') as f:
        return json.load(f)

def save_config(cfg):
    with open(CONFIG_FILE, 'w') as f:
        json.dump(cfg, f, indent=4)

@app.route('/')
def index():
    config = load_config()
    return render_template('index.html', config=config)

@app.route('/cek', methods=['POST'])
def cek():
    nisn = request.form['nisn']
    data = load_data()
    config = load_config()
    if nisn in data:
        siswa = data[nisn]
        return render_template('index.html', siswa=siswa, config=config)
    return render_template('index.html', error="NISN tidak ditemukan", config=config)

@app.route('/login', methods=['GET', 'POST'])
def login():
    config = load_config()
    if request.method == 'POST':
        if request.form['password'] == config['admin_password']:
            session['logged_in'] = True
            return redirect(url_for('dashboard'))
        flash('Password salah!')
    return render_template('login.html')

@app.route('/dashboard', methods=['GET', 'POST'])
def dashboard():
    if not session.get('logged_in'):
        return redirect(url_for('login'))
    data = load_data()
    config = load_config()
    return render_template('dashboard.html', data=data, config=config)

@app.route('/logout')
def logout():
    session.pop('logged_in', None)
    return redirect(url_for('login'))

@app.route('/update', methods=['POST'])
def update():
    if not session.get('logged_in'):
        return redirect(url_for('login'))
    config = load_config()
    config['school_name'] = request.form['school_name']
    if request.form['new_password']:
        config['admin_password'] = request.form['new_password']
    save_config(config)
    return redirect(url_for('dashboard'))

@app.route('/upload', methods=['POST'])
def upload():
    if not session.get('logged_in'):
        return redirect(url_for('login'))
    if 'logo' in request.files:
        logo = request.files['logo']
        if logo.filename:
            logo.save(os.path.join(UPLOAD_FOLDER_LOGO, 'logo.png'))
    if 'background' in request.files:
        bg = request.files['background']
        if bg.filename:
            bg.save(os.path.join(UPLOAD_FOLDER_BG, 'bg.jpg'))
    return redirect(url_for('dashboard'))

@app.route('/edit_siswa', methods=['POST'])
def edit_siswa():
    if not session.get('logged_in'):
        return redirect(url_for('login'))
    nisn = request.form['nisn']
    nama = request.form['nama']
    status = request.form['status']
    data = load_data()
    data[nisn] = {'nama': nama, 'status': status}
    save_data(data)
    return redirect(url_for('dashboard'))

@app.route('/hapus/<nisn>')
def hapus(nisn):
    if not session.get('logged_in'):
        return redirect(url_for('login'))
    data = load_data()
    if nisn in data:
        del data[nisn]
        save_data(data)
    return redirect(url_for('dashboard'))

if __name__ == '__main__':
    app.run(debug=True)
