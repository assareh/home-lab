{{- /* cert.tpl */ -}}
{{ with secret "pki/intermediate/issue/hashidemos-io" "common_name=vault.service.consul" "alt_names=vault.hashidemos.io" "ip_sans=192.168.0.101,192.168.0.102,192.168.0.103,192.168.0.104,192.168.0.105,192.168.0.106,127.0.0.1" "ttl=4444h" }}
{{ .Data.certificate }}{{ end }}
{{- /* ca.tpl */ -}}
{{ with secret "pki/intermediate/issue/hashidemos-io" "common_name=vault.service.consul" "alt_names=vault.hashidemos.io" "ip_sans=192.168.0.101,192.168.0.102,192.168.0.103,192.168.0.104,192.168.0.105,192.168.0.106,127.0.0.1" "ttl=4444h" }}
{{ .Data.issuing_ca }}{{ end }}