import UserHome from './user_home'
let YourCamps = {
  init() {
    YourCamps.addEventListeners()
  },
  addEventListeners() {
    let loadMoreCamps = document.getElementById('loadMoreCamps')
    if (loadMoreCamps) {
      if (!loadMoreCamps.classList.contains('listening')) {
        loadMoreCamps.classList.add('listening')
        loadMoreCamps.addEventListener('click', (e) => {
          YourCamps.loadMoreCamps(e.target)
        })
      }
    }
    let userYourCampsSelect = document.getElementById('userYourCampsSelect')
    if (userYourCampsSelect) {
      if (!userYourCampsSelect.classList.contains('listening')){
        userYourCampsSelect.classList.add('listening')
        userYourCampsSelect.addEventListener('change', (e) => {
          YourCamps.loadNewCamps(e.target.value);
        })
      }
    }
  },
  loadMoreCamps(target) {
    let channel = window.userHomeChannel
    channel.push('load_more_camps', {type: target.dataset.type, page: target.dataset.page})
      .receive("ok", (resp) => {
        UserHome.putRespToDom(resp, 'loadMoreCamps')
        YourCamps.addEventListeners()
      })
  },
  loadNewCamps(type) {
    console.log(type);
    let channel = window.userHomeChannel
    channel.push("load_new_camps", {type: type})
      .receive("ok", (resp) => {
        console.log(resp)
        UserHome.putRespToDom(resp, 'userHomeCampsList')
        YourCamps.addEventListeners()
      })
      .receive("error", (resp) => {console.log(resp)})

  }
}

export default YourCamps
