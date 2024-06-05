#!/bin/sh

/usr/bin/mc config host add minio ${MINIO_HOST} ${MINIO_ROOT_USER} ${MINIO_ROOT_PASSWORD};
/usr/bin/mc mb -p minio/${MINIO_LOKI_BUCKET};
mc ilm add minio/${MINIO_LOKI_BUCKET} --expire-days "${MINIO_LOKI_BUCKET_RETENTION_DAYS}"
/usr/bin/mc admin user svcacct add minio ${MINIO_ROOT_USER} --access-key ${MINIO_ACCESS_KEY} --secret-key ${MINIO_SECRET_KEY};
exit 0;