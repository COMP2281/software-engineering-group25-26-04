# =============================================================================
# DOCKERFILE - Backend
# =============================================================================
# Builds a production-ready image of your API.
#
# Build:  docker build -t my-api .
# Run:    docker run -p 8000:8000 my-api
# =============================================================================

FROM python:3.11-slim

# Set working directory
WORKDIR /app

# Install system dependencies (needed for psycopg2)
RUN apt-get update && apt-get install -y \
    gcc \
    libpq-dev \
    && rm -rf /var/lib/apt/lists/*

# Copy requirements first (better caching)
COPY requirements.txt .

# Install Python dependencies
RUN pip install --no-cache-dir -r requirements.txt

# Install production dependencies
RUN pip install --no-cache-dir gunicorn asyncpg psycopg2-binary

# Copy application code
COPY . .

# Expose port
EXPOSE 8000

# Run with Gunicorn + Uvicorn workers (production)
CMD ["gunicorn", "app.main:app", "-w", "4", "-k", "uvicorn.workers.UvicornWorker", "-b", "0.0.0.0:8000"]
