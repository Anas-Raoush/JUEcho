# JU Echo (juecho)

JU Echo is a Flutter-based mobile application designed to improve communication between university students, faculty, staff, and administrators by providing a structured feedback and issue-tracking system.

The application allows general users to submit feedback related to university services, while administrators can efficiently review, filter, respond to, and manage submissions through a dedicated admin interface.

The system is built using modern cloud technologies to ensure scalability, security, and real-time updates.

## Project Overview

JU Echo addresses common communication gaps in academic institutions by offering:

- A centralized platform for student feedback
- Transparent tracking of feedback status
- Efficient administrative workflows
- Secure authentication and data handling

The application supports two primary user roles:

- **General Users (Students, faculty, and staff)**
- **Admins (University services admins)**

Each role has a tailored interface and permissions.



## Key Features

### Student Features

- Secure authentication using **AWS Cognito**
- Submit feedback with:
    - Service category
    - Rating
    - Title and description
    - Optional suggestion for improvement
    - Optional file attachments stored in **Amazon S3**
- View all submitted feedback
- Track feedback status:
    - Submitted
    - Under Review
    - In Progress
    - Resolved
    - Rejected
    - More Info Needed
- Receive notifications when:
    - Submission status changes
    - Admin replies are added
- Reply to admin messages when additional information is requested

### Admin Features

- Secure admin access with role-based authorization
- Dedicated dashboards displaying:
    - Received submissions
    - Resolved issues
    - Top-rated services
    - Lowest-rated services
- Backend-powered filtering by:
    - Status
    - Service category
    - Rating
    - Urgency
- Sorting by date and priority
- Infinite scrolling using paginated backend queries
- Respond to submissions with:
    - Status updates
    - Internal notes
    - Urgency level
    - Direct replies to users
- Delete inappropriate or invalid submissions



## Admin Account Creation

Admin accounts are **created manually** and require **two steps**:

1. **Authentication Setup (AWS Cognito)**
    - The user is assigned to the **admin group** in Amazon Cognito.
    - This grants administrative permissions at the API level.

2. **Profile Storage (DynamoDB)**
    - The admin user profile is stored in **DynamoDB** by executing a **GraphQL mutation directly in the AWS AppSync console**.
    - This ensures the admin account exists in the application’s data layer and can be properly resolved by the frontend.

There is **no public sign-up for admin users**.  
This design ensures:

- Controlled administrative access
- Improved security
- Prevention of unauthorized privilege escalation



## Backend Architecture

The backend is built using **AWS Amplify (Gen 2)** and includes:

- **AWS AppSync (GraphQL API)**
    - Strongly typed schema
    - Backend filtering
    - Paginated queries using `limit` and `nextToken`
    - Real-time subscriptions
- **AWS Cognito**
    - User authentication
    - Role-based access control (Admin / General)
- **Amazon S3**
    - Secure file storage for file attachments
- **Amazon DynamoDB**
    - Scalable data storage for submissions, users, and notifications



## State Management & App Architecture

- Provider-based state management
- Clean separation of concerns:
    - Presentation layer (UI)
    - Providers (state and business logic)
    - Repositories (data access)
- Backend-driven pagination and filtering
- Optimized network usage by fetching data in batches
- Real-time updates handled via GraphQL subscriptions



## Technologies Used

- Flutter
- Dart
- AWS Amplify (Gen 2)
- AWS AppSync (GraphQL)
- AWS Cognito
- Amazon S3
- Amazon DynamoDB
- Provider (State Management)



## Amplify (Gen 2) Setup

This project uses **AWS Amplify Gen 2** to configure and manage all backend services.

To set up Amplify for this project, refer to the official AWS documentation:

- **Amplify Gen 2 Overview**  
  [https://docs.amplify.aws/gen2/](https://docs.amplify.aws/)

- **Setting up Amplify Backend**  
  [https://docs.amplify.aws/gen2/start/](https://docs.amplify.aws/react/start/)

- **Authentication with Amazon Cognito**  
  [https://docs.amplify.aws/gen2/auth/](https://docs.amplify.aws/flutter/build-a-backend/auth/)

- **GraphQL API with AWS AppSync**  
  [https://docs.amplify.aws/gen2/data/](https://docs.amplify.aws/flutter/build-a-backend/data/)

- **File Storage with Amazon S3**  
  [https://docs.amplify.aws/gen2/storage/](https://docs.amplify.aws/flutter/build-a-backend/storage/)

After configuring Amplify, the generated configuration file (`amplify_outputs.json`) is used by the Flutter application to connect to AWS services.



## Getting Started

### Prerequisites

- Flutter SDK
- Dart SDK
- Node.js (LTS)
- npm
- AWS account
- Amplify CLI



## Running the Application

After installing dependencies and configuring AWS Amplify, the application can be run on **Windows**, **Android**, or **Web** using standard Flutter run commands.


## Notes

- Flutter and AWS Amplify support additional platforms such as **iOS**, **macOS**, and **Linux**. To target these platforms, they must be enabled and built using the appropriate Flutter build commands and platform-specific tooling.
- Admin users must be manually assigned to the **admin** Cognito group and a corresponding user record must be created in DynamoDB via the AWS AppSync console.
- File uploads are securely stored in **Amazon S3** with role-based access control.
- The project follows a scalable, production-ready architecture suitable for academic and institutional environments.