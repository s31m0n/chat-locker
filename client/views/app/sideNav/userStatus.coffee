Template.userStatus.helpers
	myUserInfo: ->
		visualStatus = t("online")
		username = Meteor.user()?.username
		status = Session.get('user_' + username + '_status')
		switch status
			when "away"
				visualStatus = t("away")
			when "busy"
				visualStatus = t("busy")
			when "offline"
				visualStatus = t("invisible")
		visualStatus = capitalizeWord(visualStatus)
		customMessage = setStatusMessage(Session.get('user_' + username + '_statusMessages'), status)
		return {
			name: Meteor.user()?.name || username
			status: status
			customMessage : customMessage
			visualStatus: visualStatus
			_id: Meteor.userId()
			username: username
		}

	isAdmin: ->
		return Meteor.user()?.admin is true

Template.userStatus.events
	'click .options .status': (event) ->
		event.preventDefault()
		newStatus = event.currentTarget.dataset.status
		setStatusMessage( Session.get('user_' + Meteor.user().username + '_statusMessages'), newStatus)
		if newStatus in ['online','away', 'busy']
			event.stopPropagation()
		else
			$('.custom-message').css('display','none')
			AccountBox.setStatus(newStatus, null)

	'click .account-box': (event) ->
		#console.log '.account-box EVENT....'
		if $('.custom-message').css('display') is 'none'
			AccountBox.toggle()

	'click #logout': (event) ->
		event.preventDefault()
		user = Meteor.user()
		Meteor.logout ->
			FlowRouter.go 'home'
			Meteor.call('logoutCleanUp', user)

	'click #avatar': (event) ->
		FlowRouter.go 'changeAvatar'

	'click .save-message': (event, instance) ->
		cmt = $('.custom-message')
		AccountBox.setStatus(cmt.data('userStatus'), $('#custom-message-text').val())
		cmt.css('display','none')

	'click .cancel-message': (event, instance) ->
		event.preventDefault()
		event.stopPropagation()
		$('.custom-message').css('display','none')

	'click #account': (event) ->
		SideNav.setFlex "accountFlex"
		SideNav.openFlex()
		FlowRouter.go 'account'

	'click #admin': ->
		SideNav.setFlex "adminFlex"
		SideNav.openFlex()

	'click .account-link': ->
		menu.close()

Template.userStatus.rendered = ->
	AccountBox.init()
	$('.custom-message').css('display','none')

capitalizeWord = (word) ->
	word[0].toUpperCase() + word[1..].toLowerCase()

setStatusMessage = (statusMessages, newStatus) ->
	jCM = $('.custom-message')
	message = ''
	if newStatus in ['online','away', 'busy']
		jCM.data('userStatus',newStatus).css('display','block').removeClass('status-online status-busy status-offline status-away').addClass('status-' + newStatus)
		$('#label-custom-message').text(capitalizeWord(newStatus) + ' custom message')
		if statusMessages?
			message = statusMessages[newStatus]
		else
			message = ''
		$('#custom-message-text').val(message)
	else
		jCM.css('display', 'none')
	return message
