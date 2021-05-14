import CampNavigation from "./camp_navigation"
import Board from "./board"
import Audio from "./audio"
import Images from "./images"
import Opponents from "./opponents"
import ChatRoom from "./chat_room"
import Subcamps from "./subcamps"
import Manifesto from "./manifesto"
let UserCamp = {
  init(channel) {
    window.userCampChannel = channel
    UserCamp.setEventListeners()
    CampNavigation.setHistoryReload()
    Opponents.init()
    let search = window.location.search.split("=")[1]
    if (search == null) {
      // CampNavigation.expandMenu('overview')
    } else {
      let search_split = search.split("&")[0]
      switch(search_split) {
        case "overview":
          UserCamp.initOverview()
          break;
        case "board":
          UserCamp.initBoard()
          break;
        case "discussion":
          UserCamp.initDiscussion()
          break;
        case "opponents":
          Opponents.init()
          break;
        case "subcamps":
          Subcamps.init()
          break;
        case "manifesto":
          Manifesto.init()
          break;
      }
    }
  },
  setEventListeners() {
    let campOverviewNav = document.querySelectorAll('.campOverviewNav')
    if (campOverviewNav) {
      for (var i = 0; i < campOverviewNav.length; i++) {
        if (!campOverviewNav[i].classList.contains('listening')) {
          campOverviewNav[i].classList.add('listening')
          campOverviewNav[i].addEventListener('click', UserCamp.expandOverviewNav)
        }
      }
    }
    let campBoardNav  = document.querySelectorAll('.campBoardNav ')
    if (campBoardNav ) {
      for (var i = 0; i < campBoardNav .length; i++) {
        if (!campBoardNav [i].classList.contains('listening')) {
          campBoardNav [i].classList.add('listening')
          campBoardNav [i].addEventListener('click', UserCamp.expandBoardNav)
        }
      }
    }
    let campDiscussionNav  = document.querySelectorAll('.campDiscussionNav ')
    if (campDiscussionNav ) {
      for (var i = 0; i < campDiscussionNav .length; i++) {
        if (!campDiscussionNav [i].classList.contains('listening')) {
          campDiscussionNav [i].classList.add('listening')
          campDiscussionNav [i].addEventListener('click', UserCamp.expandDiscussionNav)
        }
      }
    }
    let campManifestoNav = document.querySelectorAll('.campManifestoNav')
    if (campManifestoNav) {
      for (var i = 0; i < campManifestoNav.length; i++) {
        if (!campManifestoNav[i].classList.contains('listening')) {
          campManifestoNav[i].classList.add('listening')
          campManifestoNav[i].addEventListener('click', UserCamp.expandManifestoNav)
        }
      }
    }
    let campMainNav = document.querySelectorAll('.campMainNav')
    if (campMainNav) {
      for (var i = 0; i < campMainNav.length; i++) {
        if (!campMainNav[i].classList.contains('listening')) {
          campMainNav[i].classList.add('listening')
          campMainNav[i].addEventListener('click', UserCamp.expandMainNav)
        }
      }
    }
  },
  expandOverviewNav(e) {
    let target = e.target
    console.log(target.dataset);
    let channel = window.userCampChannel
    channel.push("expand_overview", {action: target.dataset.action})
      .receive("ok", (resp) => {
        CampNavigation.expandSubMenu('overview', target.dataset.action)
        UserCamp.putRespToDom(resp, target.dataset.location)
        UserCamp.initOverview()
        UserCamp.makeButtonActive(target, ".campOverviewNav")
      })
      .receive("error", (resp) => {
        console.log(resp);
      })
  },
  expandBoardNav(e) {
    let target = e.target
    console.log(target.dataset);
    let channel = window.userCampChannel
    channel.push("expand_board", {action: target.dataset.action})
      .receive("ok", (resp) => {
        CampNavigation.expandSubMenu('board', target.dataset.action)
        UserCamp.putRespToDom(resp, target.dataset.location)
        UserCamp.initBoard()
        UserCamp.makeButtonActive(target, ".campBoardNav")
      })
      .receive("error", (resp) => {
        console.log(resp);
      })
  },
  expandDiscussionNav(e) {
    let target = e.target
    console.log(target.dataset);
    let channel = window.userCampChannel
    channel.push("expand_discussion", {action: target.dataset.action})
      .receive("ok", (resp) => {
        CampNavigation.expandSubMenu('discussion', target.dataset.action)
        UserCamp.putRespToDom(resp, target.dataset.location)
        UserCamp.initDiscussion()
        UserCamp.makeButtonActive(target, ".campDiscussionNav")
      })
      .receive("error", (resp) => {
        console.log(resp);
      })
  },
  expandManifestoNav(e) {
    let target = e.target
    console.log(target.dataset);
    let channel = window.userCampChannel
    channel.push("expand_manifesto", {action: target.dataset.action})
      .receive("ok", (resp) => {
        CampNavigation.expandSubMenu('manifesto', target.dataset.action)
        UserCamp.putRespToDom(resp, target.dataset.location)
        UserCamp.setEventListeners()
        UserCamp.makeButtonActive(target, ".campManifestoNav")
        Manifesto.init()
      })
      .receive("error", (resp) => {
        console.log(resp);
      })
  },
  expandMainNav(e) {
    let target = e.target
    console.log(target.dataset);
    let channel = window.userCampChannel
    channel.push("expand_menu", {expand: target.dataset.expand})
      .receive("ok", (resp) => {
        CampNavigation.expandMenu(target.dataset.expand)
        UserCamp.putRespToDom(resp, "campMainExpand")
        UserCamp.setEventListeners()
        UserCamp.makeButtonActive(target, ".campMainNav")
        switch(target.dataset.expand) {
          case "overview":
            UserCamp.initOverview()
            break;
          case "board":
            UserCamp.initBoard()
            break;
          case "discussion":
            UserCamp.initDiscussion()
            break;
          case "manifesto":
            Manifesto.init()
            break;
          case "manage":
            Subcamps.init()
            break;
        }
      })
      .receive("error", (resp) => {
        console.log(resp);
      })
  },
  initOverview() {
    Subcamps.init()
    Opponents.init()
  },
  initBoard() {
    Board.init()
  },
  initDiscussion() {
    ChatRoom.init()
    Audio.init()
  },
  initChatRoom() {
    console.log('initChatRoom');
    UserCamp.pushToChannel('init_chat_room', ChatRoom.init, "chat_room")
  },
  initImages() {
    console.log('initImages');
    UserCamp.pushToChannel('init_images', Images.init, "images")
  },
  initCreateSubcamp() {
    console.log('initCreateSubcamp');
    UserCamp.pushToChannel('init_create_subcamp', null, "create_subcamp")
  },
  initLeaveCamp() {
    console.log('initLeave');
    UserCamp.pushToChannel('init_leave', null, "leave")
  },
  initJoin() {
    console.log('initJoin');
    UserCamp.pushToChannel('init_join', null, "join")
  },
  makeButtonActive(button, buttonClass) {
    let buttons = document.querySelectorAll(buttonClass);
    for (let i = 0; i < buttons.length; i++) {
      buttons[i].classList.remove('active')
    }
    button.classList.add('active')
    button.blur()
  },
  pushToChannel(message, callback = null, expanded = null) {
    let channel = window.userCampChannel
    CampNavigation.putLoadingGif('userCampDiv')
    channel.push(message, {})
      .receive("ok", (resp) => {
        UserCamp.putRespToDom(resp, 'userCampDiv')
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
  putRespToDom(resp, id_to_replace, new_id = null) {
    let html = resp["html"]

    if (html) {
      let div = document.getElementById(id_to_replace)
      if (div) {
        const fragment = document.createRange().createContextualFragment(html)
        div.replaceWith(fragment)
        if (new_id) {
          let new_div = document.getElementById(new_id)
          if (new_div) {
            new_div.scrollIntoViewIfNeeded()
          }
        }
      }
    } else {
      console.log('nohtml');
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
      console.log('no html');
    }
  },
  prependRespToDom(resp, id) {
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
      console.log('no html');
    }
  }
}

export default UserCamp
