resource "aws_bedrockagentcore_gateway_target" "geo_coordinates" {
  name               = "geo-coordinates-target"
  gateway_identifier = aws_bedrockagentcore_gateway.this.gateway_id
  description        = "Geocoding tool that converts city or place names into latitude and longitude coordinates"

  credential_provider_configuration {
    gateway_iam_role {}
  }

  target_configuration {
    mcp {
      lambda {
        lambda_arn = aws_lambda_function.tool["geo_coordinates"].arn

        tool_schema {
          inline_payload {
            name        = "get_coordinates"
            description = "Search for a location by name and return its latitude, longitude, timezone, and other geographic data. Use this tool to convert city names, country names, or place names into coordinates that can be used with the weather forecast tool."

            input_schema {
              type = "object"

              property {
                name        = "name"
                type        = "string"
                description = "Name of the city, town, or place to search for (e.g., 'Dallas', 'Tokyo', 'London')"
                required    = true
              }

              property {
                name        = "count"
                type        = "integer"
                description = "Number of results to return. Default is 1."
              }
            }
          }
        }
      }
    }
  }
}

resource "aws_bedrockagentcore_gateway_target" "weather_forecast" {
  name               = "weather-forecast-target"
  gateway_identifier = aws_bedrockagentcore_gateway.this.gateway_id
  description        = "Weather forecast tool that returns current conditions, hourly, and daily forecasts using coordinates"

  credential_provider_configuration {
    gateway_iam_role {}
  }

  target_configuration {
    mcp {
      lambda {
        lambda_arn = aws_lambda_function.tool["weather_forecast"].arn

        tool_schema {
          inline_payload {
            name        = "get_forecast"
            description = "Get weather forecast data for a location using latitude and longitude coordinates. Returns current conditions, hourly forecasts (temperature, wind, cloud cover, precipitation probability), and daily forecasts (max/min temperature, UV index, precipitation). Use the get_coordinates tool first to obtain coordinates from a place name."

            input_schema {
              type = "object"

              property {
                name        = "latitude"
                type        = "number"
                description = "WGS84 latitude coordinate (e.g., 32.78 for Dallas)"
                required    = true
              }

              property {
                name        = "longitude"
                type        = "number"
                description = "WGS84 longitude coordinate (e.g., -96.80 for Dallas)"
                required    = true
              }

              property {
                name        = "start_date"
                type        = "string"
                description = "Start date for the forecast in YYYY-MM-DD format"
              }

              property {
                name        = "end_date"
                type        = "string"
                description = "End date for the forecast in YYYY-MM-DD format"
              }

              property {
                name        = "timezone"
                type        = "string"
                description = "IANA timezone name (e.g., 'America/Chicago')"
              }

              property {
                name        = "temperature_unit"
                type        = "string"
                description = "Temperature unit: 'celsius' or 'fahrenheit'. Default is celsius."
              }
            }
          }
        }
      }
    }
  }
}

# This target did not exist when the environment was first reverse-engineered
# into Terraform — date_time was deployed and referenced in the agent's system
# prompt, but never registered on the gateway. It has since been added
# manually via the console (Module 3, Step 7); this block mirrors that exact
# configuration (tool name and required `timezone` field per the workshop's
# official schema).
resource "aws_bedrockagentcore_gateway_target" "date_time" {
  name               = "date-time-target"
  gateway_identifier = aws_bedrockagentcore_gateway.this.gateway_id
  description        = "Date and time tool that returns the current date, time, and day of week for a specific timezone"

  credential_provider_configuration {
    gateway_iam_role {}
  }

  target_configuration {
    mcp {
      lambda {
        lambda_arn = aws_lambda_function.tool["date_time"].arn

        tool_schema {
          inline_payload {
            name        = "get_current_time"
            description = "Get the current date and time for a specific timezone. Use this tool to determine what 'today', 'tomorrow', or 'this weekend' means for the user's location. The timezone can be obtained from the get_coordinates tool."

            input_schema {
              type = "object"

              property {
                name        = "timezone"
                type        = "string"
                description = "IANA timezone name (e.g., 'America/Chicago', 'Europe/London', 'Asia/Tokyo'). Default is 'UTC'."
                required    = true
              }
            }
          }
        }
      }
    }
  }
}
