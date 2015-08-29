###
# SecurityLabel is a named function that will add security label access permission(s) and legacy 
# label on messages
# @param {Object} message - The message object
###

numberComparator = (first, second) ->
	return first - second

# TODO need to set this from settings.
@Jedis.channelPermissions  = ->
	# network classification level
	networkClassification = (Jedis.settings.get 'public' ).permission.classification.default
	# all reltos
	allRelTo = Jedis.accessManager.getPermissionIdsByType(['Release Caveat'])
	return [].concat( networkClassification, allRelTo)

@Jedis.legacyLabel = (permissionIds) ->
	template = "classification|label_field|1+0|trigraphs|SAP_SCI|release_caveats|RELTO"
	permissions = new Jedis.AccessPermission permissionIds
	classificationIds = permissions.getPermissionIds 'classification'
	sapSciIds = (permissions.getPermissionIds ['SAP', 'SCI']).sort(numberComparator)
	releaseCaveatIds = (permissions.getPermissionIds ['Release Caveat']).sort(numberComparator)
	return template.replace('classification', classificationIds)
		.replace('SAP_SCI', sapSciIds)
		.replace('RELTO', releaseCaveatIds)

@Jedis.securityLabelIsValid = (permissionIds) ->
	console.log '[methods]Jedis.securityLabelIsValid -> '.green, 'permissionIds: ', permissionIds 
	isValid = false

	if permissionIds
		# check that ids exist
		permissions = Jedis.accessManager.getPermissions permissionIds

		isValid = permissionIds.length is permissions.length

		# check that only one classification exists
		if isValid 
			classifications = permissions.filter (permission) ->
				return permission?.type is 'classification'
			isValid = classifications.length is 1

		# check that system country code exists (RELTO type permission)
		if isValid
			isValid = _.contains( permissionIds, Meteor.settings.public.system.countryCode )

	return isValid

beforeSaveMessage = (message) ->
	roomId = message.rid
	room = @ChatRoom.findOne({_id: roomId});
	message.accessPermissions = room.accessPermissions
	message.securityLabel = room.securityLabel
			
	return message

beforeCreateChannel = (user, room) ->
	if room?.t in ['c']
		channelPermissions = Jedis.channelPermissions()
		# default access permission
		room.accessPermissions = channelPermissions
		room.securityLabel = Jedis.legacyLabel(channelPermissions)

# Add access permission and legacy security label field to message based on Room
# only applies to Direct message and Private group messages
RocketChat.callbacks.add 'beforeSaveMessage', beforeSaveMessage
# Add access permission and legacy security label fields to Channel
RocketChat.callbacks.add 'beforeCreateChannel', beforeCreateChannel