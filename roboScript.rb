# copyright Stephen Ford 2019 all rights reserved
# frozen_string_literal: true

require 'twitter'
require 'open-uri'
require 'nokogiri'

TwitterClient = Twitter::REST::Client.new do |config|
  config.consumer_key        = 'YourKeyHere'
  config.consumer_secret     = 'YourSecretHere'
  config.access_token        = 'TwitAccessTokenHEre'
  config.access_token_secret = 'TwitSecretHere'
end

###############################################
# Returns the part of speech from the websters
# object
###############################################

def parts_of_speech(docs)
  docs.css('fl').map(&:text)
end

###############################################
# If a word doesn't have an antonym we may
# leave the word alone, or use a synonym
###############################################

def antonym?(docs)
  word_properties = parts_of_speech(docs)
  adj = word_properties.include?('adjective')
  adv = word_properties.include?('adverb')
  verb = word_properties.include?('verb')

  adj || adv || verb
end

###############################################
# A Regular word is one without special chars.
###############################################

def regular_word?(word)
  hash_tag = word[0] != '#'
  at_sign = word[0] != '@'
  hash_tag && at_sign
end

###############################################
# This method basically determines if a word
# should get an antonym or synonym. Once chosen
# the word is reformatted to match however it
# came from the original tweet
###############################################

def search_for_new_word(docs, _word)
  word_properties = parts_of_speech(docs)
  parse_drumpf_word(docs, word_properties)
end

def build_synonym(docs)
  docs.css('entry syn').text.split(', ').map { |y| y.split(' ').first }.sample
end

def build_antonym(antonyms)
  base_location(antonyms).split(', ').map { |y| y.split(' ').first }.sample
end

###############################################
# Our dictionary API can return antonyms in two
# different places depending on the kind of
# word it found. Hence the janky conditional
###############################################

def base_location(antonyms)
  if antonyms[4].nil?
    antonyms.text
  else
    antonyms[4].text
  end
end

def parse_drumpf_word(docs, word_properties)
  return build_synonym(docs) if word_properties.size == 1 && word_properties.include?('verb')

  antonyms = docs.css('entry ant')
  build_antonym(antonyms)
end

###############################################
# For every word in a tweet we analyze it to
# see what kind of mischief can be had with it
###############################################

def find_word_info(word)
  if regular_word?(word) && word.size > 1
    url = "http://www.dictionaryapi.com/api/v1/references/thesaurus/xml/#{word}?key=#{ENV['THESAURUS_KEY']}"
    docs = Nokogiri::XML(open(url))
    return search_for_new_word(docs, word) if antonym?(docs)
  else
    word
  end
end

recent_tweet = TwitterClient.search('from:realdonaldtrump', result_type: 'recent').take(1).first.text
reconstructed_words_for_tweet = []

words = recent_tweet.scan(/[\w'-@#]+/)
extras = recent_tweet.scan(/[^0-9A-Za-z'-@#]/)

words.each_with_index do |word, index|
  option = find_word_info(word)
  option.upcase! if word == word.upcase
  option.capitalize! if word[0] == word.capitalize[0]

  reconstructed_words_for_tweet << option + extras[index]
  reconstructed_words_for_tweet << option.to_s + extras[index].to_s
end

TwitterClient.tweet(reconstructed_words_for_tweet.join(''))
