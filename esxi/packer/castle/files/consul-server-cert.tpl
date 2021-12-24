{{- /* consul-server-cert.tpl */ -}}
{{ with secret "pki/int_consul/issue/dc1-server" "common_name=server.dc1.consul" "alt_names=HOSTNAME.server.dc1.consul,consul.service.consul,localhost" "ip_sans=ADDRESS,127.0.0.1" "ttl=4444h" }}{{ .Data.certificate }}
{{ .Data.issuing_ca }}{{ end }}