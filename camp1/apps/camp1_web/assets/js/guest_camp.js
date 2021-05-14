let GuestCamp = {
  init(channel) {
    let messageBoardButton = document.getElementById('campBoardNav')
    if (messageBoardButton) {
      messageBoardButton.addEventListener('click', () => {
        console.log("push message board request to server")
        channel.push('get_message_board', {})
          .receive("ok", (resp) => {
            console.log(resp);
          })
      })
    }
  }
}


export default GuestCamp
