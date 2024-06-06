# Use an official Python runtime as a parent image
FROM python:3.9-slim

WORKDIR /app

#install requirements
COPY requirements.txt requirements.txt
RUN pip3 install -r requirements.txt 

# Copy the rest of the application code to the working directory
COPY . /app/

EXPOSE 8000

# https://docs.docker.com/reference/dockerfile/#healthcheck
# interval:Time between running the check
# timeout: Maximum time to allow one check to run
# start-period: Start period for the container to initialize before starting health-retries countdown
# start-interval: Time between running the check during the start period 
# retries: Consecutive failures needed to report unhealthy
#
# only exit code 1 can be used to indicate unhealthy containers
HEALTHCHECK --interval=30s \
--timeout=30s \
--start-period=10s \
--start-interval=5s \
--retries=3 \
  CMD curl -f http://localhost:3000/ || exit 1 