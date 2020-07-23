Feature: Storage upgrade tests
  # @author wduan@redhat.com
  # @case_id OCP-23501
  @upgrade-prepare
  @users=upuser1,upuser2
  @admin
  Scenario: Cluster operator storage should be in correct status and dynamic provisioning should work well after upgrade - prepare
    Given I switch to cluster admin pseudo user
    # Check cluster operator storage should be in correct status
    Given the expression should be true> cluster_operator('storage').condition(type: 'Progressing')['status'] == "False"
    Given the expression should be true> cluster_operator('storage').condition(type: 'Available')['status'] == "True"
    Given the expression should be true> cluster_operator('storage').condition(type: 'Degraded')['status'] == "False"
    Given the expression should be true> cluster_operator('storage').condition(type: 'Upgradeable')['status'] == "True"

    # There should be one and only one default storage class
    When I run the :get client command with:
      | resource      | clusteroperator                                                         |
      | resource_name | storage                                                                 |
      | o             | jsonpath={.status.relatedObjects[?(@.resource=="storageclasses")].name} |
    And evaluation of `@result[:response]` is stored in the :default_sc clipboard
    When I log the messages:
      | <%= cb.default_sc %> (default)  |
    When I run the :get client command with:
      | resource | storageclass |
    Then the step should succeed
    And the output should contain 1 times:
      | (default) |
    And the output should contain 1 times:
      | <%= cb.default_sc %> (default) |
    When I run the :get client command with:
      | resource | storageclass |
      | o        | yaml         |
    Then the step should succeed
    And the output should contain 1 times:
      | is-default-class: "true" |
    When I run the :get client command with:
      | resource      | storageclass         |
      | resource_name | <%= cb.default_sc %> |
      | o             | yaml                 |
    Then the step should succeed
    And the output should contain:
      | is-default-class: "true" |

    # Create deployment with default storage class
    When I run the :new_project client command with:
      | project_name | upgrade-ocp-23501 |
    When I use the "upgrade-ocp-23501" project
    Given I obtain test data file "storage/misc/pvc.json"
    When I create a dynamic pvc from "pvc.json" replacing paths:
      | ["metadata"]["name"] | mypvc01-ocp-23501 |
    Then the step should succeed
    Given I obtain test data file "storage/misc/deployment.yaml"
    When I run oc create over "deployment.yaml" replacing paths:
      | ["metadata"]["name"]                                                             | mydep01-ocp-23501 |
      | ["spec"]["template"]["metadata"]["labels"]["action"]                             | upgrade-prepare   |
      | ["spec"]["template"]["spec"]["volumes"][0]["persistentVolumeClaim"]["claimName"] | mypvc01-ocp-23501 |
    Then the step should succeed
    And a pod becomes ready with labels:
      | action=upgrade-prepare |
    When I execute on the pod:
      | touch | /mnt/storage/test-before-upgrade |
    Then the step should succeed
    When I execute on the pod:
      | ls | /mnt/storage |
    Then the output should contain:
      | test-before-upgrade |

  # @author wduan@redhat.com
  @upgrade-check
  @users=upuser1,upuser2
  @admin
  Scenario: Cluster operator storage should be in correct status and dynamic provisioning should work well after upgrade
    Given I switch to cluster admin pseudo user
    # Check storage operator version after upgraded
    Given the "storage" operator version matches the current cluster version

    # Check cluster operator storage should be in correct status
    Given the expression should be true> cluster_operator('storage').condition(type: 'Progressing')['status'] == "False"
    Given the expression should be true> cluster_operator('storage').condition(type: 'Available')['status'] == "True"
    Given the expression should be true> cluster_operator('storage').condition(type: 'Degraded')['status'] == "False"
    Given the expression should be true> cluster_operator('storage').condition(type: 'Upgradeable')['status'] == "True"

    # There should be one and only one default storage class
    When I run the :get client command with:
      | resource      | clusteroperator                                                         |
      | resource_name | storage                                                                 |
      | o             | jsonpath={.status.relatedObjects[?(@.resource=="storageclasses")].name} |
    And evaluation of `@result[:response]` is stored in the :default_sc clipboard
    When I log the messages:
      | <%= cb.default_sc %> (default)  |
    When I run the :get client command with:
      | resource | storageclass |
    Then the step should succeed
    And the output should contain 1 times:
      | (default) |
    And the output should contain 1 times:
      | <%= cb.default_sc %> (default) |
    When I run the :get client command with:
      | resource | storageclass |
      | o        | yaml         |
    Then the step should succeed
    And the output should contain 1 times:
      | is-default-class: "true" |
    When I run the :get client command with:
      | resource      | storageclass         |
      | resource_name | <%= cb.default_sc %> |
      | o             | yaml                 |
    Then the step should succeed
    And the output should contain:
      | is-default-class: "true" |

    # Check deployment and data before upgrade
    When I use the "upgrade-ocp-23501" project
    Then the step should succeed
    And a pod becomes ready with labels:
      | action=upgrade-prepare |
    When I execute on the pod:
      | touch | /mnt/storage/test-after-upgrade |
    Then the step should succeed
    When I execute on the pod:
      | ls | /mnt/storage |
    Then the output should contain:
      | test-before-upgrade |
      | test-after-upgrade  |

    # Create deployment with default storage class
    Given I obtain test data file "storage/misc/pvc.json"
    When I create a dynamic pvc from "pvc.json" replacing paths:
      | ["metadata"]["name"] | mypvc02-ocp-23501 |
    Then the step should succeed
    Given I obtain test data file "storage/misc/deployment.yaml"
    When I run oc create over "deployment.yaml" replacing paths:
      | ["metadata"]["name"]                                                             | mydep02-ocp-23501 |
      | ["spec"]["template"]["metadata"]["labels"]["action"]                             | upgrade-check     |
      | ["spec"]["template"]["spec"]["volumes"][0]["persistentVolumeClaim"]["claimName"] | mypvc02-ocp-23501 |
    Then the step should succeed
    And a pod becomes ready with labels:
      | action=upgrade-check |
    When I execute on the pod:
      | touch | /mnt/storage/test-upgrade |
    Then the step should succeed
    When I execute on the pod:
      | ls | /mnt/storage |
    Then the output should contain:
      | test-upgrade |

  # @author wduan@redhat.com
  # @case_id OCP-31331
  @upgrade-prepare
  @users=upuser1,upuser2
  @admin
  Scenario: Cluster operator storage should be in correct status after upgrade - prepare
    Given I switch to cluster admin pseudo user
    # Check cluster operator storage should be in correct status
    Given the expression should be true> cluster_operator('storage').condition(type: 'Progressing')['status'] == "False"
    Given the expression should be true> cluster_operator('storage').condition(type: 'Available')['status'] == "True"
    Given the expression should be true> cluster_operator('storage').condition(type: 'Degraded')['status'] == "False"
    Given the expression should be true> cluster_operator('storage').condition(type: 'Upgradeable')['status'] == "True"

  # @author wduan@redhat.com
  @upgrade-check
  @users=upuser1,upuser2
  @admin
  Scenario: Cluster operator storage should be in correct status after upgrade
    Given I switch to cluster admin pseudo user
    # Check storage operator version after upgraded
    Given the "storage" operator version matches the current cluster version

    # Check cluster operator storage should be in correct status
    Given the expression should be true> cluster_operator('storage').condition(type: 'Progressing')['status'] == "False"
    Given the expression should be true> cluster_operator('storage').condition(type: 'Available')['status'] == "True"
    Given the expression should be true> cluster_operator('storage').condition(type: 'Degraded')['status'] == "False"
    Given the expression should be true> cluster_operator('storage').condition(type: 'Upgradeable')['status'] == "True"

  # @author chaoyang@redhat.com
  # @case_id OCP-28630
  @upgrade-prepare
  @users=upuser1,upuser2
  @admin
  Scenario: Snapshot operator should be in available status after upgrade and can created pod with snapshot - prepare
    Given the master version >= "4.4"
 
    #Deploy csi hostpath driver 
    When I run the :new_project client command with:
      | project_name | csihostpath |
    
    Given I switch to cluster admin pseudo user		
    When I use the "csihostpath" project

    Given I obtain test data file "storage/csi/csi-rbac.yaml"   
    When I run the :apply client command with:
      | f | csi-rbac.yaml | 
    Then the step should succeed
    Given SCC "privileged" is added to the "csi-provisioner" service account
    Given SCC "privileged" is added to the "csi-attacher" service account
    Given SCC "privileged" is added to the "csi-snapshotter" service account
    Given SCC "privileged" is added to the "csi-plugin" service account

    Given I obtain test data file "storage/csi/csi-hostpath-attacher.yaml"
    When I run the :apply client command with:
      | f | csi-hostpath-attacher.yaml |
    Then the step should succeed

    Given I obtain test data file "storage/csi/csi-hostpath-driverinfo.yaml"
    When I run the :apply client command with:
      | f | csi-hostpath-driverinfo.yaml |
    Then the step should succeed

    Given I obtain test data file "storage/csi/csi-hostpath-plugin.yaml"
    When I run the :apply client command with:
      | f | csi-hostpath-plugin.yaml |
    Then the step should succeed

    Given I obtain test data file "storage/csi/csi-hostpath-provisioner.yaml"
    When I run the :apply client command with:
      | f | csi-hostpath-provisioner.yaml |
    Then the step should succeed

    Given I obtain test data file "storage/csi/csi-hostpath-snapshotter.yaml"
    When I run the :apply client command with:
      | f | csi-hostpath-snapshotter.yaml |
    Then the step should succeed

    And I wait up to 360 seconds for the steps to pass:
    """
    Given the pod named "csi-hostpath-attacher-0" is ready
    Given the pod named "csi-hostpath-provisioner-0" is ready
    Given the pod named "csi-hostpath-snapshotter-0" is ready
    Given the pod named "csi-hostpathplugin-0" is ready
    """
    
    #Create storageclass volumesnapshotclass
    Given I obtain test data file "storage/csi/csi-storageclass.yaml"
    When I run the :apply client command with:
      | f | csi-storageclass.yaml |
    Then the step should succeed

    Given I obtain test data file "storage/csi/snapshotclass.yaml"
    When I run the :apply client command with:
      | f | snapshotclass.yaml |
    Then the step should succeed

    #Create pvc/pod/volumesnapshot
    Given I obtain test data file "storage/misc/pvc-with-storageClassName.json"
    When I run oc create over "pvc-with-storageClassName.json" replacing paths:
      | ["metadata"]["name"]         | pvc-hostpath    |
      | ["spec"]["storageClassName"] | csi-hostpath-sc |

    Given I obtain test data file "storage/misc/pod.yaml"
    When I run oc create over "pod.yaml" replacing paths:
      | ["metadata"]["name"]                                         | mypod         |
      | ["spec"]["volumes"][0]["persistentVolumeClaim"]["claimName"] | pvc-hostpath  |
      | ["spec"]["containers"][0]["volumeMounts"][0]["mountPath"]    | /mnt/hostpath |
    Then the step should succeed
    Given the pod named "mypod" becomes ready

    When I execute on the pod:
      | touch | /mnt/hostpath/test-before-upgrade |
    Then the step should succeed

    Given I ensure "mypod" pod is deleted

    #Create volumesnapshot
    Given I obtain test data file "storage/csi/volumesnapshot.yaml"
    When I run oc create over "volumesnapshot.yaml" replacing paths:
      | ["metadata"]["name"]                            | pvc-hostpath-snapshot  |
      | ["spec"]["volumeSnapshotClassName"]             | csi-hostpath-snapclass |
      | ["spec"]["source"]["persistentVolumeClaimName"] | pvc-hostpath           |
    Then the step should succeed
    And I wait up to 180 seconds for the steps to pass:
    """
    When I run the :describe client command with:
      | resource | volumesnapshot        |
      | name     | pvc-hostpath-snapshot |
    Then the output should match "Ready To Use\:\s+true"
    """

  # @author chaoyang@redhat.com
  @upgrade-check
  @admin
  Scenario: Snapshot operator should be in available status after upgrade and can created pod with snapshot
    Given I switch to cluster admin pseudo user

    #Snapshot operator/controller status checking
    Given the "csi-snapshot-controller" operator version matches the current cluster version

    Given the status of condition "Degraded" for "csi-snapshot-controller" operator is: False
    Given the status of condition "Progressing" for "csi-snapshot-controller" operator is: False
    Given the status of condition "Available" for "csi-snapshot-controller" operator is: True
    Given the status of condition "Upgradeable" for "csi-snapshot-controller" operator is: True

    #Restore works
    When I use the "csihostpath" project
    Given I obtain test data file "storage/csi/restorepvc.yaml"
    Then I run oc create over "restorepvc.yaml" replacing paths:
      | ["spec"]["storageClassName"]   | csi-hostpath-sc       |
      | ["spec"]["dataSource"]["name"] | pvc-hostpath-snapshot | 
    Then the step should succeed

    Given I obtain test data file "storage/misc/pod.yaml"
    When I run oc create over "pod.yaml" replacing paths:
      | ["metadata"]["name"]                                         | mypod-restore |
      | ["spec"]["volumes"][0]["persistentVolumeClaim"]["claimName"] | restore-pvc   |
      | ["spec"]["containers"][0]["volumeMounts"][0]["mountPath"]    | /mnt/hostpath |
    Given the pod named "mypod-restore" becomes ready

    When I execute on the pod:
      | ls | /mnt/hostpath |
    Then the output should contain:
      | test-before-upgrade |      