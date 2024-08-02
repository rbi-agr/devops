handle /grafana* {
    reverse_proxy grafana:3000
}
