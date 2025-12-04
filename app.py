from flask import Flask, render_template, request, jsonify
import requests
import os
from datetime import datetime

app = Flask(__name__)

# Clé API OpenWeatherMap (gratuite - 1000 appels/jour)
API_KEY = os.environ.get('OPENWEATHER_API_KEY', 'demo')
BASE_URL = "http://api.openweathermap.org/data/2.5/weather"

# Liste des principales villes françaises
VILLES_FRANCE = [
    "Paris", "Marseille", "Lyon", "Toulouse", "Nice",
    "Nantes", "Strasbourg", "Montpellier", "Bordeaux", "Lille",
    "Rennes", "Reims", "Le Havre", "Saint-Étienne", "Toulon",
    "Grenoble", "Dijon", "Angers", "Nîmes", "Villeurbanne"
]

def get_weather(city):
    """Récupère les données météo pour une ville"""
    try:
        params = {
            'q': f"{city},FR",
            'appid': API_KEY,
            'units': 'metric',
            'lang': 'fr'
        }
        response = requests.get(BASE_URL, params=params, timeout=5)
        response.raise_for_status()
        return response.json()
    except requests.exceptions.RequestException as e:
        print(f"Erreur API pour {city}: {e}")
        return None

def format_weather_data(data):
    """Formate les données météo"""
    if not data:
        return None
    
    return {
        'ville': data['name'],
        'temperature': round(data['main']['temp'], 1),
        'ressenti': round(data['main']['feels_like'], 1),
        'description': data['weather'][0]['description'].capitalize(),
        'humidite': data['main']['humidity'],
        'vent': round(data['wind']['speed'] * 3.6, 1),  # Conversion m/s en km/h
        'icon': data['weather'][0]['icon'],
        'timestamp': datetime.now().strftime('%H:%M:%S')
    }

@app.route('/')
def index():
    """Page d'accueil avec liste des villes"""
    return render_template('index.html', villes=VILLES_FRANCE)

@app.route('/meteo/<ville>')
def meteo_ville(ville):
    """Retourne la météo pour une ville spécifique"""
    data = get_weather(ville)
    weather_info = format_weather_data(data)
    
    if weather_info:
        return jsonify(weather_info)
    else:
        return jsonify({'error': 'Impossible de récupérer la météo'}), 500

@app.route('/health')
def health():
    """Endpoint de santé pour Kubernetes"""
    return jsonify({'status': 'healthy', 'timestamp': datetime.now().isoformat()})

@app.route('/ready')
def ready():
    """Endpoint de readiness pour Kubernetes"""
    # Test de connexion à l'API
    try:
        response = requests.get(BASE_URL, params={'q': 'Paris,FR', 'appid': API_KEY}, timeout=2)
        if response.status_code == 200 or response.status_code == 401:  # 401 = clé invalide mais API accessible
            return jsonify({'status': 'ready'})
    except:
        pass
    return jsonify({'status': 'not ready'}), 503

if __name__ == '__main__':
    port = int(os.environ.get('PORT', 5000))
    app.run(host='0.0.0.0', port=port, debug=False)
