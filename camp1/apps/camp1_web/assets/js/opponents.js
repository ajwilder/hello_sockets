import UserCamp from "./user_camp"
let Opponents = {
  init() {
    Opponents.addOpponentEventListeners()
  },
  addOpponentEventListeners() {
    let opponents = document.querySelectorAll('.camp-opponents-list-opponent')
    for (var i = 0; i < opponents.length; i++) {
      opponents[i].addEventListener('click', (e) => {
        let target = e.target
        let targetClassList = target.classList
        console.log(targetClassList);
        if (targetClassList.contains('unselected-opponent')) {
          Opponents.makeOpponentButtonActive(target)
          Opponents.renderNewOpponentView(target.dataset.opponent_id)
        }
      })
    }
  },
  makeOpponentButtonActive(button) {
    let buttons = document.querySelectorAll('.camp-opponents-list-opponent');
    for (let i = 0; i < buttons.length; i++) {
      buttons[i].classList.remove('selected-opponent')
      buttons[i].classList.add('unselected-opponent')
    }
    button.classList.add('selected-opponent')
    button.classList.remove('unselected-opponent')
    button.blur()
  },
  renderNewOpponentView(id) {
    let channel = window.userCampChannel
    channel.push("opponent_view", {opponent_id: id})
      .receive("ok", (resp) => {
        UserCamp.putRespToDom(resp, "CampOpponentViewDetails")
      })
      .receive("error", (resp) => {
        console.log(resp);
      })
  }
}
export default Opponents
