# Module 7: Deploy Frontend & Test

**Estimated time:** ~5 minutes

> Includes a correction found during a full run-through of the workshop that
> is **not present in the original lab guide at all** — see the **BUG / FIX**
> callout below.

Deploy the frontend with AWS Amplify and test the virtual meteorologist
end-to-end. See [`../frontend`](../frontend) for the pre-built bundle used
here.

## Tab 1 — Deploy Amplify Application

### Step 1: Download the Frontend Code

Download the pre-built frontend application (`AWS-Amplify-Frontend.zip`).

### Step 2: Create the Amplify Application

1. In the Services search bar, search for and select **AWS Amplify**
2. Click **Create new app** / **Deploy without Git**
3. Select **Deploy without Git provider** and click **Next**
4. Drag and drop the `AWS-Amplify-Frontend.zip` file
5. Click **Save and deploy**
6. Wait for deployment to complete (status changes from *Deploying* to *Deployed*)
7. Click the deployed domain / URL to open the application

> **🐛 BUG / FIX — Amplify trust policy needs updating (not in the lab guide).**
> After Amplify is deployed, the Cognito Identity Pool role's **trust
> policy** references an outdated identity pool ID, which breaks
> authenticated sign-in. Fix it manually:
>
> 1. Go to **IAM Console** → **Roles** and search for
>    `cognito-identity-pool-iam-role` (path `service-role/`)
> 2. Open the role and click the **Trust relationships** tab
> 3. Click **Edit trust policy**
> 4. Find the line: `"cognito-identity.amazonaws.com:aud": "xxxxxxx"`
> 5. Replace the existing ID with the ID found in **Cognito → Identity
>    pool → Identity pool ID**
> 6. Save the trust policy

### Step 3: Configure the Application

The app opens with a configuration screen. Enter the values you saved
throughout the workshop:

**Amazon Cognito Configuration**

| Setting | Value |
|---|---|
| User Pool ID | User Pool ID from Module 1 |
| User Pool Client ID | Client ID from Module 1 |
| Identity Pool ID | Identity Pool ID from Module 1 |
| Region | `us-east-1` |

**Amazon Bedrock AgentCore Configuration**

| Setting | Value |
|---|---|
| Agent Selection | Select **AgentCore Agent** from the dropdown |
| Agent Name | Virtual Meteorologist |
| AgentCore ARN | Agent Runtime ARN from Module 5 |
| Region | `us-east-1` |

Click **Save** to apply the configuration.

> If the app can't connect, double-check every ID and ARN against your
> notepad.

### Step 4: Log In

Use the test credentials created in Module 1 (username / password). On
first login, you'll be prompted to change the password.

**Checkpoint:** The Amplify application is deployed and you're logged in.

## Tab 2 — Test the Application

Try out the virtual meteorologist — test weather queries, conversation
memory, and international locations.

We recommend testing in Google Chrome for the best experience.

### Test 1: Basic Weather Query

```
What is the weather tomorrow in Dallas, Texas?
```

What happens behind the scenes:

1. The agent calls `get_current_time` to determine today's date
2. The agent calls `get_coordinates` with `name: "Dallas"` to get lat/long and timezone
3. The agent calls `get_forecast` with the coordinates and tomorrow's date
4. The agent formats a friendly weather response with emojis

### Test 2: Activity-Based Query

Try a question that isn't directly about weather data:

```
Can I go swimming tomorrow at the beach in Chicago?
```

The agent checks the weather conditions and provides a recommendation based
on temperature, precipitation, and wind.

### Test 3: Conversation Memory

Ask a follow-up question without repeating the location:

```
What about this weekend?
```

Because AgentCore Memory is enabled, the agent remembers you were asking
about Chicago and provides the weekend forecast for the same location.

> To verify Memory is working, go to **Amazon Bedrock AgentCore console →
> Memory → `virtual_meteorologist_memory`**. Under **Observability**, you'll
> see API invocations — this confirms the agent is reading and writing
> conversation history to Memory.

### Test 4: International Location

Try a location outside the US:

```
What's the temperature right now in Tokyo, Japan?
```

## Troubleshooting

| Issue | Solution |
|---|---|
| "Agent processing failed" | Check that the Gateway ARN and Memory ID environment variables are correct in the Agent Runtime |
| No response from agent | Verify the Agent Runtime status is **ACTIVE** in the AgentCore console |
| Authentication error | Verify the Cognito IDs in the Amplify configuration match your User Pool and Identity Pool |
| "Access denied" | Check that the Identity Pool role has the `InvokeAgentRuntime` permission (Module 6) |
| Tools not working | Verify all 3 Gateway Targets are in **Ready** status (Module 3) |

For detailed debugging, check the CloudWatch logs:

1. Go to **CloudWatch → Log groups**
2. Look for `/aws/bedrock-agentcore/runtimes/virtual_meteorologist`

## Congratulations!

You have successfully built a virtual meteorologist using Amazon Bedrock
AgentCore. Your agent can:

- ✅ Understand natural language weather queries
- ✅ Orchestrate multiple tools (geocoding, weather, date/time) automatically
- ✅ Remember conversation context across messages
- ✅ Provide friendly, emoji-rich weather responses

## Next Steps

Proceed to the Summary and Cleanup to review what you built and clean up
resources.
