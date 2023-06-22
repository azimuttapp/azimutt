# Installation Guide for Running Azimutt Container Locally

This guide will walk you through the process of running Azimutt, a containerized application, on your local machine. We will be using Docker, a platform that allows you to automate the deployment, scaling, and management of applications.

## Prerequisites

Make sure that you have Docker and Docker Compose installed on your local machine. Please refer to the [official Docker documentation](https://docs.docker.com/get-docker/) to install Docker and Docker Compose.

## Local Setup

Follow the steps below to run the Azimutt container on your local machine:

### Step 1: Clone the Azimutt repository

Clone the Azimutt repository from GitHub to your local machine.

```bash
git clone https://github.com/azimuttapp/azimutt.git
```

### Step 2: Set up Environment Variables

Navigate to the Azimutt directory:

```bash
cd azimutt
```

Copy the `.env.example` file to a new file named `.env`:

```bash
cp .env.example .env
```

Edit the `.env` file and replace the placeholder values with your actual values for each environment variable. The possible environment variables are listed in the `.env.example` file available in the repository. 

### Step 3: Pull the Docker Image

Pull the Docker image from the registry:

```bash
docker pull ghcr.io/azimuttapp/azimutt:main
```

### Step 4: Run the Docker Container

Now, we'll need to run the container using the image we've just pulled. We'll use the `--env-file` option to supply our environment variables to the container. Note that you need to replace `<path_to_your_env_file>` with the actual path to your `.env` file:

```bash
docker run -d --name azimutt \
--env-file <path_to_your_env_file> \
-p 4000:4000 \
ghcr.io/azimuttapp/azimutt:main
```

The Azimutt application should now be running on your local machine and accessible at `http://localhost:4000`.
