import UserHome from "./user_home"
import PrivateChat from "./private_chat"
let UserRT = {
  init() {
    console.log('init user rt')
    let user_socket = window.userSocket
    let userRTChannel = user_socket.channel(`user_rt_channel:${window.userID}`)
    userRTChannel.join()
      .receive("ok", (resp) => {
        UserRT.setChannelListeners()
        UserRT.createChatWidget(resp.html)
        UserRT.openChats(resp.active_chats)
        UserRT.setWidgetListeners()
      })
      .receive("error", (resp) => {
        console.log("failed to join user rt channel");
        console.log(resp);
      })
    window.userRTChannel = userRTChannel
  },
  setChannelListeners() {
    let channel = window.userRTChannel
    channel.on("invitation_update", (resp) => {
      UserRT.invitationUpdate(resp)
    })
    channel.on("new_chat_invitation", (resp) => {
      UserRT.messagePopUp(resp)
    })
    channel.on("chat_update", (resp) => {
      let channel = window[`privateChat${resp.chat}`]
      if (!channel) {
        UserRT.messagePopUp(resp)
        PrivateChat.addChatNotification(resp.chat, resp.message_count)
      }
    })
  },
  invitationUpdate(resp) {
    let chat_id = resp.private_chat_id.toString()
    if (resp.invitation_status == "accepted") {
      PrivateChat.init(resp.private_chat_id)
      if (!document.getElementById(`chatWidgetChat${chat_id}`)) {
        UserHome.appendRespToDom(resp, "chatWidgetListChats")
      }
      if (resp.popup_html) {
        UserRT.messagePopUp(resp)
      } else {
        UserRT.loadChatWindow(chat_id)
      }
      UserRT.showChatWidget()
      UserRT.setWidgetListeners()
    } else {

    }
  },
  setWidgetListeners() {
    let chatWidgetIcon = document.getElementById('chatWidgetIcon')
    if (chatWidgetIcon) {
      if (!chatWidgetIcon.classList.contains('listening')) {
        chatWidgetIcon.classList.add('listening')
        chatWidgetIcon.addEventListener('click', UserRT.toggleChatWidget)
      }
    }
    let chatWidgetClose = document.getElementById('chatWidgetClose')
    if (chatWidgetClose) {
      if (!chatWidgetClose.classList.contains('listening')) {
        chatWidgetClose.classList.add('listening')
        chatWidgetClose.addEventListener('click', UserRT.toggleChatWidget)
      }
    }
    let chatWidgetNav = document.querySelectorAll('.chatWidgetNav')
    if (chatWidgetNav) {
      for (var i = 0; i < chatWidgetNav.length; i++) {
        if (!chatWidgetNav[i].classList.contains('listening')) {
          chatWidgetNav[i].classList.add('listening')
          chatWidgetNav[i].addEventListener('click', UserRT.toggleChatWidgetNav)
        }
      }
    }
    let openChatButton = document.querySelectorAll('.openChatButton')
    if (openChatButton) {
      for (var i = 0; i < openChatButton.length; i++) {
        if (!openChatButton[i].classList.contains('listening')) {
          openChatButton[i].classList.add('listening')
          openChatButton[i].addEventListener('click', UserRT.toggleChat)
        }
      }
    }
    let input = document.getElementById('chatWidgetInput')
    if (input) {
      if (!input.classList.contains('listening')) {
        input.classList.add('listening')
        input.addEventListener('keypress', UserRT.newInput)
      }
    }
    let submit = document.getElementById('chatWidgetInputSubmit')
    if (submit) {
      if (!submit.classList.contains('listening')) {
        submit.classList.add('listening')
        submit.addEventListener('click', UserRT.newSubmit)
      }
    }
  },
  toggleChatWidget() {
    let chatWidget = document.getElementById('chatWidget')
    let chatWidgetClose = document.getElementById('chatWidgetClose')
    if (chatWidget) {
      if (chatWidget.classList.contains('active')) {
        chatWidget.classList.remove('active')
        chatWidgetClose.classList.remove('active')
        UserRT.chatWindowClosed()
      } else {
        chatWidget.classList.add('active')
        chatWidgetClose.classList.add('active')
      }
    }
    let chatWidgetChatWindow =  document.getElementById('chatWidgetChatWindow')
    if (chatWidgetChatWindow && chatWidgetChatWindow.dataset.chat) {
      PrivateChat.updateNotifications(chatWidgetChatWindow.dataset.chat)
    }
  },
  showChatWidget() {
    let chatWidget = document.getElementById('chatWidget')
    if (chatWidget) {
      chatWidget.classList.remove("hidden")
    }
    let chatWidgetChatWindow =  document.getElementById('chatWidgetChatWindow')
    if (chatWidgetChatWindow && chatWidgetChatWindow.dataset.chat) {
      PrivateChat.updateNotifications(chatWidgetChatWindow.dataset.chat)
    }
  },
  openChatWidget() {
    let chatWidget = document.getElementById('chatWidget')
    let chatWidgetClose = document.getElementById('chatWidgetClose')
    if (chatWidget) {
      chatWidget.classList.add('active')
      chatWidgetClose.classList.add('active')
    }
  },
  createChatWidget(html) {
    let widget = document.getElementById('chatWidget')
    if (!widget) {
      const fragment = document.createRange().createContextualFragment(html)
      document.querySelector('body').appendChild(fragment)
      UserRT.setWidgetListeners()
    }
  },
  toggleChatWidgetNav(e) {
    let target = e.target.dataset.toggle
    let chats = document.getElementById('chatWidgetListChats')
    let chatsNav = document.getElementById('chatWidgetNavChats')
    let requests = document.getElementById('chatWidgetListRequests')
    let requestsNav = document.getElementById('chatWidgetNavRequests')
    if (chats && requests) {
      if (target == "requests") {
        chats.classList.remove('active')
        requests.classList.add('active')
        chatsNav.classList.remove('active')
        requestsNav.classList.add('active')
      } else if (target == "chats"){
        chats.classList.add('active')
        requests.classList.remove('active')
        chatsNav.classList.add('active')
        requestsNav.classList.remove('active')
      }
      requestsNav.blur()
      chatsNav.blur()
    }
    UserRT.setWidgetListeners()

  },
  toggleChat(e) {
    let chat = e.target.dataset.chat
    PrivateChat.updateNotifications(chat)
    let chatWindow = document.getElementById('chatWidgetChatWindow')
    let loadWindow = (!chatWindow || (chatWindow && chatWindow.dataset.chat != chat)) && (chat && chat != "")
    if (loadWindow) {
      UserRT.loadChatWindow(chat)
    } else if (chatWindow && chatWindow.dataset.chat == chat) {
      UserRT.notifyChat(chat)
      UserRT.openChatWidget()
    }
    if (e.target.dataset.popup && e.target.dataset.popup == "true") {
      let popups = ["chatAcceptancePopup", "chatUpdatePopup"]
      for (var i = 0; i < popups.length; i++) {
        let element = document.getElementById(`${popups[i]}${chat}`)
        if (element) {
          element.remove()
        }
      }
    }
  },
  notifyChat(chat) {
    let channel = window.userRTChannel
    channel.push('notify_chat', {chat: chat})
      .receive('ok', (resp) => {
        console.log(resp);
      })
      .receive('error', (resp) => {
        console.log(resp);
      })
  },
  loadChatWindow(chat) {
    let channel = window.userRTChannel
    channel.push('open_chat', {chat: chat})
      .receive('ok', (resp) => {
        UserHome.putRespToDom(resp, "chatWidgetChatWindow")
        UserRT.updateWidget(chat)
        UserRT.openChatWidget()
        PrivateChat.init(chat)
        UserRT.setWidgetListeners()
        UserRT.makeButtonActive(chat)
      })
      .receive('error', (resp) => {
        console.log(resp);
      })
  },
  updateWidget(chat) {
    document.getElementById('chatWidgetInner').classList.add("active")
    let chatWidgetChat = document.getElementById(`chatWidgetChat${chat}`)
    let chatWidgetListChats = document.getElementById('chatWidgetListChats')
    console.log(chatWidgetListChats);
    console.log(chatWidgetChat);
    if (chatWidgetChat && chatWidgetListChats) {
      // chatWidgetChat.remove()
      chatWidgetListChats.prepend(chatWidgetChat)
    }
  },
  makeButtonActive(chat_id) {
    let openButtons = document.querySelectorAll('.openChatButton')
    for (var i = 0; i < openButtons.length; i++) {
      if (openButtons[i].dataset.chat == chat_id) {
        openButtons[i].classList.add('active')
        openButtons[i].blur()
      } else {
        openButtons[i].classList.remove('active')
      }
    }
  },
  newInput(e) {
    if (e.keyCode == 13 && e.target.value.length > 0) {
      e.preventDefault();
      UserRT.sendMessage(e.target.dataset.chat, e.target.value)
      e.target.value = "";
    }
  },
  newSubmit(e) {
    let input = document.getElementById('chatWidgetInput')
    UserRT.sendMessage(e.target.dataset.chat, input.value)
    input.value = "";
  },
  sendMessage(chat, message) {
    let channel = window.[`privateChat${chat}`]
    channel.push('new_message', {
      message: message,
      chat: chat
    })
  },
  messagePopUp(resp) {
    let html = resp.popup_html
    if (html) {
      const fragment = document.createRange().createContextualFragment(html)
      let div = document.body.appendChild(fragment)
      UserRT.setWidgetListeners()
      setTimeout(function () {
        document.getElementById(resp.dom_id).remove()
      }, 80000);
    }
  },
  openChats(chat_objects) {
    for (var i = 0; i < chat_objects.length; i++) {
      if (chat_objects[i].type == "private") {
        PrivateChat.init(chat_objects[i].id)
      }
    }
  },
  deleteChat(chat) {
    let widgetName = document.getElementById(`chatWidgetChat${chat}`)
    if (widgetName) {widgetName.remove()}
    let widgetWindow = document.getElementById('chatWidgetChatWindow')
    if (widgetWindow && widgetWindow.dataset.chat && widgetWindow.dataset.chat == chat) {
      widgetWindow.innerHTML = ""
    }
    let chatWidgetInner = document.getElementById('chatWidgetInner')
    if (chatWidgetInner) {
      chatWidgetInner.classList.remove('active')
    }
    let channel = window.[`privateChat${chat}`]
    if (channel) {
      channel.leave()
      window.[`privateChat${chat}`] = null
    }
  },
  updateChatName(chat, name) {
    let newNames = document.querySelectorAll(`.chatName${chat}`)
    if (newNames) {
      for (var i = 0; i < newNames.length; i++) {
        newNames[i].innerHTML = name
      }
    }
  },
  chatWindowClosed() {
    let channel = window.userRTChannel
    channel.push('chat_window_closed', {})
      .receive('ok', (resp) => {
        console.log(resp);
      })
      .receive('error', (resp) => {
        console.log(resp);
      })
  }
}
export default UserRT
