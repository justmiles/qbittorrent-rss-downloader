FeedParser 	= require 'feedparser'
request 	  = require 'request'
qBittorrent = require('qbittorrent-client').API3
expisodeParser = require 'episode-parser'

downloadDir = process.env.DOWNLOAD_DIR or process.env.PATH_TO_TV_SHOWS
processAsTv = process.env.PROCESS_AS_TV or false

client = new qBittorrent
    username: process.env.QBITTORRENT_USERNAME
    password: process.env.QBITTORRENT_PASSWORD
    host: process.env.QBITTORRENT_HOST
    port: process.env.QBITTORRENT_PORT or 8080

req = request process.env.FEED_URL

feedparser = new FeedParser()

req.on 'error', (error) ->
  console.log error

req.on 'response', (res) ->
  stream = this
  if res.statusCode != 200
    return @emit('error', new Error('Bad status code'))
  stream.pipe feedparser

feedparser.on 'error', (error) ->
  console.log error

feedparser.on 'readable', ->
  stream = this
  while item = stream.read()
    if item.link?
      if processAsTv
        episodeInfo = expisodeParser item.title
        console.log "Adding #{episodeInfo.show} S#{episodeInfo.season}E#{episodeInfo.episode} to '#{downloadDir}/#{episodeInfo.show}/Season #{episodeInfo.season}/"
        options =
          urls: encodeURI(item.link)
          savepath: "#{downloadDir}/#{episodeInfo.show}/Season #{episodeInfo.season}/"
          category: process.env.QBITTORRENT_CATEGORY or episodeInfo.show
      else
        console.log "Adding #{item.title} to '#{downloadDir}/"
        options =
          urls: encodeURI(item.link)
          savepath: downloadDir
          category: process.env.QBITTORRENT_CATEGORY
          
      client.addTorrentFromURL options, (err, res)->
        console.log err if err
        console.log res if res
