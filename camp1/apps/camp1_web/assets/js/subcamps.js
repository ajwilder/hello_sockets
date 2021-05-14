import UserCamp from './user_camp'
let Subcamps = {
  init() {
    Subcamps.addEventListeners()
  },
  addEventListeners() {
    let subcampSortSelect = document.getElementById('subcampSortSelect')
    if (subcampSortSelect) {
      if (!subcampSortSelect.classList.contains('listening')) {
        subcampSortSelect.classList.add('listening')
        subcampSortSelect.addEventListener('change', Subcamps.sortSelected)
      }
    }
    let subcampsSortDateInput = document.getElementById('subcampsSortDateInput')
    if (subcampsSortDateInput) {
      if (!subcampsSortDateInput.classList.contains('listening')) {
        subcampsSortDateInput.classList.add('listening')
        subcampsSortDateInput.addEventListener('change', Subcamps.dateSelected)
      }
    }
  },
  sortSelected(e) {
    let sort_by = e.target.value
    if (sort_by == "day" || sort_by == "week") {
      let subcampsSortDateInput = document.getElementById('subcampsSortDateInput')
      if (subcampsSortDateInput) {
        subcampsSortDateInput.classList.add('active')
      }
      let subcampsList = document.getElementById('subcampsList')
      subcampsList.innerHTML = "Select Date"
    } else {
      let subcampsSortDateInput = document.getElementById('subcampsSortDateInput')
      if (subcampsSortDateInput) {
        subcampsSortDateInput.classList.remove('active')
      }
      let channel = window.userCampChannel
      channel.push("sort_subcamps", {sort_by: sort_by})
        .receive("ok", (resp) => {
          UserCamp.putRespToDom(resp, "subcampsList")
        })
    }
  },
  dateSelected(e) {
    let date = e.target.value
    let subcampSortSelect = document.getElementById('subcampSortSelect')
    let sort_by = subcampSortSelect.value
    let channel = window.userCampChannel
    channel.push("sort_subcamps", {date: date, sort_by: sort_by})
      .receive("ok", (resp) => {
        UserCamp.putRespToDom(resp, "subcampsList")
      })
  }

}

export default Subcamps
