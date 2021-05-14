import GuestResults from "./guest_results"
let GuestSurvey = {

  init(channel) {
    window.camp_survey = {}
    window.camp_survey.items = document.querySelectorAll('.survey-item')
    window.camp_survey.totalItems = window.camp_survey.items.length
    window.camp_survey.slide = 0
    window.camp_survey.moving = false
    window.camp_survey.channel = channel
    window.camp_survey.results = {}
    GuestSurvey.setCookie('campRatings', "", 2)
    GuestSurvey.setInitialClasses();
    GuestSurvey.setEventListeners();
  },

  setInitialClasses() {
    window.camp_survey.items[window.camp_survey.totalItems - 1].classList.add('prev')
    window.camp_survey.items[0].classList.add('active')
    window.camp_survey.items[1].classList.add('next')
  },

  setEventListeners() {
    let buttons = document.querySelectorAll(".button-camp_survey")
    buttons.forEach((button) => {
      button.addEventListener('click', () => {
        if (!window.camp_survey.moving) {
          GuestSurvey.initTopicRating( button)
        }
        GuestSurvey.moveNext()
      })
    })
  },

  moveGuestSurveyTo(slide) {
    if (!window.camp_survey.moving) {
      GuestSurvey.disableInteraction()

      let prev = document.querySelector('.prev')
      let active = document.querySelector('.active')
      let next = document.querySelector('.next')

      if (prev) {
        prev.classList.remove(['prev'])

      }
      next.classList.remove(['next'])
      active.classList.remove(['active'])
      active.classList.add(['prev'])
      next.classList.add(['active'])
    }
  },

  moveNext() {
    if (!window.camp_survey.moving) {
      if (window.camp_survey.slide === (window.camp_survey.totalItems - 1)) {
        window.camp_survey.slide = 0
      } else {
        window.camp_survey.slide++
      }
      GuestSurvey.moveGuestSurveyTo(window.camp_survey.slide)
    }
  },

  movePrev() {
    if (!window.camp_survey.moving) {
      if (window.camp_survey.slide === 0) {
        window.camp_survey.slide = window.camp_survey.totalItems - 1
      } else {
        window.camp_survey.slide--
      }
      GuestSurvey.moveGuestSurveyTo(window.camp_survey.slide)
    }
  },

  disableInteraction() {
    window.camp_survey.moving = true
    setTimeout(function() {
      window.camp_survey.moving = false
    }, 500)
  },

  initTopicRating(button) {
    let data = button.dataset
    let type = data.type
    let childId = parseInt(data.id)
    let rating = parseInt(data.value)
    let channel = window.camp_survey.channel
    let content = document.getElementById(`topicContent-${childId}`).innerHTML
    let payload = {
      id: childId,
      rating: rating,
      content: content,
      type: type
    }

    channel.push("new_rating", payload)
      .receive("ok", (resp) => {
        GuestSurvey.handle_rating_response(resp, channel, childId)
        GuestSurvey.storeRatingInCookie(childId, rating)
      }
    )
  },

  storeRatingInCookie(childId, rating) {
    let campRatings = GuestSurvey.getCookie('campRatings')
    if (campRatings) {
      GuestSurvey.setCookie('campRatings', campRatings + `{${childId},${rating}}-`, 2)
    } else {
      GuestSurvey.setCookie('campRatings', `{${childId},${rating}}-`, 2)
    }
  },

  handle_rating_response(resp, channel, childId) {
    let result = resp["result"]
    let nextHTML = resp["next_html"]
    if (result) {
      if (result == "done") {
        GuestResults.init(resp, channel)
      }
    } else if (nextHTML) {
      let prev = document.querySelector('.prev')
      let surveyItems  = document.getElementById('surveyItems')
      const fragment = document.createRange().createContextualFragment(nextHTML)
      surveyItems.appendChild(fragment)
      GuestSurvey.setEventListeners();

    }
  },

  setCookie(name, value, days) {
    var expires = "";
    if (days) {
      var date = new Date();
      date.setTime(date.getTime() + (days * 24 * 60 * 60 * 1000));
      expires = "; expires=" + date.toUTCString();
    }
    document.cookie = name + "=" + (value || "") + expires + "; path=/";
  },

  getCookie(name) {
    var nameEQ = name + "=";
    var ca = document.cookie.split(';');
    for (var i = 0; i < ca.length; i++) {
      var c = ca[i];
      while (c.charAt(0) == ' ') c = c.substring(1, c.length);
      if (c.indexOf(nameEQ) == 0) return c.substring(nameEQ.length, c.length);
    }
    return null;
  }
}

export default GuestSurvey
