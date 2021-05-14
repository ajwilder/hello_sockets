export class AudioSocket {
  constructor(token, camp, action) {
    if (window["audioSocket"]) {
      window["audioSocket"].close()
    }
    console.log("new audio socket");
    this.action = action;
    this.ws_url = `ws://localhost:4000/audio/${token}/${camp}/websocket`
    this.scheduleHeartBeat();
  }

  updated() {
    this.ws_url = this.img.dataset.binaryWsUrl;
  }

  connect() {
    console.log("audio socket connect");
    this.hasErrored = false;
    this.socket = new WebSocket(this.ws_url);
    let that = this;
    this.socket.onopen = () => { that.onOpen(); }
    this.socket.onclose = () => { that.onClose(); }
    this.socket.onerror = errorEvent => { that.onError(errorEvent); };
    // this.socket.onmessage = messageEvent => { that.onMessage(messageEvent); };
    this.attemptReopen = true;
    window["audioSocket"] = this.socket
  }

  close() {
    this.attemptReopen = false;
    if (this.socket) this.socket.close();
    this.socket = null;
    clearTimeout(this.heartBeatId);
  }

  onOpen() {
    console.log("audio socket ws opened");
    let audioSocket = window["audioSocket"]
    if (this.action == "listening") {
      audioSocket.send("listen_in")
    }
    if (this.action == "streaming") {
      audioSocket.send("streaming")
    }
  }

  onClose() {
    this.maybeReopen();
    console.log("audio socket ws closed", this);
  }

  onError(errorEvent) {
    this.hasErrored = true;
    console.log("audio socket error", errorEvent);
  }

  // onMessage(messageEvent) {
  //   if (typeof messageEvent.data != "string") {
  //       this.binaryMessage(messageEvent.data);
  //   }
  // }
  //
  // binaryMessage(content) {
  //   let oldImageUrl = this.img.src;
  //   this.imageUrl = URL.createObjectURL(content);
  //   this.img.src = this.imageUrl;
  //
  //   if (oldImageUrl.startsWith("blob:")) {
  //       URL.revokeObjectURL(oldImageUrl);
  //   }
  // }

  isSocketClosed() {
    return this.socket == null || this.socket.readyState == 3;
  };

  maybeReopen() {
    let after = this.hasErrored ? 2000 : 0;
    setTimeout(() => {
        if (this.isSocketClosed() && this.attemptReopen) this.connect();
    }, after);
  };

  scheduleHeartBeat() {
    let that = this;
    this.heartBeatId = setTimeout(function () { that.sendHeartBeat(); }, 30000);
  }

  sendHeartBeat() {
    if (this.socket) {
      // Send a heartbeat message to the server to let it know
      // we're still alive, avoiding timeout.
      this.socket.send("heartbeat");
    }
    this.scheduleHeartBeat();
  }
}
