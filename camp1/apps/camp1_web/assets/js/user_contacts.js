import UserHome from './user_home'
import UserRT from './user_rt'
import CampNavigation from "./camp_navigation"
let UserContacts = {
  init() {
    UserContacts.setEventListeners()
  },
  setEventListeners() {
    let userContactsSearch = document.getElementById('userContactsSearch')
    if (userContactsSearch) {
      if (!userContactsSearch.classList.contains("listening")) {
        userContactsSearch.classList.add('listening')
        userContactsSearch.addEventListener('change', UserContacts.searchContacts)
      }
    }
    let compare_buttons = document.querySelectorAll('.contactCompareButton')
    if (compare_buttons) {
      for (var i = 0; i < compare_buttons.length; i++) {
        if (!compare_buttons[i].classList.contains("listening")){
          compare_buttons[i].classList.add("listening")
          compare_buttons[i].addEventListener('click', UserContacts.showContactCompare)
        }
      }
    }
    let userContactsNav = document.querySelectorAll('.userContactsNav')
    if (userContactsNav) {
      for (var i = 0; i < userContactsNav.length; i++) {
        if (!userContactsNav[i].classList.contains('listening')) {
          userContactsNav[i].classList.add("listening")
          userContactsNav[i].addEventListener('click', UserContacts.expandNavSelection)
        }
      }
    }
    let chat_buttons = document.querySelectorAll('.contactChatButton')
    if (chat_buttons) {
      for (var i = 0; i < chat_buttons.length; i++) {
        if (!chat_buttons[i].classList.contains("listening")){
          chat_buttons[i].classList.add("listening")
          chat_buttons[i].addEventListener('click', UserContacts.showChatInvite)

        }
      }
    }
    let contactChatsButton = document.querySelectorAll('.contactChatsButton')
    if (contactChatsButton) {
      for (var i = 0; i < contactChatsButton.length; i++) {
        if (!contactChatsButton[i].classList.contains("listening")){
          contactChatsButton[i].classList.add("listening")
          contactChatsButton[i].addEventListener('click', UserContacts.showChats)

        }
      }
    }
    let back_to_contacts = document.getElementById('backToContacts')
    if (back_to_contacts) {
      if (!back_to_contacts.classList.contains("listening")){
        back_to_contacts.classList.add("listening")
        back_to_contacts.addEventListener('click', () => {
          UserHome.initContacts()
        })
      }
    }
    let userContactsSelect = document.getElementById('userContactsSelect')
    if (userContactsSelect) {
      if (!userContactsSelect.classList.contains("listening")){
        userContactsSelect.classList.add("listening")
        userContactsSelect.addEventListener('change', UserContacts.sortContacts)
      }
    }
    let contactInviteSubmit = document.getElementById('contactInviteSubmit')
    if (contactInviteSubmit) {
      if (!contactInviteSubmit.classList.contains("listening")){
        contactInviteSubmit.classList.add("listening")
        contactInviteSubmit.addEventListener('click', UserContacts.createAppInvite)
      }
    }
    let inviteToNewChat = document.querySelectorAll('.inviteToNewChat')
    if (inviteToNewChat) {
      for (var i = 0; i < inviteToNewChat.length; i++) {
        if (!inviteToNewChat[i].classList.contains("listening")){
          inviteToNewChat[i].classList.add("listening")
          inviteToNewChat[i].addEventListener('click', UserContacts.inviteToNewChat)
        }
      }
    }
    let inviteToExistingChat = document.querySelectorAll('.inviteToExistingChat')
    if (inviteToExistingChat) {
      for (var i = 0; i < inviteToExistingChat.length; i++) {
        if (!inviteToExistingChat[i].classList.contains("listening")){
          inviteToExistingChat[i].classList.add("listening")
          inviteToExistingChat[i].addEventListener('click', UserContacts.inviteToExistingChat)
        }
      }
    }
    let inviteToExistingChatExpand = document.querySelectorAll('.inviteToExistingChatExpand')
    if (inviteToExistingChatExpand) {
      for (var i = 0; i < inviteToExistingChatExpand.length; i++) {
        if (!inviteToExistingChatExpand[i].classList.contains("listening")){
          inviteToExistingChatExpand[i].classList.add("listening")
          inviteToExistingChatExpand[i].addEventListener('click', UserContacts.inviteToExistingChatExpand)
        }
      }
    }
  },
  expandNavSelection(e) {
    let location = e.target.dataset.nav
    CampNavigation.expandSubMenu("contacts", location)
    let channel = window.userHomeChannel
    let topic = "expand_contacts_nav_" + location
    UserContacts.makeNavButtonActive(e.target)
    console.log(topic);
    channel.push(topic, {})
      .receive("ok", (resp) => {
        UserHome.putRespToDom(resp, "userContactsMain")
        UserContacts.init()
      })
  },
  makeNavButtonActive(button) {
    let buttons = document.querySelectorAll('.userContactsNav')
    if (buttons) {
      for (var i = 0; i < buttons.length; i++) {
        buttons[i].classList.remove("active")
      }
    }
    button.classList.add('active')
  },
  showContactCompare(e) {
    let contact = e.target.dataset.contact
    let channel = window.userHomeChannel
    channel.push("compare_contact", {contact: contact})
      .receive("ok", (resp) => {
        let replacementId = `contactListContact${contact}`
        UserHome.putRespToDom(resp, replacementId)
        UserContacts.replaceButtonWithCancel(e.target)
        UserContacts.init()
      })
  },
  showChatInvite(e) {
    let contact = e.target.dataset.contact
    let channel = window.userHomeChannel
    channel.push("show_chat_invite", {contact: contact})
      .receive("ok", (resp) => {
        let replacementId = `contactListContact${contact}`
        UserHome.putRespToDom(resp, replacementId)
        UserContacts.replaceButtonWithCancel(e.target)
        UserContacts.init()
        UserRT.setWidgetListeners()
      })
  },
  showChats(e) {
    let contact = e.target.dataset.contact
    let channel = window.userHomeChannel
    channel.push("show_contact_chats", {contact: contact})
      .receive("ok", (resp) => {
        let replacementId = `contactListContact${contact}`
        UserHome.putRespToDom(resp, replacementId)
        UserContacts.replaceButtonWithCancel(e.target)
        UserContacts.init()
        UserRT.setWidgetListeners()
      })
  },
  replaceButtonWithCancel(button) {
    let newButton = document.createElement('button')
    newButton.innerHTML = `Hide ${button.dataset.action}`
    newButton.classList.add("button-small")
    let old_class_list = button.classList.value
    button.replaceWith(newButton)
    let other_buttons = document.querySelectorAll(`.optionsButtons${button.dataset.contact}`)
    for (var i = 0; i < other_buttons.length; i++) {
      other_buttons[i].disabled = true;
    }
    newButton.addEventListener('click', (e) => {
      let divId = document.getElementById(`contactListContact${button.dataset.contact}`)
      divId.innerHTML = ""
      divId.classList.value = ""
      let other_buttons = document.querySelectorAll(`.optionsButtons${button.dataset.contact}`)
      for (var i = 0; i < other_buttons.length; i++) {
        other_buttons[i].disabled = false;
      }
      newButton.replaceWith(button)
      UserContacts.init()
    })
  },
  inviteToExistingChatExpand(e) {
    let contact = e.target.dataset.contact
    let channel = window.userHomeChannel
    channel.push("show_all_chats", {contact: contact})
      .receive("ok", (resp) => {
        let appendId = `contactListContact${contact}`
        UserHome.appendRespToDom(resp, appendId)
        UserContacts.init()
      })
    e.target.disabled = true
  },
  inviteToNewChat(e) {
    let contact = e.target.dataset.contact
    let channel = window.userHomeChannel
    channel.push("new_chat_invite", {contact: contact})
      .receive("ok", (resp) => {
        let replacementId = `contactListContact${contact}`
        UserHome.putRespToDom(resp, replacementId)
        UserContacts.init()
      })
  },
  inviteToExistingChat(e) {
    let contact = e.target.dataset.contact
    let chat = e.target.dataset.chat
    let channel = window.userHomeChannel
    channel.push("new_chat_invite", {contact: contact, chat: chat})
      .receive("ok", (resp) => {
        let replacementId = `contactListContact${contact}`
        UserHome.putRespToDom(resp, replacementId)
        UserContacts.init()
      })
  },
  createAppInvite(e) {
    let channel = window.userHomeChannel
    let name = document.getElementById('contactInviteYourName')
    let email = document.getElementById('contactInviteTheirEmail')
    let valid = email.checkValidity()
    if (valid) {
      channel.push("new_app_invite", {name: name.value, email: email.value})
        .receive("ok", (resp) => {
          UserHome.appendRespToDom(resp, "userContactsSentInvitations")
          UserContacts.init()
          email.classList.remove("error")
          email.value = ""
        })
    } else {
      let span = document.createElement('span')
      email.classList.add("error")
      span.id = "contactInviteEmailError"
      span.innerHTML = email.validationMessage
      UserHome.putElementToDom(span, "contactInviteEmailError")
    }
  },
  sortContacts(e) {
    let channel = window.userHomeChannel
    channel.push("sort_contacts", {sort_by: e.target.value})
      .receive("ok", (resp) => {
        UserHome.putRespToDom(resp, "userContactsList")
        UserContacts.init()
      })
      .receive("error", (resp) => {console.log(resp)})
  },
  searchContacts(e) {
    let channel = window.userHomeChannel
    channel.push("search_contacts", {query: e.target.value})
      .receive("ok", (resp) => {
        UserHome.putRespToDom(resp, "userContactsList")
        UserContacts.init()
      })
      .receive("error", (resp) => {console.log(resp)})
  }
}
export default UserContacts
