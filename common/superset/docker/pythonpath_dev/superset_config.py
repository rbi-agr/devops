# Licensed to the Apache Software Foundation (ASF) under one
# or more contributor license agreements.  See the NOTICE file
# distributed with this work for additional information
# regarding copyright ownership.  The ASF licenses this file
# to you under the Apache License, Version 2.0 (the
# "License"); you may not use this file except in compliance
# with the License.  You may obtain a copy of the License at
#
#   http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing,
# software distributed under the License is distributed on an
# "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
# KIND, either express or implied.  See the License for the
# specific language governing permissions and limitations
# under the License.
#
# This file is included in the final Docker image and SHOULD be overridden when
# deploying the image to prod. Settings configured here are intended for use in local
# development environments. Also note that superset_config_docker.py is imported
# as a final step as a means to override "defaults" configured here
#
import logging
import os

from celery.schedules import crontab
from flask_caching.backends.filesystemcache import FileSystemCache

logger = logging.getLogger()

DATABASE_DIALECT = os.getenv("DATABASE_DIALECT")
DATABASE_USER = os.getenv("DATABASE_USER")
DATABASE_PASSWORD = os.getenv("DATABASE_PASSWORD")
DATABASE_HOST = os.getenv("DATABASE_HOST")
DATABASE_PORT = os.getenv("DATABASE_PORT")
DATABASE_DB = os.getenv("DATABASE_DB")

SECRET_KEY = os.getenv("SECRET_KEY")
# The SQLAlchemy connection string.
SQLALCHEMY_DATABASE_URI = (
    f"{DATABASE_DIALECT}://"
    f"{DATABASE_USER}:{DATABASE_PASSWORD}@"
    f"{DATABASE_HOST}:{DATABASE_PORT}/{DATABASE_DB}"
)

REDIS_HOST = os.getenv("REDIS_HOST", "redis")
REDIS_PORT = os.getenv("REDIS_PORT", "6379")
REDIS_CELERY_DB = os.getenv("REDIS_CELERY_DB", "5")
REDIS_RESULTS_DB = os.getenv("REDIS_RESULTS_DB", "6")

RESULTS_BACKEND = FileSystemCache("/app/superset_home/sqllab")

CACHE_CONFIG = {
    "CACHE_TYPE": "RedisCache",
    "CACHE_DEFAULT_TIMEOUT": 300,
    "CACHE_KEY_PREFIX": "superset_",
    "CACHE_REDIS_HOST": REDIS_HOST,
    "CACHE_REDIS_PORT": REDIS_PORT,
    "CACHE_REDIS_DB": REDIS_RESULTS_DB,
}
DATA_CACHE_CONFIG = CACHE_CONFIG
PUBLIC_ROLE_LIKE="Gamma"

class CeleryConfig:
    broker_url = f"redis://{REDIS_HOST}:{REDIS_PORT}/{REDIS_CELERY_DB}"
    imports = ("superset.sql_lab",)
    result_backend = f"redis://{REDIS_HOST}:{REDIS_PORT}/{REDIS_RESULTS_DB}"
    worker_prefetch_multiplier = 1
    task_acks_late = False
    beat_schedule = {
        "reports.scheduler": {
            "task": "reports.scheduler",
            "schedule": crontab(minute="*", hour="*"),
        },
        "reports.prune_log": {
            "task": "reports.prune_log",
            "schedule": crontab(minute=10, hour=0),
        },
    }

CELERY_CONFIG = CeleryConfig

FEATURE_FLAGS = {
    "ALERT_REPORTS": True,
    "DASHBOARD_FILTERS_EXPERIMENTAL": os.getenv("SUPERSET_DASHBOARD_FILTERS_EXPOSE", "false").lower() == "true", 
    "DASHBOARD_NATIVE_FILTERS_SET": os.getenv("SUPERSET_DASHBOARD_FILTERS_EXPOSE", "false").lower() == "true", 
    "DASHBOARD_NATIVE_FILTERS": os.getenv("SUPERSET_DASHBOARD_FILTERS_EXPOSE", "false").lower() == "true", 
    "DASHBOARD_CROSS_FILTERS": os.getenv("SUPERSET_DASHBOARD_FILTERS_EXPOSE", "false").lower() == "true", 
    "ENABLE_TEMPLATE_PROCESSING": os.getenv("SUPERSET_ENABLE_TEMPLATE_PROCESSING", "false").lower() == "true",
    "DASHBOARD_RBAC": os.getenv("SUPERSET_ENABLE_RBAC_ACCESS", "false").lower() == "true" 
}
ALERT_REPORTS_NOTIFICATION_DRY_RUN = True
WEBDRIVER_BASEURL = "http://superset:8088/"
# The base URL for the email report hyperlinks.
WEBDRIVER_BASEURL_USER_FRIENDLY = WEBDRIVER_BASEURL

SQLLAB_CTAS_NO_LIMIT = True

# Enable CORS
ENABLE_CORS = os.getenv("SUPERSET_ENABLE_CORS", "false").lower() == "true"
EMBEDDING_DOMAINS = os.getenv("SUPERSET_EMBEDDING_DOMAIN", "").split(",")  # Replace with your domain

# Based On Enable CORS Set CORS options
CORS_OPTIONS = {
    'supports_credentials': True,
    'allow_headers': [
        'X-CSRFToken', 'Content-Type', 'Origin', 'X-Requested-With', 'Accept',
    ],
    'resources': {
        '/superset/csrf_token/': {'origins': '*'},  
        '/api/v1/formData/': {'origins': '*'},      
        '/superset/explore_json/*': {'origins': '*'},  
        '/api/v1/query/': {'origins': '*'},        
        '/superset/fetch_datasource_metadata/': {'origins': '*'},  
    },
    'origins': "*",
}

#Content Security Policy
CONTENT_SECURITY_POLICY = {
    'default-src': ["'self'"] + EMBEDDING_DOMAINS,  
    'frame-ancestors': ["'self'"] + EMBEDDING_DOMAINS,
}


# Disable Talisman (optional, if necessary)
TALISMAN_ENABLED = os.getenv("SUPERSET_TALISMAN_ENABLED", "true").lower() == "true"

# Optionally import superset_config_docker.py (which will have been included on
# the PYTHONPATH) in order to allow for local settings to be overridden
try:
    import superset_config_docker
    from superset_config_docker import *  # noqa

    logger.info(
        f"Loaded your Docker configuration at " f"[{superset_config_docker.__file__}]"
    )
except ImportError:
    logger.info("Using default Docker config...")
