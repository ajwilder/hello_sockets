import UserCamp from "./user_camp"
let Images = {
  init() {
    Images.addBoardEventListeners()
  },
  addBoardEventListeners() {
    let imageBoardSelect = document.getElementById('imageBoardSelect')
    if (imageBoardSelect) {
      if (!imageBoardSelect.classList.contains('listening')){
        imageBoardSelect.classList.add('listening')
        imageBoardSelect.addEventListener('change', (e) => {
          Images.loadNewPostRange(e.target.value);
        })
      }
    }
    let imageBoardCreatePost = document.getElementById('imageBoardCreatePost')
    if (imageBoardCreatePost) {
      if (!imageBoardCreatePost.classList.contains('listening')){
        imageBoardCreatePost.classList.add('listening')
        imageBoardCreatePost.addEventListener('click', (e) => {
          Images.togglePostForm(e, "imageBoardPostForm");
        })
      }
    }
    let imageBoardCreateComment = document.querySelectorAll('.imageBoardCreateComment')
    if (imageBoardCreateComment) {
      for (var i = 0; i < imageBoardCreateComment.length; i++) {
        if (!imageBoardCreateComment[i].classList.contains('listening')){
          imageBoardCreateComment[i].classList.add('listening')
          imageBoardCreateComment[i].addEventListener('click', (e) => {
            let id = e.target.dataset.postId
            let target = `imageBoardPostForm${id}`
            Images.togglePostForm(e, target, id);
          })
        }
      }
    }
    let imageBoardDisplayImage = document.querySelectorAll('.imageBoardDisplayImage')
    if (imageBoardDisplayImage) {
      for (var i = 0; i < imageBoardDisplayImage.length; i++) {
        if (!imageBoardDisplayImage[i].classList.contains('listening')){
          imageBoardDisplayImage[i].classList.add('listening')
          imageBoardDisplayImage[i].addEventListener('click', (e) => {
            Images.showImage(e.target);
          })
        }
      }
    }
    let imageBoardComments = document.querySelectorAll('.imageBoardComments')
    if (imageBoardComments) {
      for (var i = 0; i < imageBoardComments.length; i++) {
        if (!imageBoardComments[i].classList.contains('listening')){
          imageBoardComments[i].classList.add('listening')
          imageBoardComments[i].addEventListener('click', (e) => {
            Images.loadComments(e.target)
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
            Images.loadMoreComments(e.target)
          })
        }
      }
    }
    let loadMorePosts = document.querySelectorAll('.loadMorePosts')
    if (loadMorePosts) {
      for (var i = 0; i < loadMorePosts.length; i++) {
        if (!loadMorePosts[i].classList.contains('listening')){
          loadMorePosts[i].classList.add('listening')
          loadMorePosts[i].addEventListener('click', (e) => {
            Images.loadMorePosts(e.target)
          })
        }
      }
    }
    let imageBoardVotes = document.querySelectorAll('.imageBoardVote')
    if (imageBoardVotes) {
      for (var i = 0; i < imageBoardVotes.length; i++) {
        if (!imageBoardVotes[i].classList.contains('listening')){
          imageBoardVotes[i].classList.add('listening')
          imageBoardVotes[i].addEventListener('click', (e) => {
            Images.vote(e.target)
          })
        }
      }
    }
  },
  loadNewPostRange(time_period) {
    switch(time_period){
      case "another_day":
        Images.activateDateInput('day')
        break;
      case "another_week":
        Images.activateDateInput('week')
        break;
      default:
        Images.deactivateDateInput()
        let channel = window.userCampChannel
        channel.push("change_image_board_range", {time_period: time_period, page: 0})
          .receive("ok", (resp) => {
            console.log(resp)
            UserCamp.putRespToDom(resp, "campBoardPosts")
            Images.addBoardEventListeners()
          })
          .receive("error", (resp) => {console.log(resp)})
    }
  },
  loadMorePosts(target) {
    console.log(target.dataset);
    let channel = window.userCampChannel
    channel.push("load_more_image_posts", {time_period: target.dataset.time_period, page: target.dataset.page, date: target.dataset.date})
      .receive("ok", (resp) => {
        console.log(resp)
        UserCamp.putRespToDom(resp, "loadMorePosts")
        Images.addBoardEventListeners()
      })
      .receive("error", (resp) => {console.log(resp)})

  },
  activateDateInput(range) {
    let anotherDateInput = document.getElementById('anotherDateInput')
    anotherDateInput.value = null
    if (anotherDateInput) {
      anotherDateInput.classList.add('active')
      anotherDateInput.addEventListener('input', (e) => {
        Images.loadBoardPostsInRange(range, e.target.value)
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
    channel.push("change_image_board_range", {time_period: range, page: page, date: date})
      .receive("ok", (resp) => {
        console.log(resp)
        UserCamp.putRespToDom(resp, "campBoardPosts")
        Images.addBoardEventListeners()
      })
      .receive("error", (resp) => {console.log(resp)})
  },
  loadComments(target) {
    Images.replaceButtonWithHide(target)
    let channel = window.userCampChannel
    channel.push("load_image_comments", {post_id: target.dataset.postId, page: 0})
      .receive("ok", (resp) => {
        UserCamp.appendRespToDom(resp, `campBoardPost${target.dataset.postId}`)
        Images.addBoardEventListeners()
      })
      .receive("error", (resp) => {console.log(resp)})
  },
  loadMoreComments(target) {
    let channel = window.userCampChannel
    channel.push("load_more_image_comments", {post_id: target.dataset.post, page: target.dataset.page})
      .receive("ok", (resp) => {
        UserCamp.putRespToDom(resp, `loadMoreComments${target.dataset.post}`)
        Images.addBoardEventListeners()
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
        Images.hideComments(e.target)
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
      Images.showComments(e.target)
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
      Images.hideComments(e.target)
    })
  },
  togglePostForm(e, target, id = null) {
    Images.replacePostButton(e.target)
    let channel = window.userCampChannel
    channel.push("load_image_form", {id: id})
      .receive("ok", (resp) => {
        UserCamp.putRespToDom(resp, target)
        let logOutLink = document.getElementById('logOutLink')
        let inputs = document.querySelectorAll('input[name="_csrf_token"]')
        for (var i = 0; i < inputs.length; i++) {
          inputs[i].value = logOutLink.dataset.csrf
        }
        Images.addFormEventListeners()
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
        Images.hideForm(e.target)
    })
  },
  hideForm(button) {
    let id = button.dataset.postId
    if (!id) {id = ""}
    let imageBoardCreatePost = document.getElementById(`imageBoardPostForm${id}`)
    if (imageBoardCreatePost) {
      imageBoardCreatePost.classList.add('hidden')
    }
    let newButton = document.createElement('button')
    for (var i = 0; i < button.classList.length; i++) {
      newButton.classList.add(button.classList[i])
    }
    newButton.innerHTML = "Upload Image"
    if (button.dataset.postId) {
      newButton.dataset.postId = button.dataset.postId
      newButton.innerHTML = "Comment"
    }
    button.replaceWith(newButton)
    newButton.addEventListener('click', (e) => {
      Images.showForm(e.target)
    })
  },
  showForm(button) {
    let id = button.dataset.postId
    if (!id) {id = ""}
    let imageBoardCreatePost = document.getElementById(`imageBoardPostForm${id}`)
    if (imageBoardCreatePost) {
      imageBoardCreatePost.classList.remove('hidden')
    }
    let newButton = document.createElement('button')
    for (var i = 0; i < button.classList.length; i++) {
      newButton.classList.add(button.classList[i])
    }
    newButton.innerHTML = "Cancel"
    if (button.dataset.postId) {
      newButton.dataset.postId = button.dataset.postId
      newButton.innerHTML = "Cancel Comment"
    }
    button.replaceWith(newButton)
    newButton.addEventListener('click', (e) => {
      Images.hideForm(e.target)
    })
  },
  addFormEventListeners() {
  },
  showImage(target) {
    let image = document.getElementById(`imageBoardImage${target.dataset.imageid}`)
    if (image) {
      if (image.classList.contains('hidden')) {
        image.classList.remove('hidden')
        image.scrollIntoViewIfNeeded()
        document.getElementById(`imageBoardDisplayImage${target.dataset.imageid}`).innerHTML ="Hide Image"
      } else {
        image.classList.add('hidden')
        document.getElementById(`imageBoardDisplayImage${target.dataset.imageid}`).innerHTML = "Show Image"
      }
    } else if (window[`imageBoardImage${target.dataset.imageid}`]) {
      // do nothing becuase the image is probably loading
    } else {
      window[`imageBoardImage${target.dataset.imageid}`] = true
      let channel = window.userCampChannel
      channel.push("load_image", {image_id: target.dataset.imageid})
        .receive("ok", (resp) => {
          UserCamp.putRespToDom(resp, `imageBoardImage${target.dataset.postid}`, `imageBoardImage${target.dataset.imageid}`)
          Images.addBoardEventListeners()
          window[`imageBoardImage${target.dataset.imageid}`] = false
          if (target.innerHTML == "Show Image") {
            target.innerHTML = "Hide Image"
          }
        })
        .receive("error", (resp) => {console.log(resp)})
    }
  },
  vote(target) {
    if (!target.classList.contains("in_progress")) {
      let update = target.classList.contains("voted")
      let old_vote = target.classList.contains("old_vote")
      let flip_vote = Images.isFlipVote(target.dataset.value, target.dataset.postId)
      Images.changeVoteButtons(target)
      let channel = window.userCampChannel
      channel.push('new_image_vote', {id: target.dataset.postId, value: target.dataset.value, update: update, old_vote: old_vote, flip_vote: flip_vote})
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
        Images.changePointsOnComment(target.dataset.postId, -1)
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
          Images.changePointsOnComment(target.dataset.postId, 2)
        } else {
          Images.changePointsOnComment(target.dataset.postId, 1)
        }
        opposite.innerHTML = "Disagree"
      }
    } else {
      if (target.classList.contains("voted")) {
        Images.changePointsOnComment(target.dataset.postId, 1)
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
          Images.changePointsOnComment(target.dataset.postId, -2)
        } else {
          Images.changePointsOnComment(target.dataset.postId, -1)
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
export default Images
