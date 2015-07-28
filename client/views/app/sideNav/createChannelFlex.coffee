Template.createChannelFlex.helpers
	selectedUsers: ->
		return Template.instance().selectedUsers.get()

	name: ->
		return Template.instance().selectedUserNames[this.valueOf()]

	error: ->
		return Template.instance().error.get()

	roomName: ->
		return Template.instance().roomName.get()

	autocompleteSettings: ->
		return {
			limit: 10
			# inputDelay: 300
			rules: [
				{
					# @TODO maybe change this 'collection' and/or template
					#collection: 'UserAndRoom'
					subscription: 'roomSearch'
					field: 'username'
					template: Template.userSearch
					noMatchTemplate: Template.userSearchEmpty
					matchAll: true
					filter:
						type: 'u'
						$and: [
							{ _id: { $ne: Meteor.userId() } }
							{ username: { $nin: Template.instance().selectedUsers.get() } }
						]
					sort: 'username'
				}
			]
		}


	securityLabelsContext: ->
		return {
			onSelectionChanged: Template.instance().onSelectionChanged
			isOptionSelected: Template.instance().isOptionSelected
			isOptionDisabled: Template.instance().isOptionDisabled
			securityLabels: Template.instance().allowedLabels
		}




Template.createChannelFlex.events

	'autocompleteselect #channel-members': (event, instance, doc) ->
		instance.selectedUsers.set instance.selectedUsers.get().concat doc.username

		instance.selectedUserNames[doc.username] = doc.name

		event.currentTarget.value = ''
		event.currentTarget.focus()

	'click .remove-room-member': (e, instance) ->
		self = @

		users = Template.instance().selectedUsers.get()
		users = _.reject Template.instance().selectedUsers.get(), (_id) ->
			return _id is self.valueOf()

		Template.instance().selectedUsers.set(users)

		$('#channel-members').focus()




	'click header': (e, instance) ->
		SideNav.closeFlex()

	'click .cancel-channel': (e, instance) ->
		SideNav.closeFlex()

	'mouseenter header': ->
		SideNav.overArrow()

	'mouseleave header': ->
		SideNav.leaveArrow()

	'click footer .all': ->
		SideNav.setFlex "listChannelsFlex"

	'keydown input[type="text"]': (e, instance) ->
		Template.instance().error.set([])

	'click .save-channel': (e, instance) ->
		err = SideNav.validate()
		instance.roomName.set instance.find('#channel-name').value
		console.log err
		if not err
			accessPermissions = []
			Meteor.call 'createChannel', instance.find('#channel-name').value, instance.selectedUsers.get(), accessPermissions, (err, result) ->
				if err
					console.log err
					if err.error is 'name-invalid'
						instance.error.set({ invalid: true })
						return
					else
						return toastr.error err.reason

				SideNav.closeFlex()

				instance.clearForm()

				Router.go 'room', { _id: result.rid }
		else
			instance.error.set({ fields: err })

Template.createChannelFlex.onCreated ->


	Meteor.subscribe 'accessPermissions'

	instance = this
	instance.selectedUsers = new ReactiveVar []
	instance.selectedUserNames = {}
	instance.error = new ReactiveVar []
	instance.roomName = new ReactiveVar ''

	instance.clearForm = ->
		instance.error.set([])
		instance.roomName.set('')
		instance.selectedUsers.set([])
		instance.find('#channel-name').value = ''
		instance.find('#channel-members').value = ''


	# other conversation members
	instance.otherMembers = _.without(instance.data.members, Meteor.userId())
	# labels that all members have in common
	instance.allowedLabels = []
	# reactive trigger set to true when labels returned asynchronously from server
	instance.securityLabelsInitialized = new ReactiveVar(false)
	# selected security label access permission ids
	instance.selectedLabelIds = []
	instance.disabledLabelIds = []

	# adds/remove access permission ids from list of selected labels
	instance.onSelectionChanged = (params) ->
		if params.selected
			instance.selectedLabelIds.push params.selected
		else if params.deselected
			# remove deselected if it exist
			instance.selectedLabelIds = _.without(instance.selectedLabelIds, params.deselected)
	instance.isOptionSelected = (id) ->
		return _.contains instance.selectedLabelIds, id

	# determine if label is disabled
	instance.isOptionDisabled = (id) ->
		return _.contains instance.disabledLabelIds, id

	Meteor.call 'getAllowedConversationPermissions', { userIds: instance.otherMembers }, (error, result) ->
		if error
			alert error
		else
			# create shallow copies.  Adding id to both selected and disabled makes them "required"
			# in the UI because it selects the permission and doesn't allow the user to remove it.
			instance.selectedLabelIds = (result.selectedIds or []).slice(0)
			instance.disabledLabelIds = (result.disabledIds or []).slice(0)
			# initially select the default classification
			# TODO: fix the following line
			#instance.selectedLabelIds.push Meteor.settings.public.permission.classification.default
			instance.allowedLabels = result.allowed or []
			# Meteor will automatically re-run helper methods that populate select boxes.
			instance.securityLabelsInitialized.set true
