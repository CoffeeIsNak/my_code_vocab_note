#!/bin/bash
set -e

echo "🚀 Step 1: Terraform Init"
terraform init

echo "🧱 Step 2: Cloud SQL + SA Key 생성"
terraform apply -auto-approve \
  -target=google_sql_database_instance.airflow \
  -target=google_sql_database.airflow_db \
  -target=google_sql_user.airflow \
  -target=google_service_account.cloudsql_sa \
  -target=google_service_account_key.cloudsql_sa_key \
  -target=google_project_iam_member.cloudsql_sa_binding \
  -target=local_file.cloudsql_key_file

echo "🛰️ Step 3: GKE 클러스터 생성"
terraform apply -auto-approve \
  -target=google_container_cluster.primary \
  -target=google_container_node_pool.primary_nodes

echo "🔧 Step 4: kubeconfig 등록"
CLUSTER_NAME=$(terraform output -raw gke_cluster_name)
REGION=$(terraform output -raw gke_cluster_region)
PROJECT_ID=$(terraform output -raw project_id)

gcloud container clusters get-credentials "$CLUSTER_NAME" \
  --region "$REGION" \
  --project "$PROJECT_ID"


echo "⏳ Waiting 5s for context sync..."
sleep 5

echo "✅ 완료: GKE 접근 가능. key.json은 deploy/로 이동됨"
