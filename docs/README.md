# Build a Weather AI Agent with Amazon Bedrock AgentCore

AWS x SMU AI & Hack Workshop — original console-based lab instructions,
archived here module by module for reference alongside the Terraform
reconstruction in [`../terraform`](../terraform).

**Level:** 200 · **Audience:** Developers, AI/ML Engineers, Solutions
Architects · **Duration:** ~1 hour · **Region:** `us-east-1`

## Introduction

Weather affects everything — from planning a weekend hike to deciding
whether to carry an umbrella on your morning commute. We check weather apps
daily, but they give us raw data: numbers, charts, and hourly breakdowns that
we have to interpret ourselves. What if you could simply ask *"Can I go
swimming at the beach in Chicago this weekend?"* and get a thoughtful,
personalized answer?

This is where AI agents come in. Unlike traditional chatbots that simply
generate text, AI agents can reason, plan, and take action. They break down
your question into steps — figuring out today's date, looking up coordinates
for Chicago, fetching the weekend forecast — and then synthesize everything
into a clear, actionable response. The agent decides which tools to call and
in what order, all on its own.

In this workshop, you build a weather AI agent using Amazon Bedrock
AgentCore — the fully managed platform for building, deploying, and
operating AI agents at scale. AgentCore provides the infrastructure to host
your agent code, orchestrate tools through Gateways, and maintain
conversation memory — so you can focus on your agent logic instead of
managing infrastructure.

Your agent uses Amazon Nova 2 Lite as its foundation model (via Amazon
Bedrock), connects to real-time weather APIs through AWS Lambda functions
unified behind an AgentCore Gateway, and maintains conversation context
using AgentCore Memory. The frontend is built with AWS Amplify, secured by
Amazon Cognito authentication.

By the end of this workshop, you have a fully functional weather AI agent
that can answer questions like *"What's the weather tomorrow in Dallas,
Texas?"*, *"Can I go swimming at the beach in Chicago this weekend?"*, or
*"What's the temperature in Tokyo right now?"* — all powered by AgentCore.

## What You'll Learn

- How Amazon Bedrock AgentCore Runtime hosts AI agents with direct code deployment
- Creating an AgentCore Gateway to unify multiple tools behind a single endpoint
- Adding Lambda functions as Gateway Targets with tool definitions
- Using AgentCore Memory for conversation history and session management
- Building an agent with the Strands Agents SDK and Amazon Nova 2 Lite
- Connecting a frontend application to an AgentCore Runtime via Amazon Cognito

## Modules

| # | Module | Duration | Doc |
|---|---|---|---|
| 1 | Create Cognito Authentication | 10 min | [module-1-cognito-authentication.md](module-1-cognito-authentication.md) |
| 2 | Create Lambda Functions | 10 min | [module-2-lambda-functions.md](module-2-lambda-functions.md) |
| 3 | Create AgentCore Gateway & Lambda Targets | 15 min | [module-3-agentcore-gateway-targets.md](module-3-agentcore-gateway-targets.md) |
| 4 | Create AgentCore Memory | 5 min | [module-4-agentcore-memory.md](module-4-agentcore-memory.md) |
| 5 | Create Agent Runtime | 10 min | [module-5-agent-runtime.md](module-5-agent-runtime.md) |
| 6 | Add Permissions to Identity Pool | 5 min | [module-6-identity-pool-permissions.md](module-6-identity-pool-permissions.md) |
| 7 | Deploy Frontend & Test | 5 min | [module-7-frontend-deploy-test.md](module-7-frontend-deploy-test.md) |

All modules are sequential — start with Module 1 and work through in order.

Modules 5–7 include **BUG / FIX** callouts folded in from
[agentcore-weather-agent-modules-5-7.pdf](agentcore-weather-agent-modules-5-7.pdf) —
a corrections doc from a full run-through of the workshop, correcting
discrepancies found in the original lab guide (see
[bugs-and-fixes.md](bugs-and-fixes.md) for the consolidated list, and the
main [Terraform README](../README.md#documented-bugs-vs-this-terraform) for
how each one maps onto the IaC reconstruction).

## Prerequisites

- AWS Account with appropriate permissions
- A valid email address for Cognito user creation

## Outcome

Upon completion of this workshop, you will:

- Understand the core components of Amazon Bedrock AgentCore (Runtime, Gateway, Memory)
- Know how to create an AgentCore Gateway with Lambda function targets and tool definitions
- Be able to deploy an AI agent to AgentCore Runtime using direct code deployment (S3 ZIP)
- Understand how AgentCore Memory provides conversation history across sessions
- Have built and tested a complete weather AI agent with a frontend application

## Cleanup

Don't forget to clean up the environment after completing the workshop.
