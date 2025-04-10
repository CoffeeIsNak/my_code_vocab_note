#!/bin/bash
set -e

echo "🔰 Step 0: Terraform 초기화 중..."
terraform init

echo "🛠️ Step 1: GKE 클러스터 및 VPC 리소스 생성 중..."
terraform apply -auto-approve

echo "🔧 Step 2: kubeconfig 등록 중..."
# NOTE: 실제로 헌성님 프로젝트 ID로 바꿔주세요!
gcloud container clusters get-credentials my-gke \
  --region asia-northeast3 \
  --project my-code-vocab

echo "⏳ Step 3: context 적용 대기 중... (5초)"
sleep 5

echo "🚀 Step 4: ArgoCD 추가 배포 중!"
terraform apply -auto-approve

echo "✅ 완료! GKE 클러스터가 정상적으로 설정되었습니다. kubectl로 바로 접근 가능합니다."
