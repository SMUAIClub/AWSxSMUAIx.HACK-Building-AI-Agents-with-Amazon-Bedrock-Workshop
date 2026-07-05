"""
Amazon Bedrock AgentCore Runtime - Virtual Meteorologist Agent
Uses Strands SDK with AgentCore Gateway for weather tools and AgentCore Memory for conversation history.
"""
from bedrock_agentcore.runtime import BedrockAgentCoreApp
from bedrock_agentcore.memory.integrations.strands.config import AgentCoreMemoryConfig
from bedrock_agentcore.memory.integrations.strands.session_manager import AgentCoreMemorySessionManager
from strands import Agent
from strands.models import BedrockModel
from strands.tools.mcp import MCPClient
from botocore.credentials import Credentials
import os
import boto3
import logging
from datetime import datetime, timezone
from contextlib import asynccontextmanager
import httpx
from botocore.auth import SigV4Auth
from botocore.awsrequest import AWSRequest
from botocore.credentials import ReadOnlyCredentials
from mcp.client.streamable_http import streamablehttp_client
from typing import AsyncIterator

# Configure logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

# Initialize the AgentCore app
app = BedrockAgentCoreApp()

# Get configuration from environment
GATEWAY_ARN = os.environ.get('GATEWAY_ARN')
MEMORY_ID = os.environ.get('MEMORY_ID')
MODEL_ID = os.environ.get('MODEL_ID', 'us.anthropic.claude-3-7-sonnet-20250219-v1:0')
AWS_REGION = os.environ.get('AWS_REGION', 'us-east-1')

logger.info(f"Gateway ARN: {GATEWAY_ARN}")
logger.info(f"Model ID: {MODEL_ID}")
logger.info(f"Memory ID: {MEMORY_ID}")
logger.info(f"AWS Region: {AWS_REGION}")


# ========================================
# SigV4 Authentication for Gateway
# ========================================

class SigV4HTTPXAuth(httpx.Auth):
    """HTTPX Auth class that signs requests with AWS SigV4."""

    def __init__(self, credentials: ReadOnlyCredentials, service: str, region: str):
        self.credentials = credentials
        self.service = service
        self.region = region
        self.signer = SigV4Auth(credentials, service, region)

    def auth_flow(self, request: httpx.Request) -> AsyncIterator[httpx.Request]:
        headers = dict(request.headers)
        headers.pop("connection", None)
        aws_request = AWSRequest(
            method=request.method,
            url=str(request.url),
            data=request.content,
            headers=headers,
        )
        self.signer.add_auth(aws_request)
        request.headers.update(dict(aws_request.headers))
        yield request


@asynccontextmanager
async def streamablehttp_client_with_sigv4(url, credentials, service="bedrock-agentcore", region="us-east-1", timeout=30.0):
    """Create a streamable HTTP MCP client with SigV4 authentication."""
    auth = SigV4HTTPXAuth(credentials, service, region)
    async with streamablehttp_client(url, auth=auth, timeout=timeout) as client:
        yield client


# ========================================
# Agent Initialization
# ========================================

# Initialize Bedrock model
model = BedrockModel(model_id=MODEL_ID, region_name=AWS_REGION)

# Get AWS credentials for SigV4 signing
session = boto3.Session()
credentials = session.get_credentials()
frozen_credentials = Credentials(
    access_key=credentials.access_key,
    secret_key=credentials.secret_key,
    token=credentials.token
)

# Construct Gateway endpoint URL from ARN
gateway_id = GATEWAY_ARN.split('/')[-1] if GATEWAY_ARN else None
gateway_endpoint = f"https://{gateway_id}.gateway.bedrock-agentcore.{AWS_REGION}.amazonaws.com/mcp" if gateway_id else None
logger.info(f"Gateway Endpoint: {gateway_endpoint}")


def get_current_date_utc() -> str:
    """Get current date and time in UTC for system prompt context."""
    try:
        now = datetime.now(timezone.utc)
        return now.strftime("%Y-%m-%d (%A) %H:00 UTC")
    except Exception as e:
        logger.warning(f"Failed to get current date: {e}")
        return "Unknown"


# Global state
mcp_client = None
agent = None
mcp_tools = []
system_prompt_template = ""


def initialize_agent_with_gateway():
    """Initialize agent with Gateway tools using MCP Client with SigV4 auth."""
    global mcp_client, agent, mcp_tools, system_prompt_template

    try:
        if not gateway_endpoint:
            logger.error("Cannot initialize: Gateway endpoint not configured")
            agent = Agent(model=model, system_prompt="I'm not properly configured. Please contact support.")
            return

        logger.info("Initializing MCP Client with SigV4 authentication...")

        mcp_client = MCPClient(lambda: streamablehttp_client_with_sigv4(
            url=gateway_endpoint,
            credentials=frozen_credentials,
            service="bedrock-agentcore",
            region=AWS_REGION
        ))
        mcp_client.__enter__()

        logger.info("Listing tools from Gateway...")
        mcp_tools = mcp_client.list_tools_sync()
        logger.info(f"Retrieved {len(mcp_tools)} tools from Gateway")

        current_date = get_current_date_utc()

        system_prompt_template = f"""You are a virtual meteorologist AI assistant specialized in weather information.

Current date: {current_date}

You have access to tools for:
- Geocoding: Convert city/place names to latitude, longitude, and timezone
- Weather Forecast: Get current conditions, hourly and daily forecasts using coordinates
- Date/Time: Get the current date and time for any timezone

When a user asks about weather:
1. First use the date/time tool to determine the current date in the user's timezone
2. Use the geocoding tool to get coordinates and timezone for the location
3. Use the weather forecast tool with the coordinates and appropriate date range
4. Provide a clear, friendly response with relevant weather details

Tips:
- If the user says "today", "tomorrow", or "this weekend", use the date/time tool first
- Always get coordinates before requesting weather data
- Include temperature, precipitation, wind, and UV index when relevant
- Add weather-appropriate emojis to make responses engaging
- Suggest activities based on the weather conditions

Be concise, accurate, and friendly in your responses."""

        agent = Agent(
            model=model,
            tools=mcp_tools,
            system_prompt=system_prompt_template
        )

        logger.info("Agent created successfully with Gateway tools")

    except Exception as e:
        logger.error(f"Error initializing agent with Gateway: {e}", exc_info=True)
        agent = Agent(model=model, system_prompt="I'm having trouble accessing my tools. Please try again later.")


# Initialize on startup
logger.info("Initializing agent with Gateway-backed tools using IAM SigV4 authentication")
initialize_agent_with_gateway()


# ========================================
# Request Handler
# ========================================

@app.entrypoint
def invoke(payload):
    """Process user input and return weather analysis."""
    global agent

    user_message = payload.get("prompt", "")
    session_id = payload.get("sessionId", "default_session")
    user_id = payload.get("userId", "default_user")

    if not user_message:
        return {"error": "No prompt provided", "message": "Please provide a 'prompt' key in the input"}

    logger.info(f"Processing request - Session: {session_id}")

    agent_with_memory = agent

    if MEMORY_ID and mcp_tools:
        try:
            memory_config = AgentCoreMemoryConfig(
                memory_id=MEMORY_ID,
                session_id=session_id,
                actor_id=user_id
            )
            session_manager = AgentCoreMemorySessionManager(
                agentcore_memory_config=memory_config,
                region_name=AWS_REGION
            )
            agent_with_memory = Agent(
                model=model,
                tools=mcp_tools,
                system_prompt=system_prompt_template,
                session_manager=session_manager
            )
            logger.info("Agent configured with memory session manager")
        except Exception as e:
            logger.warning(f"Could not configure memory: {e}")
            agent_with_memory = agent

    try:
        result = agent_with_memory(user_message)

        if hasattr(result, 'message'):
            final_message = result.message
        elif hasattr(result, 'content'):
            final_message = result.content
        elif isinstance(result, str):
            final_message = result
        else:
            final_message = str(result)

        if isinstance(final_message, dict):
            if 'content' in final_message and isinstance(final_message['content'], list):
                final_message = ''.join([item.get('text', '') for item in final_message['content'] if 'text' in item])
            elif 'text' in final_message:
                final_message = final_message['text']

        logger.info("Request processed successfully")
        return {"result": final_message, "sessionId": session_id, "userId": user_id}

    except Exception as e:
        logger.error(f"Agent invocation error: {e}", exc_info=True)
        return {"error": "Agent processing failed", "message": str(e), "sessionId": session_id}


if __name__ == "__main__":
    logger.info("Starting Virtual Meteorologist Agent Runtime")
    app.run()
