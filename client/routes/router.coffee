Blaze.registerHelper 'pathFor', (path, kw) ->
	return FlowRouter.path path, kw.hash

BlazeLayout.setRoot 'body'


FlowRouter.subscriptions = ->
	Tracker.autorun =>
		RoomManager.init()
		@register 'admin-settings', Meteor.subscribe('admin-settings')
		@register 'accessPermissions', Meteor.subscribe('accessPermissions')
		@register 'userData', Meteor.subscribe('userData')
		@register 'activeUsers', Meteor.subscribe('activeUsers')
		@register 'fullUsers', Meteor.subscribe('fullUsers')
		@register 'room', Meteor.subscribe('room')

FlowRouter.route '/',
	name: 'index'

	action: ->
		FlowRouter.go 'home'


FlowRouter.route '/login',
	name: 'login'

	action: ->
		FlowRouter.go 'home'


FlowRouter.route '/home',
	name: 'home'

	action: ->
		BlazeLayout.render 'main', {center: 'home'}
		KonchatNotification.getDesktopPermission()

FlowRouter.route '/changeavatar',
	name: 'changeAvatar'

	action: ->
		BlazeLayout.render 'main', {center: 'avatarPrompt'}

FlowRouter.route '/admin/users',
	name: 'admin-users'

	action: ->
		BlazeLayout.render 'main', {center: 'adminUsers'}


FlowRouter.route '/admin/rooms',
	name: 'admin-rooms'

	action: ->
		BlazeLayout.render 'main', {center: 'adminRooms'}


FlowRouter.route '/admin/statistics',
	name: 'admin-statistics'

	action: ->
		BlazeLayout.render 'main', {center: 'adminStatistics'}


FlowRouter.route '/admin/:group?',
	name: 'admin'

	action: ->
		BlazeLayout.render 'main', {center: 'admin'}


FlowRouter.route '/account/:group?',
	name: 'account'

	action: (params) ->
		unless params.group
			params.group = 'Profile'
		params.group = _.capitalize params.group, true
		BlazeLayout.render 'main', { center: "account#{params.group}" }

FlowRouter.route '/history/private',
	name: 'privateHistory'

	subscriptions: (params, queryParams) ->
		@register 'privateHistory', Meteor.subscribe('privateHistory')

	action: ->
		Session.setDefault('historyFilter', '')
		BlazeLayout.render 'main', {center: 'privateHistory'}


FlowRouter.route '/terms-of-service',
	name: 'terms-of-service'

	action: ->
		Session.set 'cmsPage', 'Layout_Terms_of_Service'
		BlazeLayout.render 'cmsPage'

FlowRouter.route '/privacy-policy',
	name: 'privacy-policy'

	action: ->
		Session.set 'cmsPage', 'Layout_Privacy_Policy'
		BlazeLayout.render 'cmsPage'

FlowRouter.route '/room-not-found/:type/:name',
	name: 'room-not-found'

	action: (params) ->
		Session.set 'roomNotFound', {type: params.type, name: params.name}
		BlazeLayout.render 'main', {center: 'roomNotFound'}

FlowRouter.route '/room-deleted/:type/:name',
	name: 'room-deleted'

	action: (params) ->
		Session.set 'roomDeleted', {type: params.type, name: params.name}
		BlazeLayout.render 'main', {center: 'roomDeleted'}
