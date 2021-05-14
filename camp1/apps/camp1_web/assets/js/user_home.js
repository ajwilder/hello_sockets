import CampNavigation from "./camp_navigation"
import YourCamps from "./your_camps"
import UserContacts from "./user_contacts"
import UserChat from "./user_chat"
import UserActivity from "./user_activity"
let UserHome = {
  init(channel) {
    window.userHomeChannel = channel
    UserHome.setEventListeners()
    CampNavigation.setHistoryReload()
    let search = window.location.search.split("=")[1]
    if (window.location.search == "") {
      // CampNavigation.expandMenu('home_explore')
    }
    if (search == null) {
      // CampNavigation.expandMenu('home_explore')
    } else {
      let search_split = search.split("&")[0]
      switch(search_split) {
        case "your_camps":
          YourCamps.init()
          break;
        case "contacts":
          UserContacts.init()
          break;
        case "chat":
          UserChat.init()
          break;
      }
    }
  },
  setEventListeners() {
    let buttonLabels = ["Contacts", "Camps", "Activity", "Private", "Explore", "Survey", "CampForm", "Chat"]
    buttonLabels.forEach((label) => {
      let button = document.getElementById(`userHome${label}`)
      if (button) {
        button.addEventListener('click', () => {
          if (!button.classList.contains('active')) {
            UserHome.makeButtonActive(button)
            UserHome[`init${label}`]()
          }
        })
      }
    })
  },
  initActivity() {
    UserHome.pushToChannel('init_activity', UserActivity.init, 'activity')
  },
  initContacts() {
    UserHome.pushToChannel('init_contacts', UserContacts.init, 'contacts')
  },
  initCamps() {
    UserHome.pushToChannel('init_camps', YourCamps.init, 'your_camps')
  },
  initPrivate() {
    UserHome.pushToChannel('init_private', null, 'private')
  },
  initExplore() {
    UserHome.pushToChannel('init_explore', null, 'home_explore')
  },
  initSurvey() {
    UserHome.pushToChannel('init_survey', null, 'survey')
  },
  initCampForm() {
    UserHome.pushToChannel('init_camp_form', null, 'camp_form')
  },
  initChat() {
    UserHome.pushToChannel('init_chat', UserChat.init, 'chat')
  },
  makeButtonActive(button) {
    let buttons = document.querySelectorAll('.user-nav-link-button');
    for (let i = 0; i < buttons.length; i++) {
      buttons[i].classList.remove('active')
    }
    button.classList.add('active')
    button.blur()
  },
  pushToChannel(message, callback = null, expanded = null) {
    let channel = window.userHomeChannel
    channel.push(message, {})
      .receive("ok", (resp) => {
        UserHome.putRespToDom(resp, 'userMainDiv')
        if (expanded) {
          CampNavigation.expandMenu(expanded)
        }
        if (callback) {
          callback()
        }
      })
      .receive("error", (resp) => {
        console.log(resp);
      })
  },
  putRespToDom(resp, id) {
    let html = resp["html"]
    if (html) {
      let mainDiv = document.getElementById(id)
      if (mainDiv) {
        const fragment = document.createRange().createContextualFragment(html)
        mainDiv.replaceWith(fragment)
      }
    } else {
      console.log(id);
    }
  },
  putElementToDom(ele, id) {
    let div = document.getElementById(id)
    if (div) {
      div.replaceWith(ele)
    }
  },
  appendRespToDom(resp, id) {
    let html = resp["html"]
    if (html) {
      let div = document.getElementById(id)
      if (div) {
        const fragment = document.createRange().createContextualFragment(html)
        div.appendChild(fragment)
      } else {
        console.log('no parent')
      }
    } else {
      location.reload()
    }
  },


}
export default UserHome
