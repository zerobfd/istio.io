#!/usr/bin/env bash
# shellcheck disable=SC1090,SC2154,SC2155

# Copyright 2020 Istio Authors
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#    http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

# @setup profile=none

set -e
set -u
set -o pipefail

istioctl install --set profile=demo
_wait_for_deployment istio-system istiod

kubectl label namespace default istio-injection=enabled --overwrite

snip_before_you_begin_1
snip_before_you_begin_3

_verify_not_contains snip_envoy_passthrough_to_external_services_1 "REGISTRY_ONLY"
_verify_same snip_envoy_passthrough_to_external_services_3 "$snip_envoy_passthrough_to_external_services_3_out"

istioctl install --set profile=demo --set meshConfig.outboundTrafficPolicy.mode=REGISTRY_ONLY
_wait_for_deployment istio-system istiod
_verify_same snip_change_to_the_blockingbydefault_policy_3 "$snip_change_to_the_blockingbydefault_policy_3_out"

snip_access_an_external_http_service_1
_wait_for_istio serviceentry default httpbin-ext
_verify_elided snip_access_an_external_http_service_2 "$snip_access_an_external_http_service_2_out"
_verify_contains snip_access_an_external_http_service_3 "outbound|80||httpbin.org"

snip_access_an_external_https_service_1
_wait_for_istio serviceentry default google
_verify_same snip_access_an_external_https_service_2 "$snip_access_an_external_https_service_2_out"
_verify_contains snip_access_an_external_https_service_3 "outbound|443||www.google.com"

_verify_first_line snip_manage_traffic_to_external_services_1 "$snip_manage_traffic_to_external_services_1_out"
snip_manage_traffic_to_external_services_2
_wait_for_istio virtualservice default httpbin-ext
_verify_first_line snip_manage_traffic_to_external_services_3 "$snip_manage_traffic_to_external_services_3_out"

snip_cleanup_the_controlled_access_to_external_services_1

_verify_contains snip_minikube_docker_for_desktop_bare_metal_1 "$snip_minikube_docker_for_desktop_bare_metal_1_out"
istioctl install --set profile=demo \
                 --set meshConfig.outboundTrafficPolicy.mode=REGISTRY_ONLY --set values.global.proxy.includeIPRanges="10.96.0.0/12"
_wait_for_deployment istio-system istiod

kubectl delete po -l app=sleep
SOURCE_POD=$(kubectl get pod -l app=sleep -o jsonpath='{.items..metadata.name}')

_verify_elided snip_access_the_external_services_1 "$snip_access_the_external_services_1_out"

# @cleanup
set +e # ignore cleanup errors
snip_cleanup_the_controlled_access_to_external_services_1
snip_cleanup_1
kubectl delete ns istio-system
kubectl label namespace default istio-injection-
