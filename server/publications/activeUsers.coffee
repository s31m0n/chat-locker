Meteor.publish 'activeUsers', ->
	return this.ready();
	###
	this has been superceded by fullUsers 
	unless this.userId
		return this.ready()

	console.log '[publish] activeUsers'.green

	Meteor.users.find
		username:
			$exists: 1
		status:
			$in: ['online', 'away', 'busy']
	,
		fields:
			username: 1
			status: 1
			'profile.statusMessages': 1
			utcOffset: 1
	###
