# Toss Runner's High 1기 활동

## 활동 기간 동안 알아보고자하는 주제 

- 메인 토픽은 Redis에 관한 내용

- 현재 근무하고 있는 회사의 k8s 인프라 환경에서 왜 Redis 도입을 인프라 관점에서 고민하게 되었는지?

- 그 과정에서 단일 Redis가 아닌 Redis Sentinel vs Cluster를 왜 고려했고 어떤 특징을 비교 & 정리했는지?

- Redis Sentinel에서 새 마스터 노드 선출 시, 어떻게 해당 노드로 Write 작업을 보낼 수 있게 Config를 구성할 수 있는지?

- 보안에 문제가 되지 않는 선에서 어떻게 사용하고자 했는지?

## 클러스터 구성 방법 가이드

- k8s test cluster인 kind 기반으로 쿠버네티스 구성 후, 이 환경에서 테스트 수행
