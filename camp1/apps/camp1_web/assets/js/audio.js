import { AudioSocket } from "./audio_socket.js"
let Audio = {
  init() {
    Audio.addEventListeners()
  },
  addEventListeners() {
    let joinAudioChat = document.getElementById('joinAudioChat')
    if (joinAudioChat) {
      if (!joinAudioChat.classList.contains('listening')) {
        joinAudioChat.classList.add('listening')
        joinAudioChat.addEventListener('click', Audio.joinAudioChat)
      }
    }
    let listenIn = document.getElementById('listenIn')
    if (listenIn) {
      if (!listenIn.classList.contains('listening')) {
        listenIn.classList.add('listening')
        listenIn.addEventListener('click', Audio.listenIn)
      }
    }
    let startTheDiscussion = document.getElementById('startTheDiscussion')
    if (startTheDiscussion) {
      if (!startTheDiscussion.classList.contains('listening')) {
        startTheDiscussion.classList.add('listening')
        startTheDiscussion.addEventListener('click', Audio.startTheDiscussion)
      }
    }
    let stopStream = document.getElementById('stopStream')
    if (stopStream) {
      if (!stopStream.classList.contains('listening')) {
        stopStream.classList.add('listening')
        stopStream.addEventListener('click', Audio.stopStream)
      }
    }
  },
  listenIn(e) {
    let camp = e.target.dataset.camp
    let audioSocket = new AudioSocket(window.userToken, camp, "listening")
    audioSocket.connect()
    window["audioSocket"].onmessage = (messageEvent) => {
      console.log(messageEvent.data);
    }
    let player = new WSAudioAPI.Player({}, window["audioSocket"])
    player.start()
    window["audioPlayer"] = player
    console.log(player.getVolume());
  },
  joinAudioChat(e) {
    navigator.getUserMedia = (navigator.getUserMedia ||
      navigator.webkitGetUserMedia ||
      navigator.mozGetUserMedia ||
      navigator.msGetUserMedia);
    navigator.getUserMedia({ audio: true }, () => {}, () => {})
    let camp = e.target.dataset.camp
    let audioSocket = new AudioSocket(window.userToken, camp, "streaming")
    audioSocket.connect()
    let streamer = new WSAudioAPI.Streamer({}, window["audioSocket"])
    streamer.start()
    //   window["audioStreamer"].audioInput.context.resume()
    // })
    window["audioStreamer"] = streamer
  },
  sendMessageAudioChat(e) {
    let target = e.target
    let audioSocket = window["audioSocket"]
    audioSocket.send(JSON.stringify({action: "join", camp_id: target.dataset}))
  },
  stopStream() {
    window["audioStreamer"].stop()
  }
}
export default Audio
