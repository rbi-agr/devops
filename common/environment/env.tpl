{{ with secret "kv/env" }} {{ range $k, $v := .Data.data }} 
{{ printf "%s='%s'" $k $v | trimSpace }}{{ end }}{{ end }}