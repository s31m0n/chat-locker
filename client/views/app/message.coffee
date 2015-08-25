Template.message.helpers

	own: ->
		return 'own' if this.u?._id is Meteor.userId()

	time: ->
		return moment(this.ts).format('HH:mm')

	date: ->
		return moment(this.ts).format('LL')

	isTemp: ->
		if @temp is true
			return 'temp'
		return

	body: ->
		name = getUser( this.u.username )?.name || this.u.username
		switch this.t
			when 'r'  then t('Room_name_changed', { room_name: this.msg, user_by: name })
			when 'au' then t('User_added_by', { user_added: this.msg, user_by: name })
			when 'ru' then t('User_removed_by', { user_removed: this.msg, user_by: name })
			when 'ul' then t('User_left', { user_left: name })
			when 'nu' then t('User_added', { user_added: name })
			when 'uj' then t('User_joined_channel', { user: name })
			when 'wm' then t('Welcome', { user: name })
			when 'rtc' then RocketChat.callbacks.run 'renderRtcMessage', this
			else
				this.html = this.msg
				if _.trim(this.html) isnt ''
					this.html = _.escapeHTML this.html
				message = RocketChat.callbacks.run 'renderMessage', this
				this.html = message.html.replace /\n/gm, '<br/>'
				return this.html

	system: ->
		return 'system' if this.t in ['s', 'p', 'f', 'r', 'au', 'ru', 'ul', 'nu', 'wm', 'uj']

	sender: ->
		return getUser(this.u.username)?.name || this.u.username


Template.message.onViewRendered = (context) ->
	view = this
	this._domrange.onAttached (domRange) ->
		lastNode = domRange.lastNode()
		if lastNode.previousElementSibling?.dataset?.date isnt lastNode.dataset.date
			$(lastNode).addClass('new-day')
			$(lastNode).removeClass('sequential')
		else if lastNode.previousElementSibling?.dataset?.username isnt lastNode.dataset.username
			$(lastNode).removeClass('sequential')

		if lastNode.nextElementSibling?.dataset?.date is lastNode.dataset.date
			$(lastNode.nextElementSibling).removeClass('new-day')
			$(lastNode.nextElementSibling).addClass('sequential')
		else
			$(lastNode.nextElementSibling).addClass('new-day')
			$(lastNode.nextElementSibling).removeClass('sequential')

		if lastNode.nextElementSibling?.dataset?.username isnt lastNode.dataset.username
			$(lastNode.nextElementSibling).removeClass('sequential')

		ul = lastNode.parentElement
		wrapper = ul.parentElement

		if context.urls?.length > 0 and Template.oembedBaseWidget?
			for item in context.urls
				do (item) ->
					urlNode = lastNode.querySelector('.body a[href="'+item.url+'"]')
					if urlNode?
						$(urlNode).replaceWith Blaze.toHTMLWithData Template.oembedBaseWidget, item

		if not lastNode.nextElementSibling?
			if lastNode.classList.contains('own') is true
				view.parentView.parentView.parentView.parentView.parentView.templateInstance().atBottom = true
			else
				if view.parentView.parentView.parentView.parentView.parentView.templateInstance().atBottom isnt true
					newMessage = document.querySelector(".new-message")
					newMessage.className = "new-message"

getUser = (username) ->
	# convert user's username to name
	allUsers = RoomManager.allUsers?.get()
	allUsers?[username]