{{- /* consul-client-cert.tpl */ -}}
{{ with secret "pki/int_consul/issue/dc1-client" "common_name=client.dc1.consul" "alt_names=HOSTNAME.client.dc1.consul,localhost" "ip_sans=ADDRESS,127.0.0.1" "ttl=4444h" }}
{{ .Data.certificate }}{{ end }}