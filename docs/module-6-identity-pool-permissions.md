# Module 6: Add Permissions to Identity Pool

**Estimated time:** ~5 minutes

> Includes corrections from a full run-through of the workshop — see the
> **BUG / FIX** callout below.

## Overview

Grant the Cognito Identity Pool's authenticated role permission to invoke
the AgentCore Runtime. This is what lets the frontend call the agent on
behalf of authenticated users.

## How It Works

The Identity Pool maps authenticated Cognito users to an IAM role. That role
needs the `bedrock-agentcore:InvokeAgentRuntime` permission on your agent's
ARN.

## Step 1: Navigate to the Identity Pool Role

1. In the Services search bar, search for and select **Amazon Cognito**
2. In the left panel, select **Identity pools**
3. Click on your identity pool
4. Select the **User access** tab

> **🐛 BUG / FIX — assign the existing role.**
> Under **User access**, the authenticated role isn't set by default — set
> it explicitly:
>
> 1. Click **Edit** on the authenticated role (or **User access** → **Edit role**)
> 2. Choose **Use an existing role**
> 3. Select `cognito-identity-pool-iam-role`
> 4. **Save changes**
> 5. Scroll to the **Authenticated role** section and click the role name
>    (`cognito-identity-pool-iam-role`) to open it in IAM

## Step 2: Add the AgentCore Permission

1. In the IAM console, select the **Permissions** tab
2. Click **Add permissions** → **Create inline policy**
3. Select the **JSON** tab in the Policy editor
4. Paste the following policy:

   ```json
   {
     "Version": "2012-10-17",
     "Statement": [
       {
         "Sid": "InvokeAgentCoreRuntime",
         "Effect": "Allow",
         "Action": "bedrock-agentcore:InvokeAgentRuntime",
         "Resource": [
           "REPLACE_WITH_YOUR_AGENT_RUNTIME_ARN",
           "REPLACE_WITH_YOUR_AGENT_RUNTIME_ARN/runtime-endpoint/DEFAULT"
         ]
       }
     ]
   }
   ```

5. Replace **both instances** of `REPLACE_WITH_YOUR_AGENT_RUNTIME_ARN` with
   the Agent Runtime ARN you saved in Module 5. It should look like:

   ```
   arn:aws:bedrock-agentcore:us-east-1:123456789012:runtime/virtual_meteorologist-XXXXXXXXXX
   ```

   You need **both** the runtime ARN and the runtime ARN with
   `/runtime-endpoint/DEFAULT` appended.

6. Click **Next**
7. For **Policy name**, enter a name (e.g. `invoke-agent-runtime`)
8. Click **Create policy**

## Checkpoint

The Cognito Identity Pool's authenticated role can now invoke the AgentCore
Runtime:

- ✅ Inline policy added with `InvokeAgentRuntime` permission
- ✅ Scoped to your specific Agent Runtime ARN

## Next Steps

Proceed to Module 7 to deploy the frontend and test the application.
