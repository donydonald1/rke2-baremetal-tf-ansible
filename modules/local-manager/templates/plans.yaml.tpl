---
# Doc: https://rancher.com/docs/rke2/latest/en/upgrades/automated/
# server plan
apiVersion: upgrade.cattle.io/v1
kind: Plan
metadata:
  name: rke2-server
  namespace: system-upgrade
  labels:
    rke2_upgrade: server
    pod-security.kubernetes.io/enforce: privileged
spec:
  concurrency: 1
  %{~ if version == "" ~}
  channel: https://update.rke2.io/v1-release/channels/${channel}
  %{~ else ~}
  version: ${version}
  %{~ endif ~}
  serviceAccountName: system-upgrade
  nodeSelector:
    matchExpressions:
      - {key: rke2_upgrade, operator: Exists}
      - {key: beta.kubernetes.io/os, operator: In, values: ["linux"]}
      - {key: rke2_upgrade, operator: NotIn, values: ["disabled", "false"]}
      - {key: node-role.kubernetes.io/control-plane, operator: In, values: ["true"]}
      - {key: kured, operator: NotIn, values: ["rebooting"]}
  tolerations:
    - {key: node-role.kubernetes.io/control-plane, effect: NoSchedule, operator: Exists}
    - {key: CriticalAddonsOnly, effect: NoExecute, operator: Exists}
  cordon: true
  upgrade:
    image: rancher/rke2-upgrade
