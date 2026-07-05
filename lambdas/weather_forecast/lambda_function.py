import json
import urllib.request
import urllib.parse

def lambda_handler(event, context):
    """
    AgentCore Gateway Lambda Target: Weather Forecast
    Gets weather data using coordinates from Open-Meteo Forecast API.
    """
    print(f"Event: {json.dumps(event)}")
    
    latitude = event.get("latitude")
    longitude = event.get("longitude")
    
    if latitude is None or longitude is None:
        return {
            "error": "Missing required parameters: latitude and longitude",
            "message": "Please provide both latitude and longitude coordinates"
        }
    
    try:
        params = {
            "latitude": latitude,
            "longitude": longitude,
            "current": "temperature_2m,relative_humidity_2m,apparent_temperature,is_day,precipitation,rain,showers,snowfall,weather_code,cloud_cover,wind_speed_10m,wind_direction_10m,wind_gusts_10m",
            "hourly": "temperature_2m,wind_speed_10m,cloud_cover,precipitation_probability,snowfall,snow_depth",
            "daily": "weather_code,temperature_2m_max,temperature_2m_min,uv_index_max,precipitation_sum,rain_sum,snowfall_sum"
        }
        
        if event.get("start_date"):
            params["start_date"] = event["start_date"]
        if event.get("end_date"):
            params["end_date"] = event["end_date"]
        if event.get("timezone"):
            params["timezone"] = event["timezone"]
        if event.get("temperature_unit"):
            params["temperature_unit"] = event["temperature_unit"]
        
        url = f"https://api.open-meteo.com/v1/forecast?{urllib.parse.urlencode(params)}"
        
        req = urllib.request.Request(url)
        with urllib.request.urlopen(req) as response:
            body = json.loads(response.read().decode())
        
        print("Successfully retrieved weather data")
        return body
        
    except Exception as e:
        print(f"Error: {str(e)}")
        return {"error": str(e), "message": "Failed to retrieve weather data"}