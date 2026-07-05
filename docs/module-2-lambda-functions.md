# Module 2: Create Lambda Functions

**Estimated time:** 10 minutes

Three Lambda functions serve as weather tools: geo-coordinates lookup,
weather forecast, and date/time. Source lives in [`../lambdas`](../lambdas).

## Tab 1 — geo_coordinates

### Create the Function

1. Search **Lambda** in the Services search bar and select **Lambda**
2. Select **Create function**
3. Select **Author from scratch**
4. Configure the function:

   | Setting | Value |
   |---|---|
   | Function name | `geo_coordinates` |
   | Runtime | Python 3.13 |

5. Click **Create function**

### Add the Function Code

Navigate to the **Code** tab and replace the default code in
`lambda_function.py` with:

```python
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
```

Click **Deploy** to save the changes.

### Test the Function

1. Click the **Test** tab
2. Create a new test event named `TestGeocode`
3. Replace the default JSON with:

   ```json
   {
     "name": "Dallas",
     "count": 1
   }
   ```

4. Click **Test**

You should see a response containing latitude, longitude, timezone, and
other location data for Dallas, Texas.

## Tab 2 — weather_forecast

### Create the Function

1. Select **Functions** and then **Create function**
2. Select **Author from scratch**
3. Configure the function:

   | Setting | Value |
   |---|---|
   | Function name | `weather_forecast` |
   | Runtime | Python 3.13 |

4. Click **Create function**

### Add the Function Code

```python
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
```

Click **Deploy** to save the changes.

### Test the Function

1. Click the **Test** tab
2. Create a new test event named `TestWeather`
3. Replace the default JSON with:

   ```json
   {
     "latitude": 32.78,
     "longitude": -96.80,
     "timezone": "America/Chicago"
   }
   ```

4. Click **Test**

You should see current weather conditions, hourly forecasts, and daily
forecasts for Dallas, Texas.

## Tab 3 — date_time

### Create the Function

1. Select **Functions** and then **Create function**
2. Select **Author from scratch**
3. Configure the function:

   | Setting | Value |
   |---|---|
   | Function name | `date_time` |
   | Runtime | Python 3.13 |

4. Click **Create function**

### Add the Function Code

```python
import json
from datetime import datetime, timezone
import zoneinfo

def lambda_handler(event, context):
    """
    AgentCore Gateway Lambda Target: Date and Time
    Returns current date and time for a specific timezone.
    """
    print(f"Event: {json.dumps(event)}")

    tz_name = event.get("timezone", "UTC")

    try:
        tz = zoneinfo.ZoneInfo(tz_name)
        now = datetime.now(tz)

        result = {
            "current_date_time": now.strftime("%m/%d/%Y, %I:%M:%S %p %Z"),
            "date": now.strftime("%Y-%m-%d"),
            "time": now.strftime("%H:%M:%S"),
            "day_of_week": now.strftime("%A"),
            "timezone": tz_name
        }

        print(f"Current time in {tz_name}: {result['current_date_time']}")
        return result

    except Exception as e:
        print(f"Error: {str(e)}")
        return {
            "error": str(e),
            "message": f"Failed to get time for timezone: {tz_name}."
        }
```

Click **Deploy** to save the changes.

### Test the Function

1. Click the **Test** tab
2. Create a new test event named `TestDateTime`
3. Replace the default JSON with:

   ```json
   {
     "timezone": "America/Chicago"
   }
   ```

4. Click **Test**

You should see the current date, time, and day of the week in the Central
timezone.

## Verify All Functions

Navigate back to the Lambda Functions page. You should see three functions:

| Function Name | Purpose |
|---|---|
| `geo_coordinates` | Geocoding — place names to coordinates |
| `weather_forecast` | Weather data from coordinates |
| `date_time` | Current date and time for a timezone |

## Checkpoint

You have three Lambda functions created and tested:

- ✅ `geo_coordinates` — returns latitude/longitude for place names
- ✅ `weather_forecast` — returns weather data for coordinates
- ✅ `date_time` — returns current date/time for a timezone
