let CampNavigation = {
  putLoadingGif(id) {
    let divToReplace = document.getElementById(id)
    let img = document.createElement('img')
    img.src = "/images/loading.gif"
    let div = document.createElement('div')
    div.id = id
    div.classList.add('camp-loading-div')
    div.appendChild(img)
    divToReplace.replaceWith(div)
  },
  expandMenu(expanded) {
    let path = window.location.pathname
    path += "?1=" + expanded
    window.history.pushState(expanded, 'CampSmith', path);
  },
  expandSubMenu(menu, subMenu) {
    let path = window.location.pathname
    path += "?1=" + menu
    path += "&2=" + subMenu
    window.history.pushState(path, 'CampSmith', path);
  },
  setHistoryReload() {
    window.onpopstate = function(e){
      location.reload();
      if(e.state){
        // TODO: make this so page is not reloaded but socket connection is maintained and channel function is stored in the state.
      }
    }
  }

}
export default CampNavigation
