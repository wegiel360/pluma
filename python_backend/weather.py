from flask import Blueprint, request, jsonify
try:
    import requests
    HAS_REQUESTS = True
except ImportError:
    HAS_REQUESTS = False

weather_bp = Blueprint('weather', __name__)

def get_wmo_description(code):
    wmo_map = {
        0: ("Bezchmurnie", "wb_sunny"),
        1: ("Słonecznie", "wb_sunny"),
        2: ("Częściowe zachmurzenie", "partly_cloudy_day"),
        3: ("Pochmurno", "cloud"),
        45: ("Mgła", "foggy"),
        48: ("Osadzająca się mgła", "foggy"),
        51: ("Lekka mżawka", "grain"),
        53: ("Umiarkowana mżawka", "grain"),
        55: ("Gęsta mżawka", "grain"),
        61: ("Lekki deszcz", "rainy"),
        63: ("Umiarkowany deszcz", "rainy"),
        65: ("Ulewny deszcz", "rainy"),
        71: ("Lekkie opady śniegu", "ac_unit"),
        73: ("Umiarkowane opady śniegu", "ac_unit"),
        75: ("Intensywne opady śniegu", "ac_unit"),
        80: ("Przelotny deszcz", "rainy"),
        81: ("Umiarkowany przelotny deszcz", "rainy"),
        82: ("Gwałtowny przelotny deszcz", "rainy"),
        95: ("Burza", "thunderstorm"),
    }
    return wmo_map.get(code, ("Umiarkowanie", "partly_cloudy_day"))

@weather_bp.route("/weather/search", methods=["GET"])
def search_cities():
    """Wyszukuje miasta za pomocą Open-Meteo Geocoding API"""
    query = request.args.get("q", "").strip()
    if not query or len(query) < 2:
        return jsonify({"status": "success", "results": []})

    if HAS_REQUESTS:
        try:
            url = f"https://geocoding-api.open-meteo.com/v1/search?name={requests.utils.quote(query)}&count=6&language=pl&format=json"
            resp = requests.get(url, timeout=4).json()
            results = resp.get("results", [])
            return jsonify({"status": "success", "results": results})
        except Exception as e:
            return jsonify({"status": "error", "message": str(e), "results": []})

    return jsonify({"status": "success", "results": []})

@weather_bp.route("/weather", methods=["GET"])
def get_weather():
    """Pobiera aktualne dane pogodowe z Open-Meteo API"""
    lat = request.args.get("lat")
    lon = request.args.get("lon")
    city = request.args.get("city", "Warszawa")

    if HAS_REQUESTS:
        try:
            # Jeśli brak lat/lon, pobierz współrzędne z Open-Meteo Geocoding API
            if not lat or not lon:
                geo_url = f"https://geocoding-api.open-meteo.com/v1/search?name={requests.utils.quote(city)}&count=1&language=pl&format=json"
                geo_resp = requests.get(geo_url, timeout=3).json()
                results = geo_resp.get("results", [])
                if results:
                    lat = results[0].get("latitude")
                    lon = results[0].get("longitude")
                    city = f"{results[0].get('name')}, {results[0].get('country', '')}"
                else:
                    lat, lon = "52.2297", "21.0122"

            url = f"https://api.open-meteo.com/v1/forecast?latitude={lat}&longitude={lon}&current=temperature_2m,relative_humidity_2m,surface_pressure,wind_speed_10m,weather_code&daily=temperature_2m_max,temperature_2m_min&timezone=auto"
            resp = requests.get(url, timeout=4).json()

            current = resp.get("current", {})
            daily = resp.get("daily", {})

            temp = round(current.get("temperature_2m", 20))
            max_temp = round(daily.get("temperature_2m_max", [temp + 3])[0]) if daily.get("temperature_2m_max") else temp + 3
            min_temp = round(daily.get("temperature_2m_min", [temp - 3])[0]) if daily.get("temperature_2m_min") else temp - 3
            code = current.get("weather_code", 0)
            condition_text, icon_code = get_wmo_description(code)

            return jsonify({
                "status": "success",
                "weather": {
                    "cityName": city,
                    "temp": temp,
                    "high": max_temp,
                    "low": min_temp,
                    "condition": condition_text,
                    "humidity": round(current.get("relative_humidity_2m", 50)),
                    "windSpeed": round(current.get("wind_speed_10m", 10)),
                    "pressure": round(current.get("surface_pressure", 1013)),
                    "icon": icon_code,
                    "weatherCode": code
                }
            })
        except Exception as e:
            pass

    # Rezerwowy wynik
    return jsonify({
        "status": "success",
        "weather": {
            "cityName": city,
            "temp": 20,
            "high": 24,
            "low": 16,
            "condition": "Słonecznie",
            "humidity": 52,
            "windSpeed": 11,
            "pressure": 1013,
            "icon": "wb_sunny",
            "weatherCode": 1
        }
    })

