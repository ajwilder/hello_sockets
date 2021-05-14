import UserCamp from './user_camp'
let Manifesto = {
  init() {
    Manifesto.addEventListeners()
  },
  addEventListeners() {
    let submitManifesto = document.getElementById('submitManifesto')
    if (submitManifesto) {
      if (!submitManifesto.classList.contains('listening')){
        submitManifesto.classList.add('listening')
        submitManifesto.addEventListener('click', Manifesto.submitManifesto)
      }
    }
    let manifestoEdit = document.getElementById('manifestoEdit')
    if (manifestoEdit) {
      if (!manifestoEdit.classList.contains('listening')){
        manifestoEdit.classList.add('listening')
        manifestoEdit.addEventListener('click', Manifesto.manifestoEdit)
      }
    }
    let createManifesto = document.getElementById('createManifesto')
    if (createManifesto) {
      if (!createManifesto.classList.contains('listening')){
        createManifesto.classList.add('listening')
        createManifesto.addEventListener('click', Manifesto.createManifesto)
      }
    }
    let viewProposal = document.getElementById('viewProposal')
    if (viewProposal) {
      if (!viewProposal.classList.contains('listening')){
        viewProposal.classList.add('listening')
        viewProposal.addEventListener('click', Manifesto.viewProposal)
      }
    }
    let backToCurrent = document.getElementById('backToCurrent')
    if (backToCurrent) {
      if (!backToCurrent.classList.contains('listening')){
        backToCurrent.classList.add('listening')
        backToCurrent.addEventListener('click', Manifesto.backToCurrent)
      }
    }
    let viewHistory = document.getElementById('viewHistory')
    if (viewHistory) {
      if (!viewHistory.classList.contains('listening')){
        viewHistory.classList.add('listening')
        viewHistory.addEventListener('click', Manifesto.viewHistory)
      }
    }
    let manifestoVersionSelect = document.querySelectorAll('.manifestoVersionSelect')
    if (manifestoVersionSelect) {
      for (var i = 0; i < manifestoVersionSelect.length; i++) {
        if (!manifestoVersionSelect[i].classList.contains('listening')){
          manifestoVersionSelect[i].classList.add('listening')
          manifestoVersionSelect[i].addEventListener('click', Manifesto.versionSelect)
        }
      }
    }
    let manifestoVote = document.querySelectorAll('.manifestoVote')
    if (manifestoVote) {
      for (var i = 0; i < manifestoVote.length; i++) {
        if (!manifestoVote[i].classList.contains('listening')){
          manifestoVote[i].classList.add('listening')
          manifestoVote[i].addEventListener('click', Manifesto.vote)
        }
      }
    }
  },
  submitManifesto(e) {
    let editor = window['campManifestoEditor']
    let channel = window.userCampChannel
    let delta = editor.editor.delta
    let og_delta = window['ogDelta']
    let diff = og_delta.diff(delta)
    channel.push("submit_manifesto", {content: editor.root.innerHTML, delta: diff})
      .receive("ok", (resp) => {
        location.reload()
      })
      .receive("error", (resp) => {console.log(resp)})
  },
  manifestoEdit(e) {
    let button = e.target
    window['initialEditButtonPrompt'] = button.innerHTML
    Manifesto.activateEditor()
    let submit = document.getElementById('submitManifesto')
    window["manifestoSumbit"] = submit
    if (submit) {submit.classList.remove('hidden')}
    let prompt = document.createElement('p')
    prompt.classList = "manifesto-prompt"
    prompt.innerHTML = "Make edits and submit your propsal below:"
    window["manifestoPrompt"] = prompt
    document.getElementById('manifestoMainDiv').prepend(prompt)
    let newButton = document.createElement('button')
    newButton.innerHTML = "Cancel Proposal"
    for (var i = 0; i < button.classList.length; i++) {
      newButton.classList.add(button.classList[i])
    }
    newButton.id = "cancelManifestoEdit"
    newButton.addEventListener('click', Manifesto.cancelManifestoEdit)
    button.replaceWith(newButton)
    let hideHistory = document.getElementById('hideHistory')
    if (hideHistory) {
      Manifesto.hideHistory({target: hideHistory})
    }
    Manifesto.addEventListeners()
  },
  cancelManifestoEdit(e) {
    Manifesto.deactivateEditor()
    let button = e.target
    if (window["manifestoPrompt"]) {
      window["manifestoPrompt"].remove()
      window["manifestoSumbit"].classList.add('hidden')
    }
    let newButton = document.createElement('button')
    newButton.innerHTML = window['initialEditButtonPrompt']
    for (var i = 0; i < button.classList.length; i++) {
      newButton.classList.add(button.classList[i])
    }
    newButton.addEventListener('click', Manifesto.manifestoEdit)
    button.replaceWith(newButton)
    Manifesto.addEventListeners()
  },
  deactivateEditor() {
    if (window['campManifestoEditor']) {
      window['campManifestoEditor'].disable()
    }
    document.getElementById('editor').classList.add('hidden')
    let alternateContent = document.getElementById('alternateContent')
    if (alternateContent) {
      alternateContent.classList.remove('hidden')
    }
    let toolbar = document.querySelector('.ql-toolbar')
    if (toolbar) {
      toolbar.classList.add('hidden')
    }
  },
  createManifesto(e) {
    e.target.remove()
    let noManifesto = document.getElementById('noManifesto')
    noManifesto.innerHTML = "Create a Manifesto:"
    Manifesto.activateEditor()
    let submit = document.getElementById('submitManifesto')
    if (submit) {submit.classList.remove('hidden')}
    Manifesto.addEventListeners()
  },
  activateEditor() {
    if (window['campManifestoEditor']) {
      window['campManifestoEditor'].enable()
      document.getElementById('editor').classList.remove('hidden')
      let alternateContent = document.getElementById('alternateContent')
      if (alternateContent) {
        alternateContent.classList.add('hidden')
      }
      let toolbar = document.querySelector('.ql-toolbar')
      if (toolbar) {
        toolbar.classList.remove('hidden')
      }
    } else {
      var editor = new Quill('#editor', {
        modules: { toolbar: true },
        theme: 'snow'
      });
      window['campManifestoEditor'] = editor
      window['ogDelta'] = editor.editor.delta
    }
    let editorDiv = document.getElementById('editor')
    editorDiv.classList.remove('manifesto-display')
    editorDiv.classList.remove('hidden')
    let alternateContent = document.getElementById('alternateContent')
    alternateContent.classList.add('hidden')
  },
  viewProposal(e) {
    e.target.classList.add('hidden')
    let editor = document.getElementById('editor')
    let proposed = document.getElementById('proposedChange')
    if (editor && proposedChange) {
      editor.classList.add('hidden')
      proposedChange.classList.remove('hidden')
    }
    document.getElementById('backToCurrent').classList.remove('hidden')
    let hideHistory = document.getElementById('hideHistory')
    if (hideHistory) {
      Manifesto.hideHistory({target: hideHistory})
    }

    let alternateContent = document.getElementById('alternateContent')
    if (editor && proposedChange && alternateContent) {
      alternateContent.classList.add('hidden')
    }
  },
  backToCurrent(e) {
    e.target.classList.add('hidden')
    let editor = document.getElementById('editor')
    let proposed = document.getElementById('proposedChange')
    let alternateContent = document.getElementById('alternateContent')
    if (editor && proposedChange && alternateContent) {
      editor.classList.remove('hidden')
      proposedChange.classList.add('hidden')
      alternateContent.classList.add('hidden')
    }
    document.getElementById('viewProposal').classList.remove('hidden')
  },
  viewHistory(e) {
    let backToCurrent = document.getElementById('backToCurrent')
    if (backToCurrent) {
      Manifesto.backToCurrent({target: backToCurrent})
    }
    let button = e.target
    let historyLog = document.getElementById('historyLog')
    if (historyLog) {
      historyLog.classList.remove('hidden')
    }
    window['initialHistoryButtonPrompt'] = button.innerHTML
    let newButton = document.createElement('button')
    newButton.innerHTML = "Hide Change History"
    for (var i = 0; i < button.classList.length; i++) {
      newButton.classList.add(button.classList[i])
    }
    newButton.id = "hideHistory"
    newButton.addEventListener('click', Manifesto.hideHistory)
    button.replaceWith(newButton)
    Manifesto.addEventListeners()

    let cancelManifestoEdit = document.getElementById('cancelManifestoEdit')
    if (cancelManifestoEdit) {
      console.log('cancelManifestoEdit');
      Manifesto.cancelManifestoEdit({target: cancelManifestoEdit})
    } else {
      Manifesto.deactivateEditor()
    }

  },
  versionSelect(e) {
    let channel = window.userCampChannel
    let button = e.target
    Manifesto.makeButtonActive(button, ".manifestoVersionSelect")
    let version = button.dataset.version
    channel.push("manifesto_version_select", {version: version})
      .receive("ok", (resp) => {
        Manifesto.displayVersion(resp)
      })
      .receive("error", (resp) => {console.log(resp)})
  },
  hideHistory(e) {
    let historyLog = document.getElementById('historyLog')
    if (historyLog) {
      historyLog.classList.add('hidden')
    }
    let button = e.target
    let newButton = document.createElement('button')
    newButton.innerHTML = window['initialHistoryButtonPrompt']
    for (var i = 0; i < button.classList.length; i++) {
      newButton.classList.add(button.classList[i])
    }
    newButton.id = "hideHistory"
    newButton.addEventListener('click', Manifesto.viewHistory)
    button.replaceWith(newButton)
    Manifesto.addEventListeners()
  },
  makeButtonActive(button, buttonClass) {
    let buttons = document.querySelectorAll(buttonClass)
    for (var i = 0; i < buttons.length; i++) {
      buttons[i].classList.remove('active')
    }
    button.classList.add('active')
    button.blur()
  },
  displayVersion(resp) {
    let html = resp["html"]
    if (html) {
      let contentDiv = document.getElementById('alternateContent')
      if (contentDiv) {
        contentDiv.innerHTML = ""
        const fragment = document.createRange().createContextualFragment(html)
        contentDiv.appendChild(fragment)
      }
    }
  },
  vote(e) {
    let button = e.target
    if (!button.classList.contains('inactive')) {
      Manifesto.inactivateVoteButtons()
      let version = button.dataset.version
      let value = button.dataset.value
      Manifesto.handleVoteButtons(button)
      let channel = window.userCampChannel
      channel.push("manifesto_vote", {version: version, value: value})
        .receive("ok", (resp) => {
          Manifesto.activateVoteButtons()
        })
        .receive("error", (resp) => {console.log(resp)})
    }
  },
  handleVoteButtons(button) {
    if (button.classList.contains('active')) {
      button.classList.remove('active')
    } else {
      let buttons = document.querySelectorAll('.manifestoVote')
      for (var i = 0; i < buttons.length; i++) {
        buttons[i].classList.remove('active')
      }
      button.classList.add('active')
    }
    button.blur()
  },
  inactivateVoteButtons() {
    let buttons = document.querySelectorAll('.manifestoVote')
    for (var i = 0; i < buttons.length; i++) {
      buttons[i].classList.add('inactive')
    }
  },
  activateVoteButtons() {
    let buttons = document.querySelectorAll('.manifestoVote')
    for (var i = 0; i < buttons.length; i++) {
      buttons[i].classList.remove('inactive')
    }
  }
}

export default Manifesto
