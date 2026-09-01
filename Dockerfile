FROM python:3.11-slim

# Install system dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential \
    libpq-dev \
    git \
    curl \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app

# Copy requirements from root and install natively
# COPY <source_on_host> <destination_in_container>
# COPY requirements.txt .
COPY requirements.txt /app
RUN pip install --no-cache-dir --upgrade pip && \
    pip install --no-cache-dir --no-binary psutil -r requirements.txt

# Copy the rest of the project source code
# COPY <source_on_host> <destination_in_container>
COPY . /app


EXPOSE 3000 8888