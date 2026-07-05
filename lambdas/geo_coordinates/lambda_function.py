import json
import urllib.request
import urllib.parse

def lambda_handler(event, context):
    """
    AgentCore Gateway Lambda Target: Geocoding
    Converts place names to latitude/longitude using Open-Meteo Geocoding API.
    """
    print(f"Event: {json.dumps(event)}")
    
    name = event.get("name", "")
    count = event.get("count", 1)
    
    if not name:
        return {
            "error": "Missing required parameter: name",
            "message": "Please provide a city or place name"
        }
    
    try:
        params = urllib.parse.urlencode({"name": name, "count": count})
        url = f"https://geocoding-api.open-meteo.com/v1/search?{params}"
        
        req = urllib.request.Request(url)
        with urllib.request.urlopen(req) as response:
            body = json.loads(response.read().decode())
        
        if "results" not in body or len(body["results"]) == 0:
            return {
                "message": "No location found matching the provided name.",
                "query": name
            }
        
        print(f"Found {len(body['results'])} results for '{name}'")
        return body
        
    except Exception as e:
        print(f"Error: {str(e)}")
        return {"error": str(e), "message": "Failed to geocode the location"}