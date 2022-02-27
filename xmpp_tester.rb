#!/usr/bin/env ruby

# Created by Ryan Jeffrey

require 'blather/client/dsl'

puts "logging in..."

PUBSUB_HOST = 'chat.ryanmj.xyz'
TEST_NODE = 'testNode'

# Test module that implements the DSL.
module XMPPTest
  extend Blather::DSL
  def self.run; client.run; end

  setup 'ryan@ryanmj.xyz', 'IAmErr0r'
  when_ready {
    puts 'Done logging in.'

    puts "Connected ! as #{jid.stripped}."
    begin
      # puts 'Setting up a new node...'
      # write_to_stream Blather::Stanza::PubSub::Create.new(:set, 'ryanmj.xyz', 'testNode')
      # puts 'Done Setting up a new node.'

      puts 'Setting up a subscription...'
      write_to_stream Blather::Stanza::PubSub::Subscribe.new(:set, PUBSUB_HOST, TEST_NODE, Blather::JID.new('ryan@ryanmj.xyz'))
      puts 'Done setting up a subscription.'

      puts 'Writing a test publish...'
      write_to_stream Blather::Stanza::PubSub::Publish.new(PUBSUB_HOST, TEST_NODE, :set, 'This is my TEST PAYLOAD!!!!!')
      puts 'Done writing test publish.'

      while true
        sleep 5
        puts 'Requesting items from the server...'
        write_to_stream Blather::Stanza::PubSub::Items.request(PUBSUB_HOST, TEST_NODE)
        puts 'Done requesting items.'
      end
    rescue => e
      STDERR.puts "Error in setting up pubsub for #{jid.stripped}"
      pp e, STDERR
      EM.stop
    end
  }

  disconnected { puts "Disconnected ! from #{jid.stripped}." }

  subscription do |stanza|
    puts 'We got a subscription'
    write_to_stream stanza.approve!
  end

  pubsub_subscriptions do |stanza|
    puts 'We got a pubsub subscriptions!'
    pp stanza
  end

  pubsub_publish do |stanza|
    puts 'We got a pubsub publish!'
    pp stanza
  end

  pubsub_subscription do |stanza|
    puts 'We got a pubsub subscription!'
    pp stanza
  end

  pubsub_event do |stanza|
    puts 'We got a pubsub event!'
    pp stanza
  end

  pubsub_items do |stanza|
    puts 'We got a pubsub item!'
    pp stanza
  end

  pubsub_create do |stanza|
    puts 'We got a pubsub create node event!'
    pp stanza
  end

  message do |m|
    puts 'Got a message:'
    pp m
  end

  status do |status|
    puts 'Got a status:'
    pp status
  end

  handle :error do |err|
    puts 'Got an error from the server'
    pp err
  end

  # iq do |stanza, xpath_result|
  #   puts 'Got an IQ'
  #   pp stanza
  #   puts ''
  #   pp xpath_result
  #   puts ''
  # end
end

#helper = pubsub

# Catpture sigint and sigterm
trap(:INT) { EM.stop }
trap(:TERM) { EM.stop }
# Run event machine.

# Run.
EM.run do
  XMPPTest.run
end
