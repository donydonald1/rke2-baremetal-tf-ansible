apiVersion: helm.cattle.io/v1
kind: HelmChartConfig
metadata:
  name: rancher-vsphere-cpi
  namespace: kube-system
spec:
  valuesContent: |-
    vCenter:
        host: "${VSPHERE_SERVER}"
        port: 443
        insecureFlag: true
        datacenters: "${VSPHERE_DATACENTER}"
        username: "${VSPHERE_USER}"
        password: "${VSPHERE_PASSWORD}"
        credentialsSecret:
            generate: true
    # labels:
    #     region: k8s-region
    #     zone: k8s-zone
    #     k8s-zones: zones
    cloudControllerManager:
      nodeSelector:
        node-role.kubernetes.io/control-plane: "true"
      rbac:
        enabled: true
---
apiVersion: helm.cattle.io/v1
kind: HelmChartConfig
metadata:
  name: rancher-vsphere-csi
  namespace: kube-system
spec:
  valuesContent: |-
    storageClass:
        allowVolumeExpansion: false
        datastoreURL: "ds:///vmfs/volumes/6710f4aa-06cf84ea-41bc-44a84219d5e2/"
        enabled: true
        name: vsphere
        isDefault: true
    vCenter:
        host:  "${VSPHERE_SERVER}"
        port: 443
        insecureFlag: true
        clusterId:  "${CLUSTER_NAME}"
        cluster-distribution: "native"
        datacenters: "${VSPHERE_DATACENTER}"
        username: "${VSPHERE_USER}"
        password: "${VSPHERE_PASSWORD}"
        configSecret:
            name: "vsphere-config-secret"
            generate: true
    # labels:
    #     region: k8s-region
    #     zone: k8s-zone
    #     zones: k8s-zones
    #     k8s-zones: zones
    csiController:
      csiResizer:
        enabled: false
      # topologyPreferentialDatastores:
      #   enabled: true
      # improvedCsiIdempotency:
      #   enabled: true
      # improvedVolumeTopology:
      #   enabled: true
      nodeSelector:
        node-role.kubernetes.io/control-plane: "true"
