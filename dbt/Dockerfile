FROM python:3.11-slim

WORKDIR /app

COPY packages.yml dbt_project.yml profiles.yml ./
COPY macros ./macros
COPY models ./models
COPY snapshots ./snapshots
COPY tests ./tests

RUN pip install --no-cache-dir \
    "dbt-bigquery==1.8.2" \
    "click==8.1.7" \
    && dbt deps --profiles-dir .

CMD ["dbt", "build", "--target", "gcp", "--profiles-dir", "."]
