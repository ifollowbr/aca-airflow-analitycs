FROM apache/airflow:2.8.3-python3.10

USER airflow

RUN pip install --no-cache-dir \
    apache-airflow-providers-postgres \
    psycopg2-binary

USER airflow
