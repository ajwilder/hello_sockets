document.addEventListener('DOMContentLoaded', function () {
  applyHoverTextListeners();
})
function applyHoverTextListeners() {
  let hovers = document.querySelectorAll('.hover-text')
  if (hovers) {
    for (let i = 0; i < hovers.length; i++) {
      hovers[i].addEventListener("mouseover", (e) => {displayHoverText(e)})
    }
  }
}
function displayHoverText(e) {
  let target = e.target
  let hoverText = target.dataset.hovertext
  if (hoverText) {
    let container = document.createElement('div')
    container.classList.add('hover-text-box-container')
    let element = document.createElement('div')
    element.innerHTML = hoverText
    element.classList.add('hover-text-box')
    container.appendChild(element)
    target.appendChild(container)
    target.addEventListener("mouseout", () => {
      container.remove()
    })

  }
}
