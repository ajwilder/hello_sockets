
let ChatRoom = {
  init() {
    let camp_id = window.campId
    let socket = window.userSocket
    let chatChannel = socket.channel(`chat_room_channel:${camp_id}`)
    chatChannel.join()
    window.chatChannel = chatChannel
    ChatRoom.scrollToBottom()
    ChatRoom.addEventListeners()
    ChatRoom.addChannelListeners()
  },
  scrollToBottom() {
    let messages = document.getElementById('campChatMessages')
    if (messages) {
      messages.scrollTop = messages.scrollHeight
    }
  },
  addEventListeners() {
    let input = document.getElementById('campChatInput')
    if (input) {
      if (!input.classList.contains('listening')) {
        input.classList.add('listening')
        input.addEventListener('keypress', (e) => {
          if (e.keyCode == 13 && e.target.value.length > 0) {
            e.preventDefault();
            ChatRoom.sendMessage(e.target.value)
            e.target.value = "";
          }
        })
      }
    }
    let submit = document.getElementById('campChatInputSubmit')
    if (input && submit) {
      if (!submit.classList.contains('listening')) {
        submit.classList.add('listening')
        submit.addEventListener('click', () => {
          let input = document.getElementById('campChatInput')
          ChatRoom.sendMessage(input.value)
          input.value = "";
        })
      }
    }
    let loadMore = document.getElementById('campChatLoadPriorMessages')
    if (loadMore) {
      if (!loadMore.classList.contains('listening')) {
        loadMore.classList.add('listening')
        loadMore.addEventListener('click', () => {
          ChatRoom.loadPriorMessages()
        })
      }
    }
  },
  sendMessage(message) {
    let channel = window.chatChannel
    channel.push('new_message', {
      message: message
    })
  },
  addChannelListeners() {
    let channel = window.chatChannel
    channel.on('new_message', (resp) => {
      let html = resp.html
      if (html) {
        let messages = document.getElementById('campChatMessages')
        const fragment = document.createRange().createContextualFragment(html)
        messages.appendChild(fragment)
        ChatRoom.scrollToBottom()
      }
    })
  },
  loadPriorMessages() {
    let messages = document.querySelectorAll('.campChatMessage')
    let channel = window.chatChannel
    channel.push("load_prior_messages", {message_count: messages.length})
      .receive('ok', (resp) => {
        let html = resp.html
        if (html) {
          let button = document.getElementById('campChatLoadPriorMessages')
          const fragment = document.createRange().createContextualFragment(html)
          button.replaceWith(fragment)
          messages[0].scrollIntoViewIfNeeded()
          ChatRoom.addEventListeners()
        }
      })
      .receive('error', (resp) => {
        console.log(resp);
      })
  }


}
export default ChatRoom
