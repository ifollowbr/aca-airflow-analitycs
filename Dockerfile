FROM apache/airflow:2.8.4-python3.12

USER root
RUN pip install --no-cache-dir apache-airflow-providers-postgres psycopg2-binary
USER airflow
