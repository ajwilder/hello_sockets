import UserCamp from "./user_camp"
let Board = {
  init() {
    Board.addBoardEventListeners()
  },
  addBoardEventListeners() {
    let messageBoardSelectType = document.getElementById('messageBoardSelectType')
    if (messageBoardSelectType) {
      if (!messageBoardSelectType.classList.contains('listening')){
        messageBoardSelectType.classList.add('listening')
        messageBoardSelectType.addEventListener('change', Board.messageBoardSelect)
      }
    }
    let messageBoardSelectRange = document.getElementById('messageBoardSelectRange')
    if (messageBoardSelectRange) {
      if (!messageBoardSelectRange.classList.contains('listening')){
        messageBoardSelectRange.classList.add('listening')
        messageBoardSelectRange.addEventListener('change', Board.messageBoardSelect)
      }
    }
    let documentBoardCreatePost = document.getElementById('documentBoardCreatePost')
    if (documentBoardCreatePost) {
      if (!documentBoardCreatePost.classList.contains('listening')){
        documentBoardCreatePost.classList.add('listening')
        documentBoardCreatePost.addEventListener('click', (e) => {
          Board.toggleDocumentForm(e, "documentBoardPostForm");
        })
      }
    }
    let imageBoardCreatePost = document.getElementById('imageBoardCreatePost')
    if (imageBoardCreatePost) {
      if (!imageBoardCreatePost.classList.contains('listening')){
        imageBoardCreatePost.classList.add('listening')
        imageBoardCreatePost.addEventListener('click', (e) => {
          Board.toggleImageForm(e, "imageBoardPostForm");
        })
      }
    }
    let boardRangeDateInput = document.getElementById('boardRangeDateInput')
    if (boardRangeDateInput) {
      if (!boardRangeDateInput.classList.contains('listening')){
        boardRangeDateInput.classList.add('listening')
        boardRangeDateInput.addEventListener('change', Board.messageBoardSelect)
      }
    }
    let messageBoardCreatePost = document.getElementById('messageBoardCreatePost')
    if (messageBoardCreatePost) {
      if (!messageBoardCreatePost.classList.contains('listening')){
        messageBoardCreatePost.classList.add('listening')
        messageBoardCreatePost.addEventListener('click', (e) => {
          Board.togglePostForm(e, "messageBoardPostForm");
        })
      }
    }
    let messageBoardCreateComment = document.querySelectorAll('.messageBoardCreateComment')
    if (messageBoardCreateComment) {
      for (var i = 0; i < messageBoardCreateComment.length; i++) {
        if (!messageBoardCreateComment[i].classList.contains('listening')){
          messageBoardCreateComment[i].classList.add('listening')
          messageBoardCreateComment[i].addEventListener('click', (e) => {
            let id = e.target.dataset.postId
            let target = `messageBoardPostForm${id}`
            Board.togglePostForm(e, target, id);
          })
        }
      }
    }
    let messageBoardDisplayImage = document.querySelectorAll('.messageBoardDisplayImage')
    if (messageBoardDisplayImage) {
      for (var i = 0; i < messageBoardDisplayImage.length; i++) {
        if (!messageBoardDisplayImage[i].classList.contains('listening')){
          messageBoardDisplayImage[i].classList.add('listening')
          messageBoardDisplayImage[i].addEventListener('click', (e) => {
            Board.showImage(e.target);
          })
        }
      }
    }
    let messageBoardComments = document.querySelectorAll('.messageBoardComments')
    if (messageBoardComments) {
      for (var i = 0; i < messageBoardComments.length; i++) {
        if (!messageBoardComments[i].classList.contains('listening')){
          messageBoardComments[i].classList.add('listening')
          messageBoardComments[i].addEventListener('click', (e) => {
            Board.loadComments(e.target)
          })
        }
      }
    }
    let loadMoreComments = document.querySelectorAll('.loadMoreComments')
    if (loadMoreComments) {
      for (var i = 0; i < loadMoreComments.length; i++) {
        if (!loadMoreComments[i].classList.contains('listening')){
          loadMoreComments[i].classList.add('listening')
          loadMoreComments[i].addEventListener('click', (e) => {
            Board.loadMoreComments(e.target)
          })
        }
      }
    }
    let loadMorePosts = document.querySelectorAll('.loadMorePosts')
    if (loadMorePosts) {
      for (var i = 0; i < loadMorePosts.length; i++) {
        if (!loadMorePosts[i].classList.contains('listening')){
          loadMorePosts[i].classList.add('listening')
          loadMorePosts[i].addEventListener('click', Board.loadMorePosts)
        }
      }
    }
    let messageBoardVotes = document.querySelectorAll('.messageBoardVote')
    if (messageBoardVotes) {
      for (var i = 0; i < messageBoardVotes.length; i++) {
        if (!messageBoardVotes[i].classList.contains('listening')){
          messageBoardVotes[i].classList.add('listening')
          messageBoardVotes[i].addEventListener('click', (e) => {
            Board.vote(e.target)
          })
        }
      }
    }
  },
  messageBoardSelect() {
    let messageBoardSelectType = document.getElementById('messageBoardSelectType')
    let post_type = messageBoardSelectType.value
    let board_type = messageBoardSelectType.dataset.board_type
    let range = document.getElementById('messageBoardSelectRange').value
    let date = document.getElementById('boardRangeDateInput').value

    Board.makeDateSelectVisible(range)
    Board.makeRangeSelectVisible(post_type)
    if (post_type != "recent" && ((range == "day" || range == "week") && (date == ""))) {
      document.getElementById("campBoardPosts").innerHTML = "Select Date"
    } else {
      let channel = window.userCampChannel
      channel.push("board_select", {post_type: post_type, board_type: board_type, range: range, date: date})
        .receive("ok", (resp) => {
          console.log(resp)
          UserCamp.putRespToDom(resp, "campBoardPosts")
          Board.addBoardEventListeners()
        })
        .receive("error", (resp) => {console.log(resp)})
    }
  },
  makeRangeSelectVisible(type) {
    let messageBoardSelectRangeDiv = document.getElementById('messageBoardSelectRangeDiv')
    if (type == "top" || type == "controversial") {
      messageBoardSelectRangeDiv.classList.add('active')
    } else {
      messageBoardSelectRangeDiv.classList.remove('active')
    }
  },
  makeDateSelectVisible(range) {
    let boardRangeDateInput = document.getElementById('boardRangeDateInput')
    if (range == "day" || range == "week") {
      boardRangeDateInput.classList.add('active')
    } else {
      boardRangeDateInput.classList.remove('active')
    }
  },
  loadNewPostRange(time_period) {
    switch(time_period){
      case "another_day":
        Board.activateDateInput('day')
        break;
      case "another_week":
        Board.activateDateInput('week')
        break;
      default:
        Board.deactivateDateInput()
        let channel = window.userCampChannel
        channel.push("change_board_range", {time_period: time_period, page: 0})
          .receive("ok", (resp) => {
            console.log(resp)
            UserCamp.putRespToDom(resp, "campBoardPosts")
            Board.addBoardEventListeners()
          })
          .receive("error", (resp) => {console.log(resp)})
    }
  },
  loadMorePosts(e) {
    let target = e.target
    let page = target.dataset.page
    let date = target.dataset.date
    let order_by = target.dataset.order_by
    let board_type = target.dataset.board_type
    console.log(target.dataset);
    let channel = window.userCampChannel
    channel.push("load_more_posts", {order_by: order_by, board_type: board_type, date: date, page: page})
      .receive("ok", (resp) => {
        console.log(resp)
        UserCamp.putRespToDom(resp, "loadMorePosts")
        Board.addBoardEventListeners()
      })
      .receive("error", (resp) => {console.log(resp)})

  },
  activateDateInput(range) {
    let anotherDateInput = document.getElementById('anotherDateInput')
    anotherDateInput.value = null
    if (anotherDateInput) {
      anotherDateInput.classList.add('active')
      anotherDateInput.addEventListener('input', (e) => {
        Board.loadBoardPostsInRange(range, e.target.value)
      })
    }
    let campBoardPosts = document.getElementById('campBoardPosts')
    if (campBoardPosts) {
      campBoardPosts.innerHTML = "Select " + range
    }
  },
  deactivateDateInput() {
    let anotherDateInput = document.getElementById('anotherDateInput')
    if (anotherDateInput) {
      anotherDateInput.classList.remove('active')
    }
  },
  loadBoardPostsInRange(range, date, page = 0) {
    let channel = window.userCampChannel
    channel.push("change_board_range", {time_period: range, page: page, date: date})
      .receive("ok", (resp) => {
        console.log(resp)
        UserCamp.putRespToDom(resp, "campBoardPosts")
        Board.addBoardEventListeners()
      })
      .receive("error", (resp) => {console.log(resp)})
  },
  loadComments(target) {
    Board.replaceButtonWithHide(target)
    let channel = window.userCampChannel
    channel.push("load_comments", {post_id: target.dataset.postId, board_type: target.dataset.board_type, page: 0})
      .receive("ok", (resp) => {
        UserCamp.appendRespToDom(resp, `campBoardPost${target.dataset.postId}`)
        Board.addBoardEventListeners()
      })
      .receive("error", (resp) => {console.log(resp)})
  },
  loadMoreComments(target) {
    let page = parseInt(target.dataset.page)
    let channel = window.userCampChannel
    channel.push("load_comments", {post_id: target.dataset.post, board_type: target.dataset.board_type, page: page})
      .receive("ok", (resp) => {
        UserCamp.putRespToDom(resp, `loadMoreComments${target.dataset.post}`)
        Board.addBoardEventListeners()
      })
      .receive("error", (resp) => {console.log(resp)})
  },
  replaceButtonWithHide(button) {
    let count = button.innerHTML.match(/\d+/g)
    if (count) {
      count = count[0]
    } else {
      count = ""
    }
    let newButton = document.createElement('button')
    newButton.classList.add("button-small")
    newButton.innerHTML = `Hide ${count} Comments`
    newButton.dataset.postId = button.dataset.postId
    button.replaceWith(newButton)
    newButton.addEventListener('click', (e) => {
        Board.hideComments(e.target)
    })
  },
  hideComments(button) {
    let count = button.innerHTML.match(/\d+/g)
    if (count) {
      count = count[0]
    } else {
      count = ""
    }
    let id = button.dataset.postId
    let commentDivs = document.querySelectorAll(`.campBoardComments${id}`)
    for (var i = 0; i < commentDivs.length; i++) {
      commentDivs[i].classList.add('hidden')
    }
    let newButton = document.createElement('button')
    newButton.classList.add("button-small")
    newButton.innerHTML = `Show ${count} Comments`
    newButton.dataset.postId = button.dataset.postId
    button.replaceWith(newButton)
    newButton.addEventListener('click', (e) => {
      Board.showComments(e.target)
    })
  },
  showComments(button) {
    let count = button.innerHTML.match(/\d+/g)
    if (count) {
      count = count[0]
    } else {
      count = ""
    }
    let id = button.dataset.postId
    let commentDivs = document.querySelectorAll(`.campBoardComments${id}`)
    for (var i = 0; i < commentDivs.length; i++) {
      commentDivs[i].classList.remove('hidden')
    }
    let newButton = document.createElement('button')
    newButton.classList.add("button-small")
    newButton.innerHTML = `Hide ${count} Comments`
    newButton.dataset.postId = button.dataset.postId
    button.replaceWith(newButton)
    newButton.addEventListener('click', (e) => {
      Board.hideComments(e.target)
    })
  },
  togglePostForm(e, target, id = null) {
    Board.replacePostButton(e.target)
    let channel = window.userCampChannel
    channel.push("load_form", {id: id, image: false})
      .receive("ok", (resp) => {
        UserCamp.putRespToDom(resp, target)
        let logOutLink = document.getElementById('logOutLink')
        let inputs = document.querySelectorAll('input[name="_csrf_token"]')
        for (var i = 0; i < inputs.length; i++) {
          inputs[i].value = logOutLink.dataset.csrf
        }
      })
  },
  toggleImageForm(e, target) {
    Board.replacePostButton(e.target)
    let channel = window.userCampChannel
    channel.push("load_image_form", {})
      .receive("ok", (resp) => {
        UserCamp.putRespToDom(resp, target)
        let logOutLink = document.getElementById('logOutLink')
        let inputs = document.querySelectorAll('input[name="_csrf_token"]')
        for (var i = 0; i < inputs.length; i++) {
          inputs[i].value = logOutLink.dataset.csrf
        }
      })
  },
  toggleDocumentForm(e, target) {
    Board.replacePostButton(e.target)
    let channel = window.userCampChannel
    channel.push("load_document_form", {})
      .receive("ok", (resp) => {
        UserCamp.putRespToDom(resp, target)
        let logOutLink = document.getElementById('logOutLink')
        let inputs = document.querySelectorAll('input[name="_csrf_token"]')
        for (var i = 0; i < inputs.length; i++) {
          inputs[i].value = logOutLink.dataset.csrf
        }
      })
  },
  replacePostButton(button) {
    let newButton = document.createElement('button')
    newButton.innerHTML = "Cancel"
    for (var i = 0; i < button.classList.length; i++) {
      newButton.classList.add(button.classList[i])
    }
    if (button.dataset.postId) {
      newButton.dataset.postId = button.dataset.postId
      newButton.innerHTML = "Cancel Comment"
    }
    button.replaceWith(newButton)
    newButton.addEventListener('click', (e) => {
        Board.hideForm(e.target, button.dataset.board_type)
    })
  },
  hideForm(button, boardType) {
    let id = button.dataset.postId
    if (!id) {id = ""}
    let messageBoardCreatePost = document.getElementById(`boardForm${id}`)
    if (messageBoardCreatePost) {
      messageBoardCreatePost.classList.add('hidden')
    }
    let newButton = document.createElement('button')
    for (var i = 0; i < button.classList.length; i++) {
      newButton.classList.add(button.classList[i])
    }
    if (boardType == "posts") {
      newButton.innerHTML = "Post To This Board"
    } else if (boardType == "images") {
      newButton.innerHTML = "Upload Image"
    } else if (boardType == "documents") {
      newButton.innerHTML = "Upload Document"
    }
    newButton.dataset.board_type = boardType
    if (button.dataset.postId) {
      newButton.dataset.postId = button.dataset.postId
      newButton.innerHTML = "Comment"
    }
    button.replaceWith(newButton)
    newButton.addEventListener('click', (e) => {
      Board.showForm(e.target, boardType)
    })
  },
  showForm(button, boardType) {
    let id = button.dataset.postId
    if (!id) {id = ""}
    let messageBoardCreatePost = document.getElementById(`boardForm${id}`)
    if (messageBoardCreatePost) {
      messageBoardCreatePost.classList.remove('hidden')
    }
    let newButton = document.createElement('button')
    for (var i = 0; i < button.classList.length; i++) {
      newButton.classList.add(button.classList[i])
    }
    newButton.innerHTML = "Cancel"
    newButton.dataset.board_type = boardType
    if (button.dataset.postId) {
      newButton.dataset.postId = button.dataset.postId
      newButton.innerHTML = "Cancel Comment"
    }
    button.replaceWith(newButton)
    newButton.addEventListener('click', (e) => {
      Board.hideForm(e.target, button.dataset.board_type)
    })
  },
  showImage(target) {
    let image = document.getElementById(`imageBoardImage${target.dataset.imageid}`)
    if (image) {
      if (image.classList.contains('hidden')) {
        image.classList.remove('hidden')
        image.scrollIntoViewIfNeeded()
        document.getElementById(`messageBoardDisplayImage${target.dataset.imageid}`).innerHTML ="Hide Image"
      } else {
        image.classList.add('hidden')
        document.getElementById(`messageBoardDisplayImage${target.dataset.imageid}`).innerHTML = "Show Image"
      }
    } else if (window[`imageBoardImage${target.dataset.imageid}`]) {

    } else {
      window[`imageBoardImage${target.dataset.imageid}`] = true
      let channel = window.userCampChannel
      channel.push("load_image", {image_id: target.dataset.imageid})
        .receive("ok", (resp) => {
          UserCamp.putRespToDom(resp, `imageBoardImage${target.dataset.postid}`, `imageBoardImage${target.dataset.imageid}`)
          Board.addBoardEventListeners()
          window[`imageBoardImage${target.dataset.imageid}`] = false
          if (target.innerHTML == "Show Image") {
            target.innerHTML = "Hide Image"
          } else {
            document.getElementById(`messageBoardDisplayImage${target.dataset.imageid}`).innerHTML ="Hide Image"
          }
        })
        .receive("error", (resp) => {console.log(resp)})
    }
  },
  vote(target) {
    if (!target.classList.contains("in_progress")) {
      let update = target.classList.contains("voted")
      let old_vote = target.classList.contains("old_vote")
      let flip_vote = Board.isFlipVote(target.dataset.value, target.dataset.postId)

      Board.changeVoteButtons(target)
      let channel = window.userCampChannel
      channel.push('new_vote', {id: target.dataset.postId, value: target.dataset.value, update: update, old_vote: old_vote, flip_vote: flip_vote})
        .receive("ok", (resp) => {
          console.log(resp)
          target.classList.remove("in_progress")
        })
        .receive("error", (resp) => {console.log(resp)})
    }
  },
  isFlipVote(value, id) {
    if (value == 1) {
      return document.getElementById(`disagree${id}`).classList.contains("voted")
    } else {
      return document.getElementById(`agree${id}`).classList.contains("voted")
    }
  },
  changeVoteButtons(target) {
    if (target.dataset.value == "1") {
      if (target.classList.contains("voted")) {
        Board.changePointsOnComment(target.dataset.postId, -1)
        target.classList.remove("voted")
        target.innerHTML = "Agree"
        let opposite = document.getElementById(`disagree${target.dataset.postId}`)
        opposite.classList.remove('disabled-button')
      } else {
        target.classList.remove("disabled-button")
        target.classList.add("voted")
        target.innerHTML = "Agreed"
        let opposite = document.getElementById(`disagree${target.dataset.postId}`)
        opposite.classList.add('disabled-button')
        if (opposite.classList.contains('voted')) {
          opposite.classList.remove('voted')
          Board.changePointsOnComment(target.dataset.postId, 2)
        } else {
          Board.changePointsOnComment(target.dataset.postId, 1)
        }
        opposite.innerHTML = "Disagree"
      }
    } else {
      if (target.classList.contains("voted")) {
        Board.changePointsOnComment(target.dataset.postId, 1)
        target.classList.remove("voted")
        target.innerHTML = "Disagree"
        let opposite = document.getElementById(`agree${target.dataset.postId}`)
        opposite.classList.remove('disabled-button')
      } else {
        target.classList.remove("disabled-button")
        target.classList.add("voted")
        target.innerHTML = "Disagreed"
        let opposite = document.getElementById(`agree${target.dataset.postId}`)
        opposite.classList.add('disabled-button')
        if (opposite.classList.contains('voted')) {
          opposite.classList.remove('voted')
          Board.changePointsOnComment(target.dataset.postId, -2)
        } else {
          Board.changePointsOnComment(target.dataset.postId, -1)
        }
        opposite.innerHTML = "Agree"
      }
    }
    target.classList.add('in_progress')
    target.blur()
  },
  changePointsOnComment(comment_id, value) {
    let campBoardPoints = document.getElementById(`campBoardPoints${comment_id}`)
    if (campBoardPoints) {
      let points = campBoardPoints.innerHTML
      points = parseInt(points)
      points += value
      campBoardPoints.innerHTML = points
    }
  }

}
export default Board
