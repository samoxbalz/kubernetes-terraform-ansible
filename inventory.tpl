[k8s_master]
${master.public_ip} internal_ip=${master.ansible_host} node_name=${master.hostname}

[k8s_worker]
%{ for worker in nodes ~}
${worker.public_ip} internal_ip=${worker.ansible_host} node_name=${worker.hostname}
%{ endfor ~}
