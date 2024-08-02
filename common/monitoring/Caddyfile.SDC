{$DOMAIN_SCHEME}://{$DOMAIN_NAME} {
    {$TLS_ENTRY}

    handle /grafana* {
        reverse_proxy grafana:3000
    }
}