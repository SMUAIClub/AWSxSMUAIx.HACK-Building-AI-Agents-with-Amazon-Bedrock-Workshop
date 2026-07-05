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