#!/bin/bash
set -e

echo "🚀 [1] Cloud SQL 인프라 먼저 생성"
terraform init -input=false
terraform apply -auto-approve \
  -target=google_sql_database_instance.airflow \
  -target=google_sql_database.airflow_db \
  -target=google_sql_user.airflow \
  -target=google_service_account.cloudsql_sa \
  -target=google_service_account_key.cloudsql_sa_key \
  -target=google_project_iam_member.cloudsql_sa_binding

echo "⏳ [2] GKE 클러스터 구성"
terraform apply -auto-approve \
  -target=google_container_cluster.primary \
  -target=google_container_node_pool.primary_nodes

echo "🔑 [3] Kubeconfig 설정 중..."
gcloud container clusters get-credentials $CLUSTER_NAME \
  --region $REGION \
  --project $PROJECT_ID

echo "⏳ Waiting 5s for context sync..."
sleep 5

echo "📦 [4] 전체 확인 및 마무리 Apply"
terraform apply -auto-approve
