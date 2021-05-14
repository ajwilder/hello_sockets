import {Socket} from "phoenix"
import GuestSurvey from "./guest_survey"
import GuestCamp from "./guest_camp"

document.addEventListener('DOMContentLoaded', function () {
  let guestToken = window.guestToken
  let guestLocation = window.guestLocation
  if (guestToken && guestLocation && guestToken != "") {
    let guest_socket = new Socket("/guest_socket", {
      params: {token: guestToken},
      logger: (kind, msg, data) => { console.log(`${kind}: ${msg}`, data)}
    })

    guest_socket.connect()

    if (guestLocation == "survey") {
      let guestSurveyChannel = guest_socket.channel("guest_survey_channel")

      guestSurveyChannel.join()
        .receive("ok", resp => {
          console.log("joined guest survey channel", resp)
          if (!window.camp_survey) {
            GuestSurvey.init(guestSurveyChannel)
          }
        })
        .receive("error", reason => console.log("failed to join guest survey channel", reason))
    } else if (guestLocation == "camp") {
      let guestExploreCampChannel = guest_socket.channel(`guest_camp_channel:${window.campId}`)
      guestExploreCampChannel.join()
        .receive("ok", resp => {
          console.log("joined guest camp channel", resp)
          GuestCamp.init(guestExploreCampChannel)
        })
        .receive("error", resp => {
          console.log("failed to join camp channel", resp);
        })
    }

  }
})
