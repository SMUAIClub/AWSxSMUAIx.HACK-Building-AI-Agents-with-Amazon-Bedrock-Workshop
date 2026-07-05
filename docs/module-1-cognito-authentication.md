# Module 1: Create Cognito Authentication

**Estimated time:** 10 minutes

## Overview

Amazon Cognito provides user identity management for your application. In
this module, you'll create a User Pool for authentication, a test user, and
an Identity Pool that provides temporary AWS credentials to invoke the
AgentCore Runtime.

## What You'll Create

- **Cognito User Pool** — Manages user sign-up and sign-in
- **Test User** — A user account for testing the application
- **Identity Pool** — Maps authenticated users to IAM roles with temporary AWS credentials

## Tab 1 — Create User Pool

### Step 1: Navigate to Cognito

1. Search **Cognito** in the Services search bar
2. Select **Cognito** from the list
3. Select **Get started for free in less than five minutes**

### Step 2: Configure the Application

1. For **Application type**, select **Single-page application (SPA)**
2. For **Name your application**, enter `VirtualMeteorologistApp`
3. For **Options for sign-in identifiers**, select **Email and Username**
4. For **Required attributes for sign-up**, select **email**
5. Scroll down and select **Create user directory**
6. Scroll down and select **Go to Overview**

### Step 3: Save Configuration Values

Navigate to the Overview page and copy the following values to a notepad —
you'll need them later:

| Value | Where to Find It |
|---|---|
| User Pool ID | Overview page, top section |
| Client ID | App clients section under Applications |

> Save both the **User Pool ID** and **Client ID** to a notepad. You'll need
> these when configuring the frontend application in Module 7.

You have successfully created the Cognito User Pool. Move to the next tab to
create a test user.

## Tab 2 — Create Test User

### Step 1: Navigate to Users

1. Click the hamburger icon to expand the side panel if not already expanded
2. Select **Amazon Cognito** to return to the main page
3. Select **User pools** and then the user pool you just created
4. In the left panel, click **Users** under User management
5. Click **Create user**

### Step 2: Create the User

Input the following for the User information:

- **User name:** `AppUser`
- **Email address:** `AppUser@mycompany.com`
- Select **Mark email address as verified**
- **Password:** `TestingGen@i@pp1`

Click **Create user**.

You have successfully created the test user. Move to the next tab to create
an Identity Pool.

## Tab 3 — Create Identity Pool

The Identity Pool provides temporary AWS credentials to authenticated users.
This is how the frontend application gets permission to invoke the
AgentCore Runtime.

### Step 1: Create the Identity Pool

1. Select **Amazon Cognito** to return to the main page
2. Select **Identity pools** from the left panel
3. Select **Create identity pool**
4. For **User access**, select **Authenticated access** and then **Amazon Cognito user pool**
5. Scroll down and select **Next**
6. For **Configure permissions**, select **Create a new IAM role**
7. For **IAM role name**, input `cognito-identity-pool-iam-role`
8. Scroll down and select **Next**
9. For **User pool ID** and **App client ID**, select the ones you created in the earlier tabs
10. Scroll down and select **Next**
11. For **Identity pool name**, input `cognito-identity-pool-vm`
12. Scroll down and select **Next**
13. Review and select **Create identity pool**

### Step 2: Save the Identity Pool ID

Copy the **Identity Pool ID** and save it to your notepad.

> You should now have three values saved: **User Pool ID**, **Client ID**,
> and **Identity Pool ID**. You'll need all three for the frontend
> configuration.

You have successfully created the Identity Pool.

## Checkpoint

At this point you should have:

- ✅ A Cognito User Pool with a test user
- ✅ An Identity Pool linked to the User Pool
- ✅ Three IDs saved: User Pool ID, Client ID, Identity Pool ID

Make sure you have completed all 3 tabs above before proceeding:

- ✅ Create User Pool — Created User Pool and saved User Pool ID + Client ID
- ✅ Create Test User — Created test user (`AppUser`)
- ✅ Create Identity Pool — Created Identity Pool and saved Identity Pool ID
