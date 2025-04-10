#!/bin/bash
set -e

echo "🧨 모든 리소스 삭제 시작합니다... 정말 진행할까요? (y/N)"
read -r answer

if [[ "$answer" != "y" && "$answer" != "Y" ]]; then
  echo "❌ 삭제 취소되었습니다."
  exit 1
fi

terraform destroy -auto-approve

echo "✅ 모든 리소스가 삭제되었습니다!"
