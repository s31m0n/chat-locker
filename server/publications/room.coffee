Meteor.publish 'room', (typeName) ->
	unless this.userId
		return this.ready()

	console.log '[publish] room ->'.green, 'arguments:', arguments

	user = Meteor.users.findOne this.userId, fields: username: 1

	if typeName
		if typeof typeName isnt 'string'
			return this.ready()

		type = typeName.substr(0, 1)
		name = typeName.substr(1)

		query = {}

		if type in ['c', 'p']
			query =
				t: type
				name: name

			if type is 'p'
				query.usernames = user.username

		else if type is 'd'
			query =
				t: 'd'
				usernames:
					$all: [user.username, name]

		# Change to validate access manualy
		# if not Meteor.call 'canAccessRoom', rid, this.userId
		# 	return this.ready()

		ChatRoom.find query,
			fields:
				name: 1
				displayName: 1
				t: 1
				cl: 1
				u: 1
				usernames: 1
				accessPermissions: 1


	# if no parameter is specified, return all room records of which the user is a member
	# (membership implies the user can access)
	else
		ChatRoom.find
			usernames: user.username
		,
			fields:
				name: 1
				t: 1
				cl: 1
				u: 1
				usernames: 1
				accessPermissions: 1

