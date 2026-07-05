# Module 3: Create AgentCore Gateway & Lambda Targets

**Estimated time:** 15 minutes

## Overview

An AgentCore Gateway is the central hub that connects your AI agent to its
tools. It provides a single endpoint that the agent calls, and the Gateway
routes tool invocations to the appropriate backend — Lambda functions, MCP
servers, REST APIs, or other endpoints.

### Why Use a Gateway?

- Unifying tools behind a single endpoint
- Handling authentication between the agent and tool backends
- Managing tool discovery so the agent can list available tools dynamically
- Protocol translation between the agent and different target types (Lambda, MCP, REST)

### What You'll Create

| Resource | Purpose |
|---|---|
| Gateway IAM Role | Service role with permissions to invoke all 3 Lambda functions |
| AgentCore Gateway | Central endpoint with IAM authentication |
| 3 Lambda Targets | `geo_coordinates`, `weather_forecast`, `date_time` — each with a tool schema |

> **Important:** Complete each tab in order. Create the IAM role first, then
> the Gateway with all 3 targets.

## Tab 1 — Create Gateway IAM Role

We create the IAM role first with all 3 Lambda ARNs so the Gateway can
invoke all targets from the start.

### Step 1: Create the IAM Policy

1. Search **IAM** in the Services search bar and select **IAM**
2. In the left panel, select **Policies**
3. Click **Create policy**
4. Select the **JSON** tab in the Policy editor
5. Paste the following policy:

   ```json
   {
     "Version": "2012-10-17",
     "Statement": [
       {
         "Sid": "GetGateway",
         "Effect": "Allow",
         "Action": [
           "bedrock-agentcore:GetGateway"
         ],
         "Resource": [
           "arn:aws:bedrock-agentcore:us-east-1:YOUR_ACCOUNT_ID:gateway/virtual-meteorologist-gateway*"
         ]
       },
       {
         "Sid": "LambdaInvoke",
         "Effect": "Allow",
         "Action": [
           "lambda:InvokeFunction"
         ],
         "Resource": [
           "arn:aws:lambda:us-east-1:YOUR_ACCOUNT_ID:function:geo_coordinates",
           "arn:aws:lambda:us-east-1:YOUR_ACCOUNT_ID:function:weather_forecast",
           "arn:aws:lambda:us-east-1:YOUR_ACCOUNT_ID:function:date_time"
         ]
       }
     ]
   }
   ```

   > **Important — update the policy before saving:** Replace
   > `YOUR_ACCOUNT_ID` with your actual AWS account ID in all 4 ARNs. You can
   > find your account ID in the top-right corner of the AWS Console.

6. Click **Next**
7. For **Policy name**, enter `VirtualMeteorologistGatewayPolicy`
8. Click **Create policy**

### Step 2: Create the IAM Role

1. In the left panel, select **Roles**
2. Click **Create role**
3. For **Trusted entity type**, select **Custom trust policy**
4. Replace the default policy with:

   ```json
   {
     "Version": "2012-10-17",
     "Statement": [
       {
         "Effect": "Allow",
         "Principal": {
           "Service": "bedrock-agentcore.amazonaws.com"
         },
         "Action": "sts:AssumeRole"
       }
     ]
   }
   ```

5. Click **Next**

### Step 3: Attach the Policy

1. Search for `VirtualMeteorologistGatewayPolicy`
2. Select the checkbox next to it
3. Click **Next**

### Step 4: Name and Create the Role

1. For **Role name**, enter `VirtualMeteorologistGatewayRole`
2. Click **Create role**

You have created the Gateway IAM role. Move to the next tab to create the
Gateway.

## Tab 2 — Create Gateway + All Targets

### Step 1: Navigate to Gateways

1. Search **Amazon Bedrock AgentCore** in the Services search bar
2. Select **Amazon Bedrock AgentCore**
3. In the left panel, under **Build**, select **Gateways**
4. Click **Create gateway**

### Step 2: Gateway Details

| Setting | Value |
|---|---|
| Gateway name | `virtual-meteorologist-gateway` |

### Step 3: Inbound Auth Configurations

For **Inbound Auth type**, select **Use IAM permissions**.

> Use IAM permissions means the agent runtime will authenticate with the
> Gateway using IAM SigV4 signing. This is the simplest auth model for
> runtime-to-gateway communication.

### Step 4: Permissions

1. Select **Use an existing service role**
2. Search for and select `VirtualMeteorologistGatewayRole`

### Step 5: Configure Target 1 (geo_coordinates)

Scroll down to the Target section:

| Setting | Value |
|---|---|
| Target name | `geo-coordinates-target` |
| Target description | Geocoding tool that converts city or place names into latitude and longitude coordinates |
| Target type | Lambda ARN |
| Lambda ARN | Paste the ARN of your `geo_coordinates` Lambda function |

> To find the Lambda ARN: open the Lambda console in a new tab, click on
> `geo_coordinates`, and copy the Function ARN from the top of the page.

**Target Schema** — For **Target schema**, select **Define as in-line
schema** and paste:

```json
[
  {
    "name": "get_coordinates",
    "description": "Search for a location by name and return its latitude, longitude, timezone, and other geographic data. Use this tool to convert city names, country names, or place names into coordinates that can be used with the weather forecast tool.",
    "inputSchema": {
      "type": "object",
      "properties": {
        "name": {
          "type": "string",
          "description": "Name of the city, town, or place to search for (e.g., 'Dallas', 'Tokyo', 'London')"
        },
        "count": {
          "type": "integer",
          "description": "Number of results to return. Default is 1."
        }
      },
      "required": ["name"]
    }
  }
]
```

**Outbound Auth** — select **IAM Role**.

### Step 6: Add Target 2 (weather_forecast)

Click **Add another target** and configure:

| Setting | Value |
|---|---|
| Target name | `weather-forecast-target` |
| Target description | Weather forecast tool that returns current conditions, hourly, and daily forecasts using coordinates |
| Target type | Lambda ARN |
| Lambda ARN | Paste the ARN of your `weather_forecast` Lambda function |

**Target Schema:**

```json
[
  {
    "name": "get_forecast",
    "description": "Get weather forecast data for a location using latitude and longitude coordinates. Returns current conditions, hourly forecasts (temperature, wind, cloud cover, precipitation probability), and daily forecasts (max/min temperature, UV index, precipitation). Use the get_coordinates tool first to obtain coordinates from a place name.",
    "inputSchema": {
      "type": "object",
      "properties": {
        "latitude": {
          "type": "number",
          "description": "WGS84 latitude coordinate (e.g., 32.78 for Dallas)"
        },
        "longitude": {
          "type": "number",
          "description": "WGS84 longitude coordinate (e.g., -96.80 for Dallas)"
        },
        "start_date": {
          "type": "string",
          "description": "Start date for the forecast in YYYY-MM-DD format"
        },
        "end_date": {
          "type": "string",
          "description": "End date for the forecast in YYYY-MM-DD format"
        },
        "timezone": {
          "type": "string",
          "description": "IANA timezone name (e.g., 'America/Chicago')"
        },
        "temperature_unit": {
          "type": "string",
          "description": "Temperature unit: 'celsius' or 'fahrenheit'. Default is celsius."
        }
      },
      "required": ["latitude", "longitude"]
    }
  }
]
```

**Outbound Auth** — select **IAM Role**.

### Step 7: Add Target 3 (date_time)

Click **Add another target** and configure:

| Setting | Value |
|---|---|
| Target name | `date-time-target` |
| Target description | Date and time tool that returns the current date, time, and day of week for a specific timezone |
| Target type | Lambda ARN |
| Lambda ARN | Paste the ARN of your `date_time` Lambda function |

**Target Schema:**

```json
[
  {
    "name": "get_current_time",
    "description": "Get the current date and time for a specific timezone. Use this tool to determine what 'today', 'tomorrow', or 'this weekend' means for the user's location. The timezone can be obtained from the get_coordinates tool.",
    "inputSchema": {
      "type": "object",
      "properties": {
        "timezone": {
          "type": "string",
          "description": "IANA timezone name (e.g., 'America/Chicago', 'Europe/London', 'Asia/Tokyo'). Default is 'UTC'."
        }
      },
      "required": ["timezone"]
    }
  }
]
```

**Outbound Auth** — select **IAM Role**.

> This target is easy to miss — `date_time` gets deployed and referenced in
> the agent's system prompt well before this step, so it's easy to forget to
> come back and register it as a Gateway target too.

### Step 8: Create the Gateway

1. Review all settings — you should see 3 targets configured
2. Click **Create gateway**
3. Wait for the Gateway and all targets to become **Ready**

### Step 9: Save the Gateway ARN

Copy the **Gateway ARN** and save it to your notepad.

> Save the Gateway ARN — you'll need it in Module 5 when configuring the
> Agent Runtime.

### Step 10: Verify All Targets

In the Gateway Targets section, you should see all three targets:

| Target Name | Lambda Function | Status |
|---|---|---|
| `geo-coordinates-target` | `geo_coordinates` | Ready |
| `weather-forecast-target` | `weather_forecast` | Ready |
| `date-time-target` | `date_time` | Ready |

## How the Agent Will Use These Tools

When a user asks *"What's the weather in Dallas tomorrow?"*, the agent will:

1. Call `get_current_time` to determine today's date and the user's timezone
2. Call `get_coordinates` with `name: "Dallas"` to get latitude, longitude, and timezone
3. Call `get_forecast` with the coordinates and date range to get the weather

The agent figures out this sequence automatically based on the tool
descriptions.

## Checkpoint

Your Gateway is fully configured with:

- ✅ Custom IAM role with all 3 Lambda ARNs
- ✅ 3 Lambda targets connected and Ready
- ✅ Tool definitions that describe each tool's purpose and inputs
- ✅ Gateway ARN saved for the Agent Runtime

Make sure you have completed both tabs above before proceeding:

- ✅ Create Gateway IAM Role — Created IAM role with Lambda invoke permissions for all 3 functions
- ✅ Create Gateway + All Targets — Created Gateway, added all 3 targets, and saved the Gateway ARN

## Next Steps

Proceed to Module 4 to create AgentCore Memory for conversation history.
