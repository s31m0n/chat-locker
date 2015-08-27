# @TODO bug com o botão para "rolar até o fim" (novas mensagens) quando há uma mensagem com texto que gere rolagem horizontal
Template.room.helpers
	tAddUsers: ->
		return t('Add_users')

	tQuickSearch: ->
		return t('Quick_Search')

	favorite: ->
		sub = ChatSubscription.findOne { rid: this._id }, { fields: { f: 1 } }
		return 'icon-star favorite-room' if sub?.f? and sub.f
		return 'icon-star-empty'

	subscribed: ->
		return ChatSubscription.find({ rid: this._id }).count() > 0

	messagesHistory: ->
		return ChatMessage.find { rid: this._id, t: { '$ne': 't' }  }, { sort: { ts: 1 } }

	hasMore: ->
		return RoomHistoryManager.hasMore this._id

	isLoading: ->
		return 'btn-loading' if RoomHistoryManager.isLoading this._id

	windowId: ->
		return "chat-window-#{this._id}"

	uploading: ->
		return Session.get 'uploading'

	usersTyping: ->
		usernames = MsgTyping.get @_id
		if usernames.length is 0
			return
		names = usernames.map (username) ->
			return getUser(username)?.name || username 

		if names.length is 1
			name = names[0]
			return {
				multi: false
				selfTyping: MsgTyping.selfTyping.get()
				#user's name, NOT username
				users: name
			}

		# usernames = _.map messages, (message) -> return message.u.username

		last = names.pop()
		if names.length > 4
			last = t('others')
		#user's name, NOT username
		names = names.join(', ')
		names = [names, last]
		return {
			multi: true
			selfTyping: MsgTyping.selfTyping.get()
			users: names.join " #{t 'and'} "
		}

	roomName: ->
		roomData = Session.get('roomData' + this._id)
		return '' unless roomData

		if roomData.t is 'd'
			return ChatSubscription.findOne({ rid: this._id }, { fields: { name: 1, displayName:1 } })?.displayName
		else
			return roomData.displayName

	roomIcon: ->
		roomData = Session.get('roomData' + this._id)
		return '' unless roomData?.t

		switch roomData.t
			when 'd' then return 'icon-at'
			when 'c' then return 'icon-hash'
			when 'p' then return 'icon-lock'

	userData: ->
		roomData = Session.get('roomData' + this._id)

		return {} unless roomData

		if roomData.t is 'd'
			username = _.without roomData.usernames, Meteor.user().username

			userData = {
				name: getUser(username)?.name|| username
				# not used, but if wanted, need to set in RoomManager 
				#emails: Session.get('user_' + username + '_emails') || []
				#phone: Session.get('user_' + username + '_phone')
				username: String(username)
			}

			if Meteor.user()?.admin is true
				userData = _.extend userData, Meteor.users.findOne { username: String(username) }

			return userData

	userStatus: ->
		roomData = Session.get('roomData' + this._id)

		return {} unless roomData

		if roomData.t is 'd'
			username = _.without roomData.usernames, Meteor.user().username
			return Session.get('user_' + username + '_status') || 'offline'

		else
			return 'offline'

	autocompleteSettingsAddUser: ->
		return {
			limit: 10
			# inputDelay: 300
			rules: [
				{
					collection: 'UserAndRoom'
					subscription: 'roomSearch'
					field: 'name'
					template: Template.roomSearch
					noMatchTemplate: Template.roomSearchEmpty
					matchAll: true
					filter: { type: 'u', uid: { $ne: Meteor.userId() } }
					sort: 'name'
				}
			]
		}

	autocompleteSettingsRoomSearch: ->
		return {
			limit: 10
			# inputDelay: 300
			rules: [
				{
					collection: 'UserAndRoom'
					subscription: 'roomSearch'
					field: 'name'
					template: Template.roomSearch
					noMatchTemplate: Template.roomSearchEmpty
					matchAll: true
					filter: { uid: { $ne: Meteor.userId() } }
					sort: 'name'
				}
			]
		}

	isChannel: ->
		roomData = Session.get('roomData' + this._id)
		return '' unless roomData
		return roomData.t is 'c'

	canAddUser: ->
		roomData = Session.get('roomData' + this._id)
		return '' unless roomData
		return roomData.t in ['p', 'c'] and roomData.u?._id is Meteor.userId()

	canEditName: ->
		roomData = Session.get('roomData' + this._id)
		return '' unless roomData
		return roomData.u?._id is Meteor.userId() and roomData.t in ['c', 'p']

	canDirectMessage: ->
		return Meteor.user()?.username isnt this?.username

	roomNameEdit: ->
		return Session.get('roomData' + this._id)?.displayName

	editingTitle: ->
		return 'hidden' if Session.get('editRoomTitle')

	showEditingTitle: ->
		return 'hidden' if not Session.get('editRoomTitle')

	flexOpened: ->
		return 'opened' if Session.equals('flexOpened', true)

	arrowPosition: ->
		return 'left' unless Session.equals('flexOpened', true)

	phoneNumber: ->
		return '' unless this.phoneNumber
		if this.phoneNumber.length > 10
			return "(#{this.phoneNumber.substr(0,2)}) #{this.phoneNumber.substr(2,5)}-#{this.phoneNumber.substr(7)}"
		else
			return "(#{this.phoneNumber.substr(0,2)}) #{this.phoneNumber.substr(2,4)}-#{this.phoneNumber.substr(6)}"

	isGroupChat: ->
		room = ChatRoom.findOne(this._id, { reactive: false })
		return room?.t in ['c', 'p']

	userActiveByUsername: (username) ->
		status = Session.get 'user_' + username + '_status'
		if status in ['online', 'away', 'busy']
			message = ''
			statusMessages = Session.get('user_' + username + '_statusMessages')
			if (statusMessages?)
				message = statusMessages[status]
			return {username: username, status: status, customMessage: message}
		return {username: username, status: 'offline', customMessage: ''}

	roomUsers: ->
		room = ChatRoom.findOne(this._id, { reactive: false })
		users = []

		for username in room?.usernames or []
			user = getUser(username)
			users.push
				firstName: user?.firstName
				lastName: user?.lastName
				name: user?.name
				username: username
				status: user?.status

		users = _.sortBy users, 'lastName'

		ret =
			_id: this._id
			total: room?.usernames?.length or 0
			totalOnline: users.length
			users: users

		return ret

	flexUserInfo: ->
		username = Session.get('showUserInfo')
		userData = {}
		if username 
			message = ''
			status = Session.get 'user_' + username + '_status'
			if status in ['online', 'away', 'busy']
				statusMessages = Session.get('user_' + username + '_statusMessages')
				if (statusMessages?)
					message = statusMessages[status]

			userData = {
				name: getUser(username)?.name || username
				username: String(username)
				# TODO modify to find user similar to if admin below
				customMessage: message
				status: status
			}
			if Meteor.user()?.admin is true
				userData = _.extend userData, Meteor.users.findOne { username: String(username) }

		return userData

	seeAll: ->
		if Template.instance().showUsersOffline.get()
			return t('See_only_online')
		else
			return t('See_all')

	getPupupConfig: ->
		template = Template.instance()
		return {
			getInput: ->
				return template.find('.input-message')
		}

	remoteVideoUrl: ->
		return Session.get('remoteVideoUrl')

	selfVideoUrl: ->
		return Session.get('selfVideoUrl')

	videoActive: ->
		return (Session.get('remoteVideoUrl') || Session.get('selfVideoUrl'))

	remoteMonitoring: ->
		return (webrtc?.stackid? && (webrtc.stackid == 'webrtc-ib'))

	flexOpenedRTC1: ->
		return 'layout1' if Session.equals('flexOpenedRTC1', true)

	flexOpenedRTC2: ->
		return 'layout2' if Session.equals('flexOpenedRTC2', true)

	rtcLayout1: ->
		return (Session.get('rtcLayoutmode') == 1 ? true: false);

	rtcLayout2: ->
		return (Session.get('rtcLayoutmode') == 2 ? true: false);

	rtcLayout3: ->
		return (Session.get('rtcLayoutmode') == 3 ? true: false);

	noRtcLayout: ->
		return (!Session.get('rtcLayoutmode') || (Session.get('rtcLayoutmode') == 0) ? true: false);

	permissions: ->
		# The data context only contains the room id. one way to get the banner data is to just pass
		# this id to a server-side method and let it look up the room details (such as permissions)
		# and then return the banner info.
		#
		# HOWEVER, doing it this way does not allow the banner to be reactive in case the underlying
		# room data changes (eg, if someone edits Mongo manually). This is because the template has
		# no way of knowing if anything changed, so the method never gets called again. One way around
		# this is to make "bannerData" itself reactive by having it depend directly on the room data.
		# Then, since that data gets synchronized with the server, the template will be reprocessed
		# when the data changes.

		roomData = Session.get('roomData' + this._id)
		if roomData
			Template.instance().accessPermissions.set roomData?.accessPermissions
		else
			Template.instance().accessPermissions.set []

		return Template.instance().accessPermissions
	canEditPermissions: ->
		roomData = Session.get('roomData' + this._id)
		return false unless roomData
		return roomData.t in ['d','p']

	maxMessageLength: ->
		return RocketChat.settings.get('Message_MaxAllowedSize')

	isAdmin: ->
		return Meteor.user()?.admin is true

	utc: ->
		if @utcOffset?
			return "UTC #{@utcOffset}"
	
	phoneNumber: ->
		return '' unless @phoneNumber
		if @phoneNumber.length > 10
			return "(#{@phoneNumber.substr(0,2)}) #{@phoneNumber.substr(2,5)}-#{@phoneNumber.substr(7)}"
		else
			return "(#{@phoneNumber.substr(0,2)}) #{@phoneNumber.substr(2,4)}-#{@phoneNumber.substr(6)}"
	
	lastLogin: ->
		if @lastLogin
			return moment(@lastLogin).format('LLL')

	canJoin: ->
		return !! ChatRoom.findOne { _id: @_id, t: 'c' }

	canRecordAudio: ->
		return navigator.getUserMedia? or navigator.webkitGetUserMedia?


Template.room.events
	"touchstart .message": (e, t) ->
		message = this._arguments[1]
		doLongTouch = ->
			mobileMessageMenu.show(message, t)

		t.touchtime = Meteor.setTimeout doLongTouch, 2000

	"touchend .message": (e, t) ->
		Meteor.clearTimeout t.touchtime

	"touchmove .message": (e, t) ->
		Meteor.clearTimeout t.touchtime

	"touchcancel .message": (e, t) ->
		Meteor.clearTimeout t.touchtime

	"click .upload-progress-item > a": ->
		Session.set "uploading-cancel-#{this.id}", true

	"click .flex-tab .more": (event) ->
		if (Session.get('flexOpened'))
			Session.set('rtcLayoutmode', 0)
			Session.set('flexOpened',false)
		else
			Session.set('flexOpened', true)


	"click .flex-tab  .video-remote" : (e) ->
		if (Session.get('flexOpened'))
			if (!Session.get('rtcLayoutmode'))
				Session.set('rtcLayoutmode', 1)
			else
				t = Session.get('rtcLayoutmode')
				t = (t + 1) % 4
				console.log  'setting rtcLayoutmode to ' + t  if window.rocketDebug
				Session.set('rtcLayoutmode', t)

	"click .flex-tab  .video-self" : (e) ->
		if (Session.get('rtcLayoutmode') == 3)
			console.log 'video-self clicked in layout3' if window.rocketDebug
			i = document.getElementById("fullscreendiv")
			if i.requestFullscreen
				i.requestFullscreen()
			else
				if i.webkitRequestFullscreen
					i.webkitRequestFullscreen()
				else
					if i.mozRequestFullScreen
						i.mozRequestFullScreen()
					else
						if i.msRequestFullscreen
							i.msRequestFullscreen()

	'click .toggle-favorite': (event) ->
		event.stopPropagation()
		event.preventDefault()
		Meteor.call 'toogleFavorite', @_id, !$('i', event.currentTarget).hasClass('favorite-room')

	'click .join': (event) ->
		event.stopPropagation()
		event.preventDefault()
		Meteor.call 'joinRoom', @_id

	'focus .input-message': (event) ->
		KonchatNotification.removeRoomNotification @_id

	'keyup .input-message': (event) ->
		Template.instance().chatMessages.keyup(@_id, event, Template.instance())

	'paste .input-message': (e) ->
		if not e.originalEvent.clipboardData?
			return

		items = e.originalEvent.clipboardData.items
		files = []
		for item in items
			if item.kind is 'file' and item.type.indexOf('image/') isnt -1
				e.preventDefault()
				files.push
					file: item.getAsFile()
					name: 'Clipboard'

		fileUpload files

	'keydown .input-message': (event) ->
		Template.instance().chatMessages.keydown(@_id, event, Template.instance())

	'click .message-form .icon-paper-plane': (event) ->
		input = $(event.currentTarget).siblings("textarea")
		Template.instance().chatMessages.send(this._id, input.get(0))
		event.preventDefault()
		event.stopPropagation()
		input.focus()
		input.get(0).updateAutogrow()

	'click .add-user': (event) ->
		toggleAddUser()

	'click .edit-room-title': (event) ->
		event.preventDefault()
		Session.set('editRoomTitle', true)
		$(".fixed-title").addClass "visible"
		Meteor.setTimeout ->
			$('#room-title-field').focus().select()
		, 10

	'keydown #user-add-search': (event) ->
		if event.keyCode is 27 # esc
			toggleAddUser()

	'keydown #room-title-field': (event) ->
		if event.keyCode is 27 # esc
			Session.set('editRoomTitle', false)
		else if event.keyCode is 13 # enter
			renameRoom @_id, $(event.currentTarget).val()

	'blur #room-title-field': (event) ->
		# TUDO: create a configuration to select the desired behaviour
		# renameRoom this._id, $(event.currentTarget).val()
		Session.set('editRoomTitle', false)
		$(".fixed-title").removeClass "visible"

	"click .flex-tab .user-image > a" : (e) ->
		Session.set('flexOpened', true)
		Session.set('showUserInfo', $(e.currentTarget).data('username'))

	'click .user-card-message': (e) ->
		roomData = Session.get('roomData' + this._arguments[1].rid)
		if roomData.t in ['c', 'p']
			Session.set('flexOpened', true)
			Session.set('showUserInfo', $(e.currentTarget).data('username'))
		else
			Session.set('flexOpened', true)

	'click .user-view nav .back': (e) ->
		Session.set('showUserInfo', null)

	'click .user-view nav .pvt-msg': (e) ->
		console.log 'room click .user-view nav .pvt-msg' if window.rocketDebug
		# determine if we're creating new room or opening existing room.  DM uses
		# usernames for room id
		me = Meteor.user().username
		to = Session.get('showUserInfo')
		rid = [me, to].sort().join('')
		if ChatSubscription.findOne({rid:rid})
			# conversation already exists
			FlowRouter.go('direct', {username:Session.get('showUserInfo')})
		else
			# close side nav if it's open
			if SideNav.flexStatus
				SideNav.setFlex null
				SideNav.closeFlex( ->
					# sidenav is animated so need to wait for it to close if open
					SideNav.setFlex "directMessagesFlex", {user: to }
					SideNav.openFlex()
				)
		# removed direct call to createDirectMessage because we need to set security labels first

	'click button.load-more': (e) ->
		RoomHistoryManager.getMore @_id

	'autocompleteselect #user-add-search': (event, template, doc) ->
		roomData = Session.get('roomData' + Session.get('openedRoom'))

		if roomData.t is 'd'
			Meteor.call 'createGroupRoom', roomData.usernames, doc.username, (error, result) ->
				if error
					return Errors.throw error.reason

				if result?.rid?
					$('#user-add-search').val('')
		else if roomData.t in ['c', 'p']
			Meteor.call 'addUserToRoom', { rid: roomData._id, username: doc.username }, (error, result) ->
				if error
					return toastr.error error.reason

				$('#user-add-search').val('')
				toggleAddUser()

	'autocompleteselect #room-search': (event, template, doc) ->
		if doc.type is 'u'
			Meteor.call 'createDirectMessage', doc.username, (error, result) ->
				if error
					return Errors.throw error.reason

				if result?.rid?
					FlowRouter.go('direct', { username: doc.username })
					$('#room-search').val('')
		else if doc.type is 'r'
			if doc.t is 'c'
				FlowRouter.go('channel', { name: doc.name })
			else if doc.t is 'p'
				FlowRouter.go('group', { name: doc.name })

			$('#room-search').val('')

	# 'scroll .wrapper': (e, instance) ->
		# console.log 'room scroll .wrapper' if window.rocketDebug
		# if e.currentTarget.offsetHeight + e.currentTarget.scrollTop o e.currentTarget.scrollHeight
		# 	instance.scrollOnBottom = false
		# else
		# 	instance.scrollOnBottom = true
		# 	$('.new-message').addClass('not')

	'click .new-message': (e) ->
		Template.instance().atBottom = true
		Template.instance().find('.input-message').focus()

	'click .see-all': (e, instance) ->
		instance.showUsersOffline.set(!instance.showUsersOffline.get())

	"mousedown .edit-message": (e) ->
		Template.instance().chatMessages.edit(e.currentTarget.parentNode.parentNode)
		# Session.set 'editingMessageId', undefined
		# Meteor.defer ->
		# 	Session.set 'editingMessageId', self._id
		# 	Meteor.defer ->
		# 		$('.input-message-editing').select()

	"click .mention-link": (e) ->
		channel = $(e.currentTarget).data('channel')
		if channel?
			FlowRouter.go 'channel', {name: channel}
			return

		Session.set('flexOpened', true)
		Session.set('showUserInfo', $(e.currentTarget).data('username'))

	'click .image-to-download': (event) ->
		ChatMessage.update {_id: this._arguments[1]._id, 'urls.url': $(event.currentTarget).data('url')}, {$set: {'urls.$.downloadImages': true}}

	'click .delete-message': (event) ->
		message = @_arguments[1]
		msg = event.currentTarget.parentNode.parentNode
		instance = Template.instance()
		return if msg.classList.contains("system")
		swal {
			title: t('Are_you_sure')
			text: t('You_will_not_be_able_to_recover')
			type: 'warning'
			showCancelButton: true
			confirmButtonColor: '#DD6B55'
			confirmButtonText: t('Yes_delete_it')
			cancelButtonText: t('Cancel')
			closeOnConfirm: false
			html: false
		}, ->
			swal 
				title: t('Deleted')
				text: t('Your_entry_has_been_deleted')
				type: 'success'
				timer: 1000
				showConfirmButton: false 

			instance.chatMessages.deleteMsg(message)

	'click .start-video': (event) ->
		_id = Template.instance().data._id
		webrtc.to = _id.replace(Meteor.userId(), '')
		webrtc.room = _id
		webrtc.mode = 1
		webrtc.start(true)

	'click .stop-video': (event) ->
		webrtc.stop()

	'click .monitor-video': (event) ->
		_id = Template.instance().data._id
		webrtc.to = _id.replace(Meteor.userId(), '')
		webrtc.room = _id
		webrtc.mode = 2
		webrtc.start(true)


	'click .setup-video': (event) ->
		webrtc.mode = 2
		webrtc.activateLocalStream()


	'dragenter .dropzone': (e) ->
		e.currentTarget.classList.add 'over'

	'dragleave .dropzone-overlay': (e) ->
		e.currentTarget.parentNode.classList.remove 'over'

	'dropped .dropzone-overlay': (event) ->
		event.currentTarget.parentNode.classList.remove 'over'

		e = event.originalEvent or event
		files = e.target.files
		if not files or files.length is 0
			files = e.dataTransfer?.files or []

		filesToUpload = []
		for file in files
			filesToUpload.push
				file: file
				name: file.name

		fileUpload filesToUpload

	'change .message-form input[type=file]': (event, template) ->
		e = event.originalEvent or event
		files = e.target.files
		if not files or files.length is 0
			files = e.dataTransfer?.files or []

		filesToUpload = []
		for file in files
			filesToUpload.push
				file: file
				name: file.name

		fileUpload filesToUpload

	'click .message-form .mic': (e, t) ->
		AudioRecorder.start ->
			t.$('.stop-mic').removeClass('hidden')
			t.$('.mic').addClass('hidden')

	'click .message-form .stop-mic': (e, t) ->
		AudioRecorder.stop (blob) ->
			fileUpload [{
				file: blob
				type: 'audio'
				name: 'Audio record'
			}]

		t.$('.stop-mic').addClass('hidden')
		t.$('.mic').removeClass('hidden')

	'click .deactivate': ->
		username = Session.get('showUserInfo')
		user = Meteor.users.findOne { username: String(username) }
		Meteor.call 'setUserActiveStatus', user?._id, false, (error, result) ->
			if result
				toastr.success t('User_has_been_deactivated')
			if error
				toastr.error error.reason
	
	'click .activate': ->
		username = Session.get('showUserInfo')
		user = Meteor.users.findOne { username: String(username) }
		Meteor.call 'setUserActiveStatus', user?._id, true, (error, result) ->
			if result
				toastr.success t('User_has_been_activated')
			if error
				toastr.error error.reason

	'click .security-banner': (event) ->
		event.stopPropagation()
		event.preventDefault()
		data = {}
		roomId = Template.instance().data._id
		data.relabelRoom = roomId
		roomData = Session.get('roomData' + roomId)
		if roomData.t is 'd'
			SideNav.setFlex "directMessagesFlex", data
		else if roomData.t is 'p'
			SideNav.setFlex "privateGroupsFlex", data
		else 
			console.log "The room's security label cannot be modified" if window.rocketDebug
			return

		SideNav.openFlex()
		console.log "Relabel a Room: " + roomId

Template.room.onCreated ->
	console.log 'room.onCreated' if window.rocketDebug
	self = this
	# this.scrollOnBottom = true
	# this.typing = new msgTyping this.data._id
	this.showUsersOffline = new ReactiveVar true
	this.atBottom = true
	this.accessPermissions = new ReactiveVar []

	# If current user is admin, subscribe to full user data
	if Meteor.user()?.admin is true
		Tracker.autorun ->
			if Session.get('showUserInfo') and not Meteor.users.findOne Session.get 'showUserInfo'
				Meteor.subscribe 'fullUsers', Session.get('showUserInfo'), 1

	# If current user is admin, subscribe to full user data
	if Meteor.user()?.admin is true
		Tracker.autorun ->
			if Session.get('showUserInfo') and not Meteor.users.findOne Session.get 'showUserInfo'
				Meteor.subscribe 'fullUsers', Session.get('showUserInfo'), 1

Template.room.onRendered ->
	FlexTab.check()
	this.chatMessages = new ChatMessages
	this.chatMessages.init(this.firstNode)
	# ScrollListener.init()

	wrapper = this.find('.wrapper')
	newMessage = this.find(".new-message")

	template = this

	onscroll = _.throttle ->
		template.atBottom = wrapper.scrollTop >= wrapper.scrollHeight - wrapper.clientHeight
	, 200

	Meteor.setInterval ->
		if template.atBottom
			wrapper.scrollTop = wrapper.scrollHeight - wrapper.clientHeight
			newMessage.className = "new-message not"
	, 100

	wrapper.addEventListener 'touchstart', ->
		template.atBottom = false

	wrapper.addEventListener 'touchend', ->
		onscroll()

	wrapper.addEventListener 'scroll', ->
		template.atBottom = false
		onscroll()

	wrapper.addEventListener 'mousewheel', ->
		template.atBottom = false
		onscroll()

	wrapper.addEventListener 'wheel', ->
		template.atBottom = false
		onscroll()

	# salva a data da renderização para exibir alertas de novas mensagens
	$.data(this.firstNode, 'renderedAt', new Date)

	webrtc.onRemoteUrl = (url) ->
		Session.set('flexOpened', true)
		Session.set('remoteVideoUrl', url)

	webrtc.onSelfUrl = (url) ->
		Session.set('flexOpened', true)
		Session.set('selfVideoUrl', url)

	RoomHistoryManager.getMoreIfIsEmpty this.data._id

renameRoom = (rid, name) ->
	name = name?.toLowerCase().trim()
	console.log 'room renameRoom' if window.rocketDebug
	room = Session.get('roomData' + rid)
	if room.displayName is name
		Session.set('editRoomTitle', false)
		return false

	Meteor.call 'saveRoomName', rid, name, (error, result) ->
		if result
			Session.set('editRoomTitle', false)
			# If room was renamed then close current room and send user to the new one
			RoomManager.close room.t + room.name
			switch room.t
				when 'c'
					FlowRouter.go 'channel', name: result.slugName
				when 'p'
					FlowRouter.go 'group', name: result.slugName

			toastr.success t('Room_name_changed_successfully')
		if error
			if error.error is 'name-invalid'
				toastr.error t('Invalid_room_name', name)
				return
			if error.error is 'duplicate-name'
				if room.t is 'c'
					toastr.error t('Duplicate_channel_name', name)
				else
					toastr.error t('Duplicate_private_group_name', name)
				return
			toastr.error error.reason

toggleAddUser = ->
	console.log 'room toggleAddUser' if window.rocketDebug
	btn = $('.add-user')
	$('.add-user-search').toggleClass('show-search')
	if $('i', btn).hasClass('icon-plus')
		$('#user-add-search').focus()
		$('i', btn).removeClass('icon-plus').addClass('icon-cancel')
	else
		$('#user-add-search').val('')
		$('i', btn).removeClass('icon-cancel').addClass('icon-plus')

getUser = (username) ->
	# convert user's username to name
	allUsers = RoomManager.allUsers.get()
	allUsers[username]
