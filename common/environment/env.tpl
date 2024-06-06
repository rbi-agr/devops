{{ range secrets "kv/" }} {{ with secret (printf "kv/%s" .) }} {{ range $k, $v := .Data.data }} 
{{ printf "%s='%s'" $k $v | trimSpace }}{{ end }}{{ end }}{{ end }}