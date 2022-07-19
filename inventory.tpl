[k8s_master]
${master}

[k8s_worker]
%{ for ip in nodes ~}
${ip}
%{ endfor ~}
