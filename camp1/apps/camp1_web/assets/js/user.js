import {Socket} from "phoenix"
import UserHome from "./user_home"
import UserRT from "./user_rt"
import UserCamp from "./user_camp"
document.addEventListener('DOMContentLoaded', function () {
  let userToken = window.userToken
  let userLocation = window.userLocation
  if (userToken && userLocation && userToken != "") {
    let user_socket = new Socket("/user_socket", {
      params: {token: userToken},
      // logger: (kind, msg, data) => { console.log(`${kind}: ${msg}`, data)}
    })
    user_socket.connect()
    window.userSocket = user_socket

    UserRT.init()
    if (userLocation == "home") {

      let userHomeChannel = user_socket.channel("user_home_channel")
      userHomeChannel.join()
        .receive("ok", (resp) => {
          UserHome.init(userHomeChannel)
        })
        .receive("error", (resp) => {
          console.log("failed to join user home channel");
          console.log(resp);
        })
    } else if (userLocation == "camp") {
      let userCampChannel = user_socket.channel(`user_camp_channel:${window.campId}`)
      userCampChannel.join()
        .receive("ok", (resp) => {
          UserCamp.init(userCampChannel)
        })
        .receive("error", (resp) => {
          console.log("failed to join camp home channel");
          console.log(resp);
        })
    }
  }
})
