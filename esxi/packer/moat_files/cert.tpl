{{- /* cert.tpl */ -}}
{{ with secret "pki/intermediate/issue/hashidemos-io" "common_name=nginx.service.consul" "alt_names=moat.hashidemos.io" "ip_sans=ADDRESS" "ttl=4444h" }}
{{ .Data.certificate }}{{ end }}
{{- /* ca.tpl */ -}}
{{ with secret "pki/intermediate/issue/hashidemos-io" "common_name=nginx.service.consul" "alt_names=moat.hashidemos.io" "ip_sans=ADDRESS" "ttl=4444h" }}
{{ .Data.issuing_ca }}{{ end }}