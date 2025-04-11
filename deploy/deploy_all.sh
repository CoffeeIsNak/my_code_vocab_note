#!/bin/bash
set -e
trap 'echo "⚠️ 개발 시 에러 발생! 스크립트 중단."; exit 1' ERR

# =========================
# CONFIG
# =========================
KEY_JSON_PATH="./key.json"
DB_CONN_STR="postgresql+psycopg2://airflow:postgres@127.0.0.1:5432/airflowdb"

# =========================
# Check for key.json
# =========================
if [ ! -f "$KEY_JSON_PATH" ]; then
  echo "❌ key.json not found at $KEY_JSON_PATH"
  exit 1
fi

# =========================
# 1. Airflow
# =========================
echo "\n🔨 Deploying Airflow..."
NAMESPACE="airflow"
kubectl create ns $NAMESPACE --dry-run=client -o yaml | kubectl apply -f -

# Secret for Cloud SQL Proxy
kubectl delete secret cloudsql-instance-credentials -n $NAMESPACE --ignore-not-found
kubectl create secret generic cloudsql-instance-credentials \
  --from-file=key.json=$KEY_JSON_PATH \
  -n $NAMESPACE

# Secret for SQLAlchemy URI
kubectl delete secret airflow-db-secret -n $NAMESPACE --ignore-not-found
kubectl create secret generic airflow-db-secret \
  --from-literal=sql_alchemy_conn="$DB_CONN_STR" \
  -n $NAMESPACE

# Helm install
helm repo add apache-airflow https://airflow.apache.org || true
helm repo update
helm upgrade --install airflow apache-airflow/airflow \
  -f "./airflow/values.yaml" \
  -n $NAMESPACE

# =========================
# 2. Spark
# =========================
echo "\n🔨 Deploying Spark Operator & Spark Connect..."
NAMESPACE="spark"
kubectl create ns $NAMESPACE --dry-run=client -o yaml | kubectl apply -f -

# Secret for Cloud SQL Proxy (optional, if Spark apps access DB)
kubectl delete secret cloudsql-instance-credentials -n $NAMESPACE --ignore-not-found
kubectl create secret generic cloudsql-instance-credentials \
  --from-file=key.json=$KEY_JSON_PATH \
  -n $NAMESPACE

# Spark Operator 설치
helm repo add spark-operator https://googlecloudplatform.github.io/spark-on-k8s-operator || true
helm repo update
helm upgrade --install spark spark-operator/spark-operator \
  -f "./spark/values.yaml" \
  -n $NAMESPACE

# Spark Connect Server 직접 배포
kubectl apply -f ./spark/spark-connect.yaml -n $NAMESPACE

# =========================
# 3. ELK
# =========================
echo "\n🔨 Deploying ELK Stack..."
NAMESPACE="elk"
kubectl create ns $NAMESPACE --dry-run=client -o yaml | kubectl apply -f -

helm repo add elastic https://helm.elastic.co || true
helm repo update

# Elasticsearch
helm upgrade --install elasticsearch elastic/elasticsearch \
  -f "./elk/elasticsearch-values.yaml" \
  -n $NAMESPACE

# Kibana
helm upgrade --install kibana elastic/kibana \
  -f "./elk/kibana-values.yaml" \
  -n $NAMESPACE

# =========================
echo "\n📅 모든 서비스 배포 완료!"
echo "📊 kubectl get all --all-namespaces 로 확인하세요!"
