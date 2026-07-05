# Module 5: Create Agent Runtime

**Estimated time:** 10 minutes

> Includes corrections from a full run-through of the workshop — see the
> **BUG / FIX** callouts below. These are not in the original lab guide (or
> contradict it).

## Overview

The Agent Runtime hosts your AI agent code. In this module, you'll deploy
the virtual meteorologist agent using **direct code deployment** —
uploading a pre-built ZIP package containing the Strands agent code and its
dependencies.

### How the Agent Runtime Works

The agent runtime is a Python application that:

- Connects to the Gateway via SigV4-signed MCP protocol to discover and call tools
- Uses Amazon Nova 2 Lite as the foundation model for reasoning and conversation
- Integrates with AgentCore Memory for conversation history across sessions
- Handles requests from the frontend via the `@app.entrypoint` decorator

### What's Inside the Agent Runtime Package

| File | Purpose |
|---|---|
| `main.py` | Strands agent code with Gateway integration, SigV4 auth, and Memory |
| Dependencies | `strands-agents`, `bedrock-agentcore`, `boto3`, `mcp`, `httpx` |

See [`../agent`](../agent) for the source and build script.

> **Complete the two tabs in order:** create the IAM role first, then deploy
> the runtime.

## Tab 1 — Create the Runtime IAM Role

The Agent Runtime needs an IAM role with permissions to invoke the Bedrock
model, access the Gateway, use Memory, and read from S3. Create the policy
first, then the role, then attach.

### Step 1: Create the IAM Policy

1. In the Services search bar, search for and select **IAM**
2. In the left panel, select **Policies**
3. Click **Create policy**
4. Select the **JSON** tab in the Policy editor
5. Paste the following policy:

   ```json
   {
     "Version": "2012-10-17",
     "Statement": [
       {
         "Sid": "BedrockModelAccess",
         "Effect": "Allow",
         "Action": [
           "bedrock:InvokeModel",
           "bedrock:InvokeModelWithResponseStream"
         ],
         "Resource": [
           "arn:aws:bedrock:*::foundation-model/amazon.nova-2-lite-v1:0",
           "arn:aws:bedrock:*:*:inference-profile/us.amazon.nova-2-lite-v1:0"
         ]
       },
       {
         "Sid": "GatewayAccess",
         "Effect": "Allow",
         "Action": [
           "bedrock-agentcore:InvokeGateway",
           "bedrock-agentcore:GetGateway",
           "bedrock-agentcore:ListGatewayTargets"
         ],
         "Resource": "REPLACE_WITH_YOUR_GATEWAY_ARN"
       },
       {
         "Sid": "MemoryAccess",
         "Effect": "Allow",
         "Action": [
           "bedrock-agentcore:CreateEvent",
           "bedrock-agentcore:ListEvents",
           "bedrock-agentcore:GetMemory",
           "bedrock-agentcore:DeleteEvent"
         ],
         "Resource": "REPLACE_WITH_YOUR_MEMORY_ARN"
       },
       {
         "Sid": "S3CodeAccess",
         "Effect": "Allow",
         "Action": [
           "s3:GetObject",
           "s3:GetObjectVersion"
         ],
         "Resource": "arn:aws:s3:::bedrock-agentcore-runtime-*/*"
       },
       {
         "Sid": "CloudWatchLogs",
         "Effect": "Allow",
         "Action": [
           "logs:CreateLogGroup",
           "logs:CreateLogStream",
           "logs:PutLogEvents",
           "logs:DescribeLogGroups",
           "logs:DescribeLogStreams"
         ],
         "Resource": "arn:aws:logs:us-east-1:*:log-group:/aws/bedrock-agentcore/runtimes/virtual_meteorologist*"
       }
     ]
   }
   ```

   > **🐛 BUG / FIX — remove the Converse permissions.**
   > The original lab guide's `BedrockModelAccess` statement includes
   > `bedrock:Converse` and `bedrock:ConverseStream`. **These actions do not
   > exist** — remove them from the `Action` list, keeping only
   > `bedrock:InvokeModel` and `bedrock:InvokeModelWithResponseStream` (as
   > shown in the corrected policy above). Leaving them in can cause the
   > policy to be rejected.

   **Before saving, replace the placeholders** with the actual ARNs you
   saved earlier:

   | Placeholder | Replace With | Where You Saved It |
   |---|---|---|
   | `REPLACE_WITH_YOUR_GATEWAY_ARN` | Your Gateway ARN (e.g. `arn:aws:bedrock-agentcore:us-east-1:123456789012:gateway/xxxxxxxx`) | Module 3, Step 7 |
   | `REPLACE_WITH_YOUR_MEMORY_ARN` | Your Memory ARN (e.g. `arn:aws:bedrock-agentcore:us-east-1:123456789012:memory/virtual_meteorologist-...`) | Module 4, Step 5 |

6. Click **Next**
7. For **Policy name**, enter a name (e.g. `agent-runtime-policy`)
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

1. Search for the policy you created in Step 1
2. Select the checkbox next to it
3. Click **Next**

### Step 4: Name and Create the Role

1. For **Role name**, enter a name (e.g. `agent-runtime-role`)
2. Click **Create role**

**Checkpoint:** You've created the IAM role. Move to Tab 2 to deploy the
runtime.

## Tab 2 — Deploy the Runtime

### Step 1: Download the Agent Runtime Package

Download the pre-built agent runtime ZIP (`agent-runtime.zip`). This
contains the Strands agent code (`main.py`) and all required Python
dependencies pre-packaged for ARM64.

### Step 2: Navigate to AgentCore Runtime

1. In the Amazon Bedrock AgentCore console, select **Agent Runtime** under **Runtime** in the left panel.

   > **🐛 BUG / FIX — terminology changed.**
   > The button previously labeled **Host agent/tool** in the lab guide is
   > now **Create runtime**. Click **Create runtime** instead.

### Step 3: Configure the Agent

| Setting | Value |
|---|---|
| Name | `virtual_meteorologist` |

Under **Additional details**:

| Setting | Value |
|---|---|
| Description | Virtual meteorologist agent powered by Amazon Nova 2 Lite with weather tools via AgentCore Gateway |

### Step 4: Configure the Agent Source

1. For the source type, select **Direct code deployment**
2. For the package type, select **Upload ZIP**
3. For the S3 path, leave the auto-populated value
4. Click **Browse / Choose file** and select the `agent-runtime.zip` you downloaded
5. For the entrypoint / handler, enter the value shown in the console (`main.py`)
6. For the architecture, select **ARM64**

> **Note:** The S3 bucket must be in the same region as your AgentCore
> Runtime (`us-east-1`). The console auto-creates this bucket for you.

### Step 5: Configure Execution Role

1. For the execution role, select **Use an existing role**
2. Select the role you created in Tab 1 (e.g. `agent-runtime-role`)

### Step 6: Configure Environment Variables

Expand **Advanced configurations** at the bottom of the page. Under
**Environment variables**, click **Add new variable** for each of the
following:

| Key | Value |
|---|---|
| `GATEWAY_ARN` | Gateway ARN saved in Module 3 |
| `MEMORY_ID` | Memory ID saved in Module 4 |
| `MODEL_ID` | `us.amazon.nova-2-lite-v1:0` |
| `AWS_REGION` | `us-east-1` |

Leave **Security** set to **Public**.

> Use the exact Gateway ARN and Memory ID you saved earlier — these are
> critical for the agent to connect to its tools and memory.

### Step 7: Create the Agent

1. Review all settings
2. Click **Create**
3. Wait for the agent status to become **Active** (3–5 minutes)

### Step 8: Save the Runtime ARN

You may see: *"Update your IAM execution role with all resource IDs that are
part of your Agent code."* You can safely dismiss this — the IAM policy from
Tab 1 already includes the specific Gateway and Memory ARNs the agent needs.

Once the runtime is active, copy the **Agent Runtime ARN** and save it to
your notepad — you'll need it in Module 6.

### Step 9 (Optional): Test the Agent

1. Select the endpoint and click **Test / Invoke**
2. In the input section, replace the placeholder with your question:

   ```json
   {"prompt": "What is the weather in Dallas, Texas?"}
   ```

3. Click **Run** and observe the output

If you see errors, check the CloudWatch logs under
`/aws/bedrock-agentcore/runtimes/`.

## Understanding the Agent Code

Here's what the agent runtime does when it starts up:

1. Reads `GATEWAY_ARN`, `MEMORY_ID`, `MODEL_ID` from environment variables
2. Constructs the Gateway endpoint URL from the ARN
3. Creates a Gateway client with SigV4 authentication
4. Connects to the Gateway and discovers available tools
5. Creates a Strands Agent with Amazon Nova 2 Lite, the tools, and a weather-focused system prompt
6. Waits for incoming requests via the `@app.entrypoint` decorator

When a request comes in:

1. Extracts the user message, session ID, and user ID from the payload
2. Creates a memory session manager for conversation history
3. Invokes the agent with the user message
4. The agent reasons about which tools to call and in what order
5. Returns the final response to the frontend

## Checkpoint

Your Agent Runtime is deployed and active with:

- ✅ Direct code deployment via S3 ZIP
- ✅ Connected to the Gateway for weather tools
- ✅ Memory configured for conversation history
- ✅ Agent Runtime ARN saved to notepad

## Next Steps

Proceed to Module 6 to grant the Cognito Identity Pool permission to invoke
the runtime.
