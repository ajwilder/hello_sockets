import UserRT from "./user_rt"
let PrivateChat = {
  init(chat_id) {
    let channel = window[`privateChat${chat_id}`]
    if (channel) {
      // PrivateChat.updateNotifications(chat_id)
    } else {
      let socket = window.userSocket
      let chatChannel = socket.channel(`private_chat_channel:${chat_id}`)
      chatChannel.join()
      window[`privateChat${chat_id}`] = chatChannel
      PrivateChat.addChannelListeners(chat_id)
    }
    PrivateChat.scrollToBottom(chat_id)
    PrivateChat.addEventListeners()
  },
  scrollToBottom(chat_id) {
    let messages = document.getElementById(`chatWidgetMessages${chat_id}`)
    if (messages) {
      messages.scrollTop = messages.scrollHeight
    }
  },
  addEventListeners() {
    let loadMore = document.querySelectorAll('.loadPriorChatMessages')
    if (loadMore) {
      for (var i = 0; i < loadMore.length; i++) {
        if (!loadMore[i].classList.contains('listening')) {
          loadMore[i].classList.add('listening')
          loadMore[i].addEventListener('click', PrivateChat.loadPriorMessages)
        }
      }
    }
  },
  addChannelListeners(chat_id) {
    let channel = window[`privateChat${chat_id}`]
    channel.on('new_message', (resp) => {
      PrivateChat.newMessage(resp, chat_id)

    })
  },
  newMessage(resp, chat_id) {
    let html = resp.html
    if (html) {
      let widget = document.getElementById('chatWidget')
      let messages = document.getElementById(`chatWidgetMessages${chat_id}`)
      if (messages && widget.classList.contains('active')) {
        const fragment = document.createRange().createContextualFragment(html)
        messages.appendChild(fragment)
        PrivateChat.scrollToBottom(chat_id)
      } else {
        PrivateChat.addChatNotification(chat_id, 1)
      }
    }
    let new_name = resp.new_name
    let chat = resp.chat
    if (chat && new_name) {
      UserRT.updateChatName(chat, new_name)
    }
  },
  loadPriorMessages(e) {
    let chat = e.target.dataset.chat
    let messages = document.querySelectorAll(`.privateChatMessage${chat}`)
    let channel = window[`privateChat${chat}`]
    channel.push("load_prior_messages", {chat: chat, message_count: messages.length})
      .receive('ok', (resp) => {
        let html = resp.html
        if (html) {
          let button = document.getElementById(`loadPriorChatMessages${chat}`)
          const fragment = document.createRange().createContextualFragment(html)
          button.replaceWith(fragment)
          messages[0].scrollIntoViewIfNeeded()
          PrivateChat.addEventListeners()
        }
      })
      .receive('error', (resp) => {
        console.log(resp);
      })
  },
  addChatNotification(chat_id, count) {
    let chatWidgetChatName = document.getElementById(`chatWidgetChatName${chat_id}`)
    if (chatWidgetChatName) {
      let notification =  document.getElementById(`chatWidgetChatNotification${chat_id}`)
      if (notification) {
        let notifcationNumber = parseInt(notification.innerHTML)
        notification.innerHTML = notifcationNumber + count
      } else {
        let notification = document.createElement('div')
        notification.classList.add("chat-widget-chat-notification")
        notification.id = `chatWidgetChatNotification${chat_id}`
        notification.innerHTML = count
        chatWidgetChatName.appendChild(notification)
      }
    }
    let chatWidget = document.getElementById('chatWidget')
    if (chatWidget) {
      let notification =  document.getElementById('chatWidgetNotification')
      if (notification) {
        let notifcationNumber = parseInt(notification.innerHTML)
        notification.innerHTML = notifcationNumber + count
      } else {
        let notification = document.createElement('div')
        notification.classList.add("chat-widget-notification")
        notification.id = 'chatWidgetNotification'
        notification.innerHTML = count
        chatWidget.appendChild(notification)
      }
    }
  },
  updateNotifications(chat_id) {
    let notification = document.getElementById(`chatWidgetChatNotification${chat_id}`)
    if (notification) {
      let chatWidget = document.getElementById('chatWidget')
      if (chatWidget) {
        let notifcationNumber = parseInt(notification.innerHTML)
        let widgetNotification =  document.getElementById('chatWidgetNotification')
        if (widgetNotification) {
          let widgetNotifcationNumber = parseInt(widgetNotification.innerHTML)
          let newNumber = widgetNotifcationNumber - notifcationNumber
          if (newNumber < 1) {
            widgetNotification.remove()
          } else {
            widgetNotification.innerHTML = widgetNotifcationNumber - notifcationNumber
          }
        }
      }
      notification.remove()
    }
    let notification2 = document.getElementById(`chatHomeChatNotification${chat_id}`)
    if (notification2) {
      notification2.remove()
    }
  }
}
export default PrivateChat
