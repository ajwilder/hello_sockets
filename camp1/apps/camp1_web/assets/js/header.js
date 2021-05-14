document.addEventListener('DOMContentLoaded', function () {
  let navigationDropdownLink = document.getElementById("navigationDropdownLink");
  if (navigationDropdownLink) {
    navigationDropdownLink.addEventListener('click', toggleCampDropdown)
  }
});

function toggleCampDropdown() {
  let navigationDropdown = document.getElementById("navigationDropdown");
  if (navigationDropdown) {
    if (navigationDropdown.classList.contains('active')) {
      navigationDropdown.classList.remove('active')
    } else {
      navigationDropdown.classList.add('active')
    }
  }
}
