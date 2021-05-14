import UserHome from './user_home'
import UserRT from './user_rt'
import CampNavigation from "./camp_navigation"
let UserChat = {
  init(channel) {
    UserChat.setEventListeners()
  },
  setEventListeners() {

    let userChatsSearch = document.getElementById('userChatsSearch')
    if (userChatsSearch) {
      if (!userChatsSearch.classList.contains("listening")) {
        userChatsSearch.classList.add('listening')
        userChatsSearch.addEventListener('change', UserChat.searchChats)
      }
    }
    let userChatsSelect = document.getElementById('userChatsSelect')
    if (userChatsSelect) {
      if (!userChatsSelect.classList.contains("listening")) {
        userChatsSelect.classList.add('listening')
        userChatsSelect.addEventListener('change', UserChat.sortChats)
      }
    }
    let newChatSubmit = document.getElementById('newChatSubmit')
    if (newChatSubmit) {
      if (!newChatSubmit.classList.contains("listening")) {
        newChatSubmit.classList.add('listening')
        newChatSubmit.addEventListener('click', UserChat.newChatSubmit)
      }
    }
    let userChatsNav = document.querySelectorAll('.userChatsNav')
    if (userChatsNav) {
      for (var i = 0; i < userChatsNav.length; i++) {
        if (!userChatsNav[i].classList.contains('listening')) {
          userChatsNav[i].classList.add("listening")
          userChatsNav[i].addEventListener('click', UserChat.expandNavSelection)
        }
      }
    }
    let newChatContactAdd = document.querySelectorAll('.newChatContactAdd')
    if (newChatContactAdd) {
      for (var i = 0; i < newChatContactAdd.length; i++) {
        if (!newChatContactAdd[i].classList.contains('listening')) {
          newChatContactAdd[i].classList.add("listening")
          newChatContactAdd[i].addEventListener('click', UserChat.newChatContactAdd)
        }
      }
    }
    let userChatInviteResponseYes = document.querySelectorAll('.userChatInviteResponseYes')
    if (userChatInviteResponseYes) {
      for (var i = 0; i < userChatInviteResponseYes.length; i++) {
        if (!userChatInviteResponseYes[i].classList.contains('listening')) {
          userChatInviteResponseYes[i].classList.add("listening")
          userChatInviteResponseYes[i].addEventListener('click', UserChat.inviteRespondYes)
        }
      }
    }
    let userChatInviteResponseNo = document.querySelectorAll('.userChatInviteResponseNo')
    if (userChatInviteResponseNo) {
      for (var i = 0; i < userChatInviteResponseNo.length; i++) {
        if (!userChatInviteResponseNo[i].classList.contains('listening')) {
          userChatInviteResponseNo[i].classList.add("listening")
          userChatInviteResponseNo[i].addEventListener('click', UserChat.inviteRespondNo)
        }
      }
    }
    let userChatInviteDetails = document.querySelectorAll('.userChatInviteDetails')
    if (userChatInviteDetails) {
      for (var i = 0; i < userChatInviteDetails.length; i++) {
        if (!userChatInviteDetails[i].classList.contains('listening')) {
          userChatInviteDetails[i].classList.add("listening")
          userChatInviteDetails[i].addEventListener('click', UserChat.userChatInviteDetails)
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
    let editChatButton = document.querySelectorAll('.editChatButton')
    if (editChatButton) {
      for (var i = 0; i < editChatButton.length; i++) {
        if (!editChatButton[i].classList.contains('listening')) {
          editChatButton[i].classList.add('listening')
          editChatButton[i].addEventListener('click', UserChat.toggleEditChat)
        }
      }
    }
    let chatEditSubmit = document.querySelectorAll('.chatEditSubmit')
    if (chatEditSubmit) {
      for (var i = 0; i < chatEditSubmit.length; i++) {
        if (!chatEditSubmit[i].classList.contains('listening')) {
          chatEditSubmit[i].classList.add('listening')
          chatEditSubmit[i].addEventListener('click', UserChat.chatEditSubmit)
        }
      }
    }
    let leaveChatButton = document.querySelectorAll('.leaveChatButton')
    if (leaveChatButton) {
      for (var i = 0; i < leaveChatButton.length; i++) {
        if (!leaveChatButton[i].classList.contains('listening')) {
          leaveChatButton[i].classList.add('listening')
          leaveChatButton[i].addEventListener('click', UserChat.leaveChat)
        }
      }
    }
  },
  expandNavSelection(e) {
    let location = e.target.dataset.nav
    CampNavigation.expandSubMenu("chat", location)
    let channel = window.userHomeChannel
    let topic = "expand_chats_nav_" + location
    UserChat.makeNavButtonActive(e.target)
    console.log(topic);
    channel.push(topic, {})
      .receive("ok", (resp) => {
        UserHome.putRespToDom(resp, "userChatsMain")
        UserChat.init()
      })
  },
  expandChatRequests() {
    let location = "invitations"
    CampNavigation.expandSubMenu("chat", location)
    let channel = window.userHomeChannel
    let topic = "expand_chats_nav_" + location
    UserChat.makeNavButtonActive(document.getElementById('userChatsNavRequests'))
    console.log(topic);
    channel.push(topic, {})
      .receive("ok", (resp) => {
        UserHome.putRespToDom(resp, "userChatsMain")
        UserChat.init()
      })
  },
  makeNavButtonActive(button) {
    let buttons = document.querySelectorAll('.userChatsNav')
    if (buttons) {
      for (var i = 0; i < buttons.length; i++) {
        buttons[i].classList.remove("active")
      }
    }
    button.classList.add('active')
  },
  inviteRespondYes(e) {
    let channel = window.userRTChannel
    let invite = e.target.dataset.invite
    channel.push("chat_invite_yes", {invite: invite})
      .receive("ok", (resp) => {
        UserHome.putRespToDom(resp, `chatInvitation${invite}`)
        UserChat.setEventListeners()
      })
      .receive("error", (resp) => console.log(resp))
  },
  inviteRespondNo(e) {
    let channel = window.userRTChannel
    let invite = e.target.dataset.invite
    channel.push("chat_invite_no", {invite: invite})
      .receive("ok", (resp) => {
        UserHome.putRespToDom(resp, `chatInvitation${invite}`)
        UserChat.setEventListeners()
      })
      .receive("error", (resp) => console.log(resp))
  },
  sortChats(e) {
    let channel = window.userHomeChannel
    channel.push("sort_chats", {sort_by: e.target.value})
      .receive("ok", (resp) => {
        UserHome.putRespToDom(resp, "userChatsList")
        UserChat.init()
      })
      .receive("error", (resp) => {console.log(resp)})
  },
  searchChats(e) {
    let channel = window.userHomeChannel
    channel.push("search_chats", {query: e.target.value})
      .receive("ok", (resp) => {
        UserHome.putRespToDom(resp, "userChatsList")
        UserChat.init()
      })
      .receive("error", (resp) => {console.log(resp)})
  },
  userChatInviteDetails(e) {
    let chat = e.target.dataset.chat
    let channel = window.userHomeChannel
    channel.push("chat_invite_details", {chat: chat})
      .receive("ok", (resp) => {
        UserHome.putRespToDom(resp, `chatInvitationDetails${chat}`)
        UserChat.init()
      })
      .receive("error", (resp) => {console.log(resp)})
  },
  toggleEditChat(e) {
    let chat = e.target.dataset.chat
    let channel = window.userHomeChannel
    channel.push("toggle_edit_chat", {chat: chat})
      .receive("ok", (resp) => {
        UserHome.appendRespToDom(resp, `userChat${chat}`)
        UserChat.replaceButtonWithCancel(e.target)
        UserChat.init()
      })
      .receive("error", (resp) => {console.log(resp)})
  },
  chatEditSubmit(e) {
    let chat = e.target.dataset.chat
    let input = document.getElementById(`chatEditNameInput${chat}`)
    if (input && input.value != "") {
      let new_name = input.value
      let channel = window.userHomeChannel
      channel.push("chat_edit_submit", {chat: chat, new_name: new_name})
        .receive("ok", (resp) => {
          UserHome.putRespToDom(resp, `chatEditForm${chat}`)
          UserRT.updateChatName(chat, new_name)
          UserChat.init()
          let newButton = document.getElementById(`cancelEdit${chat}`)
          if (newButton) {
            newButton.click()
          }
        })
        .receive("error", (resp) => {console.log(resp)})
    }

  },
  replaceButtonWithCancel(button) {
    let newButton = document.createElement('button')
    newButton.innerHTML = "Cancel Edit"
    newButton.classList.add("button-small")
    newButton.id = `cancelEdit${button.dataset.chat}`
    button.replaceWith(newButton)
    newButton.addEventListener('click', (e) => {
      let form = document.getElementById(`chatEditForm${button.dataset.chat}`)
      if (form) {
        form.remove()
      }
      newButton.replaceWith(button)
      UserChat.init()
    })
  },
  leaveChat(e) {
    let chat = e.target.dataset.chat
    let channel = window.userHomeChannel
    channel.push("leave_chat", {chat: chat})
      .receive("ok", (resp) => {
        UserHome.putRespToDom(resp, `userChat${chat}`)
        UserRT.deleteChat(chat)
        UserChat.init()
      })
      .receive("error", (resp) => {console.log(resp)})

  },
  newChatContactAdd(e) {
    let contact = e.target.dataset.contact
    let newChatContactsList = document.getElementById('newChatContactsList')
    let newChatContact = document.getElementById(`newChatContact${contact}`)
    newChatContact.classList.add('newChatContactSelected')
    newChatContactsList.prepend(newChatContact)

    let newChatSubmitDiv = document.getElementById('newChatSubmitDiv')
    newChatSubmitDiv.classList.add('active')
    newChatContactsList.classList.add('active')
    UserChat.changeAddButtonToRemove(e.target, contact)
  },
  newChatContactRemove(contact) {
    let contactsList = document.getElementById('contactsList')
    let newChatContact = document.getElementById(`newChatContact${contact}`)
    newChatContact.classList.remove('newChatContactSelected')
    contactsList.append(newChatContact)

    let selected = document.querySelectorAll('.newChatContactSelected')
    if (selected.length == 0) {
      let newChatSubmitDiv = document.getElementById('newChatSubmitDiv')
      let newChatContactsList = document.getElementById('newChatContactsList')
      newChatSubmitDiv.classList.remove('active')
      newChatContactsList.classList.remove('active')
    }
  },
  changeAddButtonToRemove(button, contact) {
    let newButton = document.createElement('button')
    newButton.innerHTML = "Remove"
    newButton.classList.add("button-small")
    newButton.classList.add("newChatContactRemove")
    button.replaceWith(newButton)
    newButton.addEventListener('click', (e) => {
      UserChat.newChatContactRemove(contact)
      newButton.replaceWith(button)
      UserChat.init()
    })
  },
  newChatSubmit(e) {
    let nameInput = document.getElementById('newChatNameInput')
    let members = document.querySelectorAll('.newChatContactSelected')
    let contacts = Array.from(members).map((member) => {return member.dataset.contact})
    if (nameInput && nameInput.value != "" && contacts.length != 0) {
      name = nameInput.value
      let channel = window.userHomeChannel
      channel.push("new_chat", {name: name, contacts: contacts})
        .receive("ok", (resp) => {
          UserChat.expandChatRequests()
        })
        .receive("error", (resp) => {console.log(resp)})
    } else if (nameInput.value == "") {
      nameInput.focus()
    }

  }

}
export default UserChat
