[k8s_master]
${master}

[k8s_worker]
%{ for ip in nodes ~}
${ip}
%{ endfor ~}

[all:vars]
ansible_ssh_extra_args='-o StrictHostKeyChecking=no'