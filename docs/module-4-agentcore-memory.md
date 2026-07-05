# Module 4: Create AgentCore Memory

**Estimated time:** 5 minutes

## Overview

AgentCore Memory provides built-in conversation history for your agent.
Without memory, every request to the agent is independent — the agent has no
context of previous interactions. With memory, the agent can reference
earlier parts of the conversation, making interactions more natural and
contextual.

## How AgentCore Memory Works

AgentCore Memory supports two types of memory:

### Short-Term Memory (Raw Events)

Short-term memory stores the raw conversation events — user messages, agent
responses, and tool calls — within a session. This is what allows the agent
to remember what was said earlier in the same conversation.

| Concept | Description |
|---|---|
| Session | A conversation thread identified by a session ID |
| Event | A single interaction (user message, agent response, tool call) |
| Expiration | How long raw events are retained (7–365 days) |

Example: When a user asks *"What about tomorrow?"* after asking about
today's weather in Dallas, the agent uses short-term memory to know that
"tomorrow" refers to Dallas.

### Long-Term Memory (Extraction Strategies)

Long-term memory goes beyond raw events by extracting and organizing
knowledge that persists across sessions. AgentCore provides built-in
extraction strategies:

| Strategy | What It Does |
|---|---|
| Summarization | Summarizes interactions to preserve critical context and key insights |
| Semantic Knowledge | Extracts general factual knowledge, concepts, and meanings in a context-independent format |
| User Preference | Extracts user behavior patterns from conversations |
| Episodic Memory | Transforms events into structured episodes and enables the agent to learn from past actions using reflections |

> For this workshop, we configure short-term memory only. Long-term memory
> strategies are optional and can be added later for more advanced use cases
> like remembering a user's preferred temperature unit across sessions.

## What You'll Create

| Resource | Purpose |
|---|---|
| AgentCore Memory | 30-day short-term conversation memory for the virtual meteorologist |

## Steps

### Step 1: Navigate to AgentCore Memory

1. In the Amazon Bedrock AgentCore console, select **Memory** under **Build** in the left panel
2. Click **Create memory**

### Step 2: Configure Memory Details

| Setting | Value |
|---|---|
| Memory name | `virtual_meteorologist_memory` |
| Short-term memory (raw event) expiration | 30 days |

### Step 3: Additional Configurations (Optional)

Expand **Additional configurations - optional** and add:

| Setting | Value |
|---|---|
| Memory description | Conversation memory for the virtual meteorologist agent |

Leave KMS key and Long-term memory extraction strategies as default (we
won't configure long-term memory for this workshop).

### Step 4: Create the Memory

1. Review the configuration
2. Click **Create memory**
3. Wait for the Memory status to become **active**

### Step 5: Save the Memory ID

Copy the **Memory ID** and save it to your notepad.

> Save the Memory ID — you'll need it in Module 5 when configuring the Agent
> Runtime environment variables.

## How Memory Integrates with the Agent

The agent runtime code uses the `AgentCoreMemorySessionManager` from the
Bedrock AgentCore SDK. Here's what happens behind the scenes:

1. User sends a message → the session manager loads the conversation history from memory
2. Agent processes the request → the agent has full context of previous interactions
3. Agent responds → the session manager saves the new interaction to memory
4. Next request → the cycle repeats, with the agent always having context

This is handled automatically by the agent runtime code — you don't need to
manage memory manually.

## Checkpoint

You have an AgentCore Memory resource created with:

- ✅ 30-day short-term memory expiration
- ✅ Memory ID saved to notepad
