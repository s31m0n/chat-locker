Meteor.startup ->
	Meteor.users.find({}, { fields: { name: 1, username: 1, pictures: 1, status: 1, emails: 1, phone: 1, services: 1, 'profile.statusMessages':1 } }).observe
		added: (user) ->
			Session.set('user_' + user.username + '_status', user.status)
			if user.profile?.statusMessages?
				Session.set('user_' + user.username + '_statusMessages', user.profile.statusMessages)
		changed: (user) ->
			Session.set('user_' + user.username + '_status', user.status)
			if user.profile?.statusMessages?
				#console.log 'Changed user 1: ', user.profile.statusMessages
				Session.set('user_' + user.username + '_statusMessages', user.profile.statusMessages)
		removed: (user) ->
			Session.set('user_' + user.username + '_status', null)
			Session.set('user_' + user.username + '_statusMessages', null)
