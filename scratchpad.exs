curl 'http://localhost:4000/phoenix/live_reload/socket/websocket?vsn=2.0.0' \
  -H 'Pragma: no-cache' \
  -H 'Origin: http://localhost:4000' \
  -H 'Accept-Language: en-US,en;q=0.9' \
  -H 'Sec-WebSocket-Key: Rt5pwgHTi0AqhT/50gZ3Cw==' \
  -H 'User-Agent: Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_3) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/85.0.4183.102 Safari/537.36' \
  -H 'Upgrade: websocket' \
  -H 'Sec-WebSocket-Extensions: permessage-deflate; client_max_window_bits' \
  -H 'Cache-Control: no-cache' \
  -H 'Connection: Upgrade' \
  -H 'Sec-WebSocket-Version: 13' \
  --compressed -i


  HelloSocketsWeb.Endpoint.broadcast("ping", "send_ping", %{})
  HelloSocketsWeb.Endpoint.broadcast("ping", "ping", %{})
  HelloSocketsWeb.Endpoint.broadcast("ping", "request_ping", %{})
HelloSocketsWeb.Endpoint.broadcast("ping", "test", %{data: "test"})



curl -i 'http://localhost:4000/socket/websocket?token=undefined&vsn=2.0.0' \
  -H 'Pragma: no-cache' \
  -H 'Origin: http://localhost:4000' \
  -H 'Accept-Language: en-US,en;q=0.9' \
  -H 'Sec-WebSocket-Key: Vkk8I2svhdwoNhkvCZhRtg==' \
  -H 'User-Agent: Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/85.0.4183.121 Safari/537.36' \
  -H 'Upgrade: websocket' \
  -H 'Sec-WebSocket-Extensions: permessage-deflate; client_max_window_bits' \
  -H 'Cache-Control: no-cache' \
  -H 'Connection: Upgrade' \
  -H 'Sec-WebSocket-Version: 13' \
  --compressed
