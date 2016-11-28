dgram = require 'dgram'

miaGame = require './miaGame'
remotePlayer = require './remotePlayer'

class Server
	log = ->
	constructor: (@game, port) ->
		handleRawMessage = (message, rinfo) =>
			fromHost = rinfo.address
			fromPort = rinfo.port
			log "received '#{message}' from #{fromHost}:#{fromPort}"
			messageParts = message.toString().split ';'
			command = messageParts[0]
			args = messageParts[1..]
			@handleMessage command, args, new UdpConnection(fromHost, fromPort, @udpSocket)

		@players = {}
		@udpSocket = dgram.createSocket 'udp4', handleRawMessage
		@udpSocket.bind port
		@heartbeat = @startHeartbeat()

	enableLogging: -> log = console.log

	startHeartbeat: ->
		return setInterval () =>
			for id, player of @players
				player.heartbeat()
		, 2000

	handleMessage: (messageCommand, messageArgs, connection) ->
		log "handleMessage '#{messageCommand}' '#{messageArgs}' from #{connection.id}"
		if messageCommand == 'ECHO'
			if (messageArgs.length > 0)
				text = messageArgs.join('')
			else
				text = '42'
			@handleEcho text, connection
		else if messageCommand == 'REGISTER'
			name = messageArgs[0]
			@handleRegistration name, connection, false
		else if messageCommand == 'REGISTER_SPECTATOR'
			name = messageArgs[0]
			@handleRegistration name, connection, true
		else if messageCommand == 'UNREGISTER'
			player = @playerFor connection
			if player?
				@handleUnregistration player, connection
		else
			player = @playerFor connection
			player?.handleMessage messageCommand, messageArgs
	
	handleEcho: (text, connection) ->
		log "echoing: '#{text}'"
		connection.sendMessage "ECHOING;" + text

	handleRegistration: (name, connection, isSpectator) ->
		newPlayer = @createPlayer name, connection
		unless @isValidName name
			newPlayer.registrationRejected 'INVALID_NAME'
		else if @nameIsTakenByAnotherPlayer name, connection
			newPlayer.registrationRejected 'NAME_ALREADY_TAKEN'
		else
			@addPlayer connection, newPlayer, isSpectator

	handleUnregistration: (player, connection) ->
		delete @players[connection.id]
		@game.unregister player
		player.unregistered()

	isValidName: (name) ->
		name != '' and name.length <= 20 and not /[,;:\s]/.test name

	nameIsTakenByAnotherPlayer: (name, connection) ->
		existingPlayer = @findPlayerByName(name)
		existingPlayer and not connection.belongsTo existingPlayer

	findPlayerByName: (name) ->
		for key, player of @players
			return player if player.name == name
		null

	shutDown: ->
		clearInterval(@heartbeat)
		@udpSocket.close()

	playerFor: (connection) ->
		@players[connection.id]
	
	addPlayer: (connection, player, isSpectator) ->
		@players[connection.id] = player
		if isSpectator
			@game.registerSpectator player
		else
			@game.registerPlayer player
		player.registered()

	createPlayer: (name, connection) ->
		connection.createPlayer name
		
	class UdpConnection
		constructor: (@host, @port, @socket) ->
			@id = "#{@host}:#{@port}"
	
		belongsTo: (player) ->
			player.remoteHost == @host

		sendMessage: (message) ->
			buffer = new Buffer(message)
			@socket.send buffer, 0, buffer.length, @port, @host
	
		createPlayer: (name) ->
			sendMessageCallback = (message, withLogging) =>
				if withLogging
					log "sending '#{message}' to #{name} (#{@id})"
				@sendMessage message
			player = remotePlayer.create name, sendMessageCallback
			
			player.remoteHost = @host
			player
	


exports.start = (game, port) ->
	return new Server game, port
