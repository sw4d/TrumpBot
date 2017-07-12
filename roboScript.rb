require 'twitter'
require 'open-uri'
require 'nokogiri'

twitClient = Twitter::REST::Client.new do |config|
  config.consumer_key        = 'YourKeyHere'
  config.consumer_secret     = 'YourSecretHere'
  config.access_token        = 'TwitAccessTokenHEre'
  config.access_token_secret = 'TwitSecretHere'
end

# I pass puniness @foxandfriends - Adore!

@dKey = ENV['THESAURUS_KEY']
@bestWords = ['America', 'Congress']

def prtCheck(docs)
	docs.css('fl').map { |x| x.text }
end

def partOfSpeechCheck(docs)
	prtCheckMap = prtCheck(docs)
	adj = prtCheckMap.include?('adjective')
	adv = prtCheckMap.include?('adverb')
	verb = prtCheckMap.include?('verb')

	return adj || adv || verb
end

def specialCharsScrub(word)
	hashtag = word[0] != '#'
	atSign = word[0] != '@'
	return hashtag && atSign
end

def scrubForNewValue(docs, word)
	prtCheckMap = prtCheck(docs)
	nuWord = nil

	if prtCheckMap.size == 1 && prtCheckMap.include?('verb')
		nuWord = docs.css('entry syn').text.split(', ').map { |y| y.split(' ').first }.sample
	else
		wordMap = docs.css('entry ant')
		if wordMap[4].nil?
			nuWord = wordMap.text.split(', ').map { |y| y.split(' ').first }.sample
		else
			nuWord = wordMap[4].text.split(', ').map { |y| y.split(' ').first }.sample
		end	
	end	
	nuWord.capitalize if word[0] == word.capitalize[0]
	return nuWord
end

def findWordInfo(word)
	if specialCharsScrub(word) && word.size > 1
		url = "http://www.dictionaryapi.com/api/v1/references/thesaurus/xml/#{word}?key=#{@dKey}"
		docs = Nokogiri::XML(open(url))
			if partOfSpeechCheck(docs)
				nuWord = scrubForNewValue(docs, word)
				return nuWord
			else
				return word
			end
	else
		return word
	end
end

# TODO theTweet does not account for when a retweet is most recent. need to grab all of the most recent tweets, then iterate through each
#  to filter out the retweets. Using a conditional like: if object.is_a?(Twitter::Tweet)
theTweet = twitClient.search("from:realdonaldtrump", result_type: "recent").take(1).first.text
finalProduct = []

words = theTweet.scan(/[\w'-@#]+/)
extras = theTweet.scan(/[^0-9A-Za-z'-@#]/)

words.each_with_index do |word, index|
	option = findWordInfo(word)
	option.upcase! if word == word.upcase
	option.capitalize! if word[0] == word.capitalize[0]

	finalProduct << option + extras[index]
end

#instead of puts, just blast to twitter world
puts finalProduct.join('')

#Hillary Clinton intrigue outcome diffuse Undemocratic Party openly soften cease further Level Bernie Sanders. Expire she prevent end hinder