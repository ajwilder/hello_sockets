let GuestResults = {
  init(resp, channel) {
    if (resp) {
      GuestResults.addResultsToDom(resp)
    }
    GuestResults.addCampEventListeners()
  },
  addResultsToDom(resp) {
    let titleHTML = resp["title_html"]
    if (titleHTML) {
      let titleSection = document.getElementById('titleSection')
      if (titleSection) {
        const fragment = document.createRange().createContextualFragment(titleHTML)
        titleSection.replaceWith(fragment)
      }
    }
    let resultsHTML = resp["results_html"]
    if (resultsHTML) {
      let surveySection = document.getElementById('surveySection')
      if (surveySection) {
        const fragment = document.createRange().createContextualFragment(resultsHTML)
        surveySection.replaceWith(fragment)
      }
    }
  },
  addCampEventListeners() {
    let camps = document.querySelectorAll('.results-topic-count')
    if (camps) {
      for (let i = 0; i < camps.length; i++) {
        let camp = camps[i]
        console.log(camp);
        camp.addEventListener("dragstart", GuestResults.drag)
        camp.addEventListener("dragover", GuestResults.allowDrop)
        camp.addEventListener("drop", GuestResults.drop)
      }
    }
  },
  drag(ev) {
    ev.dataTransfer.setData("dragId", ev.target.dataset.id);
    ev.dataTransfer.setData("dragRating", ev.target.dataset.rating);
  },
  allowDrop(ev) {
    ev.preventDefault();
  },
  drop(ev) {
    ev.preventDefault();
    let dragID = parseInt(ev.dataTransfer.getData("dragId"));
    let dragRating = parseInt(ev.dataTransfer.getData("dragRating"));
    let targetID = parseInt(ev.target.dataset.id)
    let targetRating = parseInt(ev.target.dataset.rating)
    let channel = window.camp_survey.channel
    let payload = [[dragID, dragRating], [targetID, targetRating]]
    channel.push("combine_camps", payload)
      .receive("ok", (resp) => {
        GuestResults.handleCombineCampsResponse(resp, targetID, dragID)
      })
  },
  handleCombineCampsResponse(resp, targetID, dragID) {

    GuestResults.toggleFadeTargetAndDrag(targetID, dragID)
    GuestResults.toggleFadeCombinationIfExists()
    GuestResults.createOrEditAgreementText(resp)
    // Results.changeHeroPrompt()
    setTimeout(() => {
      GuestResults.moveCombinationIfExists()
      GuestResults.moveTargetAndDrag(targetID, dragID)
      GuestResults.removeAllFades()
    }, 500)
  },
  toggleFadeTargetAndDrag(targetID, dragID) {
    let drag = document.getElementById('topic' + dragID)
    let target = document.getElementById('topic' + targetID)
    if (drag.classList.contains('faded')) {
      drag.classList.remove('faded')
      target.classList.remove('faded')
    } else {
      drag.classList.add('faded')
      target.classList.add('faded')
    }
  },
  toggleFadeCombinationIfExists() {
    let combos = document.querySelectorAll('.combined-camps')
    for (let i = 0; i < combos.length; i++) {
      if (combos[i].classList.contains("faded")) {
        combos[i].classList.remove('faded')
      } else {
        combos[i].classList.add('faded')
      }
    }
  },
  removeAllFades() {
    let camps = document.querySelectorAll('.results-topic')
    for (let i = 0; i < camps.length; i++) {
      camps[i].classList.remove('faded')
    }
  },
  moveTargetAndDrag(targetID, dragID) {
    let combinedSection = document.getElementById('combinedCamps')
    let combinedContainer = document.getElementById('combinedCampsContainer')
    combinedContainer.classList.add('activated')
    let drag = document.getElementById('topic' + dragID)
    let target = document.getElementById('topic' + targetID)
    drag.removeEventListener("drop", GuestResults.drop)
    target.removeEventListener("drop", GuestResults.drop)
    drag.classList.add("combined-camps")
    target.classList.add("combined-camps")
    combinedSection.appendChild(drag)
    combinedSection.appendChild(target)
  },
  moveCombinationIfExists() {
    let combos = document.querySelectorAll('.combined-camps')
    let individualContainer = document.getElementById('campResults')
    for (let i = 0; i < combos.length; i++) {
      combos[i].classList.remove('combined-camps')
      individualContainer.insertBefore(combos[i], individualContainer.firstChild)
    }
  },
  createOrEditAgreementText(resp){

    let agreementCount = document.getElementById('agreementCount')
    if (agreementCount) {
      let agreement = document.getElementById('agreementText')
      agreement.classList.add('faded')
      setTimeout(() => {
        agreementCount.innerHTML = GuestResults.getPeopleHtml(resp.prq.like_minded)
        agreement.classList.remove('faded')
      },500)

    } else {
      let combinedContainer = document.getElementById('combinedCampsContainer')
      let agreement = document.createElement('div')
      let likeMinded = resp.prq.like_minded
      agreement.classList.add('agreement')
      agreement.classList.add('faded')
      agreement.id = "agreementText"
      agreement.innerHTML = `<span class="agreement-arrow">↑</span><span id="agreementCount" class="agreement-count">${GuestResults.getPeopleHtml(likeMinded)} </span> ${likeMinded == 1 ? "agrees" : "agree"} with you about these`
      combinedContainer.appendChild(agreement)
      setTimeout(() => {
        agreement.classList.remove('faded')
      },500)
    }
  },
  getPeopleHtml(people) {
    if (people > 1) {
      return `${people} <span class=agreement-people>people</span>`
    } else if (people == 1) {
      return `${people} <span class=agreement-people>person</span>`
    } else if (people == null || people == 0) {
      return `0 <span class=agreement-people>people</span>`
    }
  },
  changeHeroPrompt() {
    let heroPrompt = document.getElementById('resultsHeroPrompt')
    if (heroPrompt) {
      if (!heroPrompt.classList.contains('camps-combined')) {
        heroPrompt.classList.add('faded')
        setTimeout(() => {
          heroPrompt.classList.add('camps-combined')
          heroPrompt.classList.remove('faded')
        }, 2000)
      }
    }
  }
}
export default GuestResults
