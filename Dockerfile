FROM apache/airflow:2.8.4-python3.10

USER airflow

RUN pip install --no-cache-dir \
    "apache-airflow-providers-postgres>=5.0.0,<6.0.0" \
    "psycopg2-binary>=2.9.0,<3.0.0"

USER airflow
